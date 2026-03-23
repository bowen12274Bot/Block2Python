from __future__ import annotations

import json
import uuid
from pathlib import Path

from block2python.clients.pyside6.blockly_embed import BlocklyEmbed, BlocklyOutput

try:
    from PySide6.QtCore import QEvent, QPoint, Qt
    from PySide6.QtGui import QCloseEvent, QMouseEvent
    from PySide6.QtWidgets import QFrame, QHBoxLayout, QPushButton, QVBoxLayout, QWidget
except ModuleNotFoundError as e:  # pragma: no cover
    raise RuntimeError("PySide6 is required to use the toolbox window.") from e


class ToolboxWindow(QWidget):
    def __init__(self, level_id: str, result_file: Path, html_path: Path) -> None:
        super().__init__()
        self._level_id = level_id
        self._result_file = result_file
        self._html_path = html_path
        self._drag_offset: QPoint | None = None
        self._closed_written = False

        self.setWindowTitle("Logic Toolbox")
        self.setWindowFlag(Qt.WindowType.Tool, True)
        self.setWindowFlag(Qt.WindowType.FramelessWindowHint, True)
        self.setWindowFlag(Qt.WindowType.WindowStaysOnTopHint, True)
        self.resize(920, 680)

        root = QVBoxLayout(self)
        root.setContentsMargins(12, 12, 12, 12)
        root.setSpacing(10)

        self._blockly = BlocklyEmbed()
        self._blockly.output_received.connect(self._on_blockly_output)
        self._blockly.load_placeholder(self._html_path)
        root.addWidget(self._blockly, 1)

        self._footer = QFrame()
        self._footer.setObjectName("toolboxFooter")
        self._footer.installEventFilter(self)
        footer_layout = QHBoxLayout(self._footer)
        footer_layout.setContentsMargins(8, 8, 8, 8)
        footer_layout.setSpacing(8)
        footer_layout.addStretch(1)

        self._verify_button = QPushButton("Verify")
        self._verify_button.clicked.connect(self._on_verify_clicked)
        footer_layout.addWidget(self._verify_button)

        self._close_button = QPushButton("Close Toolbox")
        self._close_button.clicked.connect(self._on_close_clicked)
        footer_layout.addWidget(self._close_button)

        root.addWidget(self._footer)

        self.setStyleSheet(
            """
            QWidget {
                background: #1f1f1f;
                color: #f3f3f3;
            }
            QFrame#toolboxFooter {
                background: #2b2b2b;
                border-radius: 10px;
            }
            QPushButton {
                padding: 8px 14px;
                border-radius: 8px;
                background: #3b3b3b;
                color: #f3f3f3;
            }
            QPushButton:hover {
                background: #4a4a4a;
            }
            """
        )

    def eventFilter(self, watched: object, event: QEvent) -> bool:
        if watched is self._footer and isinstance(event, QMouseEvent):
            if event.type() == QEvent.Type.MouseButtonPress and event.button() == Qt.MouseButton.LeftButton:
                self._drag_offset = event.globalPosition().toPoint() - self.frameGeometry().topLeft()
                return True
            if event.type() == QEvent.Type.MouseMove and self._drag_offset is not None:
                self.move(event.globalPosition().toPoint() - self._drag_offset)
                return True
            if event.type() == QEvent.Type.MouseButtonRelease:
                self._drag_offset = None
                return True
        return super().eventFilter(watched, event)

    def closeEvent(self, event: QCloseEvent) -> None:
        if not self._closed_written:
            self._write_result({
                "status": "toolbox_closed",
                "level_id": self._level_id,
                "request_id": uuid.uuid4().hex,
            })
            self._closed_written = True
        super().closeEvent(event)

    def _on_verify_clicked(self) -> None:
        self._blockly.request_output()

    def _on_close_clicked(self) -> None:
        self._write_result({
            "status": "toolbox_closed",
            "level_id": self._level_id,
            "request_id": uuid.uuid4().hex,
        })
        self._closed_written = True
        self.close()

    def _on_blockly_output(self, output: BlocklyOutput) -> None:
        self._write_result(
            {
                "status": "verified_request",
                "request_id": uuid.uuid4().hex,
                "level_id": self._level_id,
                "python_code": output.python_code,
                "block_json": output.block_json,
            }
        )

    def _write_result(self, payload: dict) -> None:
        self._result_file.parent.mkdir(parents=True, exist_ok=True)
        tmp_path = self._result_file.with_suffix(self._result_file.suffix + ".tmp")
        tmp_path.write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")
        tmp_path.replace(self._result_file)
