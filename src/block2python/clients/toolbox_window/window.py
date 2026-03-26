from __future__ import annotations

import ctypes
import json
import uuid
from pathlib import Path

from block2python.clients.pyside6.blockly_embed import BlocklyEmbed, BlocklyOutput
from block2python.clients.pyside6.window_alignment import apply_window_rect, compute_target_rect

try:
    from PySide6.QtCore import QTimer, Qt
    from PySide6.QtGui import QCloseEvent
    from PySide6.QtWidgets import QVBoxLayout, QWidget
except ModuleNotFoundError as e:  # pragma: no cover
    raise RuntimeError("PySide6 is required to use the toolbox window.") from e


class ToolboxWindow(QWidget):
    def __init__(self, level_id: str, result_file: Path, html_path: Path, layout_file: Path) -> None:
        super().__init__()
        self._level_id = level_id
        self._result_file = result_file
        self._html_path = html_path
        self._layout_file = layout_file
        self._closed_written = False
        self._last_layout_signature: tuple[int, int, int, int, bool] | None = None

        self.setWindowTitle("Logic Toolbox")
        self.setWindowFlag(Qt.WindowType.Tool, True)
        self.setWindowFlag(Qt.WindowType.FramelessWindowHint, True)
        self.setWindowFlag(Qt.WindowType.WindowStaysOnTopHint, True)
        self.resize(920, 680)

        root = QVBoxLayout(self)
        root.setContentsMargins(0, 0, 0, 0)
        root.setSpacing(0)

        self._blockly = BlocklyEmbed()
        self._blockly.output_received.connect(self._on_blockly_output)
        self._blockly.message_received.connect(self._on_blockly_message)
        self._blockly.load_placeholder(self._html_path)
        root.addWidget(self._blockly, 1)

        self._sync_timer = QTimer(self)
        self._sync_timer.setInterval(700)
        self._sync_timer.timeout.connect(self._request_workspace_sync)
        self._sync_timer.start()

        self._layout_timer = QTimer(self)
        self._layout_timer.setInterval(120)
        self._layout_timer.timeout.connect(self._refresh_layout)
        self._layout_timer.start()
        self.hide()
        self._refresh_layout()

        self.setStyleSheet(
            """
            QWidget {
                background: #1f1f1f;
                color: #f3f3f3;
            }
            """
        )

    def closeEvent(self, event: QCloseEvent) -> None:
        if not self._closed_written:
            self._write_result({
                "status": "toolbox_closed",
                "level_id": self._level_id,
                "request_id": uuid.uuid4().hex,
            })
            self._closed_written = True
        super().closeEvent(event)

    def _request_workspace_sync(self) -> None:
        self._blockly.request_output()

    def _refresh_layout(self) -> None:
        try:
            raw = json.loads(self._layout_file.read_text(encoding="utf-8"))
        except Exception:
            return
        if not isinstance(raw, dict):
            return
        if str(raw.get("level_id", "")) not in {"", self._level_id}:
            return
        if not bool(raw.get("visible", False)):
            self.hide()
            self._last_layout_signature = None
            return

        target_rect = compute_target_rect(raw)
        if target_rect is None:
            return
        x, y, move_width, move_height = target_rect

        signature = (x, y, move_width, move_height, True)
        if signature == self._last_layout_signature:
            return
        self._last_layout_signature = signature

        if not self.isVisible():
            self.setFixedSize(move_width, move_height)
            self.move(x, y)
            self.show()
        if ctypes.windll.user32 is not None:
            apply_window_rect(int(self.winId()), x, y, move_width, move_height)
        else:
            self.setFixedSize(move_width, move_height)
            self.move(x, y)

    def _on_blockly_output(self, output: BlocklyOutput) -> None:
        self._write_result(
            {
                "status": "toolbox_sync",
                "request_id": uuid.uuid4().hex,
                "level_id": self._level_id,
                "python_code": output.python_code,
                "block_json": output.block_json,
            }
        )

    def _on_blockly_message(self, kind: str, message: str) -> None:
        normalized_status = "toolbox_error" if kind == "error" else "toolbox_status"
        self._write_result(
            {
                "status": normalized_status,
                "request_id": uuid.uuid4().hex,
                "level_id": self._level_id,
                "message": message,
            }
        )

    def _write_result(self, payload: dict) -> None:
        self._result_file.parent.mkdir(parents=True, exist_ok=True)
        tmp_path = self._result_file.with_suffix(self._result_file.suffix + ".tmp")
        tmp_path.write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")
        tmp_path.replace(self._result_file)
