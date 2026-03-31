from __future__ import annotations

import io
import json
from pathlib import Path

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
        ) + "\n"
    )
    outstream = io.StringIO()

    server.serve(instream, outstream)

    responses = [json.loads(line) for line in outstream.getvalue().splitlines() if line.strip()]
    last_response = responses[-1]
    assert last_response["ok"] is True
    assert last_response["state"]["mode"] == "challenge"
    assert last_response["state"]["practice"]["challenge_id"] == "challenge-group-01-practice"
    assert last_response["state"]["practice"]["current_level_id"] == "group-01-practice-01"
    assert last_response["state"]["practice"]["can_next"] is True
    assert last_response["state"]["progress"]["cleared_level_ids"] == ["group-01-practice-01"]
    assert last_response["state"]["last_submission"]["level_id"] == "group-01-practice-01"
    assert last_response["state"]["last_submission"]["judge_status"] == "AC"


def test_bridge_server_handles_unexpected_dispatch_exception() -> None:
    class _ExplodingBridgeServer(BridgeServer):
        def handle_request(self, request: object) -> dict[str, object]:
            raise RuntimeError("boom")

    server = _ExplodingBridgeServer(use_stub_judge=True)
    instream = io.StringIO('{"action":{"action_type":"advance","payload":{}}}\n')
    outstream = io.StringIO()

    exit_code = server.serve(instream, outstream)

    assert exit_code == 0
    response = json.loads(outstream.getvalue().strip())
    assert response["ok"] is False
    assert response["state"] is None
    assert "Bridge internal error" in response["error"]


def test_bridge_server_accepts_unicode_python_code_payload() -> None:
    server = BridgeServer(use_stub_judge=True)
    instream = io.StringIO(
        "\n".join(
            [
                '{"action":{"action_type":"advance","payload":{}}}',
                '{"action":{"action_type":"advance","payload":{}}}',
                '{"action":{"action_type":"advance","payload":{}}}',
                json.dumps(
                    {
                        "action": {
                            "action_type": "run_level",
                            "payload": {"python_code": "print(\"??\")\n", "block_json": None},
                        }
                    },
                    ensure_ascii=False,
                ),
            ]
        ) + "\n"
    )
    outstream = io.StringIO()

    server.serve(instream, outstream)

    responses = [json.loads(line) for line in outstream.getvalue().splitlines() if line.strip()]
    last_response = responses[-1]
    assert last_response["ok"] is True
    assert last_response["state"]["mode"] == "challenge"
    assert last_response["state"]["last_submission"]["kind"] == "run_result"


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
        ) + "\n"
    )
    outstream = io.StringIO()

    server.serve(instream, outstream)

    responses = [json.loads(line) for line in outstream.getvalue().splitlines() if line.strip()]
    reset_response = responses[-1]
    assert reset_response["ok"] is True
    assert reset_response["state"]["mode"] == "scene"
    assert reset_response["state"]["node_id"] == "main-map-entry"
    assert reset_response["state"]["last_submission"] is None


def test_bridge_server_supports_tutor_reply_for_active_level() -> None:
    server = BridgeServer(use_stub_judge=True)
    instream = io.StringIO(
        "\n".join(
            [
                '{"action":{"action_type":"advance","payload":{}}}',
                '{"action":{"action_type":"advance","payload":{}}}',
                '{"action":{"action_type":"advance","payload":{}}}',
                '{"command":"tutor_reply","payload":{"question":"How should I start?","python_code":"print(1)\\n","provider":"temple"}}',
            ]
        ) + "\n"
    )
    outstream = io.StringIO()

    server.serve(instream, outstream)

    responses = [json.loads(line) for line in outstream.getvalue().splitlines() if line.strip()]
    tutor_response = responses[-1]
    assert tutor_response["ok"] is True
    assert tutor_response["state"]["mode"] == "challenge"
    assert tutor_response["tutor"] is not None
    assert tutor_response["tutor"]["reply_type"] in {
        "concept_explanation",
        "next_step_hint",
        "debug_hint",
        "scope_refusal",
        "solution_refusal",
    }
    assert isinstance(tutor_response["tutor"]["content"], str)
    assert tutor_response["tutor"]["content"].strip() != ""


def test_bridge_server_supports_tutor_reply_with_explicit_level_id() -> None:
    server = BridgeServer(use_stub_judge=True)
    instream = io.StringIO(
        '{"command":"tutor_reply","payload":{"level_id":"group-01-demo","question":"What is input output?","python_code":"print(1)\\n","provider":"stub"}}\n'
    )
    outstream = io.StringIO()

    server.serve(instream, outstream)

    response = json.loads(outstream.getvalue().strip())
    assert response["ok"] is True
    assert response["state"]["mode"] == "scene"
    assert response["tutor"] is not None
    assert response["tutor"]["metadata"]["provider"] == "stub"


def test_bridge_server_tutor_reply_rejects_missing_question() -> None:
    server = BridgeServer(use_stub_judge=True)
    instream = io.StringIO('{"command":"tutor_reply","payload":{"level_id":"group-01-demo"}}\n')
    outstream = io.StringIO()

    server.serve(instream, outstream)

    response = json.loads(outstream.getvalue().strip())
    assert response["ok"] is False
    assert response["state"] is None
    assert "TutorReplyRequest.question" in response["error"]


def test_bridge_server_tutor_reply_accepts_current_code_alias() -> None:
    server = BridgeServer(use_stub_judge=True)
    instream = io.StringIO(
        '{"command":"tutor_reply","payload":{"level_id":"group-01-demo","question":"Explain this","current_code":"print(1)\\n","current_blocks":{"kind":"workspace"},"provider":"stub"}}\n'
    )
    outstream = io.StringIO()

    server.serve(instream, outstream)

    response = json.loads(outstream.getvalue().strip())
    assert response["ok"] is True
    assert response["tutor"] is not None
    assert response["tutor"]["metadata"]["provider"] == "stub"


def test_bridge_server_tutor_reply_accepts_recent_feedback() -> None:
    server = BridgeServer(use_stub_judge=True)
    instream = io.StringIO(
        '{"command":"tutor_reply","payload":{"level_id":"group-01-demo","question":"How do I fix this?","python_code":"print(1)\\n","provider":"stub","recent_feedback":["analysis: syntax error","judge: WA on case 2"]}}\n'
    )
    outstream = io.StringIO()

    server.serve(instream, outstream)

    response = json.loads(outstream.getvalue().strip())
    assert response["ok"] is True
    assert response["tutor"] is not None
    assert response["tutor"]["metadata"]["provider"] == "stub"


def test_bridge_server_tutor_reply_api_skill_requires_provider_options() -> None:
    server = BridgeServer(use_stub_judge=True)
    instream = io.StringIO(
        '{"command":"tutor_reply","payload":{"level_id":"group-01-demo","question":"Explain this","provider":"api_skill"}}\n'
    )
    outstream = io.StringIO()

    server.serve(instream, outstream)

    response = json.loads(outstream.getvalue().strip())
    assert response["ok"] is False
    assert response["state"] is None
    assert "provider_options.endpoint_url" in response["error"]


def test_bridge_server_tutor_reply_api_skill_allows_missing_api_key_for_local_endpoint() -> None:
    server = BridgeServer(use_stub_judge=True)
    instream = io.StringIO(
        '{"command":"tutor_reply","payload":{"level_id":"group-01-demo","question":"Explain this","python_code":"print(1)\\n","provider":"api_skill","provider_options":{"endpoint_url":"http://127.0.0.1:1/v1/chat/completions","model":"qwen3.5:9b","timeout_sec":1.0}}}\n'
    )
    outstream = io.StringIO()

    server.serve(instream, outstream)

    response = json.loads(outstream.getvalue().strip())
    assert response["ok"] is True
    assert response["tutor"] is not None
    assert response["tutor"]["reply_type"] in {
        "concept_explanation",
        "next_step_hint",
        "debug_hint",
        "scope_refusal",
        "solution_refusal",
    }


def test_bridge_server_tutor_reply_temple_accepts_provider_options() -> None:
    server = BridgeServer(use_stub_judge=True)
    instream = io.StringIO(
        '{"command":"tutor_reply","payload":{"level_id":"group-01-demo","question":"Explain this","provider":"temple","provider_options":{"model":"qwen3.5:0.8b"}}}\n'
    )
    outstream = io.StringIO()

    server.serve(instream, outstream)

    response = json.loads(outstream.getvalue().strip())
    assert response["ok"] is True
    assert response["tutor"] is not None
    assert response["tutor"]["metadata"]["provider"] == "temple"
    assert response["tutor"]["metadata"]["selector_model"] == "qwen3.5:0.8b"


def test_bridge_server_writes_tutor_thinking_trace_when_configured(tmp_path: Path) -> None:
    thinking_log = tmp_path / "tutor_thinking.log"
    server = BridgeServer(use_stub_judge=True, thinking_log_file=thinking_log)
    instream = io.StringIO(
        '{"command":"tutor_reply","payload":{"level_id":"group-01-demo","question":"Explain this","python_code":"print(1)\\n","provider":"temple"}}\n'
    )
    outstream = io.StringIO()

    server.serve(instream, outstream)

    response = json.loads(outstream.getvalue().strip())
    assert response["ok"] is True
    assert thinking_log.exists()

    content = thinking_log.read_text(encoding="utf-8")
    assert "TUTOR_THINKING_HUMAN" in content
    assert any(
        token in content
        for token in ("event: temple_selector_input", "event: temple_selector_skipped")
    )
    assert any(
        token in content
        for token in ("event: temple_selector_decision", "event: temple_selector_skipped")
    )
    assert "event: temple_template_output" in content
