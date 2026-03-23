from __future__ import annotations

from typing import TYPE_CHECKING

from block2python.integration.contracts import (
    AvailableActions,
    ChallengeState,
    DemoState,
    GameMode,
    GameState,
)

if TYPE_CHECKING:
    from .session import GameSession


def build_game_state(session: GameSession) -> GameState:
    state = session.current_state()
    runtime_state = session.runtime.current_state()
    progress = session._progress_state()
    session._sync_group_runtime_states(progress, state)
    map_route = session._map_route_state(state, progress)

    if session.player_profile.profile_created and not session.intro_completed:
        return GameState(
            mode=GameMode.SCENE,
            quest_id=session.runtime.quest.quest_id,
            node_id="opening-intro",
            node_title="Opening Intro",
            player_profile=session.player_profile,
            intro_completed=False,
            scene=session._opening_intro_scene(),
            progress=progress,
            available_actions=AvailableActions(advance=True),
            last_submission=session.last_submission,
            map_route=map_route,
        )

    if state.mode is session._session_mode_complete() or runtime_state is None:
        return GameState(
            mode=GameMode.COMPLETE,
            quest_id=session.runtime.quest.quest_id,
            player_profile=session.player_profile,
            intro_completed=session.intro_completed,
            progress=progress,
            available_actions=AvailableActions(),
            last_submission=session.last_submission,
            map_route=map_route,
        )

    scene = session._scene_state(runtime_state.scene) if state.mode is session._session_mode_scene() else None
    demo = None
    challenge = None
    if runtime_state.challenge is not None:
        if state.mode is session._session_mode_demo():
            demo = DemoState(
                demo_id=runtime_state.challenge.challenge_id,
                title=state.node_title or state.current_level_title or "Demo",
                body=state.current_level_prompt or "Demo placeholder.",
                current_level_id=state.current_level_id,
            )
        else:
            challenge = ChallengeState(
                challenge_id=runtime_state.challenge.challenge_id,
                challenge_type=runtime_state.challenge.challenge_type,
                current_level_id=state.current_level_id,
                current_level_title=state.current_level_title,
                current_level_prompt=state.current_level_prompt,
            )

    if state.mode is session._session_mode_scene():
        mode = GameMode.SCENE
        can_advance = runtime_state is not None and len(runtime_state.available_next_node_ids) == 1
        actions = AvailableActions(advance=can_advance)
    elif state.mode is session._session_mode_demo():
        mode = GameMode.DEMO
        actions = AvailableActions(advance=True)
    else:
        mode = GameMode.CHALLENGE
        actions = AvailableActions(submit=True)

    return GameState(
        mode=mode,
        quest_id=state.quest_id,
        node_id=state.node_id,
        node_title=state.node_title,
        player_profile=session.player_profile,
        intro_completed=session.intro_completed,
        scene=scene,
        demo=demo,
        challenge=challenge,
        progress=progress,
        available_actions=actions,
        last_submission=session.last_submission,
        map_route=map_route,
    )
