from __future__ import annotations

import io
import json

from block2python.integration.bridge_stdio import BridgeServer


def test_bridge_server_handles_advance_over_stdio_streams() -> None:
    server = BridgeServer(use_stub_judge=True)
    instream = io.StringIO('{"action":{"action_type":"advance","payload":{}}}\n')
    outstream = io.StringIO()

    exit_code = server.serve(instream, outstream)

    assert exit_code == 0
    response = json.loads(outstream.getvalue().strip())
    assert response["ok"] is True
    assert response["state"]["mode"] == "scene"
    assert response["state"]["node_id"] == "group-01-story"
    assert response["state"]["last_submission"] is None


def test_bridge_server_persists_session_across_requests() -> None:
    server = BridgeServer(use_stub_judge=True)
    instream = io.StringIO(
        "\n".join(
            [
                '{"action":{"action_type":"advance","payload":{}}}',
                '{"action":{"action_type":"advance","payload":{}}}',
                '{"action":{"action_type":"advance","payload":{}}}',
                '{"action":{"action_type":"submit_level","payload":{"python_code":"print(3)\\n","block_json":{"kind":"workspace"}}}}',
            ]
        )
        + "\n"
    )
    outstream = io.StringIO()

    server.serve(instream, outstream)

    responses = [json.loads(line) for line in outstream.getvalue().splitlines() if line.strip()]
    last_response = responses[-1]
    assert last_response["ok"] is True
    assert last_response["state"]["mode"] == "challenge"
    assert last_response["state"]["practice"]["challenge_id"] == "challenge-group-01-practice"
    assert last_response["state"]["practice"]["current_level_id"] == "group-01-practice-02"
    assert last_response["state"]["progress"]["cleared_level_ids"] == ["group-01-practice-01"]
    assert last_response["state"]["last_submission"]["level_id"] == "group-01-practice-01"
    assert last_response["state"]["last_submission"]["judge_status"] == "AC"


def test_bridge_server_returns_error_for_invalid_json() -> None:
    server = BridgeServer(use_stub_judge=True)
    instream = io.StringIO("{not-json}\n")
    outstream = io.StringIO()

    server.serve(instream, outstream)

    response = json.loads(outstream.getvalue().strip())
    assert response["ok"] is False
    assert response["state"] is None
    assert "Invalid JSON" in response["error"]


def test_bridge_server_returns_error_for_invalid_action_shape() -> None:
    server = BridgeServer(use_stub_judge=True)
    instream = io.StringIO('{"action":{"action_type":123,"payload":{}}}\n')
    outstream = io.StringIO()

    server.serve(instream, outstream)

    response = json.loads(outstream.getvalue().strip())
    assert response["ok"] is False
    assert response["state"] is None
    assert "action_type" in response["error"]


def test_bridge_server_supports_reset_command() -> None:
    server = BridgeServer(use_stub_judge=True)
    instream = io.StringIO(
        "\n".join(
            [
                '{"action":{"action_type":"advance","payload":{}}}',
                '{"command":"reset"}',
            ]
        )
        + "\n"
    )
    outstream = io.StringIO()

    server.serve(instream, outstream)

    responses = [json.loads(line) for line in outstream.getvalue().splitlines() if line.strip()]
    reset_response = responses[-1]
    assert reset_response["ok"] is True
    assert reset_response["state"]["mode"] == "scene"
    assert reset_response["state"]["node_id"] == "main-map-entry"
    assert reset_response["state"]["last_submission"] is None
