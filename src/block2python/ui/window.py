from __future__ import annotations

from pathlib import Path

from block2python.app.core import AppCore, LevelState
from block2python.app.demo_levels import demo_levels
from block2python.app.progress import JsonFileProgress
from block2python.contracts import LevelSpec, Submission

try:
    from PySide6.QtCore import Qt
    from PySide6.QtWidgets import (
        QAbstractItemView,
        QApplication,
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
        QVBoxLayout,
        QWidget,
    )
except ModuleNotFoundError as e:  # pragma: no cover
    raise RuntimeError("PySide6 is required to use the UI. Install: pip install PySide6") from e


class MainWindow(QMainWindow):
    def __init__(self) -> None:
        super().__init__()
        self.setWindowTitle("Block2Python (Demo)")
        self.resize(1100, 700)

        self._levels: dict[str, LevelSpec] = {}
        self._app = AppCore({}, progress=JsonFileProgress(self._progress_path()))

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

        self._prompt = QPlainTextEdit()
        self._prompt.setReadOnly(True)
        self._prompt.setPlaceholderText("Prompt")
        self._prompt.setMinimumHeight(120)
        right_layout.addWidget(self._prompt)

        self._code = QPlainTextEdit()
        self._code.setPlaceholderText("Write Python code here...")
        self._code.setMinimumHeight(220)
        right_layout.addWidget(self._code, 1)

        actions_row = QWidget()
        actions_layout = QHBoxLayout(actions_row)
        actions_layout.setContentsMargins(0, 0, 0, 0)
        actions_layout.setSpacing(8)

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
        return Path(".block2python") / "progress.json"

    def _reload_levels(self) -> None:
        try:
            self._levels = demo_levels()
        except Exception as e:  # noqa: BLE001
            QMessageBox.critical(self, "Failed to Load Levels", str(e))
            return

        self._app = AppCore(self._levels, progress=JsonFileProgress(self._progress_path()))
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
        self._feedback.clear()
        self._status.setText("")

        level_id = self._selected_level_id()
        level = self._levels.get(level_id or "")
        if not level:
            self._level_title.setText("No level selected")
            self._prompt.setPlainText("")
            self._submit_button.setEnabled(False)
            return

        self._level_title.setText(f"{level.level_id} — {level.title}")
        self._prompt.setPlainText(level.prompt)
        self._refresh_ui_state()

    def _refresh_ui_state(self) -> None:
        level_id = self._selected_level_id()
        if not level_id:
            self._submit_button.setEnabled(False)
            return

        states = {v.level_id: v.state for v in self._app.list_levels()}
        state = states.get(level_id, LevelState.LOCKED)

        if state is LevelState.LOCKED:
            self._submit_button.setEnabled(False)
            self._status.setText("Locked (clear prerequisites first)")
        elif state is LevelState.CLEARED:
            self._submit_button.setEnabled(True)
            self._status.setText("Cleared (you can resubmit)")
        else:
            self._submit_button.setEnabled(True)
            self._status.setText("Unlocked")

    def _submit(self) -> None:
        level_id = self._selected_level_id()
        if not level_id:
            return
        code = self._code.toPlainText()
        submission = Submission(level_id=level_id, python_code=code)
        outcome = self._app.submit(submission)

        lines: list[str] = []
        lines.append(f"analysis: {outcome.analysis.status} — {outcome.analysis.summary}")
        if outcome.analysis.violations:
            lines.append(f"violations: {len(outcome.analysis.violations)}")
            for v in outcome.analysis.violations[:10]:
                lines.append(f"- [{v.severity}] {v.rule_id}: {v.message}")

        lines.append(f"judge: {outcome.judge.status} — {outcome.judge.summary}")
        lines.append(f"cleared: {outcome.cleared}")
        self._feedback.setPlainText("\n".join(lines))

        self._reload_levels()

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

