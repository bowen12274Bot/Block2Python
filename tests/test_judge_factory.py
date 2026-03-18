"""Tests for judge factory and environment-based configuration."""

from __future__ import annotations

from pathlib import Path

import pytest

from block2python.level_play import build_judge_from_env
from block2python.judge import StubJudge, WasmJudge


class TestJudgeFactory:
    """Test judge factory with different environment configurations."""

    def test_default_mode_auto_fallback_to_stub(self, clean_judge_env, monkeypatch):
        # Ensure this test is deterministic even when assets/wasm/python.wasm exists locally.
        monkeypatch.setenv("BLOCK2PYTHON_WASM_PATH", "nonexistent/python.wasm")
        judge, info = build_judge_from_env()
        assert isinstance(judge, StubJudge)
        assert "auto fallback" in info.lower()

    def test_forced_stub_mode(self, clean_judge_env, monkeypatch):
        monkeypatch.setenv("BLOCK2PYTHON_JUDGE_MODE", "stub")
        judge, info = build_judge_from_env()
        assert isinstance(judge, StubJudge)
        assert "StubJudge" in info

    def test_wasm_mode_without_file_fails_gracefully(self, clean_judge_env, monkeypatch):
        monkeypatch.setenv("BLOCK2PYTHON_JUDGE_MODE", "wasm")
        monkeypatch.setenv("BLOCK2PYTHON_WASM_PATH", "nonexistent.wasm")
        judge, info = build_judge_from_env()
        assert isinstance(judge, WasmJudge)
        assert "WasmJudge" in info

    def test_auto_mode_with_wasm_file(self, clean_judge_env, monkeypatch, fake_wasm_path: Path):
        monkeypatch.setenv("BLOCK2PYTHON_JUDGE_MODE", "auto")
        monkeypatch.setenv("BLOCK2PYTHON_WASM_PATH", str(fake_wasm_path))
        judge, info = build_judge_from_env()
        assert isinstance(judge, WasmJudge)
        assert "WasmJudge" in info

    def test_fail_fast_configuration(self, clean_judge_env, monkeypatch, fake_wasm_path: Path):
        monkeypatch.setenv("BLOCK2PYTHON_JUDGE_MODE", "wasm")
        monkeypatch.setenv("BLOCK2PYTHON_WASM_PATH", str(fake_wasm_path))
        monkeypatch.setenv("BLOCK2PYTHON_JUDGE_FAIL_FAST", "false")
        judge, _ = build_judge_from_env()
        assert isinstance(judge, WasmJudge)
        assert judge._fail_fast is False

    def test_custom_wasmtime_bin(self, clean_judge_env, monkeypatch, fake_wasm_path: Path):
        monkeypatch.setenv("BLOCK2PYTHON_JUDGE_MODE", "wasm")
        monkeypatch.setenv("BLOCK2PYTHON_WASM_PATH", str(fake_wasm_path))
        monkeypatch.setenv("BLOCK2PYTHON_WASMTIME_BIN", "custom-wasmtime")
        judge, info = build_judge_from_env()
        assert isinstance(judge, WasmJudge)
        assert "custom-wasmtime" in info

    def test_invalid_mode_raises(self, clean_judge_env, monkeypatch):
        monkeypatch.setenv("BLOCK2PYTHON_JUDGE_MODE", "invalid_mode")
        with pytest.raises(Exception):  # JudgeBuildError
            build_judge_from_env()

