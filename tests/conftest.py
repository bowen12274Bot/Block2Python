"""Pytest configuration and shared fixtures."""

from __future__ import annotations

import os
from pathlib import Path

import pytest


# Ensure `src/` is on sys.path during pytest collection/import time so test modules
# can import the package before any fixtures run.
_REPO_ROOT = Path(__file__).parent.parent
_SRC_PATH = str(_REPO_ROOT / "src")
if _SRC_PATH not in os.sys.path:
    os.sys.path.insert(0, _SRC_PATH)


@pytest.fixture(autouse=True)
def setup_test_env():
    """Ensure PYTHONPATH includes src/ for all tests."""
    repo_root = Path(__file__).parent.parent
    src_path = str(repo_root / "src")
    if src_path not in os.sys.path:
        os.sys.path.insert(0, src_path)
    yield


@pytest.fixture
def fake_wasm_path(tmp_path: Path) -> Path:
    """Create a fake python.wasm file for testing."""
    wasm = tmp_path / "python.wasm"
    wasm.write_text("fake wasm binary")
    return wasm


@pytest.fixture
def clean_judge_env(monkeypatch):
    """Clean judge-related environment variables before each test."""
    env_vars = [
        "BLOCK2PYTHON_JUDGE_MODE",
        "BLOCK2PYTHON_WASM_PATH",
        "BLOCK2PYTHON_WASMTIME_BIN",
        "BLOCK2PYTHON_JUDGE_FAIL_FAST",
    ]
    for var in env_vars:
        monkeypatch.delenv(var, raising=False)
    yield
