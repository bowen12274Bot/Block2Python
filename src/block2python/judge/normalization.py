from __future__ import annotations

from block2python.contracts import OutputNormalization


def normalize_output(text: str, policy: OutputNormalization) -> str:
    normalized = text

    if policy.normalize_newlines_to_lf:
        normalized = normalized.replace("\r\n", "\n").replace("\r", "\n")

    if policy.strip_trailing_whitespace:
        normalized = "\n".join(line.rstrip() for line in normalized.split("\n"))

    if policy.strip_trailing_newline:
        normalized = normalized.rstrip("\n")

    return normalized
