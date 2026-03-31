from __future__ import annotations

import asyncio
import json
import logging
import os
from abc import ABC, abstractmethod
from urllib import error, request
from urllib.parse import urlsplit

from ..models import TutorContext, TutorReplyType, TutorResponse

logger = logging.getLogger(__name__)
tutor_thinking_logger = logging.getLogger("block2python.tutor_thinking")


TEMPLE_TEMPLATE_TABLE: dict[str, list[str]] = {
    "concept_explanation": [
        "allowed_concept_focus",
        "generic_concept_focus",
    ],
    "next_step_hint": [
        "hint_ladder_first",
        "generic_next_step",
    ],
    "debug_hint": [
        "analysis_violation_first",
        "runtime_error_signal",
        "runtime_error_generic",
        "failed_case_signal",
        "submission_feedback_first",
        "hint_ladder_secondary",
        "generic_debug",
    ],
    "scope_refusal": [
        "forbidden_concepts",
        "generic_scope_refusal",
    ],
    "solution_refusal": [
        "hint_ladder_redirect",
        "generic_solution_refusal",
    ],
}

SELECTOR_LOCKED_REPLY_TYPES: set[str] = {"scope_refusal", "solution_refusal", "debug_hint"}


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
            content, template_variant, reason_code = self._concept_explanation(context)
        elif reply_type == "debug_hint":
            content, template_variant, reason_code = self._debug_hint(context)
        elif reply_type == "scope_refusal":
            content, template_variant, reason_code = self._scope_refusal(context)
        elif reply_type == "solution_refusal":
            content, template_variant, reason_code = self._solution_refusal(context)
        else:
            content, template_variant, reason_code = self._next_step_hint(context)

        content = _truncate(content, context.answer_style.max_response_length)
        template_id = f"{reply_type}:{template_variant}"
        _log_provider_trace(
            "temple_template_selected",
            reply_type=reply_type,
            template_id=template_id,
            template_variant=template_variant,
            reason_code=reason_code,
        )
        _log_tutor_thinking(
            "temple_template_output",
            reply_type=reply_type,
            template_id=template_id,
            template_variant=template_variant,
            reason_code=reason_code,
            output=content,
        )
        return TutorResponse(
            reply_type=reply_type,
            content=content,
            metadata={
                "provider": "temple_template",
                "template_id": template_id,
                "template_variant": template_variant,
                "reason_code": reason_code,
            },
        )

    @staticmethod
    def _concept_explanation(context: TutorContext) -> tuple[str, str, str]:
        if context.allowed_concepts:
            concept = context.allowed_concepts[0]
            return (
                f"先聚焦在「{concept}」這個概念。"
                f"請從本關需求開始：{context.level_prompt.strip() or '請先依照題目需求整理思路'}",
                "allowed_concept_focus",
                "concept_from_allowed",
            )
        return (
            "先聚焦題目需求，再用一句話說明你目前的解題方向。",
            "generic_concept_focus",
            "concept_generic",
        )

    @staticmethod
    def _next_step_hint(context: TutorContext) -> tuple[str, str, str]:
        if context.hint_ladder:
            return context.hint_ladder[0], "hint_ladder_first", "next_step_from_hint_ladder"
        return (
            "先確認輸入與輸出，再挑一個最小步驟先實作。",
            "generic_next_step",
            "next_step_generic",
        )

    @staticmethod
    def _debug_hint(context: TutorContext) -> tuple[str, str, str]:
        if context.analysis_violations:
            return (
                f"先檢查這個問題：{context.analysis_violations[0]}",
                "analysis_violation_first",
                "debug_analysis_violation",
            )
        if context.judge_status == "RE":
            if context.failed_cases_summary:
                return (
                    f"這看起來是執行期錯誤（RE）。先從這個訊號檢查：{context.failed_cases_summary}",
                    "runtime_error_signal",
                    "debug_runtime_error",
                )
            return (
                "這看起來是執行期錯誤（RE）。先檢查未定義名稱、型別轉換與索引邊界。",
                "runtime_error_generic",
                "debug_runtime_error",
            )
        if context.failed_cases_summary:
            return (
                f"先利用這個失敗案例訊號定位問題：{context.failed_cases_summary}",
                "failed_case_signal",
                "debug_failed_case",
            )
        if context.submission_history:
            return (
                f"先從你最新一次回饋開始排查：{context.submission_history[0]}",
                "submission_feedback_first",
                "debug_submission_feedback",
            )
        if context.hint_ladder:
            return (
                context.hint_ladder[min(1, len(context.hint_ladder) - 1)],
                "hint_ladder_secondary",
                "debug_hint_ladder",
            )
        return (
            "用一組最小測資重新檢查輸入解析與輸出格式。",
            "generic_debug",
            "debug_generic",
        )

    @staticmethod
    def _scope_refusal(context: TutorContext) -> tuple[str, str, str]:
        if context.forbidden_concepts:
            forbidden = ", ".join(context.forbidden_concepts)
            return (
                f"我不能引導超出本關範圍的概念：{forbidden}。",
                "forbidden_concepts",
                "scope_forbidden_concepts",
            )
        return (
            "這個問題超出本關可引導的範圍。",
            "generic_scope_refusal",
            "scope_generic",
        )

    @staticmethod
    def _solution_refusal(context: TutorContext) -> tuple[str, str, str]:
        if context.hint_ladder:
            return (
                f"我不能直接提供完整解答。先試試這個提示：{context.hint_ladder[0]}",
                "hint_ladder_redirect",
                "solution_refusal_hint_ladder",
            )
        return (
            "我不能直接提供完整解答，但可以一步一步給你提示。",
            "generic_solution_refusal",
            "solution_refusal_generic",
        )


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
        selected, source, selector_reason = await self._resolve_reply_type(context, reply_type)
        base = await self.template_provider.reply(context, selected)
        metadata = dict(base.metadata)
        metadata.update(
            {
                "provider": "temple",
                "selector_model": self.model_name,
                "selected_reply_type": selected,
                "selector_source": source,
            }
        )
        if selector_reason:
            metadata["selector_reason"] = selector_reason
        if self.endpoint_url.strip():
            metadata["selector_endpoint"] = self.endpoint_url

        _log_provider_trace(
            "local_selector_reply",
            selector_model=self.model_name,
            selector_source=source,
            endpoint=_safe_endpoint(self.endpoint_url),
            requested_reply_type=reply_type,
            selected_reply_type=selected,
            template_id=metadata.get("template_id"),
            template_variant=metadata.get("template_variant"),
            reason_code=metadata.get("reason_code"),
            selector_reason=selector_reason,
            analysis_status=context.analysis_status,
            judge_status=context.judge_status,
            question_chars=len(context.student_question.strip()),
        )
        _log_tutor_thinking(
            "temple_selector_output",
            requested_reply_type=reply_type,
            selected_reply_type=selected,
            selector_source=source,
            selector_model=self.model_name,
            selector_reason=selector_reason,
            template_id=metadata.get("template_id"),
            template_variant=metadata.get("template_variant"),
            reason_code=metadata.get("reason_code"),
        )
        return TutorResponse(reply_type=base.reply_type, content=base.content, metadata=metadata)

    async def _resolve_reply_type(
        self,
        context: TutorContext,
        reply_type: TutorReplyType,
    ) -> tuple[TutorReplyType, str, str | None]:
        if reply_type in SELECTOR_LOCKED_REPLY_TYPES:
            _log_tutor_thinking(
                "temple_selector_skipped",
                requested_reply_type=reply_type,
                reason="policy_locked_reply_type",
                analysis_status=context.analysis_status,
                judge_status=context.judge_status,
            )
            return reply_type, "policy_locked", "policy_locked_reply_type"

        if context.judge_status == "AC":
            selected = self._select_reply_type(context, reply_type)
            _log_tutor_thinking(
                "temple_selector_skipped",
                requested_reply_type=reply_type,
                selected_reply_type=selected,
                reason="ac_short_circuit",
                analysis_status=context.analysis_status,
                judge_status=context.judge_status,
                question=context.student_question,
            )
            return selected, "heuristic_ac", "ac_short_circuit"

        _log_tutor_thinking(
            "temple_selector_input",
            requested_reply_type=reply_type,
            question=context.student_question,
            code_prompt=context.current_code or "(empty)",
            analysis_status=context.analysis_status,
            judge_status=context.judge_status,
            failed_case=context.failed_cases_summary or "(none)",
            recent_feedback=list(context.submission_history),
            skill_table=_build_skill_table(context),
            temple_table=_build_temple_table(),
        )

        if not self.endpoint_url.strip():
            selected = self._select_reply_type(context, reply_type)
            _log_provider_trace(
                "local_selector_heuristic_only",
                selector_model=self.model_name,
                requested_reply_type=reply_type,
                selected_reply_type=selected,
            )
            _log_tutor_thinking(
                "temple_selector_decision",
                mode="heuristic",
                requested_reply_type=reply_type,
                selected_reply_type=selected,
                reason="endpoint_not_configured",
            )
            return selected, "heuristic", "endpoint_not_configured"

        try:
            selected, selector_reason = await asyncio.to_thread(self._select_reply_type_with_model, context, reply_type)
            _log_provider_trace(
                "local_selector_model_selected",
                selector_model=self.model_name,
                endpoint=_safe_endpoint(self.endpoint_url),
                requested_reply_type=reply_type,
                selected_reply_type=selected,
                selector_reason=selector_reason,
            )
            _log_tutor_thinking(
                "temple_selector_decision",
                mode="model",
                requested_reply_type=reply_type,
                selected_reply_type=selected,
                reason=selector_reason,
            )
            return selected, "model", selector_reason
        except Exception as exc:  # noqa: BLE001
            selected = self._select_reply_type(context, reply_type)
            logger.warning("Local selector model call failed; using heuristic fallback: %s", exc)
            _log_provider_trace(
                "local_selector_model_fallback",
                selector_model=self.model_name,
                endpoint=_safe_endpoint(self.endpoint_url),
                requested_reply_type=reply_type,
                selected_reply_type=selected,
                error_type=type(exc).__name__,
                error=str(exc),
            )
            _log_tutor_thinking(
                "temple_selector_decision",
                mode="heuristic_fallback",
                requested_reply_type=reply_type,
                selected_reply_type=selected,
                reason=f"model_call_failed:{type(exc).__name__}",
            )
            return selected, "heuristic_fallback", f"model_call_failed:{type(exc).__name__}"

    def _select_reply_type_with_model(
        self,
        context: TutorContext,
        reply_type: TutorReplyType,
    ) -> tuple[TutorReplyType, str | None]:
        if reply_type in SELECTOR_LOCKED_REPLY_TYPES:
            return reply_type, "policy_locked_reply_type"

        response_json = self._call_selector_api(context, reply_type)
        selected, selector_reason, raw_model_output = self._extract_selector_decision(response_json)
        if selected is None:
            fallback = self._select_reply_type(context, reply_type)
            _log_tutor_thinking(
                "temple_selector_model_raw",
                requested_reply_type=reply_type,
                raw_output=raw_model_output,
                selected_reply_type=fallback,
                reason="invalid_model_response_fallback",
            )
            return fallback, "invalid_model_response_fallback"

        _log_tutor_thinking(
            "temple_selector_model_raw",
            requested_reply_type=reply_type,
            raw_output=raw_model_output,
            selected_reply_type=selected,
            reason=selector_reason,
        )
        return selected, selector_reason

    def _call_selector_api(self, context: TutorContext, reply_type: TutorReplyType) -> dict[str, object]:
        _log_provider_trace(
            "local_selector_model_call",
            selector_model=self.model_name,
            endpoint=_safe_endpoint(self.endpoint_url),
            requested_reply_type=reply_type,
            timeout_sec=self.timeout_sec,
            has_api_key=bool(self.api_key.strip()),
        )

        skill_table = _build_skill_table(context)
        temple_table = _build_temple_table()

        selector_system_prompt = self.system_prompt or (
            "你是教學回覆類型分類器。"
            "只回傳 JSON，例如 {\"reply_type\": \"next_step_hint\", \"reason\": \"一句簡短理由\"}。"
            "理由要精簡且可執行。"
        )
        selector_user_prompt = (
            "請在 concept_explanation、next_step_hint、debug_hint 中選一個回覆類型。\n"
            "請依據 code prompt + skill table + temple table 做判斷。\n"
            f"預設類型：{reply_type}\n"
            f"學生問題：{context.student_question}\n"
            f"目前程式碼：\n{context.current_code or '(空)'}\n"
            f"分析狀態：{context.analysis_status}\n"
            f"失敗案例：{context.failed_cases_summary or '(無)'}\n"
            f"近期回饋：{', '.join(context.submission_history) if context.submission_history else '(無)'}\n"
            f"Skill table JSON：{json.dumps(skill_table, ensure_ascii=False, sort_keys=True)}\n"
            f"Temple table JSON：{json.dumps(temple_table, ensure_ascii=False, sort_keys=True)}"
        )

        _log_tutor_thinking(
            "temple_selector_prompt",
            provider="temple",
            selector_model=self.model_name,
            requested_reply_type=reply_type,
            system_prompt=selector_system_prompt,
            user_prompt=selector_user_prompt,
            skill_table=skill_table,
            temple_table=temple_table,
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

        _log_tutor_thinking(
            "temple_selector_raw_response",
            selector_model=self.model_name,
            raw_response=raw,
        )

        decoded = json.loads(raw)
        if not isinstance(decoded, dict):
            raise RuntimeError("Local selector returned non-object payload")
        return decoded

    @staticmethod
    def _extract_selector_decision(payload: dict[str, object]) -> tuple[TutorReplyType | None, str | None, str]:
        message_content = (
            (((payload.get("choices") or [{}])[0]).get("message") or {}).get("content") or ""
        )
        content = str(message_content).strip()
        if not content:
            return None, None, ""

        candidates = {
            "concept_explanation",
            "next_step_hint",
            "debug_hint",
            "scope_refusal",
            "solution_refusal",
        }

        normalized = content.strip().lower()
        if normalized in candidates:
            return normalized, None, content  # type: ignore[return-value]

        try:
            decoded = json.loads(content)
        except json.JSONDecodeError:
            decoded = None

        if isinstance(decoded, dict):
            reply_type_raw = decoded.get("reply_type")
            reason_raw = decoded.get("reason") or decoded.get("rationale")
            reason = str(reason_raw).strip() if reason_raw is not None else None
            if isinstance(reply_type_raw, str):
                reply_type_text = reply_type_raw.strip().lower()
                if reply_type_text in candidates:
                    return reply_type_text, reason, content  # type: ignore[return-value]

        for candidate in candidates:
            if candidate in normalized:
                return candidate, None, content  # type: ignore[return-value]

        return None, None, content

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

        content, reasoning_fallback = _extract_openai_message_content(response_json)
        if not content:
            raise RuntimeError("OpenAI-compatible provider returned empty content")

        usage = response_json.get("usage")
        metadata = {
            "provider": "api_skill",
            "model": self.model,
            "usage": usage if isinstance(usage, dict) else {},
        }
        if reasoning_fallback:
            metadata["reasoning_fallback"] = True
        usage_dict = metadata["usage"] if isinstance(metadata["usage"], dict) else {}
        _log_provider_trace(
            "openai_compatible_reply",
            model=self.model,
            endpoint=_safe_endpoint(self.endpoint_url),
            reply_type=reply_type,
            content_chars=len(content),
            reasoning_fallback=reasoning_fallback,
            prompt_tokens=usage_dict.get("prompt_tokens"),
            completion_tokens=usage_dict.get("completion_tokens"),
            total_tokens=usage_dict.get("total_tokens"),
        )
        _log_tutor_thinking(
            "api_skill_output",
            reply_type=reply_type,
            model=self.model,
            output=content,
            usage=usage_dict,
        )
        return TutorResponse(
            reply_type=reply_type,
            content=_truncate(content, context.answer_style.max_response_length),
            metadata=metadata,
        )

    def _call_api(self, context: TutorContext, reply_type: TutorReplyType) -> dict[str, object]:
        if not self.endpoint_url.strip():
            raise RuntimeError("OpenAI-compatible endpoint_url is required")

        _log_provider_trace(
            "openai_compatible_call",
            model=self.model,
            endpoint=_safe_endpoint(self.endpoint_url),
            reply_type=reply_type,
            timeout_sec=self.timeout_sec,
        )

        skill_table = _build_skill_table(context)
        system_prompt = self.system_prompt or _build_system_prompt(context)
        user_prompt = _build_user_prompt(context, reply_type, skill_table=skill_table)
        _log_tutor_thinking(
            "api_skill_prompt",
            provider="api_skill",
            model=self.model,
            reply_type=reply_type,
            system_prompt=system_prompt,
            user_prompt=user_prompt,
            skill_table=skill_table,
            temple_table=_build_temple_table(),
        )

        payload = {
            "model": self.model,
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt},
            ],
            "temperature": 0,
            "max_tokens": _max_completion_tokens(context, model=self.model),
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


def _build_skill_table(context: TutorContext) -> dict[str, object]:
    mistakes = []
    for item in context.common_mistakes:
        mistakes.append(
            {
                "pattern": item.pattern,
                "diagnosis": item.diagnosis,
                "hint": item.hint,
            }
        )

    return {
        "teaching_skill_id": context.teaching_skill_id,
        "learning_goals": list(context.learning_goals),
        "allowed_concepts": list(context.allowed_concepts),
        "forbidden_concepts": list(context.forbidden_concepts),
        "hint_ladder": list(context.hint_ladder),
        "common_mistakes": mistakes,
        "refusal_rules": list(context.refusal_rules),
        "allow_full_solution": context.allow_full_solution,
        "answer_style": {
            "tone": context.answer_style.tone,
            "max_steps": context.answer_style.max_steps,
            "max_response_length": context.answer_style.max_response_length,
        },
    }


def _build_temple_table() -> dict[str, list[str]]:
    return dict(TEMPLE_TEMPLATE_TABLE)


def _extract_openai_message_content(payload: dict[str, object]) -> tuple[str, bool]:
    message = (((payload.get("choices") or [{}])[0]).get("message") or {})
    content = str(message.get("content") or "").strip()
    if content:
        return content, False

    reasoning = str(message.get("reasoning") or message.get("reasoning_content") or "").strip()
    if reasoning == "":
        return "", False

    candidate = _extract_final_answer_from_reasoning(reasoning)
    return candidate, True


def _extract_final_answer_from_reasoning(reasoning: str) -> str:
    text = reasoning.strip()
    if text == "":
        return ""

    markers = (
        "Final Answer:",
        "Final answer:",
        "Answer:",
        "最終答案：",
        "最終答案:",
        "最終回覆：",
        "最終回覆:",
        "答案：",
        "答案:",
    )
    lowered = text.lower()
    for marker in markers:
        index = lowered.rfind(marker.lower())
        if index >= 0:
            tail = text[index + len(marker):].strip()
            if tail != "":
                first_line = tail.splitlines()[0].strip()
                if first_line != "":
                    return first_line

    lines = [line.strip() for line in text.splitlines() if line.strip()]
    for line in reversed(lines):
        compact = line.replace("`", "").strip()
        if compact == "":
            continue
        if compact.lower().startswith("thinking process"):
            continue
        if compact.endswith(":"):
            continue
        if compact[0].isdigit() and compact.lstrip("0123456789").startswith("."):
            continue
        return compact

    return lines[-1] if lines else ""


def _build_system_prompt(context: TutorContext) -> str:
    allowed = ", ".join(context.allowed_concepts) if context.allowed_concepts else "(未指定)"
    forbidden = ", ".join(context.forbidden_concepts) if context.forbidden_concepts else "(未指定)"
    return (
        "你是程式學習導師。請提供精簡、可執行、循序漸進的提示。"
        "優先依照提供的 skill table 進行教學引導。"
        "請只輸出最終回覆，不要輸出思考過程或推理過程。"
        "除非 allow_full_solution 為 true，否則不要直接給完整解答。"
        f"允許概念：{allowed}。禁止概念：{forbidden}。"
    )


def _build_user_prompt(
    context: TutorContext,
    reply_type: TutorReplyType,
    *,
    skill_table: dict[str, object] | None = None,
) -> str:
    recent_feedback_text = "(無)"
    if context.submission_history:
        recent_feedback_text = "\n".join(f"- {item}" for item in context.submission_history)

    if skill_table is None:
        skill_table = _build_skill_table(context)

    skill_table_json = json.dumps(skill_table, ensure_ascii=False, sort_keys=True)

    return (
        f"回覆類型：{reply_type}\n"
        f"關卡：{context.level_id} - {context.level_title}\n"
        f"學生問題：{context.student_question}\n"
        f"目前程式碼：\n{context.current_code}\n"
        f"分析狀態：{context.analysis_status}\n"
        f"評測狀態：{context.judge_status}\n"
        f"近期回饋：\n{recent_feedback_text}\n"
        f"失敗案例：{context.failed_cases_summary or '(無)'}\n"
        f"Skill table JSON：{skill_table_json}"
    )


def _max_completion_tokens(context: TutorContext, *, model: str) -> int:
    # qwen3.5:9b on Ollama can be slow with very high token caps.
    # Keep this bound moderate and rely on reasoning fallback when content is empty.
    model_text = model.strip().lower()
    if model_text.startswith("qwen3.5:9b"):
        return 512

    target_chars = max(120, context.answer_style.max_response_length)
    estimated_tokens = target_chars // 2
    return max(96, min(384, estimated_tokens))


def _truncate(content: str, max_length: int) -> str:
    if max_length <= 0:
        return ""
    if len(content) <= max_length:
        return content
    if max_length <= 3:
        return content[:max_length]
    return content[: max_length - 3] + "..."


def _safe_endpoint(endpoint_url: str) -> str:
    text = endpoint_url.strip()
    if text == "":
        return ""

    parsed = urlsplit(text)
    if not parsed.scheme or not parsed.netloc:
        return text
    return f"{parsed.scheme}://{parsed.netloc}{parsed.path}"


def _log_provider_trace(event: str, **fields: object) -> None:
    payload = {"event": event, **fields}
    logger.info("TUTOR_TRACE %s", json.dumps(payload, ensure_ascii=False, default=str, sort_keys=True))
    logger.info("TUTOR_TRACE_HUMAN %s | %s", event, _humanize_trace_fields(fields))


def _log_tutor_thinking(event: str, **fields: object) -> None:
    payload = {"event": event, **fields}
    if _thinking_json_enabled():
        tutor_thinking_logger.info("TUTOR_THINKING %s", json.dumps(payload, ensure_ascii=False, default=str, sort_keys=True))
    tutor_thinking_logger.info("TUTOR_THINKING_HUMAN\n%s", _format_tutor_thinking_human(event, fields))


def _thinking_json_enabled() -> bool:
    raw = os.environ.get("BLOCK2PYTHON_TUTOR_THINKING_JSON", "").strip().lower()
    return raw in {"1", "true", "yes", "on"}


def _format_tutor_thinking_human(event: str, fields: dict[str, object]) -> str:
    lines = [f"event: {event}"]
    for key in sorted(fields.keys()):
        value = fields[key]
        lines.extend(_format_tutor_thinking_field(key, value))
    return "\n".join(lines)


def _format_tutor_thinking_field(key: str, value: object) -> list[str]:
    if isinstance(value, (dict, list, tuple, set)):
        pretty = json.dumps(value, ensure_ascii=False, default=str, indent=2, sort_keys=True)
        clipped = _clip_multiline(pretty, limit=4000)
        return [f"{key}:", _indent_block(clipped, "  ")]

    text = str(value)
    if "\n" in text:
        clipped = _clip_multiline(text, limit=4000)
        return [f"{key}:", _indent_block(clipped, "  ")]

    return [f"{key}: {_clip_single_line(text, limit=240)}"]


def _indent_block(text: str, prefix: str) -> str:
    return "\n".join(prefix + line for line in text.splitlines())


def _clip_single_line(text: str, *, limit: int) -> str:
    if len(text) <= limit:
        return text
    if limit <= 3:
        return text[:limit]
    return text[: limit - 3] + "..."


def _clip_multiline(text: str, *, limit: int) -> str:
    if len(text) <= limit:
        return text
    if limit <= 32:
        return text[:limit]
    clipped = text[: limit - 27]
    return clipped + "\n...(truncated)..."


def _humanize_trace_fields(fields: dict[str, object]) -> str:
    parts: list[str] = []
    for key in sorted(fields.keys()):
        parts.append(f"{key}={_humanize_trace_value(fields[key])}")
    return "; ".join(parts)


def _humanize_trace_value(value: object) -> str:
    if isinstance(value, dict):
        inner = ", ".join(f"{k}={_humanize_trace_value(v)}" for k, v in sorted(value.items(), key=lambda item: str(item[0])))
        return "{" + inner + "}"
    if isinstance(value, (list, tuple, set)):
        return "[" + ", ".join(_humanize_trace_value(item) for item in value) + "]"
    text = str(value)
    if len(text) > 160:
        return text[:157] + "..."
    return text
