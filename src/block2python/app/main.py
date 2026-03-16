<<<<<<< HEAD
from block2python.clients.cli.main import main

<<<<<<< HEAD
    from .core import AppCore
    from .demo_levels import demo_levels
    from .judge_factory import build_judge_from_env
    from .progress import JsonFileProgress

    judge, judge_info = build_judge_from_env()
    print("Block2Python (Demo)")
=======
def main() -> int:
    from .runtime import build_configured_app, configured_levels_dir

    app, _levels, judge_info = build_configured_app()
    print("Block2Python")
>>>>>>> merge/judge_introduction_branch
    print(judge_info)
    print(f"levels_dir={configured_levels_dir()}")

    for view in app.list_levels():
        print(f"- {view.level_id}: {view.title} [{view.state}]")

    return 0
<<<<<<< HEAD


def __progress_path():
    from pathlib import Path

    return Path(".block2python") / "progress.json"
=======
__all__ = ["main"]
>>>>>>> main
=======
>>>>>>> merge/judge_introduction_branch
