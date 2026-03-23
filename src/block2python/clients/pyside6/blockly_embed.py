from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path

try:
    from PySide6.QtCore import QObject, QUrl, Signal, Slot
    from PySide6.QtWebChannel import QWebChannel
    from PySide6.QtWebEngineWidgets import QWebEngineView
except ModuleNotFoundError as e:  # pragma: no cover
    raise RuntimeError("PySide6 (with QtWebEngine) is required. Install: pip install PySide6") from e


@dataclass(frozen=True, slots=True)
class BlocklyOutput:
    python_code: str
    block_json: dict


class BlocklyBridge(QObject):
    output_received = Signal(str, str)

    @Slot(str, str)
    def setBlocklyOutput(self, python_code: str, block_json_str: str) -> None:  # noqa: N802
        self.output_received.emit(python_code, block_json_str)


class BlocklyEmbed(QWebEngineView):
    output_received = Signal(object)

    def __init__(self) -> None:
        super().__init__()
        self._bridge = BlocklyBridge()
        self._bridge.output_received.connect(self._on_output_received)

        channel = QWebChannel(self.page())
        channel.registerObject("bridge", self._bridge)
        self.page().setWebChannel(channel)

    def load_placeholder(self, html_path: Path) -> None:
        self.setUrl(QUrl.fromLocalFile(str(html_path.resolve())))

    def request_output(self) -> None:
        self.page().runJavaScript(
            "window.block2pythonSendOutputToBridge && window.block2pythonSendOutputToBridge();"
        )

    def _on_output_received(self, python_code: str, block_json_str: str) -> None:
        try:
            raw = json.loads(block_json_str or "{}")
            if not isinstance(raw, dict):
                raw = {"_raw": raw}
        except Exception:  # noqa: BLE001
            raw = {"_parse_error": True, "_raw": block_json_str}

        self.output_received.emit(BlocklyOutput(python_code=python_code, block_json=raw))
