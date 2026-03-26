from __future__ import annotations

import argparse
from pathlib import Path


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="External Blockly toolbox window")
    parser.add_argument("--level-id", required=True)
    parser.add_argument("--result-file", required=True)
    parser.add_argument("--html-path", required=True)
    parser.add_argument("--layout-file", required=True)
    return parser


def main() -> int:
    try:
        from PySide6.QtWidgets import QApplication
    except ModuleNotFoundError:
        print("PySide6 is not installed for this Python interpreter.")
        return 1

    from .window import ToolboxWindow

    args = build_parser().parse_args()
    app = QApplication([])
    window = ToolboxWindow(
        level_id=args.level_id,
        result_file=Path(args.result_file),
        html_path=Path(args.html_path),
        layout_file=Path(args.layout_file),
    )
    return app.exec()
