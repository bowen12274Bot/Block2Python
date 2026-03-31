from __future__ import annotations

import pytest

from block2python.integration.contracts import (
    IntegrationContractValidationError,
    TutorReplyPayload,
    TutorReplyRequest,
    deserialize_tutor_reply_payload,
    deserialize_tutor_reply_request,
    serialize_tutor_reply_payload,
    serialize_tutor_reply_request,
)


def test_deserialize_tutor_reply_request_with_defaults() -> None:
    request = deserialize_tutor_reply_request({"question": "  How to start?  "})

    assert request.question == "How to start?"
    assert request.provider == "temple"
    assert request.level_id is None
    assert request.python_code == ""
    assert request.block_json is None
    assert request.conversation_history == ()
    assert request.recent_feedback == ()
    assert request.provider_options == {}


def test_deserialize_tutor_reply_request_supports_alias_fields_and_openai_options() -> None:
    request = deserialize_tutor_reply_request(
        {
            "question": "Explain",
            "provider": "OPENAI_COMPATIBLE",
            "level_id": "group-01-demo",
            "current_code": "print(1)\n",
            "current_blocks": {"kind": "workspace"},
            "conversation_history": [{"role": "user", "content": "hello"}],
            "recent_feedback": ["analysis: syntax error", "judge: WA on case 2"],
            "endpoint_url": "https://example.invalid/v1/chat/completions",
            "model": "gpt-x",
            "api_key": "secret",
            "timeout_sec": 20,
        }
    )

    assert request.provider == "api_skill"
    assert request.level_id == "group-01-demo"
    assert request.python_code == "print(1)\n"
    assert request.block_json == {"kind": "workspace"}
    assert request.conversation_history == ({"role": "user", "content": "hello"},)
    assert request.recent_feedback == ("analysis: syntax error", "judge: WA on case 2")
    assert request.provider_options == {
        "endpoint_url": "https://example.invalid/v1/chat/completions",
        "model": "gpt-x",
        "api_key": "secret",
        "timeout_sec": 20,
    }


def test_deserialize_tutor_reply_request_rejects_invalid_history_item() -> None:
    with pytest.raises(IntegrationContractValidationError, match=r"conversation_history\[0\] must be an object"):
        deserialize_tutor_reply_request(
            {
                "question": "x",
                "conversation_history": ["bad"],
            }
        )


def test_deserialize_tutor_reply_request_rejects_invalid_recent_feedback_item() -> None:
    with pytest.raises(IntegrationContractValidationError, match=r"recent_feedback\[0\] must be a string"):
        deserialize_tutor_reply_request(
            {
                "question": "x",
                "recent_feedback": [123],
            }
        )


def test_deserialize_tutor_reply_request_accepts_submission_history_alias() -> None:
    request = deserialize_tutor_reply_request(
        {
            "question": "x",
            "submission_history": ["analysis: missing colon", "judge: WA"],
        }
    )

    assert request.recent_feedback == ("analysis: missing colon", "judge: WA")


def test_tutor_reply_request_round_trip_serialization() -> None:
    request = TutorReplyRequest(
        question="Explain",
        provider="temple",
        level_id="group-01-demo",
        python_code="print(1)",
        block_json={"kind": "workspace"},
        conversation_id="cid-1",
        conversation_history=({"role": "user", "content": "help"},),
        history_summary="summary",
        recent_feedback=("analysis: syntax error",),
        provider_options={"x": 1},
    )

    payload = serialize_tutor_reply_request(request)
    restored = deserialize_tutor_reply_request(payload)

    assert restored == request


def test_tutor_reply_payload_round_trip_serialization() -> None:
    payload = TutorReplyPayload(
        reply_type="next_step_hint",
        content="Try reading input first.",
        metadata={"provider": "temple"},
    )

    serialized = serialize_tutor_reply_payload(payload)
    restored = deserialize_tutor_reply_payload(serialized)

    assert restored == payload


def test_deserialize_tutor_reply_payload_rejects_invalid_shape() -> None:
    with pytest.raises(IntegrationContractValidationError, match="TutorReplyPayload.reply_type"):
        deserialize_tutor_reply_payload({"reply_type": "", "content": "x", "metadata": {}})

# EOF
