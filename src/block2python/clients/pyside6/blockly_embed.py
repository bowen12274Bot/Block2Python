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
    message_received = Signal(str, str)

    @Slot(str, str)
    def setBlocklyOutput(self, python_code: str, block_json_str: str) -> None:  # noqa: N802
        self.output_received.emit(python_code, block_json_str)

    @Slot(str, str)
    def setBlocklyMessage(self, kind: str, message: str) -> None:  # noqa: N802
        self.message_received.emit(kind, message)


class BlocklyEmbed(QWebEngineView):
    output_received = Signal(object)
    message_received = Signal(str, str)

    def __init__(self) -> None:
        super().__init__()
        self._bridge = BlocklyBridge()
        self._bridge.output_received.connect(self._on_output_received)
        self._bridge.message_received.connect(self._on_message_received)
        self._pending_toolbox_block_ids: tuple[str, ...] | None = None

        channel = QWebChannel(self.page())
        channel.registerObject("bridge", self._bridge)
        self.page().setWebChannel(channel)
        self.loadFinished.connect(self._on_load_finished)

    def load_placeholder(self, html_path: Path) -> None:
        self.setUrl(QUrl.fromLocalFile(str(html_path.resolve())))

    def request_output(self) -> None:
        self.page().runJavaScript(
            "window.block2pythonSendOutputToBridge && window.block2pythonSendOutputToBridge();"
        )

    def set_toolbox_block_ids(self, block_ids: tuple[str, ...] | list[str]) -> None:
        self._pending_toolbox_block_ids = tuple(str(block_id) for block_id in block_ids)
        self._apply_toolbox_block_ids()

    def _on_output_received(self, python_code: str, block_json_str: str) -> None:
        try:
            raw = json.loads(block_json_str or "{}")
            if not isinstance(raw, dict):
                raw = {"_raw": raw}
        except Exception:  # noqa: BLE001
            raw = {"_parse_error": True, "_raw": block_json_str}

        self.output_received.emit(BlocklyOutput(python_code=python_code, block_json=raw))

    def _on_message_received(self, kind: str, message: str) -> None:
        self.message_received.emit(kind, message)

    def _on_load_finished(self, ok: bool) -> None:
        if ok:
            self._apply_toolbox_block_ids()

    def _apply_toolbox_block_ids(self) -> None:
        if self._pending_toolbox_block_ids is None:
            return
        payload = json.dumps(list(self._pending_toolbox_block_ids), ensure_ascii=True)
        self.page().runJavaScript(
            f"window.block2pythonConfigureToolbox && window.block2pythonConfigureToolbox({payload});"
        )
