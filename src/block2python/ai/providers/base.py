from __future__ import annotations

import asyncio
import json
from abc import ABC, abstractmethod
from urllib import error, request

from ..models import TutorContext, TutorReplyType, TutorResponse


class TutorProvider(ABC):
    @abstractmethod
    async def reply(self, context: TutorContext, reply_type: TutorReplyType) -> TutorResponse:
        """Generate a tutor response from context and target reply type."""


class StubTutorProvider(TutorProvider):
    def __init__(self, *, message_prefix: str = "Stub tutor") -> None:
        self.message_prefix = message_prefix

    async def reply(self, context: TutorContext, reply_type: TutorReplyType) -> TutorResponse:
        content = (
            f"{self.message_prefix}: reply_type={reply_type}; "
            f"level={context.level_id}; question={context.student_question.strip() or '<empty>'}"
        )
        return TutorResponse(
            reply_type=reply_type,
            content=_truncate(content, context.answer_style.max_response_length),
            metadata={"provider": "stub"},
        )


class TemplateTutorProvider(TutorProvider):
    async def reply(self, context: TutorContext, reply_type: TutorReplyType) -> TutorResponse:
        if reply_type == "concept_explanation":
            content = self._concept_explanation(context)
        elif reply_type == "debug_hint":
            content = self._debug_hint(context)
        elif reply_type == "scope_refusal":
            content = self._scope_refusal(context)
        elif reply_type == "solution_refusal":
            content = self._solution_refusal(context)
        else:
            content = self._next_step_hint(context)

        content = _truncate(content, context.answer_style.max_response_length)
        return TutorResponse(reply_type=reply_type, content=content, metadata={"provider": "template"})

    @staticmethod
    def _concept_explanation(context: TutorContext) -> str:
        if context.allowed_concepts:
            concept = context.allowed_concepts[0]
            return (
                f"Focus on the concept '{concept}'. "
                f"Start from this level requirement: {context.level_prompt.strip() or 'follow the prompt'}"
            )
        return "Focus on the level prompt first, then explain your approach in one short sentence."

    @staticmethod
    def _next_step_hint(context: TutorContext) -> str:
        if context.hint_ladder:
            return context.hint_ladder[0]
        return "Start by identifying input, output, and one small operation to implement first."

    @staticmethod
    def _debug_hint(context: TutorContext) -> str:
        if context.analysis_violations:
            return f"Check this issue first: {context.analysis_violations[0]}"
        if context.failed_cases_summary:
            return f"Use the failed case signal: {context.failed_cases_summary}"
        if context.submission_history:
            return f"Start from your latest feedback: {context.submission_history[0]}"
        if context.hint_ladder:
            return context.hint_ladder[min(1, len(context.hint_ladder) - 1)]
        return "Re-check your input parsing and output format with one tiny sample."

    @staticmethod
    def _scope_refusal(context: TutorContext) -> str:
        if context.forbidden_concepts:
            forbidden = ", ".join(context.forbidden_concepts)
            return f"I cannot guide concepts outside this level scope: {forbidden}."
        return "I cannot help with out-of-scope concepts for this level."

    @staticmethod
    def _solution_refusal(context: TutorContext) -> str:
        if context.hint_ladder:
            return f"I cannot provide a full solution. Try this hint: {context.hint_ladder[0]}"
        return "I cannot provide a full solution, but I can provide step-by-step hints."


class LocalTemplateSelector(TutorProvider):
    def __init__(
        self,
        *,
        template_provider: TemplateTutorProvider | None = None,
        model_name: str = "qwen3.5:0.8b",
        endpoint_url: str = "",
        api_key: str = "",
        timeout_sec: float = 12.0,
        system_prompt: str | None = None,
    ) -> None:
        self.template_provider = template_provider or TemplateTutorProvider()
        self.model_name = model_name
        self.endpoint_url = endpoint_url
        self.api_key = api_key
        self.timeout_sec = timeout_sec
        self.system_prompt = system_prompt

    async def reply(self, context: TutorContext, reply_type: TutorReplyType) -> TutorResponse:
        selected, source = await self._resolve_reply_type(context, reply_type)
        base = await self.template_provider.reply(context, selected)
        metadata = dict(base.metadata)
        metadata.update(
            {
                "provider": "local_template_selector",
                "selector_model": self.model_name,
                "selected_reply_type": selected,
                "selector_source": source,
            }
        )
        if self.endpoint_url.strip():
            metadata["selector_endpoint"] = self.endpoint_url
        return TutorResponse(reply_type=base.reply_type, content=base.content, metadata=metadata)

    async def _resolve_reply_type(
        self,
        context: TutorContext,
        reply_type: TutorReplyType,
    ) -> tuple[TutorReplyType, str]:
        if not self.endpoint_url.strip():
            return self._select_reply_type(context, reply_type), "heuristic"

        try:
            selected = await asyncio.to_thread(self._select_reply_type_with_model, context, reply_type)
            return selected, "model"
        except Exception:  # noqa: BLE001
            return self._select_reply_type(context, reply_type), "heuristic_fallback"

    def _select_reply_type_with_model(
        self,
        context: TutorContext,
        reply_type: TutorReplyType,
    ) -> TutorReplyType:
        if reply_type in {"scope_refusal", "solution_refusal", "debug_hint"}:
            return reply_type

        response_json = self._call_selector_api(context, reply_type)
        selected = self._extract_reply_type(response_json)
        if selected is None:
            return self._select_reply_type(context, reply_type)
        return selected

    def _call_selector_api(self, context: TutorContext, reply_type: TutorReplyType) -> dict[str, object]:
        selector_system_prompt = self.system_prompt or (
            "You classify a tutoring reply type. "
            "Return JSON only, like {\"reply_type\": \"next_step_hint\"}."
        )
        selector_user_prompt = (
            "Choose one reply type from: concept_explanation, next_step_hint, debug_hint.\n"
            f"Requested default type: {reply_type}\n"
            f"Question: {context.student_question}\n"
            f"Analysis status: {context.analysis_status}\n"
            f"Failed case: {context.failed_cases_summary or '(none)'}\n"
            f"Recent feedback: {', '.join(context.submission_history) if context.submission_history else '(none)'}"
        )

        payload = {
            "model": self.model_name,
            "messages": [
                {"role": "system", "content": selector_system_prompt},
                {"role": "user", "content": selector_user_prompt},
            ],
            "temperature": 0,
        }

        body = json.dumps(payload).encode("utf-8")
        headers = {
            "Content-Type": "application/json",
        }
        if self.api_key.strip():
            headers["Authorization"] = f"Bearer {self.api_key}"

        req = request.Request(
            self.endpoint_url,
            data=body,
            headers=headers,
            method="POST",
        )

        with request.urlopen(req, timeout=self.timeout_sec) as resp:  # noqa: S310
            raw = resp.read().decode("utf-8")

        decoded = json.loads(raw)
        if not isinstance(decoded, dict):
            raise RuntimeError("Local selector returned non-object payload")
        return decoded

    @staticmethod
    def _extract_reply_type(payload: dict[str, object]) -> TutorReplyType | None:
        message_content = (
            (((payload.get("choices") or [{}])[0]).get("message") or {}).get("content") or ""
        )
        content = str(message_content).strip()
        if not content:
            return None

        candidates = {
            "concept_explanation",
            "next_step_hint",
            "debug_hint",
            "scope_refusal",
            "solution_refusal",
        }

        normalized = content.strip().lower()
        if normalized in candidates:
            return normalized  # type: ignore[return-value]

        try:
            decoded = json.loads(content)
        except json.JSONDecodeError:
            decoded = None

        if isinstance(decoded, dict):
            reply_type_raw = decoded.get("reply_type")
            if isinstance(reply_type_raw, str):
                reply_type_text = reply_type_raw.strip().lower()
                if reply_type_text in candidates:
                    return reply_type_text  # type: ignore[return-value]

        for candidate in candidates:
            if candidate in normalized:
                return candidate  # type: ignore[return-value]

        return None

    @staticmethod
    def _select_reply_type(context: TutorContext, reply_type: TutorReplyType) -> TutorReplyType:
        if reply_type in {"scope_refusal", "solution_refusal", "debug_hint"}:
            return reply_type

        question = context.student_question.strip().lower()
        if any(keyword in question for keyword in ("what is", "why", "explain", "為什麼", "是什麼")):
            return "concept_explanation"

        return reply_type


class OpenAICompatibleProvider(TutorProvider):
    def __init__(
        self,
        *,
        endpoint_url: str,
        model: str,
        api_key: str,
        timeout_sec: float = 30.0,
        system_prompt: str | None = None,
    ) -> None:
        self.endpoint_url = endpoint_url
        self.model = model
        self.api_key = api_key
        self.timeout_sec = timeout_sec
        self.system_prompt = system_prompt

    async def reply(self, context: TutorContext, reply_type: TutorReplyType) -> TutorResponse:
        response_json = await asyncio.to_thread(self._call_api, context, reply_type)

        content = (
            (((response_json.get("choices") or [{}])[0]).get("message") or {}).get("content") or ""
        ).strip()
        if not content:
            raise RuntimeError("OpenAI-compatible provider returned empty content")

        usage = response_json.get("usage")
        metadata = {
            "provider": "openai_compatible",
            "model": self.model,
            "usage": usage if isinstance(usage, dict) else {},
        }
        return TutorResponse(
            reply_type=reply_type,
            content=_truncate(content, context.answer_style.max_response_length),
            metadata=metadata,
        )

    def _call_api(self, context: TutorContext, reply_type: TutorReplyType) -> dict[str, object]:
        if not self.endpoint_url.strip():
            raise RuntimeError("OpenAI-compatible endpoint_url is required")
        if not self.api_key.strip():
            raise RuntimeError("OpenAI-compatible api_key is required")

        payload = {
            "model": self.model,
            "messages": [
                {"role": "system", "content": self.system_prompt or _build_system_prompt(context)},
                {"role": "user", "content": _build_user_prompt(context, reply_type)},
            ],
        }

        body = json.dumps(payload).encode("utf-8")
        req = request.Request(
            self.endpoint_url,
            data=body,
            headers={
                "Content-Type": "application/json",
                "Authorization": f"Bearer {self.api_key}",
            },
            method="POST",
        )

        try:
            with request.urlopen(req, timeout=self.timeout_sec) as resp:  # noqa: S310
                raw = resp.read().decode("utf-8")
        except error.URLError as exc:
            raise RuntimeError(f"OpenAI-compatible request failed: {exc}") from exc

        try:
            decoded = json.loads(raw)
        except json.JSONDecodeError as exc:
            raise RuntimeError("OpenAI-compatible provider returned invalid JSON") from exc

        if not isinstance(decoded, dict):
            raise RuntimeError("OpenAI-compatible provider returned non-object payload")

        return decoded


def _build_system_prompt(context: TutorContext) -> str:
    allowed = ", ".join(context.allowed_concepts) if context.allowed_concepts else "(not specified)"
    forbidden = ", ".join(context.forbidden_concepts) if context.forbidden_concepts else "(not specified)"
    return (
        "You are a programming tutor. Provide concise, scaffolded hints. "
        "Do not provide full solutions unless allow_full_solution is true. "
        f"Allowed concepts: {allowed}. Forbidden concepts: {forbidden}."
    )


def _build_user_prompt(context: TutorContext, reply_type: TutorReplyType) -> str:
    recent_feedback_text = "(none)"
    if context.submission_history:
        recent_feedback_text = "\n".join(f"- {item}" for item in context.submission_history)

    return (
        f"Reply type: {reply_type}\n"
        f"Level: {context.level_id} - {context.level_title}\n"
        f"Question: {context.student_question}\n"
        f"Current code:\n{context.current_code}\n"
        f"Recent feedback:\n{recent_feedback_text}\n"
        f"Failed case: {context.failed_cases_summary or '(none)'}"
    )


def _truncate(content: str, max_length: int) -> str:
    if max_length <= 0:
        return ""
    if len(content) <= max_length:
        return content
    if max_length <= 3:
        return content[:max_length]
    return content[: max_length - 3] + "..."
