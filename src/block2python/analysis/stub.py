from __future__ import annotations

from typing import Any, cast

from block2python.contracts import AnalysisResult, AnalysisStatus, LevelSpec, RuleViolation, Submission

from .api import Analyzer


class StubAnalyzer(Analyzer):
    """
    A configurable fake analyzer used to bypass real AST structure checking.

    Configuration (optional):
      - level.metadata["stub_analysis"] = {
          "status": "PASS"|"FAIL"|"SYNTAX_ERROR",
          "summary": "...",
          "violations": [{"rule_id": "...", "message": "...", "severity": "ERROR"}]
        }
    Default behavior: PASS.
    """

    def analyze(self, submission: Submission, level: LevelSpec) -> AnalysisResult:
        cfg = cast(dict[str, Any], level.metadata.get("stub_analysis", {}))
        status_raw = str(cfg.get("status", AnalysisStatus.PASS.value)).upper()
        summary = str(cfg.get("summary", "StubAnalyzer: analysis not implemented yet."))

        try:
            status = AnalysisStatus(status_raw)
        except ValueError:
            status = AnalysisStatus.INTERNAL_ERROR
            summary = f"StubAnalyzer misconfigured status: {status_raw}"

        violations_raw = cfg.get("violations", ())
        violations: list[RuleViolation] = []
        if isinstance(violations_raw, list):
            for item in violations_raw:
                if not isinstance(item, dict):
                    continue
                rule_id = str(item.get("rule_id", "UNKNOWN"))
                message = str(item.get("message", ""))
                severity = str(item.get("severity", "ERROR")).upper()
                violations.append(RuleViolation(rule_id=rule_id, message=message, severity=severity))  # type: ignore[arg-type]

        return AnalysisResult(
            status=status,
            summary=summary,
            violations=tuple(violations),
            debug={"stub": True, "level_id": level.level_id, "python_len": len(submission.python_code)},
        )

