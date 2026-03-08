from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum
from typing import Any, Literal


@dataclass(frozen=True, slots=True)
class Testcase:
    stdin: str
    expected_stdout: str
    name: str | None = None


@dataclass(frozen=True, slots=True)
class OutputNormalization:
    strip_trailing_whitespace: bool = True
    normalize_newlines_to_lf: bool = True
    strip_trailing_newline: bool = True


@dataclass(frozen=True, slots=True)
class JudgePolicy:
    time_limit_ms: int = 2000
    memory_limit_kb: int | None = None
    output_normalization: OutputNormalization = field(default_factory=OutputNormalization)


@dataclass(frozen=True, slots=True)
class AnalysisPolicy:
    required_keywords: tuple[str, ...] = ()
    forbidden_keywords: tuple[str, ...] = ()


@dataclass(frozen=True, slots=True)
class ConceptPolicy:
    allowed_concepts: tuple[str, ...] = ()
    forbidden_concepts: tuple[str, ...] = ()


@dataclass(frozen=True, slots=True)
class LevelSpec:
    level_id: str
    title: str
    chapter_id: str | None = None
    quest_id: str | None = None
    order_index: int | None = None
    prompt: str = ""
    learning_markdown: str = ""
    story_intro_markdown: str = ""
    story_outro_markdown: str = ""
    prerequisite_level_ids: tuple[str, ...] = ()
    next_level_ids: tuple[str, ...] = ()
    testcases: tuple[Testcase, ...] = ()
    judge_policy: JudgePolicy = field(default_factory=JudgePolicy)
    analysis_policy: AnalysisPolicy = field(default_factory=AnalysisPolicy)
    concept_policy: ConceptPolicy = field(default_factory=ConceptPolicy)
    block_schema_version: str | None = None
    metadata: dict[str, Any] = field(default_factory=dict)


@dataclass(frozen=True, slots=True)
class Submission:
    level_id: str
    python_code: str
    block_json: dict[str, Any] | None = None
    block_schema_version: str | None = None
    submission_id: str | None = None


class JudgeStatus(str, Enum):
    AC = "AC"
    WA = "WA"
    TLE = "TLE"
    MLE = "MLE"
    RE = "RE"
    INTERNAL_ERROR = "INTERNAL_ERROR"


@dataclass(frozen=True, slots=True)
class CaseResult:
    status: Literal["PASS", "FAIL", "ERROR", "TIMEOUT", "MEMORY_LIMIT"]
    stdin: str
    expected_stdout: str
    actual_stdout: str = ""
    stderr: str = ""
    exit_code: int | None = None
    elapsed_ms: int | None = None


@dataclass(frozen=True, slots=True)
class JudgeResult:
    status: JudgeStatus
    summary: str = ""
    case_results: tuple[CaseResult, ...] = ()
    failed_case_index: int | None = None
    stdout: str = ""
    stderr: str = ""
    elapsed_ms: int | None = None
    debug: dict[str, Any] = field(default_factory=dict)


class AnalysisStatus(str, Enum):
    PASS = "PASS"
    FAIL = "FAIL"
    SYNTAX_ERROR = "SYNTAX_ERROR"
    INTERNAL_ERROR = "INTERNAL_ERROR"


@dataclass(frozen=True, slots=True)
class RuleViolation:
    rule_id: str
    message: str
    severity: Literal["ERROR", "WARNING"] = "ERROR"
    line: int | None = None
    col: int | None = None
    details: dict[str, Any] = field(default_factory=dict)


@dataclass(frozen=True, slots=True)
class AnalysisResult:
    status: AnalysisStatus
    summary: str = ""
    violations: tuple[RuleViolation, ...] = ()
    debug: dict[str, Any] = field(default_factory=dict)
