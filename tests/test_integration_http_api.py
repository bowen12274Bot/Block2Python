from __future__ import annotations

from pathlib import Path

from block2python.integration.bridge_stdio import BridgeServer
from block2python.integration.http_api import (
    TutorApiRouter,
    TutorUserConfig,
    load_tutor_user_config,
    prepare_tutor_reply_payload,
    save_tutor_user_config,
)


def test_load_tutor_user_config_returns_defaults_when_file_missing(tmp_path: Path) -> None:
    config_path = tmp_path / "tutor_config.json"

    config = load_tutor_user_config(config_path=config_path)

    assert config.provider == "template"
    assert config.endpoint_url == "https://api.openai.com/v1/chat/completions"
    assert config.model == "gpt-4o-mini"
    assert config.api_key == ""


def test_save_and_load_tutor_user_config_round_trip(tmp_path: Path) -> None:
    config_path = tmp_path / "tutor_config.json"
    expected = TutorUserConfig(
        provider="openai_compatible",
        endpoint_url="https://example.invalid/v1/chat/completions",
        model="gpt-x",
        api_key="secret",
        timeout_sec=20.0,
        system_prompt="You are Byte",
    )

    save_tutor_user_config(expected, config_path=config_path)
    restored = load_tutor_user_config(config_path=config_path)

    assert restored == expected


def test_tutor_api_router_supports_config_get_and_post(tmp_path: Path) -> None:
    router = TutorApiRouter(
        bridge_server=BridgeServer(use_stub_judge=True),
        config_path=tmp_path / "tutor_config.json",
    )

    status_code, update_payload = router.handle_request(
        method="POST",
        path="/api/tutor/config",
        body={"provider": "stub", "api_key": "abc123"},
    )

    assert status_code == 200
    assert update_payload["provider"] == "stub"
    assert update_payload["api_key"] == "abc123"

    status_code, get_payload = router.handle_request(method="GET", path="/api/tutor/config", body=None)

    assert status_code == 200
    assert get_payload["provider"] == "stub"
    assert get_payload["api_key"] == "abc123"


def test_tutor_api_router_reply_uses_configured_provider_when_missing_in_payload(tmp_path: Path) -> None:
    router = TutorApiRouter(
        bridge_server=BridgeServer(use_stub_judge=True),
        config_path=tmp_path / "tutor_config.json",
    )
    router.handle_request(method="POST", path="/api/tutor/config", body={"provider": "stub"})

    status_code, payload = router.handle_request(
        method="POST",
        path="/api/tutor/reply",
        body={
            "question": "How should I start?",
            "level_id": "group-01-demo",
            "python_code": "print(1)\n",
        },
    )

    assert status_code == 200
    assert payload["metadata"]["provider"] == "stub"
    assert payload["reply_type"] in {
        "concept_explanation",
        "next_step_hint",
        "debug_hint",
        "scope_refusal",
        "solution_refusal",
    }


def test_prepare_tutor_reply_payload_injects_openai_defaults_from_user_config() -> None:
    config = TutorUserConfig(
        provider="openai_compatible",
        endpoint_url="https://example.invalid/v1/chat/completions",
        model="gpt-x",
        api_key="secret",
        timeout_sec=12.5,
        system_prompt="You are Byte",
    )

    payload = prepare_tutor_reply_payload({"question": "Explain this"}, config=config)

    assert payload["provider"] == "openai_compatible"
    options = payload["provider_options"]
    assert isinstance(options, dict)
    assert options["endpoint_url"] == "https://example.invalid/v1/chat/completions"
    assert options["model"] == "gpt-x"
    assert options["api_key"] == "secret"
    assert options["timeout_sec"] == 12.5
    assert options["system_prompt"] == "You are Byte"


def test_tutor_api_router_reply_rejects_invalid_request_shape(tmp_path: Path) -> None:
    router = TutorApiRouter(
        bridge_server=BridgeServer(use_stub_judge=True),
        config_path=tmp_path / "tutor_config.json",
    )

    status_code, payload = router.handle_request(
        method="POST",
        path="/api/tutor/reply",
        body={"question": ""},
    )

    assert status_code == 400
    assert payload["error_code"] == "invalid_request"
    assert "question" in payload["error"]


def test_tutor_api_router_returns_404_for_unknown_route(tmp_path: Path) -> None:
    router = TutorApiRouter(
        bridge_server=BridgeServer(use_stub_judge=True),
        config_path=tmp_path / "tutor_config.json",
    )

    status_code, payload = router.handle_request(method="GET", path="/api/unknown", body=None)

    assert status_code == 404
    assert payload["error_code"] == "not_found"
