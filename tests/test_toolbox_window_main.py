from __future__ import annotations

from pathlib import Path

from block2python.clients.toolbox_window.main import build_parser


def test_toolbox_window_parser_accepts_layout_file() -> None:
    parser = build_parser()

    args = parser.parse_args(
        [
            "--level-id",
            "group-01-practice-01",
            "--result-file",
            str(Path("result.json")),
            "--html-path",
            str(Path("index.html")),
            "--layout-file",
            str(Path("layout.json")),
        ]
    )

    assert args.level_id == "group-01-practice-01"
    assert args.result_file.endswith("result.json")
    assert args.html_path.endswith("index.html")
    assert args.layout_file.endswith("layout.json")
