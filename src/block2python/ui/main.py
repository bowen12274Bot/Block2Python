from __future__ import annotations

import sys

def main() -> int:
    try:
        from PySide6.QtWidgets import QApplication
    except ModuleNotFoundError:
        print("PySide6 is not installed for this Python interpreter.")
        print(f"Python: {sys.executable}")
        print(f"Version: {sys.version.splitlines()[0]}")
        print("Install (recommended): python -m pip install PySide6")
        return 1

    from .window import MainWindow

    app = QApplication([])
    window = MainWindow()
    window.show()
    return app.exec()
