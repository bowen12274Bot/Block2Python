from __future__ import annotations

from .errors import IntegrationContractValidationError
from .models import (
    ActionType,
    ActorCueState,
    GameState,
    PlayerAction,
    TutorReplyPayload,
    TutorReplyRequest,
)


_TUTOR_PROVIDER_ALIASES: dict[str, str] = {
    "stub": "stub",
    "temple": "temple",
    "template": "temple",
    "local": "temple",
    "api_skill": "api_skill",
    "api+skill": "api_skill",
    "api-skill": "api_skill",
    "openai_compatible": "api_skill",
}


def _serialize_actor_cue(actor: ActorCueState | None) -> dict[str, object] | None:
    if actor is None:
        return None
    return {
        "actor_id": actor.actor_id,
        "display_name": actor.display_name,
        "portrait_id": actor.portrait_id,
        "expression_id": actor.expression_id,
        "pose_id": actor.pose_id,
        "visual_state": actor.visual_state,
        "image_path": actor.image_path,
    }


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
        "toolbox_opened": practice.toolbox_opened,
        "toolbox_penalty_percent": practice.toolbox_penalty_percent,
        "toolbox_block_ids": list(practice.toolbox_block_ids),
        "can_run": practice.can_run,
        "can_submit": practice.can_submit,
        "can_next": practice.can_next,
        "mission_text": practice.mission_text,
        "battery_percent": practice.battery_percent,
        "battery_threshold_percent": practice.battery_threshold_percent,
        "assistant_messages": list(practice.assistant_messages),
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
                    "background_id": block.background_id,
                    "emphasis": block.emphasis,
                    "speaker_side": block.speaker_side,
                    "left_actor": _serialize_actor_cue(block.left_actor),
                    "center_actor": _serialize_actor_cue(block.center_actor),
                    "right_actor": _serialize_actor_cue(block.right_actor),
                }
                for block in state.scene.dialogue_blocks
            ],
            "mission_statement_scene_id": state.scene.mission_statement_scene_id,
            "mission_statement_title": state.scene.mission_statement_title,
            "mission_statement_text": state.scene.mission_statement_text,
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
            "unlock_blocks": [dict(block) for block in state.demo.unlock_blocks],
            "toolbox_block_ids": list(state.demo.toolbox_block_ids),
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
            "output_text": state.last_submission.output_text,
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
            "run": state.available_actions.run,
            "submit": state.available_actions.submit,
            "next_level": state.available_actions.next_level,
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


def serialize_tutor_reply_request(request: TutorReplyRequest) -> dict[str, object]:
    return {
        "question": request.question,
        "provider": request.provider,
        "level_id": request.level_id,
        "python_code": request.python_code,
        "block_json": dict(request.block_json) if isinstance(request.block_json, dict) else None,
        "conversation_id": request.conversation_id,
        "conversation_history": [dict(item) for item in request.conversation_history],
        "history_summary": request.history_summary,
        "recent_feedback": list(request.recent_feedback),
        "provider_options": dict(request.provider_options),
    }


def deserialize_tutor_reply_request(payload: object) -> TutorReplyRequest:
    if not isinstance(payload, dict):
        raise IntegrationContractValidationError("TutorReplyRequest payload must be a dict")

    question = payload.get("question")
    if not isinstance(question, str) or not question.strip():
        raise IntegrationContractValidationError("TutorReplyRequest.question must be a non-empty string")

    provider_raw = payload.get("provider", "temple")
    if not isinstance(provider_raw, str) or not provider_raw.strip():
        raise IntegrationContractValidationError("TutorReplyRequest.provider must be a non-empty string")
    provider = _normalize_tutor_provider(provider_raw)

    level_id_raw = payload.get("level_id")
    level_id: str | None = None
    if level_id_raw is not None:
        if not isinstance(level_id_raw, str):
            raise IntegrationContractValidationError("TutorReplyRequest.level_id must be a string")
        level_id = level_id_raw.strip() or None

    python_code = payload.get("python_code")
    if python_code is None and "current_code" in payload:
        python_code = payload.get("current_code")
    if python_code is None:
        python_code = ""
    if not isinstance(python_code, str):
        raise IntegrationContractValidationError("TutorReplyRequest.python_code must be a string")

    block_json = payload.get("block_json")
    if block_json is None and "current_blocks" in payload:
        block_json = payload.get("current_blocks")
    if block_json is not None and not isinstance(block_json, dict):
        raise IntegrationContractValidationError("TutorReplyRequest.block_json must be a dict or null")

    conversation_id = payload.get("conversation_id")
    if conversation_id is not None and not isinstance(conversation_id, str):
        raise IntegrationContractValidationError("TutorReplyRequest.conversation_id must be a string")

    history_summary = payload.get("history_summary")
    if history_summary is not None and not isinstance(history_summary, str):
        raise IntegrationContractValidationError("TutorReplyRequest.history_summary must be a string")

    history_raw = payload.get("conversation_history", ())
    if history_raw is None:
        history_raw = ()
    if not isinstance(history_raw, (list, tuple)):
        raise IntegrationContractValidationError("TutorReplyRequest.conversation_history must be an array")

    history: list[dict[str, object]] = []
    for index, item in enumerate(history_raw):
        if not isinstance(item, dict):
            raise IntegrationContractValidationError(
                f"TutorReplyRequest.conversation_history[{index}] must be an object"
            )

        role = item.get("role")
        if role is not None and not isinstance(role, str):
            raise IntegrationContractValidationError(
                f"TutorReplyRequest.conversation_history[{index}].role must be a string"
            )

        content = item.get("content")
        if content is not None and not isinstance(content, str):
            raise IntegrationContractValidationError(
                f"TutorReplyRequest.conversation_history[{index}].content must be a string"
            )

        history.append(dict(item))

    recent_feedback_raw = payload.get("recent_feedback")
    if recent_feedback_raw is None and "submission_history" in payload:
        recent_feedback_raw = payload.get("submission_history")
    if recent_feedback_raw is None:
        recent_feedback_raw = ()
    if not isinstance(recent_feedback_raw, (list, tuple)):
        raise IntegrationContractValidationError("TutorReplyRequest.recent_feedback must be an array")

    recent_feedback: list[str] = []
    for index, item in enumerate(recent_feedback_raw):
        if not isinstance(item, str):
            raise IntegrationContractValidationError(
                f"TutorReplyRequest.recent_feedback[{index}] must be a string"
            )
        trimmed_item = item.strip()
        if trimmed_item:
            recent_feedback.append(trimmed_item)

    provider_options_raw = payload.get("provider_options", {})
    if provider_options_raw is None:
        provider_options_raw = {}
    if not isinstance(provider_options_raw, dict):
        raise IntegrationContractValidationError("TutorReplyRequest.provider_options must be a dict")

    provider_options = dict(provider_options_raw)
    for field_name in ("endpoint_url", "model", "api_key", "system_prompt", "timeout_sec"):
        if field_name in payload and field_name not in provider_options:
            provider_options[field_name] = payload[field_name]

    return TutorReplyRequest(
        question=question.strip(),
        provider=provider,
        level_id=level_id,
        python_code=python_code,
        block_json=dict(block_json) if isinstance(block_json, dict) else None,
        conversation_id=conversation_id,
        conversation_history=tuple(history),
        history_summary=history_summary,
        recent_feedback=tuple(recent_feedback),
        provider_options=provider_options,
    )


def serialize_tutor_reply_payload(payload: TutorReplyPayload) -> dict[str, object]:
    return {
        "reply_type": payload.reply_type,
        "content": payload.content,
        "metadata": dict(payload.metadata),
    }


def deserialize_tutor_reply_payload(payload: object) -> TutorReplyPayload:
    if not isinstance(payload, dict):
        raise IntegrationContractValidationError("TutorReplyPayload must be a dict")

    reply_type = payload.get("reply_type")
    if not isinstance(reply_type, str) or not reply_type.strip():
        raise IntegrationContractValidationError("TutorReplyPayload.reply_type must be a non-empty string")

    content = payload.get("content")
    if not isinstance(content, str):
        raise IntegrationContractValidationError("TutorReplyPayload.content must be a string")

    metadata = payload.get("metadata", {})
    if metadata is None:
        metadata = {}
    if not isinstance(metadata, dict):
        raise IntegrationContractValidationError("TutorReplyPayload.metadata must be a dict")

    return TutorReplyPayload(reply_type=reply_type.strip(), content=content, metadata=dict(metadata))


def _normalize_tutor_provider(provider_raw: str) -> str:
    normalized = provider_raw.strip().lower()
    mapped = _TUTOR_PROVIDER_ALIASES.get(normalized)
    if mapped is None:
        supported = ", ".join(sorted({"stub", "temple", "api_skill"}))
        raise IntegrationContractValidationError(
            f"TutorReplyRequest.provider has unsupported value: {provider_raw}. Supported: {supported}"
        )
    return mapped
