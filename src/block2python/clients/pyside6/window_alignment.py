from __future__ import annotations

import ctypes
from ctypes import wintypes

try:
    _user32 = ctypes.windll.user32
except AttributeError:  # pragma: no cover
    _user32 = None


class _POINT(ctypes.Structure):
    _fields_ = [("x", wintypes.LONG), ("y", wintypes.LONG)]


def find_window_handle(window_title: str) -> int:
    if _user32 is None or not window_title:
        return 0
    hwnd = _user32.FindWindowW(None, window_title)
    if hwnd:
        return int(hwnd)

    matches: list[int] = []
    enum_proc = ctypes.WINFUNCTYPE(wintypes.BOOL, wintypes.HWND, wintypes.LPARAM)

    def _enum_callback(hwnd: int, _lparam: int) -> bool:
        if not _user32.IsWindowVisible(hwnd):
            return True
        length = _user32.GetWindowTextLengthW(hwnd)
        if length <= 0:
            return True
        buffer = ctypes.create_unicode_buffer(length + 1)
        _user32.GetWindowTextW(hwnd, buffer, length + 1)
        title = buffer.value
        if window_title == title or window_title in title or title in window_title:
            matches.append(int(hwnd))
            return False
        return True

    _user32.EnumWindows(enum_proc(_enum_callback), 0)
    return matches[0] if matches else 0


def resolve_client_origin(owner_hwnd: int, owner_title: str) -> tuple[int, int] | None:
    hwnd = owner_hwnd
    if not hwnd:
        hwnd = find_window_handle(owner_title)
    if _user32 is None or not hwnd:
        return None
    point = _POINT(0, 0)
    if not _user32.ClientToScreen(hwnd, ctypes.byref(point)):
        return None
    return int(point.x), int(point.y)


def compute_target_rect(payload: dict) -> tuple[int, int, int, int] | None:
    if not bool(payload.get("visible", False)):
        return None

    owner_title = str(payload.get("owner_title", ""))
    owner_hwnd = int(payload.get("owner_hwnd", 0))
    relative_x = int(payload.get("relative_x", payload.get("x", 0)))
    relative_y = int(payload.get("relative_y", payload.get("y", 0)))
    width = max(int(payload.get("width", 1)), 1)
    height = max(int(payload.get("height", 1)), 1)
    screen_x = int(payload.get("screen_x", -1))
    screen_y = int(payload.get("screen_y", -1))
    screen_width = max(int(payload.get("screen_width", width)), 1)
    screen_height = max(int(payload.get("screen_height", height)), 1)
    client_origin = resolve_client_origin(owner_hwnd, owner_title)

    if client_origin is not None and screen_x >= 0 and screen_y >= 0:
        return client_origin[0] + screen_x, client_origin[1] + screen_y, screen_width, screen_height
    if screen_x >= 0 and screen_y >= 0:
        return screen_x, screen_y, screen_width, screen_height
    if client_origin is None:
        return None
    return client_origin[0] + relative_x, client_origin[1] + relative_y, width, height


def apply_window_rect(window_hwnd: int, x: int, y: int, width: int, height: int) -> None:
    if _user32 is None:
        return
    _SWP_NOZORDER = 0x0004
    _SWP_NOACTIVATE = 0x0010
    _user32.SetWindowPos(int(window_hwnd), 0, x, y, width, height, _SWP_NOZORDER | _SWP_NOACTIVATE)
