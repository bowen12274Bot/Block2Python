from __future__ import annotations


class GameContentError(Exception):
    """Base error for game content loading and assembly."""


class GameContentLoadError(GameContentError):
    """Raised when structured game content files are invalid."""


class GameContentAssemblyError(GameContentError):
    """Raised when cross references cannot be assembled into a game slice."""
