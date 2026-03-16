from __future__ import annotations

from pathlib import Path

from block2python.app.core import AppCore, LevelState
from block2python.app.runtime import build_configured_app, default_progress_path
from block2python.contracts import LevelSpec, Submission

try:
    from PySide6.QtCore import Qt
    from PySide6.QtWidgets import (
        QAbstractItemView,
        QHBoxLayout,
        QLabel,
        QListWidget,
        QListWidgetItem,
        QMainWindow,
        QMessageBox,
        QPushButton,
        QPlainTextEdit,
        QSizePolicy,
        QSplitter,
        QTabWidget,
        QVBoxLayout,
        QWidget,
    )
except ModuleNotFoundError as e:  # pragma: no cover
    raise RuntimeError("PySide6 is required to use the UI. Install: pip install PySide6") from e

from .blockly_embed import BlocklyEmbed, BlocklyOutput


class MainWindow(QMainWindow):
    def __init__(self) -> None:
        super().__init__()
        self.setWindowTitle("Block2Python")
        self.resize(1100, 700)

        self._levels: dict[str, LevelSpec] = {}
        self._judge_info: str = ""
        self._app = AppCore({})
        self._block_json_by_level: dict[str, dict] = {}
        self._draft_code_by_level: dict[str, str] = {}

        root = QWidget()
        self.setCentralWidget(root)

        splitter = QSplitter()
        splitter.setChildrenCollapsible(False)

        self._levels_list = QListWidget()
        self._levels_list.setSelectionMode(QAbstractItemView.SelectionMode.SingleSelection)
        self._levels_list.currentItemChanged.connect(self._on_level_selected)
        splitter.addWidget(self._levels_list)

        right = QWidget()
        right_layout = QVBoxLayout(right)
        right_layout.setContentsMargins(12, 12, 12, 12)
        right_layout.setSpacing(8)

        header_row = QWidget()
        header_layout = QHBoxLayout(header_row)
        header_layout.setContentsMargins(0, 0, 0, 0)
        header_layout.setSpacing(8)

        self._level_title = QLabel("No level selected")
        self._level_title.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Preferred)
        header_layout.addWidget(self._level_title)

        self._reload_button = QPushButton("Reload Levels")
        self._reload_button.clicked.connect(self._reload_levels)
        header_layout.addWidget(self._reload_button)

        self._reset_progress_button = QPushButton("Reset Progress")
        self._reset_progress_button.clicked.connect(self._reset_progress)
        header_layout.addWidget(self._reset_progress_button)

        right_layout.addWidget(header_row)

        self._content_tabs = QTabWidget()

        self._prompt = QPlainTextEdit()
        self._prompt.setReadOnly(True)
        self._prompt.setPlaceholderText("任務 / 題目敘述")
        self._content_tabs.addTab(self._prompt, "任務")

        self._blockly = BlocklyEmbed()
        self._blockly.output_received.connect(self._on_blockly_output)
        self._content_tabs.addTab(self._blockly, "積木（WebEngine）")

        self._learning = QPlainTextEdit()
        self._learning.setReadOnly(True)
        self._learning.setPlaceholderText("教學內容（暫以純文字顯示）")
        self._content_tabs.addTab(self._learning, "教學")

        self._story_intro = QPlainTextEdit()
        self._story_intro.setReadOnly(True)
        self._story_intro.setPlaceholderText("劇情（開場）")
        self._content_tabs.addTab(self._story_intro, "劇情（前）")

        self._story_outro = QPlainTextEdit()
        self._story_outro.setReadOnly(True)
        self._story_outro.setPlaceholderText("劇情（結尾）")
        self._content_tabs.addTab(self._story_outro, "劇情（後）")

        self._content_tabs.setMinimumHeight(180)
        right_layout.addWidget(self._content_tabs)

        self._code = QPlainTextEdit()
        self._code.setPlaceholderText("Write Python code here...")
        self._code.setMinimumHeight(220)
        right_layout.addWidget(self._code, 1)

        actions_row = QWidget()
        actions_layout = QHBoxLayout(actions_row)
        actions_layout.setContentsMargins(0, 0, 0, 0)
        actions_layout.setSpacing(8)

        self._pass_block_button = QPushButton("Complete Block Step")
        self._pass_block_button.clicked.connect(self._pass_block_step)
        actions_layout.addWidget(self._pass_block_button)

        self._submit_button = QPushButton("Submit")
        self._submit_button.clicked.connect(self._submit)
        actions_layout.addWidget(self._submit_button)

        self._status = QLabel("")
        self._status.setTextInteractionFlags(Qt.TextInteractionFlag.TextSelectableByMouse)
        actions_layout.addWidget(self._status, 1)

        right_layout.addWidget(actions_row)

        self._feedback = QPlainTextEdit()
        self._feedback.setReadOnly(True)
        self._feedback.setPlaceholderText("Feedback")
        right_layout.addWidget(self._feedback, 1)

        splitter.addWidget(right)
        splitter.setStretchFactor(0, 0)
        splitter.setStretchFactor(1, 1)
        splitter.setSizes([280, 820])

        layout = QVBoxLayout(root)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.addWidget(splitter)

        self._reload_levels()

    def _progress_path(self) -> Path:
        return default_progress_path()

    def _reload_levels(self) -> None:
        try:
            self._app, self._levels, self._judge_info = build_configured_app()
        except Exception as e:  # noqa: BLE001
            QMessageBox.critical(self, "Failed to Load Levels", str(e))
            return

        self._blockly.load_placeholder(Path("assets") / "blockly" / "index.html")
        self._levels_list.clear()

        for view in self._app.list_levels():
            item = QListWidgetItem(f"{view.level_id}  {view.title}")
            item.setData(Qt.ItemDataRole.UserRole, view.level_id)
            item.setToolTip(f"State: {view.state}")
            self._levels_list.addItem(item)

        if self._levels_list.count() > 0:
            self._levels_list.setCurrentRow(0)
        self._refresh_ui_state()

    def _selected_level_id(self) -> str | None:
        item = self._levels_list.currentItem()
        if not item:
            return None
        level_id = item.data(Qt.ItemDataRole.UserRole)
        return str(level_id) if level_id else None

    def _on_level_selected(self, _current: QListWidgetItem | None, _previous: QListWidgetItem | None) -> None:
        prev_level_id = None
        if _previous is not None:
            prev_level_id_raw = _previous.data(Qt.ItemDataRole.UserRole)
            prev_level_id = str(prev_level_id_raw) if prev_level_id_raw else None
        if prev_level_id:
            self._draft_code_by_level[prev_level_id] = self._code.toPlainText()

        self._feedback.clear()
        self._status.setText("")

        level_id = self._selected_level_id()
        level = self._levels.get(level_id or "")
        if not level:
            self._level_title.setText("No level selected")
            self._prompt.setPlainText("")
            self._learning.setPlainText("")
            self._story_intro.setPlainText("")
            self._story_outro.setPlainText("")
            self._submit_button.setEnabled(False)
            return

        self._level_title.setText(f"{level.level_id} — {level.title}")
        self._prompt.setPlainText(level.prompt)
        self._learning.setPlainText(level.learning_markdown)
        self._story_intro.setPlainText(level.story_intro_markdown)
        self._story_outro.setPlainText(level.story_outro_markdown)

        if level.level_id in self._draft_code_by_level:
            self._code.setPlainText(self._draft_code_by_level[level.level_id])
        self._refresh_ui_state()

    def _refresh_ui_state(self) -> None:
        level_id = self._selected_level_id()
        if not level_id:
            self._submit_button.setEnabled(False)
            self._pass_block_button.setEnabled(False)
            return

        states = {v.level_id: v.state for v in self._app.list_levels()}
        state = states.get(level_id, LevelState.LOCKED)
        block_passed = self._app.is_block_passed(level_id)

        if state is LevelState.LOCKED:
            self._submit_button.setEnabled(False)
            self._pass_block_button.setEnabled(False)
            self._status.setText(f"State: LOCKED | block={'OK' if block_passed else 'TODO'} | cleared=NO")
        elif state is LevelState.CLEARED:
            self._submit_button.setEnabled(True)
            self._pass_block_button.setEnabled(not block_passed)
            self._status.setText(f"State: CLEARED | block={'OK' if block_passed else 'TODO'} | cleared=YES")
        else:
            self._pass_block_button.setEnabled(not block_passed)
            if block_passed:
                self._submit_button.setEnabled(True)
                self._status.setText("State: UNLOCKED | block=OK | cleared=NO")
            else:
                self._submit_button.setEnabled(False)
                self._status.setText("State: UNLOCKED | block=TODO | cleared=NO (complete block step first)")

    def _submit(self) -> None:
        level_id = self._selected_level_id()
        if not level_id:
            return
        code = self._code.toPlainText()
        block_json = self._block_json_by_level.get(level_id)
        block_schema_version = None
        if isinstance(block_json, dict) and "schema_version" in block_json:
            block_schema_version = str(block_json.get("schema_version"))
        submission = Submission(
            level_id=level_id,
            python_code=code,
            block_json=block_json,
            block_schema_version=block_schema_version,
        )
        outcome = self._app.submit(submission)

        lines: list[str] = []
        lines.append(f"analysis: {outcome.analysis.status} — {outcome.analysis.summary}")
        if outcome.analysis.violations:
            lines.append(f"violations: {len(outcome.analysis.violations)}")
            for v in outcome.analysis.violations[:10]:
                lines.append(f"- [{v.severity}] {v.rule_id}: {v.message}")

        lines.append(f"judge: {outcome.judge.status} — {outcome.judge.summary}")
        if self._judge_info:
            lines.append(self._judge_info)
        if outcome.judge.elapsed_ms is not None:
            lines.append(f"judge_elapsed_ms: {outcome.judge.elapsed_ms}")
        if outcome.judge.stderr:
            lines.append("judge_stderr:")
            lines.append(outcome.judge.stderr[:800])
        lines.append(f"cleared: {outcome.cleared}")
        lines.append(f"block_passed: {outcome.block_passed}")
        if block_schema_version:
            lines.append(f"block_schema_version: {block_schema_version}")
        if outcome.judge.case_results:
            lines.append(f"cases: {len(outcome.judge.case_results)} (failed={outcome.judge.failed_case_index})")
            for idx, cr in enumerate(outcome.judge.case_results[:5]):
                if cr.status == "PASS":
                    continue
                lines.append(f"- case[{idx}] {cr.status}")
                lines.append(f"  expected: {cr.expected_stdout!r}")
                lines.append(f"  actual:   {cr.actual_stdout!r}")
                if cr.elapsed_ms is not None:
                    lines.append(f"  elapsed_ms: {cr.elapsed_ms}")
                if cr.exit_code is not None:
                    lines.append(f"  exit_code: {cr.exit_code}")
                if cr.stderr:
                    lines.append(f"  stderr: {cr.stderr[:300]!r}")
        self._feedback.setPlainText("\n".join(lines))

        self._reload_levels()

    def _pass_block_step(self) -> None:
        level_id = self._selected_level_id()
        if not level_id:
            return
        ok = self._app.mark_block_passed(level_id)
        if not ok:
            QMessageBox.information(self, "Block Step", "Cannot mark block step passed (locked/unknown level).")
        self._reload_levels()

    def _on_blockly_output(self, output: BlocklyOutput) -> None:
        level_id = self._selected_level_id()
        if not level_id:
            return
        self._block_json_by_level[level_id] = output.block_json
        self._code.setPlainText(output.python_code)
        self._draft_code_by_level[level_id] = output.python_code

        self._app.mark_block_passed(level_id)
        self._refresh_ui_state()
        self._feedback.setPlainText("已從積木頁收到輸出：已填入 Python 並標記積木步驟通過。")

    def _reset_progress(self) -> None:
        reply = QMessageBox.question(
            self,
            "Reset Progress",
            "Delete local progress file and reset cleared levels?",
            QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No,
        )
        if reply is QMessageBox.StandardButton.No:
            return

        path = self._progress_path()
        try:
            if path.exists():
                path.unlink()
        except Exception as e:  # noqa: BLE001
            QMessageBox.warning(self, "Reset Failed", str(e))
            return

        self._reload_levels()
