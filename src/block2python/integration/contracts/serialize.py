from __future__ import annotations

from .errors import IntegrationContractValidationError
from .models import ActionType, GameState, PlayerAction


def serialize_game_state(state: GameState) -> dict[str, object]:
    scene = None
    if state.scene is not None:
        scene = {
            "scene_id": state.scene.scene_id,
            "title": state.scene.title,
            "dialogue_blocks": [
                {
                    "speaker": block.speaker,
                    "text": block.text,
                    "portrait_id": block.portrait_id,
                    "expression": block.expression,
                    "emphasis": block.emphasis,
                }
                for block in state.scene.dialogue_blocks
            ],
        }

    challenge = None
    if state.challenge is not None:
        challenge = {
            "challenge_id": state.challenge.challenge_id,
            "challenge_type": state.challenge.challenge_type,
            "current_level_id": state.challenge.current_level_id,
            "current_level_title": state.challenge.current_level_title,
            "current_level_prompt": state.challenge.current_level_prompt,
        }

    last_submission = None
    if state.last_submission is not None:
        last_submission = {
            "level_id": state.last_submission.level_id,
            "cleared": state.last_submission.cleared,
            "block_passed": state.last_submission.block_passed,
            "analysis_status": state.last_submission.analysis_status,
            "analysis_summary": state.last_submission.analysis_summary,
            "judge_status": state.last_submission.judge_status,
            "judge_summary": state.last_submission.judge_summary,
        }

    return {
        "mode": state.mode.value,
        "quest_id": state.quest_id,
        "node_id": state.node_id,
        "node_title": state.node_title,
        "scene": scene,
        "challenge": challenge,
        "progress": {
            "completed_node_ids": list(state.progress.completed_node_ids),
            "cleared_level_ids": list(state.progress.cleared_level_ids),
        },
        "available_actions": {
            "advance": state.available_actions.advance,
            "submit": state.available_actions.submit,
            "restart_quest": state.available_actions.restart_quest,
        },
        "last_submission": last_submission,
        "errors": list(state.errors),
    }


def serialize_player_action(action: PlayerAction) -> dict[str, object]:
    return {
        "action_type": action.action_type.value,
        "payload": dict(action.payload),
    }


def deserialize_player_action(payload: object) -> PlayerAction:
    if not isinstance(payload, dict):
        raise IntegrationContractValidationError("PlayerAction payload must be a dict")

    action_type = payload.get("action_type")
    if not isinstance(action_type, str):
        raise IntegrationContractValidationError("PlayerAction.action_type must be a string")

    try:
        parsed_action_type = ActionType(action_type)
    except ValueError as exc:
        raise IntegrationContractValidationError(f"Unknown PlayerAction.action_type: {action_type}") from exc

    raw_action_payload = payload.get("payload", {})
    if raw_action_payload is None:
        raw_action_payload = {}
    if not isinstance(raw_action_payload, dict):
        raise IntegrationContractValidationError("PlayerAction.payload must be a dict")

    normalized_payload = dict(raw_action_payload)
    block_json = normalized_payload.get("block_json")
    if block_json is not None and not isinstance(block_json, dict):
        raise IntegrationContractValidationError("PlayerAction.payload.block_json must be a dict or null")

    python_code = normalized_payload.get("python_code")
    if python_code is not None and not isinstance(python_code, str):
        raise IntegrationContractValidationError("PlayerAction.payload.python_code must be a string")

    return PlayerAction(action_type=parsed_action_type, payload=normalized_payload)