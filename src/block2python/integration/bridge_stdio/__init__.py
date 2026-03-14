from __future__ import annotations

from typing import TYPE_CHECKING, Any

__all__ = ["BridgeServer", "main"]

if TYPE_CHECKING:
    from .server import BridgeServer


def __getattr__(name: str) -> Any:
    if name in {"BridgeServer", "main"}:
        from .server import BridgeServer, main

        exports = {
            "BridgeServer": BridgeServer,
            "main": main,
        }
        return exports[name]
    raise AttributeError(name)
