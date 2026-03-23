from __future__ import annotations

from .errors import IntegrationContractValidationError
from .models import ActionType, GameState, PlayerAction


def _serialize_practice_payload(practice) -> dict[str, object]:
    return {
        "challenge_id": practice.challenge_id,
        "challenge_type": practice.challenge_type,
        "group_id": practice.group_id,
        "level_id": practice.level_id,
        "level_title": practice.level_title,
        "prompt": practice.prompt,
        "progress_current": practice.progress_current,
        "progress_total": practice.progress_total,
        "is_review_mode": practice.is_review_mode,
        "toolbox_allowed": practice.toolbox_allowed,
        "toolbox_used": practice.toolbox_used,
        "can_submit": practice.can_submit,
        "current_level_id": practice.current_level_id,
        "current_level_title": practice.current_level_title,
        "current_level_prompt": practice.current_level_prompt,
    }


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

    demo = None
    if state.demo is not None:
        demo = {
            "demo_id": state.demo.demo_id,
            "title": state.demo.title,
            "group_id": state.demo.group_id,
            "level_id": state.demo.level_id,
            "prompt": state.demo.prompt,
            "learning_markdown": state.demo.learning_markdown,
            "story_intro_markdown": state.demo.story_intro_markdown,
            "story_outro_markdown": state.demo.story_outro_markdown,
            "can_advance": state.demo.can_advance,
            "body": state.demo.body,
            "current_level_id": state.demo.current_level_id,
        }

    practice = None
    if state.practice is not None:
        practice = _serialize_practice_payload(state.practice)

    last_submission = None
    if state.last_submission is not None:
        last_submission = {
            "level_id": state.last_submission.level_id,
            "cleared": state.last_submission.cleared,
            "block_passed": state.last_submission.block_passed,
            "kind": state.last_submission.kind,
            "status_label": state.last_submission.status_label,
            "analysis_status": state.last_submission.analysis_status,
            "analysis_summary": state.last_submission.analysis_summary,
            "judge_status": state.last_submission.judge_status,
            "judge_summary": state.last_submission.judge_summary,
            "verification_only": state.last_submission.verification_only,
            "answer_correct": state.last_submission.answer_correct,
            "details": dict(state.last_submission.details),
        }

    map_route = None
    if state.map_route is not None:
        map_route = {
            "route_id": state.map_route.route_id,
            "quest_id": state.map_route.quest_id,
            "title": state.map_route.title,
            "groups": [
                {
                    "group_id": group.group_id,
                    "title": group.title,
                    "status_key": group.status_key,
                    "status_label": group.status_label,
                    "is_enterable": group.is_enterable,
                    "current_label": group.current_label,
                    "demo_slot": _serialize_group_slot(group.demo_slot),
                    "practice_slot": _serialize_group_slot(group.practice_slot),
                    "demo_route": [_serialize_map_route_step(step) for step in group.demo_route],
                    "practice_route": [_serialize_map_route_step(step) for step in group.practice_route],
                }
                for group in state.map_route.groups
            ],
        }

    return {
        "mode": state.mode.value,
        "quest_id": state.quest_id,
        "node_id": state.node_id,
        "node_title": state.node_title,
        "player_profile": {
            "name": state.player_profile.name,
            "gender": state.player_profile.gender,
            "profile_created": state.player_profile.profile_created,
        },
        "intro_completed": state.intro_completed,
        "scene": scene,
        "demo": demo,
        "practice": practice,
        "progress": {
            "completed_node_ids": list(state.progress.completed_node_ids),
            "cleared_level_ids": list(state.progress.cleared_level_ids),
            "demo_seen_group_ids": list(state.progress.demo_seen_group_ids),
            "toolbox_used_level_ids": list(state.progress.toolbox_used_level_ids),
        },
        "available_actions": {
            "advance": state.available_actions.advance,
            "submit": state.available_actions.submit,
            "restart_quest": state.available_actions.restart_quest,
        },
        "last_submission": last_submission,
        "map_route": map_route,
        "errors": list(state.errors),
    }


def _serialize_map_route_step(step) -> dict[str, object]:
    return {
        "step_id": step.step_id,
        "step_type": step.step_type,
        "title": step.title,
        "target_page": step.target_page,
        "status_key": step.status_key,
        "status_label": step.status_label,
        "tracked_node_ids": list(step.tracked_node_ids),
        "level_ids": list(step.level_ids),
        "node_id": step.node_id,
        "scene_id": step.scene_id,
        "challenge_id": step.challenge_id,
        "is_planned": step.is_planned,
        "is_repeatable": step.is_repeatable,
    }


def _serialize_group_slot(slot) -> dict[str, object] | None:
    if slot is None:
        return None
    return {
        "slot_key": slot.slot_key,
        "title": slot.title,
        "status_key": slot.status_key,
        "status_label": slot.status_label,
        "is_unlocked": slot.is_unlocked,
        "viewed": slot.viewed,
        "completed_count": slot.completed_count,
        "total_count": slot.total_count,
        "next_level_id": slot.next_level_id,
        "entry_level_id": slot.entry_level_id,
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

    group_id = normalized_payload.get("group_id")
    if group_id is not None and not isinstance(group_id, str):
        raise IntegrationContractValidationError("PlayerAction.payload.group_id must be a string")

    name = normalized_payload.get("name")
    if name is not None and not isinstance(name, str):
        raise IntegrationContractValidationError("PlayerAction.payload.name must be a string")

    gender = normalized_payload.get("gender")
    if gender is not None and not isinstance(gender, str):
        raise IntegrationContractValidationError("PlayerAction.payload.gender must be a string")

    return PlayerAction(action_type=parsed_action_type, payload=normalized_payload)
