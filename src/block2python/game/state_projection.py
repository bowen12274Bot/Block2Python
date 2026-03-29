from __future__ import annotations

from typing import TYPE_CHECKING

from block2python.integration.contracts import (
    AvailableActions,
    PracticeState,
    DemoState,
    GameMode,
    GameState,
)

if TYPE_CHECKING:
    from block2python.content import ResolvedChallengeSpec
    from block2python.contracts import LevelSpec
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

    scene = session._scene_state(runtime_state.scene, runtime_state.node) if state.mode is session._session_mode_scene() else None
    current_challenge = runtime_state.challenge
    current_level = session._current_level_for_challenge(current_challenge) if current_challenge is not None else None
    group_id = _group_id_for_active_state(session, state, current_level)
    runtime_group = session.group_runtime_states.get(group_id) if group_id is not None else None

    if state.mode is session._session_mode_scene():
        mode = GameMode.SCENE
        can_advance = runtime_state is not None and len(runtime_state.available_next_node_ids) == 1
        actions = AvailableActions(advance=can_advance)
    elif state.mode is session._session_mode_demo():
        mode = GameMode.DEMO
        actions = AvailableActions(advance=True)
    else:
        mode = GameMode.CHALLENGE
        can_next = current_level is not None and session.next_enabled_level_id == current_level.level_id
        actions = AvailableActions(run=True, submit=True, next_level=can_next)

    demo = None
    practice = None
    if current_challenge is not None and current_level is not None:
        if state.mode is session._session_mode_demo():
            demo = _build_demo_state(
                session=session,
                challenge=current_challenge,
                level=current_level,
                group_id=group_id,
                can_advance=actions.advance,
                node_title=state.node_title,
            )
        else:
            practice = _build_practice_state(
                session=session,
                challenge=current_challenge,
                level=current_level,
                group_id=group_id,
                runtime_group=runtime_group,
                can_run=actions.run,
                can_submit=actions.submit,
                can_next=actions.next_level,
            )

    return GameState(
        mode=mode,
        quest_id=state.quest_id,
        node_id=state.node_id,
        node_title=state.node_title,
        player_profile=session.player_profile,
        intro_completed=session.intro_completed,
        scene=scene,
        demo=demo,
        practice=practice,
        progress=progress,
        available_actions=actions,
        last_submission=session.last_submission,
        map_route=map_route,
    )


def _group_id_for_active_state(session: GameSession, state, current_level: LevelSpec | None) -> str | None:
    if current_level is not None:
        group_id = session._group_id_for_level_id(current_level.level_id)
        if group_id is not None:
            return group_id
    if state.node_id is not None:
        return session._group_id_for_node_id(state.node_id)
    return None


def _build_demo_state(
    *,
    session: GameSession,
    challenge: ResolvedChallengeSpec,
    level: LevelSpec,
    group_id: str | None,
    can_advance: bool,
    node_title: str,
) -> DemoState:
    prompt = level.prompt
    learning_markdown = level.learning_markdown
    story_intro_markdown = level.story_intro_markdown
    story_outro_markdown = level.story_outro_markdown
    body_parts = [part for part in (prompt, learning_markdown, story_intro_markdown, story_outro_markdown) if part]
    return DemoState(
        demo_id=challenge.challenge_id,
        title=node_title or level.title or challenge.title,
        group_id=group_id,
        level_id=level.level_id,
        prompt=prompt,
        learning_markdown=learning_markdown,
        story_intro_markdown=story_intro_markdown,
        story_outro_markdown=story_outro_markdown,
        can_advance=can_advance,
        body="\n\n".join(body_parts),
        current_level_id=level.level_id,
        unlock_blocks=_demo_unlock_blocks(group_id),
        toolbox_block_ids=session.current_toolbox_block_ids(),
    )


def _demo_unlock_blocks(group_id: str | None) -> tuple[dict[str, str], ...]:
    if group_id == "group-01":
        return (
            {"title": "print", "description": "Output text to the screen."},
            {"title": "input", "description": "Read user input into your program."},
        )
    return (
        {"title": "Coming Soon", "description": "Future stages will add more blocks here."},
    )


def _build_practice_state(
    *,
    session: GameSession,
    challenge: ResolvedChallengeSpec,
    level: LevelSpec,
    group_id: str | None,
    runtime_group,
    can_run: bool,
    can_submit: bool,
    can_next: bool,
) -> PracticeState:
    progress_current, progress_total = _practice_progress(challenge, level)
    toolbox_allowed = bool(
        challenge.toolbox_policy is not None
        and challenge.toolbox_policy.allow_toolbox_in_practice
        and challenge.challenge_type == "practice"
    )
    toolbox_block_ids = session.current_toolbox_block_ids() if toolbox_allowed else ()
    return PracticeState(
        challenge_id=challenge.challenge_id,
        challenge_type=challenge.challenge_type,
        group_id=group_id,
        level_id=level.level_id,
        level_title=level.title,
        prompt=level.prompt,
        progress_current=progress_current,
        progress_total=progress_total,
        is_review_mode=bool(runtime_group.practice_reviewing) if runtime_group is not None else False,
        toolbox_allowed=toolbox_allowed,
        toolbox_used=level.level_id in session.toolbox_used_level_ids,
        toolbox_block_ids=toolbox_block_ids,
        can_run=can_run,
        can_submit=can_submit,
        can_next=can_next,
        mission_text=level.prompt,
        battery_percent=session.current_practice_battery_percent(group_id),
        battery_threshold_percent=80,
        assistant_messages=_assistant_messages(session, level, toolbox_allowed, can_next),
        current_level_id=level.level_id,
        current_level_title=level.title,
        current_level_prompt=level.prompt,
    )


def _practice_progress(challenge: ResolvedChallengeSpec, level: LevelSpec) -> tuple[int, int]:
    total = len(challenge.levels)
    for index, challenge_level in enumerate(challenge.levels, start=1):
        if challenge_level.level_id == level.level_id:
            return index, total
    return 0, total


def _assistant_messages(session: GameSession, level: LevelSpec, toolbox_allowed: bool, can_next: bool) -> tuple[str, ...]:
    messages = [
        "Byte: Read the mission, then run the code to inspect output.",
    ]
    if can_next:
        messages.append("Byte: This level is cleared. Press Next to continue.")
    elif session.last_submission is not None and session.last_submission.level_id == level.level_id:
        messages.append("Byte: Check the diagnostic output, then decide whether to rerun, edit, or submit.")
    if toolbox_allowed:
        messages.append("Byte: If you get stuck, open the Tool Kit to try a block-based run.")
    return tuple(messages)
