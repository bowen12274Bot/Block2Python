from __future__ import annotations

def main() -> int:
    print("Block2Python entrypoints")
    print("- Godot client: powershell -ExecutionPolicy Bypass -File tools/run_godot_client.ps1")
    print("- Bridge server: python -m block2python.integration.bridge_stdio.server")
    print("- CLI client: python -m block2python.clients.cli.main")
    print("- Legacy PySide6 client: python -m block2python.clients.pyside6")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
