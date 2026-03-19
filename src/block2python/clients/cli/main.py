from __future__ import annotations

from block2python.clients.bootstrap import build_configured_app, configured_levels_dir


def main() -> int:
    app, _levels, judge_info = build_configured_app()
    print("Block2Python")
    print(judge_info)
    print(f"levels_dir={configured_levels_dir()}")

    for view in app.list_levels():
        print(f"- {view.level_id}: {view.title} [{view.state}]")

    return 0

