from __future__ import annotations

import ast

from block2python.contracts import AnalysisResult, AnalysisStatus, LevelSpec, RuleViolation, Submission

from .api import Analyzer


class AstAnalyzer(Analyzer):
    """
    MVP AST analyzer for the project establishment phase.

    Scope (MVP):
      - Syntax check (ast.parse)
      - Out-of-scope bans based on docs/requirements.md
      - Optional per-level keyword rules via LevelSpec.analysis_policy

    Non-goals (later):
      - Deep structural diff, CFG, mapping to Blockly, etc.
    """

    def analyze(self, submission: Submission, level: LevelSpec) -> AnalysisResult:
        code = submission.python_code or ""

        try:
            tree = ast.parse(code)
        except SyntaxError as e:
            violation = RuleViolation(
                rule_id="syntax.error",
                message=str(e.msg),
                severity="ERROR",
                line=getattr(e, "lineno", None),
                col=getattr(e, "offset", None),
            )
            return AnalysisResult(
                status=AnalysisStatus.SYNTAX_ERROR,
                summary="Syntax error",
                violations=(violation,),
            )
        except Exception as e:  # noqa: BLE001
            violation = RuleViolation(rule_id="analysis.internal_error", message=str(e), severity="ERROR")
            return AnalysisResult(status=AnalysisStatus.INTERNAL_ERROR, summary="Internal error", violations=(violation,))

        violations: list[RuleViolation] = []

        # Per-level keyword rules (establishment phase: simple string contains).
        required = level.analysis_policy.required_keywords
        forbidden = level.analysis_policy.forbidden_keywords
        if required:
            for kw in required:
                if kw and kw not in code:
                    violations.append(
                        RuleViolation(
                            rule_id=f"required.keyword.{kw}",
                            message=f"必須包含關鍵字：{kw}",
                            severity="ERROR",
                        )
                    )
        if forbidden:
            for kw in forbidden:
                if kw and kw in code:
                    violations.append(
                        RuleViolation(
                            rule_id=f"forbidden.keyword.{kw}",
                            message=f"禁止使用關鍵字：{kw}",
                            severity="ERROR",
                        )
                    )

        # Global out-of-scope bans (docs/requirements.md §2.3)
        visitor = _OutOfScopeVisitor()
        visitor.visit(tree)
        violations.extend(visitor.violations)

        if violations:
            return AnalysisResult(status=AnalysisStatus.FAIL, summary="Structure/scope check failed", violations=tuple(violations))

        return AnalysisResult(status=AnalysisStatus.PASS, summary="OK")


class _OutOfScopeVisitor(ast.NodeVisitor):
    def __init__(self) -> None:
        self.violations: list[RuleViolation] = []

    def _add(self, node: ast.AST, rule_id: str, message: str) -> None:
        self.violations.append(
            RuleViolation(
                rule_id=rule_id,
                message=message,
                severity="ERROR",
                line=getattr(node, "lineno", None),
                col=getattr(node, "col_offset", None),
            )
        )

    def visit_Import(self, node: ast.Import) -> None:  # noqa: N802
        self._add(node, "forbidden.import", "目前不允許使用 import（超出 Demo 範圍）")

    def visit_ImportFrom(self, node: ast.ImportFrom) -> None:  # noqa: N802
        self._add(node, "forbidden.import", "目前不允許使用 import（超出 Demo 範圍）")

    def visit_FunctionDef(self, node: ast.FunctionDef) -> None:  # noqa: N802
        self._add(node, "forbidden.def", "目前不允許使用 def（函式超出 Demo 範圍）")

    def visit_AsyncFunctionDef(self, node: ast.AsyncFunctionDef) -> None:  # noqa: N802
        self._add(node, "forbidden.def", "目前不允許使用 def（函式超出 Demo 範圍）")

    def visit_ClassDef(self, node: ast.ClassDef) -> None:  # noqa: N802
        self._add(node, "forbidden.class", "目前不允許使用 class（物件導向超出 Demo 範圍）")

    def visit_While(self, node: ast.While) -> None:  # noqa: N802
        self._add(node, "forbidden.while", "目前不允許使用 while（超出 Demo 範圍）")

    def visit_List(self, node: ast.List) -> None:  # noqa: N802
        self._add(node, "forbidden.list", "目前不允許使用 list（超出 Demo 範圍）")

    def visit_Dict(self, node: ast.Dict) -> None:  # noqa: N802
        self._add(node, "forbidden.dict", "目前不允許使用 dict（超出 Demo 範圍）")

    def visit_Tuple(self, node: ast.Tuple) -> None:  # noqa: N802
        self._add(node, "forbidden.tuple", "目前不允許使用 tuple（超出 Demo 範圍）")

