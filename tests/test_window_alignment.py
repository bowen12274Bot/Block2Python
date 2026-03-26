from __future__ import annotations

from block2python.clients.pyside6 import window_alignment


def test_compute_target_rect_prefers_client_origin_plus_screen(monkeypatch) -> None:
    monkeypatch.setattr(window_alignment, "resolve_client_origin", lambda owner_hwnd, owner_title: (200, 120))

    rect = window_alignment.compute_target_rect(
        {
            "visible": True,
            "owner_hwnd": 123,
            "owner_title": "Godot",
            "relative_x": 10,
            "relative_y": 15,
            "width": 300,
            "height": 200,
            "screen_x": 40,
            "screen_y": 50,
            "screen_width": 320,
            "screen_height": 220,
        }
    )

    assert rect == (240, 170, 320, 220)


def test_compute_target_rect_uses_screen_only_without_client_origin(monkeypatch) -> None:
    monkeypatch.setattr(window_alignment, "resolve_client_origin", lambda owner_hwnd, owner_title: None)

    rect = window_alignment.compute_target_rect(
        {
            "visible": True,
            "owner_hwnd": 0,
            "owner_title": "",
            "width": 300,
            "height": 200,
            "screen_x": 40,
            "screen_y": 50,
            "screen_width": 320,
            "screen_height": 220,
        }
    )

    assert rect == (40, 50, 320, 220)


def test_compute_target_rect_falls_back_to_relative_with_client_origin(monkeypatch) -> None:
    monkeypatch.setattr(window_alignment, "resolve_client_origin", lambda owner_hwnd, owner_title: (200, 120))

    rect = window_alignment.compute_target_rect(
        {
            "visible": True,
            "owner_hwnd": 123,
            "owner_title": "Godot",
            "relative_x": 10,
            "relative_y": 15,
            "width": 300,
            "height": 200,
            "screen_x": -1,
            "screen_y": -1,
        }
    )

    assert rect == (210, 135, 300, 200)


def test_compute_target_rect_returns_none_for_invalid_or_hidden_payload(monkeypatch) -> None:
    monkeypatch.setattr(window_alignment, "resolve_client_origin", lambda owner_hwnd, owner_title: None)

    assert window_alignment.compute_target_rect({"visible": False}) is None
    assert window_alignment.compute_target_rect({"visible": True, "screen_x": -1, "screen_y": -1}) is None


def test_resolve_client_origin_returns_none_for_invalid_inputs(monkeypatch) -> None:
    monkeypatch.setattr(window_alignment, "_user32", None)
    assert window_alignment.resolve_client_origin(0, "") is None


def test_apply_window_rect_uses_win32_set_window_pos(monkeypatch) -> None:
    calls: list[tuple[int, int, int, int, int, int, int]] = []

    class FakeUser32:
        def SetWindowPos(self, hwnd, insert_after, x, y, width, height, flags):
            calls.append((hwnd, insert_after, x, y, width, height, flags))
            return 1

    monkeypatch.setattr(window_alignment, "_user32", FakeUser32())

    window_alignment.apply_window_rect(10, 11, 12, 13, 14)

    assert calls == [(10, 0, 11, 12, 13, 14, 0x0004 | 0x0010)]
