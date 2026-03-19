from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path

import pytest

from block2python.app import runtime
from block2python.app.main import main
from block2python.app.progress import InMemoryProgress, JsonFileProgress
from block2python.contracts import JudgePolicy, LevelSpec


def test_configured_levels_dir_from_env(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("BLOCK2PYTHON_LEVELS_DIR", "custom-levels")
    assert runtime.configured_levels_dir() == Path("custom-levels")


def test_configured_levels_dir_default(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.delenv("BLOCK2PYTHON_LEVELS_DIR", raising=False)
    assert runtime.configured_levels_dir() == Path("assets") / "levels"


def test_load_configured_levels_wraps_error(monkeypatch: pytest.MonkeyPatch) -> None:
    def _boom(_: Path) -> dict[str, LevelSpec]:
        raise runtime.LevelsLoadError("bad levels")

    monkeypatch.setattr(runtime, "load_levels", _boom)
    with pytest.raises(RuntimeError, match="Failed to load levels"):
        runtime.load_configured_levels()


def test_build_configured_app_wires_dependencies(monkeypatch: pytest.MonkeyPatch) -> None:
    levels = {
        "l1": LevelSpec(level_id="l1", title="L1", judge_policy=JudgePolicy()),
    }

    class DummyApp:
        pass

    dummy_app = DummyApp()

    class DummyProgress:
        def __init__(self, path: Path) -> None:
            self.path = path

    def _load_configured_levels() -> dict[str, LevelSpec]:
        return levels

    def _build_judge_from_env() -> tuple[object, str]:
        return object(), "judge=StubJudge"

    def _app_ctor(levels_arg: dict[str, LevelSpec], *, judge: object, progress: DummyProgress) -> DummyApp:
        assert levels_arg is levels
        assert isinstance(progress, DummyProgress)
        assert progress.path == Path(".block2python") / "progress.json"
        assert judge is not None
        return dummy_app

    monkeypatch.setattr(runtime, "load_configured_levels", _load_configured_levels)
    monkeypatch.setattr(runtime, "build_judge_from_env", _build_judge_from_env)
    monkeypatch.setattr(runtime, "JsonFileProgress", DummyProgress)
    monkeypatch.setattr(runtime, "AppCore", _app_ctor)

    app, loaded_levels, judge_info = runtime.build_configured_app()
    assert app is dummy_app
    assert loaded_levels is levels
    assert judge_info == "judge=StubJudge"


@dataclass
class _View:
    level_id: str
    title: str
    state: str


def test_main_prints_summary(monkeypatch: pytest.MonkeyPatch, capsys: pytest.CaptureFixture[str]) -> None:
    class DummyApp:
        def list_levels(self) -> tuple[_View, ...]:
            return (_View(level_id="demo", title="Demo Level", state="UNLOCKED"),)

    def _build() -> tuple[DummyApp, dict[str, LevelSpec], str]:
        return DummyApp(), {}, "judge=StubJudge"

    monkeypatch.setattr("block2python.app.runtime.build_configured_app", _build)
    monkeypatch.setattr("block2python.app.runtime.configured_levels_dir", lambda: Path("assets") / "levels")

    assert main() == 0
    out = capsys.readouterr().out
    assert "Block2Python" in out
    assert "judge=StubJudge" in out
    assert "- demo: Demo Level [UNLOCKED]" in out


def test_inmemory_progress_roundtrip() -> None:
    progress = InMemoryProgress.empty()
    assert not progress.is_cleared("x")
    assert not progress.is_block_passed("x")
    progress.mark_block_passed("x")
    progress.mark_cleared("x")
    assert progress.is_block_passed("x")
    assert progress.is_cleared("x")


def test_json_file_progress_save_and_load(tmp_path: Path) -> None:
    path = tmp_path / "progress.json"
    p1 = JsonFileProgress(path)
    p1.mark_block_passed("demo")
    p1.mark_cleared("demo")

    raw = json.loads(path.read_text(encoding="utf-8"))
    assert raw["schema_version"] == "0.2"
    assert raw["block_passed_level_ids"] == ["demo"]
    assert raw["cleared_level_ids"] == ["demo"]

    p2 = JsonFileProgress(path)
    assert p2.is_block_passed("demo")
    assert p2.is_cleared("demo")


def test_json_file_progress_ignores_invalid_payload(tmp_path: Path) -> None:
    path = tmp_path / "progress.json"
    path.write_text("[]", encoding="utf-8")
    p = JsonFileProgress(path)
    assert not p.is_block_passed("demo")
    assert not p.is_cleared("demo")
