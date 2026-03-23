import importlib

import pytest

from block2python.clients.bootstrap import build_configured_app
from block2python.clients.pyside6 import MainWindow, main as pyside6_main
from block2python.content import load_game_content, load_levels
from block2python.game import GameSession
from block2python.integration import __all__ as integration_exports
from block2python.level_play import AppCore


def test_clients_bootstrap_package_exports_runtime_helpers() -> None:
    assert callable(build_configured_app)


def test_legacy_app_package_is_removed() -> None:
    with pytest.raises(ModuleNotFoundError):
        importlib.import_module("block2python.app")


def test_legacy_challenge_package_is_removed() -> None:
    with pytest.raises(ModuleNotFoundError):
        importlib.import_module("block2python.challenge")


def test_content_package_exports_game_content_loader() -> None:
    assert callable(load_game_content)


def test_legacy_game_content_package_is_removed() -> None:
    with pytest.raises(ModuleNotFoundError):
        importlib.import_module("block2python.game_content")


def test_pyside6_client_package_exports_main_window_and_main() -> None:
    assert MainWindow is not None
    assert callable(pyside6_main)


def test_legacy_ui_package_is_removed() -> None:
    with pytest.raises(ModuleNotFoundError):
        importlib.import_module("block2python.ui")


def test_integration_package_exists_for_future_godot_bridge() -> None:
    assert integration_exports == []
