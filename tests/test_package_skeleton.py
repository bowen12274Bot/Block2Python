from block2python.app.core import AppCore as LegacyAppCore
from block2python.app.game_session import GameSession as LegacyGameSession
from block2python.app.levels_loader import load_levels as legacy_load_levels
from block2python.challenge import AppCore
from block2python.content import load_levels
from block2python.game import GameSession
from block2python.game_content import load_game_content as legacy_load_game_content
from block2python.integration import __all__ as integration_exports


def test_legacy_app_core_shim_points_to_new_package() -> None:
    assert LegacyAppCore is AppCore


def test_legacy_game_session_shim_points_to_new_package() -> None:
    assert LegacyGameSession is GameSession


def test_legacy_levels_loader_shim_points_to_content_package() -> None:
    assert legacy_load_levels is load_levels


def test_legacy_game_content_package_still_exports_loader() -> None:
    assert callable(legacy_load_game_content)


def test_integration_package_exists_for_future_godot_bridge() -> None:
    assert integration_exports == []
