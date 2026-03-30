from __future__ import annotations

from dataclasses import dataclass
from typing import Iterable

from .models import ConversationTurn


@dataclass(frozen=True, slots=True)
class HistoryCompressionResult:
    history: tuple[ConversationTurn, ...]
    summary: str | None
    token_estimate: int
    compressed: bool


class ConversationHistoryCompressor:
    def __init__(
        self,
        *,
        compress_trigger_tokens: int = 20_000,
        target_tokens: int = 10_000,
        keep_recent_turns: int = 8,
    ) -> None:
        self.compress_trigger_tokens = compress_trigger_tokens
        self.target_tokens = target_tokens
        self.keep_recent_turns = keep_recent_turns

    def compress(
        self,
        history: Iterable[ConversationTurn],
        existing_summary: str | None = None,
    ) -> HistoryCompressionResult:
        turns = tuple(history)
        estimated = _estimate_history_tokens(turns, existing_summary)
        if estimated <= self.compress_trigger_tokens:
            return HistoryCompressionResult(
                history=turns,
                summary=existing_summary,
                token_estimate=estimated,
                compressed=False,
            )

        kept_turns = turns[-self.keep_recent_turns:] if self.keep_recent_turns > 0 else ()
        dropped_turns = turns[: len(turns) - len(kept_turns)]
        dropped_summary = _summarize_turns(dropped_turns)

        if existing_summary and dropped_summary:
            merged_summary = f"{existing_summary}\n{dropped_summary}".strip()
        elif existing_summary:
            merged_summary = existing_summary
        else:
            merged_summary = dropped_summary

        while _estimate_history_tokens(kept_turns, merged_summary) > self.target_tokens and len(kept_turns) > 1:
            kept_turns = kept_turns[1:]

        return HistoryCompressionResult(
            history=kept_turns,
            summary=merged_summary,
            token_estimate=_estimate_history_tokens(kept_turns, merged_summary),
            compressed=True,
        )


def _estimate_history_tokens(turns: tuple[ConversationTurn, ...], summary: str | None) -> int:
    # Simple and deterministic estimate: ~4 chars per token.
    base_chars = sum(len(turn.content) + len(turn.role) for turn in turns)
    if summary:
        base_chars += len(summary)
    return max(1, base_chars // 4)


def _summarize_turns(turns: tuple[ConversationTurn, ...]) -> str:
    if not turns:
        return ""

    lines: list[str] = []
    for turn in turns:
        content = turn.content.replace("\n", " ").strip()
        if len(content) > 80:
            content = content[:77] + "..."
        lines.append(f"{turn.role}: {content}")

    return "Summary of previous conversation:\n" + "\n".join(lines)
