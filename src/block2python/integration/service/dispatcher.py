from __future__ import annotations

from block2python.game import GameSession, GameSessionError
from block2python.integration.contracts import ActionType, GameState, PlayerAction


class IntegrationDispatchError(Exception):
    """Raised when a PlayerAction cannot be dispatched."""


def dispatch(session: GameSession, action: PlayerAction) -> GameState:
    try:
        if action.action_type is ActionType.ADVANCE:
            session.advance()
            return session.current_game_state()

        if action.action_type is ActionType.SUBMIT_LEVEL:
            python_code = action.payload.get("python_code")
            if not isinstance(python_code, str) or not python_code:
                raise IntegrationDispatchError("submit_level requires payload.python_code")

            block_json = action.payload.get("block_json")
            if block_json is not None and not isinstance(block_json, dict):
                raise IntegrationDispatchError("submit_level payload.block_json must be a dict or null")

            session.submit_current_level(python_code=python_code, block_json=block_json)
            return session.current_game_state()

        if action.action_type is ActionType.VERIFY_TOOLBOX_LEVEL:
            python_code = action.payload.get("python_code")
            if not isinstance(python_code, str) or not python_code:
                raise IntegrationDispatchError("verify_toolbox_level requires payload.python_code")

            block_json = action.payload.get("block_json")
            if block_json is not None and not isinstance(block_json, dict):
                raise IntegrationDispatchError("verify_toolbox_level payload.block_json must be a dict or null")

            session.verify_current_level_with_toolbox(python_code=python_code, block_json=block_json)
            return session.current_game_state()

        if action.action_type is ActionType.START_GROUP_STORY:
            group_id = action.payload.get("group_id")
            if not isinstance(group_id, str) or not group_id:
                raise IntegrationDispatchError("start_group_story requires payload.group_id")

            session.start_group_story(group_id)
            return session.current_game_state()

        if action.action_type is ActionType.START_GROUP_DEMO:
            group_id = action.payload.get("group_id")
            if not isinstance(group_id, str) or not group_id:
                raise IntegrationDispatchError("start_group_demo requires payload.group_id")

            session.start_group_demo(group_id)
            return session.current_game_state()

        if action.action_type is ActionType.START_GROUP_PRACTICE:
            group_id = action.payload.get("group_id")
            if not isinstance(group_id, str) or not group_id:
                raise IntegrationDispatchError("start_group_practice requires payload.group_id")

            session.start_group_practice(group_id)
            return session.current_game_state()

        if action.action_type is ActionType.CREATE_PLAYER_PROFILE:
            name = action.payload.get("name")
            gender = action.payload.get("gender")
            if not isinstance(name, str):
                raise IntegrationDispatchError("create_player_profile requires payload.name")
            if not isinstance(gender, str):
                raise IntegrationDispatchError("create_player_profile requires payload.gender")

            return session.create_player_profile(name=name, gender=gender)

        if action.action_type is ActionType.COMPLETE_INTRO:
            return session.complete_intro()

        if action.action_type is ActionType.RESTART_QUEST:
            raise IntegrationDispatchError("restart_quest is not implemented")
    except GameSessionError as exc:
        raise IntegrationDispatchError(str(exc)) from exc

    raise IntegrationDispatchError(f"Unsupported PlayerAction: {action.action_type.value}")
