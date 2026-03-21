from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum

from block2python.level_play import AppCore, SubmitOutcome
from block2python.content import (
    AssembledGameSlice,
    GameRuntime,
    GroupMapRoutesSpec,
    MapRouteSpec,
    MapRouteStepSpec,
    ResolvedChallengeSpec,
    SceneSpec,
)
from block2python.contracts import AnalysisResult, AnalysisStatus, JudgeResult, JudgeStatus, LevelSpec, Submission
from block2python.integration.contracts import (
    AvailableActions,
    ChallengeState,
    DialogueBlockState,
    GameMode,
    GameState,
    GroupMapRouteState,
    GroupSlotState,
    MapRouteState,
    MapRouteStepState,
    ProgressState,
    SceneState,
    SubmissionFeedback,
)


class SessionMode(str, Enum):
    SCENE = "SCENE"
    CHALLENGE = "CHALLENGE"
    COMPLETE = "COMPLETE"


class GameSessionError(Exception):
    """Raised when the game session receives an invalid action."""


@dataclass(frozen=True, slots=True)
class GameSessionState:
    mode: SessionMode
    quest_id: str
    node_id: str | None = None
    node_title: str = ""
    scene_id: str | None = None
    challenge_id: str | None = None
    current_level_id: str | None = None
    current_level_title: str | None = None
    current_level_prompt: str | None = None


@dataclass(slots=True)
class GroupRuntimeState:
    group_id: str
    unlock_state: str = "locked"
    display_state: str = "locked"
    entered_once: bool = False
    demo_seen: bool = False
    practice_unlocked: bool = False
    practice_completed_count: int = 0
    practice_total_count: int = 0
    practice_current_level_id: str | None = None
    practice_last_level_id: str | None = None
    practice_reviewing: bool = False
    completed: bool = False


@dataclass(slots=True)
class GameSession:
    app: AppCore
    runtime: GameRuntime
    scene_seen_node_ids: set[str] = field(default_factory=set)
    demo_seen_group_ids: set[str] = field(default_factory=set)
    toolbox_used_level_ids: set[str] = field(default_factory=set)
    group_runtime_states: dict[str, GroupRuntimeState] = field(default_factory=dict)
    last_submission: SubmissionFeedback | None = None

    @classmethod
    def start(cls, *, app: AppCore, game_slice: AssembledGameSlice, quest_id: str) -> GameSession:
        return cls(app=app, runtime=GameRuntime.start(game_slice, quest_id=quest_id))

    def current_state(self) -> GameSessionState:
        self._sync_demo_seen_from_runtime()
        runtime_state = self.runtime.current_state()
        if runtime_state is None:
            return GameSessionState(mode=SessionMode.COMPLETE, quest_id=self.runtime.quest.quest_id)

        node = runtime_state.node
        scene_visible = runtime_state.scene is not None and node.node_id not in self.scene_seen_node_ids
        if scene_visible:
            return GameSessionState(
                mode=SessionMode.SCENE,
                quest_id=self.runtime.quest.quest_id,
                node_id=node.node_id,
                node_title=node.title,
                scene_id=runtime_state.scene.scene_id if runtime_state.scene else None,
                challenge_id=runtime_state.challenge.challenge_id if runtime_state.challenge else None,
            )

        if runtime_state.challenge is not None:
            current_level = self._current_level_for_challenge(runtime_state.challenge)
            if current_level is None:
                self.runtime.complete_current_node()
                return self.current_state()
            return GameSessionState(
                mode=SessionMode.CHALLENGE,
                quest_id=self.runtime.quest.quest_id,
                node_id=node.node_id,
                node_title=node.title,
                scene_id=runtime_state.scene.scene_id if runtime_state.scene else None,
                challenge_id=runtime_state.challenge.challenge_id,
                current_level_id=current_level.level_id,
                current_level_title=current_level.title,
                current_level_prompt=current_level.prompt,
            )

        return GameSessionState(
            mode=SessionMode.SCENE,
            quest_id=self.runtime.quest.quest_id,
            node_id=node.node_id,
            node_title=node.title,
            scene_id=runtime_state.scene.scene_id if runtime_state.scene else None,
        )

    def current_game_state(self) -> GameState:
        state = self.current_state()
        runtime_state = self.runtime.current_state()
        progress = self._progress_state()
        self._sync_group_runtime_states(progress, state)
        map_route = self._map_route_state(state, progress)

        if state.mode is SessionMode.COMPLETE or runtime_state is None:
            return GameState(
                mode=GameMode.COMPLETE,
                quest_id=self.runtime.quest.quest_id,
                progress=progress,
                available_actions=AvailableActions(),
                last_submission=self.last_submission,
                map_route=map_route,
            )

        scene = self._scene_state(runtime_state.scene) if state.mode is SessionMode.SCENE else None
        challenge = None
        if runtime_state.challenge is not None:
            challenge = ChallengeState(
                challenge_id=runtime_state.challenge.challenge_id,
                challenge_type=runtime_state.challenge.challenge_type,
                current_level_id=state.current_level_id,
                current_level_title=state.current_level_title,
                current_level_prompt=state.current_level_prompt,
            )

        if state.mode is SessionMode.SCENE:
            mode = GameMode.SCENE
            can_advance = runtime_state is not None and len(runtime_state.available_next_node_ids) == 1
            actions = AvailableActions(advance=can_advance)
        else:
            mode = GameMode.CHALLENGE
            actions = AvailableActions(submit=True)

        return GameState(
            mode=mode,
            quest_id=state.quest_id,
            node_id=state.node_id,
            node_title=state.node_title,
            scene=scene,
            challenge=challenge,
            progress=progress,
            available_actions=actions,
            last_submission=self.last_submission,
            map_route=map_route,
        )

    def advance(self) -> GameSessionState:
        self.last_submission = None
        state = self.current_state()
        if state.mode is SessionMode.COMPLETE:
            raise GameSessionError("Game session is already complete")
        if state.mode is SessionMode.CHALLENGE:
            raise GameSessionError("Cannot advance a challenge node without clearing the current level")

        if state.node_id is None:
            raise GameSessionError("Current scene node is missing node_id")

        runtime_state = self.runtime.current_state()
        if runtime_state is None:
            raise GameSessionError("Game session is already complete")

        if runtime_state.challenge is not None and runtime_state.scene is not None and state.node_id not in self.scene_seen_node_ids:
            self.scene_seen_node_ids.add(state.node_id)
            return self.current_state()

        self.runtime.complete_current_node()
        return self.current_state()

    def start_group_demo(self, group_id: str) -> GameSessionState:
        if not group_id:
            raise GameSessionError("group_id is required")
        group = self._route_group(group_id)
        if group is None:
            raise GameSessionError(f"Unknown group_id: {group_id}")

        progress = self._progress_state()
        if not self._is_group_demo_unlocked(group, set(progress.completed_node_ids), set(progress.cleared_level_ids)):
            raise GameSessionError(f"Demo for {group_id} is still locked until story is completed")

        target_node_id = self._entry_node_id_for_steps(group.demo_route, allowed_step_types={"challenge", "demo"})
        if target_node_id is None:
            raise GameSessionError(f"Group {group_id} has no demo entry node")

        self._sync_group_runtime_states(progress, self.current_state())
        runtime_group = self.group_runtime_states.get(group_id)
        if runtime_group is not None:
            runtime_group.entered_once = True
        self._jump_to_node(target_node_id)
        return self.current_state()

    def start_group_story(self, group_id: str) -> GameSessionState:
        if not group_id:
            raise GameSessionError("group_id is required")
        group = self._route_group(group_id)
        if group is None:
            raise GameSessionError(f"Unknown group_id: {group_id}")
        target_node_id = self._entry_node_id_for_steps(group.demo_route, allowed_step_types={"story"})
        if target_node_id is None:
            raise GameSessionError(f"Group {group_id} has no story entry node")

        self._sync_group_runtime_states(self._progress_state(), self.current_state())
        runtime_group = self.group_runtime_states.get(group_id)
        if runtime_group is not None:
            runtime_group.entered_once = True
        self._jump_to_node(target_node_id)
        return self.current_state()

    def start_group_practice(self, group_id: str) -> GameSessionState:
        if not group_id:
            raise GameSessionError("group_id is required")
        self._sync_demo_seen_from_runtime()
        if group_id not in self.demo_seen_group_ids:
            raise GameSessionError(f"Practice for {group_id} is still locked")

        group = self._route_group(group_id)
        if group is None:
            raise GameSessionError(f"Unknown group_id: {group_id}")
        progress = self._progress_state()
        self._sync_group_runtime_states(progress, self.current_state())
        runtime_group = self.group_runtime_states.get(group_id)
        if runtime_group is not None and runtime_group.completed:
            runtime_group.practice_reviewing = True
        target_node_id = self._entry_node_id_for_steps(group.practice_route)
        if target_node_id is None:
            raise GameSessionError(f"Group {group_id} has no practice entry node")

        self._jump_to_node(target_node_id)
        return self.current_state()

    def submit_current_level(self, *, python_code: str, block_json: dict | None = None) -> tuple[GameSessionState, SubmitOutcome]:
        state = self.current_state()
        if state.mode is not SessionMode.CHALLENGE:
            raise GameSessionError("Current node is not a challenge")
        if state.current_level_id is None:
            raise GameSessionError("Challenge node has no current level")

        self.app.mark_block_passed(state.current_level_id)
        if self._is_placeholder_auto_ac_level(state.current_level_id):
            self.app.mark_cleared(state.current_level_id)
            outcome = SubmitOutcome(
                analysis=AnalysisResult(status=AnalysisStatus.PASS, summary="Placeholder level auto-cleared"),
                judge=JudgeResult(status=JudgeStatus.AC, summary="Placeholder level auto-cleared"),
                cleared=True,
                block_passed=True,
            )
        else:
            outcome = self.app.submit(
                Submission(level_id=state.current_level_id, python_code=python_code, block_json=block_json)
            )
        self.last_submission = SubmissionFeedback(
            level_id=state.current_level_id,
            cleared=outcome.cleared,
            block_passed=outcome.block_passed,
            analysis_status=outcome.analysis.status.value,
            analysis_summary=outcome.analysis.summary,
            judge_status=outcome.judge.status.value,
            judge_summary=outcome.judge.summary,
            verification_only=False,
            answer_correct=outcome.judge.status is JudgeStatus.AC,
        )
        self._advance_review_practice_level(state)
        return self.current_state(), outcome

    def verify_current_level_with_toolbox(
        self,
        *,
        python_code: str,
        block_json: dict | None = None,
    ) -> tuple[GameSessionState, SubmitOutcome]:
        state = self.current_state()
        if state.mode is not SessionMode.CHALLENGE:
            raise GameSessionError("Current node is not a challenge")
        if state.current_level_id is None:
            raise GameSessionError("Challenge node has no current level")

        runtime_state = self.runtime.current_state()
        if runtime_state is None or runtime_state.challenge is None:
            raise GameSessionError("Current node is not a challenge")
        if runtime_state.challenge.challenge_type != "practice":
            raise GameSessionError("Toolbox verification is only available in practice challenges")

        outcome = self.app.verify(
            Submission(level_id=state.current_level_id, python_code=python_code, block_json=block_json)
        )
        self.toolbox_used_level_ids.add(state.current_level_id)
        self.last_submission = SubmissionFeedback(
            level_id=state.current_level_id,
            cleared=False,
            block_passed=False,
            analysis_status=outcome.analysis.status.value,
            analysis_summary=outcome.analysis.summary,
            judge_status=outcome.judge.status.value,
            judge_summary=outcome.judge.summary,
            verification_only=True,
            answer_correct=outcome.judge.status is JudgeStatus.AC,
        )
        return self.current_state(), outcome

    def _current_level_for_challenge(self, challenge: ResolvedChallengeSpec) -> LevelSpec | None:
        review_level = self._review_level_for_challenge(challenge)
        if review_level is not None:
            return review_level
        for level in challenge.levels:
            if self.app.is_cleared(level.level_id):
                continue
            if self._should_auto_clear_on_enter(level):
                self.app.mark_cleared(level.level_id)
                continue
            return level
        return None

    def _scene_state(self, scene: SceneSpec | None) -> SceneState | None:
        if scene is None:
            return None
        return SceneState(
            scene_id=scene.scene_id,
            title=scene.title,
            dialogue_blocks=tuple(
                DialogueBlockState(
                    speaker=block.speaker,
                    text=block.text,
                    portrait_id=block.portrait_id,
                    expression=block.expression,
                    emphasis=block.emphasis,
                )
                for block in scene.dialogue_blocks
            ),
        )

    def _progress_state(self) -> ProgressState:
        completed_node_ids = tuple(
            node_id for node_id in self.runtime.quest.node_ids if node_id in self.runtime.completed_node_ids
        )
        cleared_level_ids = tuple(
            level_id for level_id in self.runtime.game_slice.levels if self.app.is_cleared(level_id)
        )
        return ProgressState(
            completed_node_ids=completed_node_ids,
            cleared_level_ids=cleared_level_ids,
            demo_seen_group_ids=tuple(sorted(self.demo_seen_group_ids)),
            toolbox_used_level_ids=tuple(sorted(self.toolbox_used_level_ids)),
        )

    def _map_route_state(self, state: GameSessionState, progress: ProgressState) -> MapRouteState | None:
        route_spec = self._route_spec_for_current_quest()
        if route_spec is None:
            return None

        groups = tuple(self._group_map_route_state(group, state, progress) for group in route_spec.groups)
        return MapRouteState(
            route_id=route_spec.route_id,
            quest_id=route_spec.quest_id,
            title=route_spec.title,
            groups=groups,
        )

    def _route_spec_for_current_quest(self) -> MapRouteSpec | None:
        quest_id = self.runtime.quest.quest_id
        for route in self.runtime.game_slice.map_routes.values():
            if route.quest_id == quest_id:
                return route
        return None

    def _group_map_route_state(
        self,
        group: GroupMapRoutesSpec,
        state: GameSessionState,
        progress: ProgressState,
    ) -> GroupMapRouteState:
        demo_route = tuple(self._map_route_step_state(step, state, progress, group.demo_route, group.group_id) for step in group.demo_route)
        practice_route = tuple(self._map_route_step_state(step, state, progress, group.practice_route, group.group_id) for step in group.practice_route)
        runtime_group = self.group_runtime_states[group.group_id]
        status_key = self._group_display_state(runtime_group, state)
        return GroupMapRouteState(
            group_id=group.group_id,
            title=group.title,
            status_key=status_key,
            status_label=self._group_status_label(status_key, self._is_planned_only_group(demo_route + practice_route)),
            is_enterable=runtime_group.unlock_state != "locked",
            current_label=self._group_current_label(status_key, demo_route + practice_route),
            demo_slot=self._group_slot_state("demo", "Demo", demo_route, runtime_group),
            practice_slot=self._group_slot_state("practice", "Practice", practice_route, runtime_group),
            demo_route=demo_route,
            practice_route=practice_route,
        )

    def _map_route_step_state(
        self,
        step: MapRouteStepSpec,
        state: GameSessionState,
        progress: ProgressState,
        route_steps: tuple[MapRouteStepSpec, ...],
        group_id: str,
    ) -> MapRouteStepState:
        status_key = self._route_step_status_key(step, state, progress, route_steps, group_id)
        return MapRouteStepState(
            step_id=step.step_id,
            step_type=step.step_type,
            title=step.title,
            target_page=step.target_page,
            status_key=status_key,
            status_label=self._route_step_status_label(status_key),
            tracked_node_ids=step.tracked_node_ids,
            level_ids=step.level_ids,
            node_id=step.node_id,
            scene_id=step.scene_id,
            challenge_id=step.challenge_id,
            is_planned=step.is_planned,
            is_repeatable=step.is_repeatable,
        )

    def _group_slot_state(
        self,
        slot_key: str,
        title: str,
        route_steps: tuple[MapRouteStepState, ...],
        runtime_group: GroupRuntimeState,
    ) -> GroupSlotState:
        slot_status_key = self._slot_status_key(slot_key, route_steps, runtime_group)
        return GroupSlotState(
            slot_key=slot_key,
            title=title,
            status_key=slot_status_key,
            status_label=self._group_status_label(slot_status_key, False),
            is_unlocked=self._is_demo_slot_unlocked(route_steps, runtime_group) if slot_key == "demo" else runtime_group.practice_unlocked,
            viewed=runtime_group.demo_seen if slot_key == "demo" else False,
            completed_count=runtime_group.practice_completed_count if slot_key == "practice" else 0,
            total_count=runtime_group.practice_total_count if slot_key == "practice" else 0,
            next_level_id=runtime_group.practice_current_level_id if slot_key == "practice" else None,
            entry_level_id=runtime_group.practice_current_level_id if slot_key == "practice" else None,
        )

    def _slot_status_key(
        self,
        slot_key: str,
        route_steps: tuple[MapRouteStepState, ...],
        runtime_group: GroupRuntimeState,
    ) -> str:
        if slot_key == "demo":
            if any(step.status_key == "current" and step.step_type in {"challenge", "demo"} for step in route_steps) and not runtime_group.completed:
                return "current"
            if runtime_group.demo_seen:
                return "completed"
            if self._is_demo_slot_unlocked(route_steps, runtime_group):
                return "available"
            return "locked"

        if not runtime_group.practice_unlocked and not runtime_group.completed:
            return "locked"
        if runtime_group.practice_reviewing:
            return "reviewing"
        if any(step.status_key == "current" for step in route_steps) and not runtime_group.completed:
            return "current"
        if runtime_group.practice_total_count > 0 and runtime_group.practice_completed_count >= runtime_group.practice_total_count:
            return "completed"
        return "available"

    @staticmethod
    def _is_demo_slot_unlocked(route_steps: tuple[MapRouteStepState, ...], runtime_group: GroupRuntimeState) -> bool:
        if runtime_group.unlock_state == "locked":
            return False
        return any(step.step_type in {"challenge", "demo"} and step.status_key in {"available", "current", "completed", "reviewing"} for step in route_steps)

    def _is_group_demo_unlocked(
        self,
        group: GroupMapRoutesSpec,
        completed_node_ids: set[str],
        cleared_level_ids: set[str],
    ) -> bool:
        for step in group.demo_route:
            if step.step_type in {"challenge", "demo"}:
                return True
            if step.step_type == "story" and not self._is_route_step_spec_completed(step, completed_node_ids, cleared_level_ids):
                return False
        return False

    def _group_display_state(self, runtime_group: GroupRuntimeState, _state: GameSessionState) -> str:
        current_group_id = self._current_mainline_group_id()
        if runtime_group.completed:
            if runtime_group.practice_reviewing:
                return "reviewing"
            return "completed"
        if runtime_group.unlock_state == "locked":
            return "locked"
        if current_group_id == runtime_group.group_id:
            return "current"
        return "available"

    def _group_current_label(self, status_key: str, steps: tuple[MapRouteStepState, ...]) -> str:
        if status_key == "current":
            for step in steps:
                if step.status_key == "current":
                    return f"Current flow: {step.title}"
        if status_key == "reviewing":
            return "Reviewing Practice"
        return ""

    def _all_trackable_steps_completed(self, steps: tuple[MapRouteStepState, ...]) -> bool:
        trackable_steps = [step for step in steps if self._is_trackable_step(step)]
        return bool(trackable_steps) and all(step.status_key == "completed" for step in trackable_steps)

    @staticmethod
    def _is_trackable_step(step: MapRouteStepState) -> bool:
        return bool(step.tracked_node_ids or step.level_ids or step.node_id or step.challenge_id or step.scene_id)

    @staticmethod
    def _is_planned_only_group(steps: tuple[MapRouteStepState, ...]) -> bool:
        return not any(bool(step.tracked_node_ids or step.level_ids or step.node_id or step.challenge_id or step.scene_id) for step in steps)

    @staticmethod
    def _group_status_label(status_key: str, is_planned_only: bool) -> str:
        if is_planned_only and status_key == "available":
            return "Planned"
        if is_planned_only and status_key == "locked":
            return "Queued"
        if status_key == "reviewing":
            return "Reviewing"
        return GameSession._route_step_status_label(status_key)

    @staticmethod
    def _primary_step_level_ids(route_steps: tuple[MapRouteStepState, ...]) -> tuple[str, ...]:
        for step in route_steps:
            if step.status_key == "current" and step.level_ids:
                return step.level_ids
        for step in route_steps:
            if step.status_key in {"available", "completed", "reviewing"} and step.level_ids:
                return step.level_ids
        for step in route_steps:
            if step.level_ids:
                return step.level_ids
        return ()

    @staticmethod
    def _first_uncleared_level_id_from_list(level_ids: tuple[str, ...], cleared_level_ids: set[str]) -> str | None:
        for level_id in level_ids:
            if level_id not in cleared_level_ids:
                return level_id
        return None

    def _ensure_group_runtime_states(self, route_spec: MapRouteSpec) -> None:
        for index, group in enumerate(route_spec.groups):
            runtime_group = self.group_runtime_states.get(group.group_id)
            if runtime_group is None:
                runtime_group = GroupRuntimeState(group_id=group.group_id)
                if index == 0:
                    runtime_group.unlock_state = "available"
                    runtime_group.display_state = "available"
                self.group_runtime_states[group.group_id] = runtime_group

    def _sync_group_runtime_states(self, progress: ProgressState, state: GameSessionState) -> None:
        route_spec = self._route_spec_for_current_quest()
        if route_spec is None:
            return

        self._ensure_group_runtime_states(route_spec)
        completed_node_ids = set(progress.completed_node_ids)
        cleared_level_ids = set(progress.cleared_level_ids)
        demo_seen_group_ids = set(progress.demo_seen_group_ids)
        current_group_id = self._group_id_for_state(state)

        previous_group_completed = True
        for index, group in enumerate(route_spec.groups):
            runtime_group = self.group_runtime_states[group.group_id]
            if index == 0 and runtime_group.unlock_state == "locked":
                runtime_group.unlock_state = "available"

            runtime_group.demo_seen = runtime_group.demo_seen or group.group_id in demo_seen_group_ids
            if current_group_id == group.group_id:
                runtime_group.entered_once = True

            level_ids = self._group_practice_level_ids(group)
            runtime_group.practice_total_count = len(level_ids)
            runtime_group.practice_completed_count = sum(1 for level_id in level_ids if level_id in cleared_level_ids)
            var_review_target = runtime_group.practice_current_level_id
            if runtime_group.practice_reviewing and state.current_level_id is not None and state.current_level_id in level_ids:
                var_review_target = state.current_level_id
            if runtime_group.practice_reviewing:
                if var_review_target in level_ids:
                    runtime_group.practice_current_level_id = var_review_target
                else:
                    runtime_group.practice_current_level_id = level_ids[0] if level_ids else None
            else:
                runtime_group.practice_current_level_id = self._first_uncleared_level_id_from_list(level_ids, cleared_level_ids) or (level_ids[0] if level_ids else None)
            runtime_group.practice_unlocked = runtime_group.demo_seen and bool(level_ids)
            if state.current_level_id is not None and state.current_level_id in level_ids:
                runtime_group.practice_last_level_id = state.current_level_id

            if runtime_group.demo_seen or runtime_group.practice_completed_count > 0 or self._group_has_any_progress(group, completed_node_ids):
                runtime_group.entered_once = True

            runtime_group.completed = self._is_group_completed_from_progress(group, completed_node_ids, cleared_level_ids)
            if runtime_group.completed:
                runtime_group.unlock_state = "completed"
            elif previous_group_completed and runtime_group.unlock_state == "locked":
                runtime_group.unlock_state = "available"

            runtime_group.display_state = self._group_display_state(runtime_group, state)
            previous_group_completed = runtime_group.completed

    def _group_practice_level_ids(self, group: GroupMapRoutesSpec) -> tuple[str, ...]:
        for step in group.practice_route:
            if step.level_ids:
                return step.level_ids
        return ()

    def _group_has_any_progress(self, group: GroupMapRoutesSpec, completed_node_ids: set[str]) -> bool:
        for step in group.demo_route + group.practice_route:
            if step.node_id is not None and step.node_id in completed_node_ids:
                return True
            if any(node_id in completed_node_ids for node_id in step.tracked_node_ids):
                return True
        return False

    def _is_group_completed_from_progress(
        self,
        group: GroupMapRoutesSpec,
        completed_node_ids: set[str],
        cleared_level_ids: set[str],
    ) -> bool:
        trackable_steps = [step for step in group.demo_route + group.practice_route if self._is_trackable_spec_step(step)]
        return bool(trackable_steps) and all(
            self._is_route_step_spec_completed(step, completed_node_ids, cleared_level_ids, group.group_id)
            for step in trackable_steps
        )

    @staticmethod
    def _is_trackable_spec_step(step: MapRouteStepSpec) -> bool:
        return bool(step.tracked_node_ids or step.level_ids or step.node_id or step.challenge_id or step.scene_id)

    def _is_route_step_spec_completed(
        self,
        step: MapRouteStepSpec,
        completed_node_ids: set[str],
        cleared_level_ids: set[str],
        group_id: str | None = None,
    ) -> bool:
        if self._is_demo_step_counted_as_completed(step, group_id, self.demo_seen_group_ids):
            return True
        if step.level_ids:
            return all(level_id in cleared_level_ids for level_id in step.level_ids)
        if step.node_id is not None:
            return step.node_id in completed_node_ids
        if step.tracked_node_ids:
            return all(node_id in completed_node_ids for node_id in step.tracked_node_ids)
        return False


    def _current_mainline_group_id(self) -> str | None:
        route_spec = self._route_spec_for_current_quest()
        if route_spec is None:
            return None
        current_group_id: str | None = None
        for group in route_spec.groups:
            runtime_group = self.group_runtime_states.get(group.group_id)
            if runtime_group is None:
                continue
            if runtime_group.unlock_state == "locked":
                continue
            if runtime_group.completed:
                continue
            if not runtime_group.entered_once:
                continue
            current_group_id = group.group_id
        return current_group_id

    def _group_id_for_state(self, state: GameSessionState) -> str | None:
        if state.current_level_id is not None:
            group_id = self._group_id_for_level_id(state.current_level_id)
            if group_id is not None:
                return group_id
        if state.node_id is not None:
            return self._group_id_for_node_id(state.node_id)
        return None

    def _group_id_for_level_id(self, level_id: str) -> str | None:
        route_spec = self._route_spec_for_current_quest()
        if route_spec is None:
            return None
        for group in route_spec.groups:
            for step in group.demo_route + group.practice_route:
                if level_id in step.level_ids:
                    return group.group_id
        return None

    def _group_id_for_node_id(self, node_id: str) -> str | None:
        route_spec = self._route_spec_for_current_quest()
        if route_spec is None:
            return None
        for group in route_spec.groups:
            for step in group.demo_route + group.practice_route:
                if step.node_id == node_id:
                    return group.group_id
                if node_id in step.tracked_node_ids:
                    return group.group_id
        return None


    def _advance_review_practice_level(self, state: GameSessionState) -> None:
        if state.current_level_id is None:
            return
        group_id = self._group_id_for_level_id(state.current_level_id)
        if group_id is None:
            return
        runtime_group = self.group_runtime_states.get(group_id)
        if runtime_group is None or not runtime_group.practice_reviewing:
            return
        level_ids = self._group_practice_level_ids(self._route_group(group_id))
        if not level_ids:
            return
        try:
            current_index = level_ids.index(state.current_level_id)
        except ValueError:
            runtime_group.practice_current_level_id = level_ids[0]
            runtime_group.practice_last_level_id = level_ids[0]
            return
        if current_index >= len(level_ids) - 1:
            first_level_id = level_ids[0]
            runtime_group.practice_current_level_id = first_level_id
            runtime_group.practice_last_level_id = first_level_id
            runtime_group.practice_reviewing = False
            self._jump_to_node("main-map-entry")
            return
        next_index = current_index + 1
        next_level_id = level_ids[next_index]
        runtime_group.practice_current_level_id = next_level_id
        runtime_group.practice_last_level_id = next_level_id

    def _review_level_for_challenge(self, challenge: ResolvedChallengeSpec) -> LevelSpec | None:
        runtime_state = self.runtime.current_state()
        if runtime_state is None:
            return None
        if runtime_state.node.challenge_group_id != challenge.challenge_id:
            return None
        group_id = self._group_id_for_node_id(runtime_state.node.node_id)
        if group_id is None:
            return None
        runtime_group = self.group_runtime_states.get(group_id)
        if runtime_group is None or not runtime_group.practice_reviewing:
            return None
        target_level_id = runtime_group.practice_current_level_id or runtime_group.practice_last_level_id
        if target_level_id is None and challenge.levels:
            target_level_id = challenge.levels[0].level_id
        if target_level_id is None:
            return None
        for level in challenge.levels:
            if level.level_id == target_level_id:
                return level
        return None

    def _route_step_status_key(
        self,
        step: MapRouteStepSpec,
        state: GameSessionState,
        progress: ProgressState,
        route_steps: tuple[MapRouteStepSpec, ...],
        group_id: str,
    ) -> str:
        completed_node_ids = set(progress.completed_node_ids)
        cleared_level_ids = set(progress.cleared_level_ids)
        demo_seen_group_ids = set(progress.demo_seen_group_ids)

        if self._is_route_step_current(step, state):
            return "current"
        if self._is_route_step_completed(step, completed_node_ids, cleared_level_ids, demo_seen_group_ids, group_id):
            return "completed"
        if step.is_planned and not step.tracked_node_ids and not step.level_ids and step.node_id is None and step.challenge_id is None:
            return "planned"
        if self._is_route_step_available(step, route_steps, completed_node_ids, cleared_level_ids, demo_seen_group_ids):
            return "available"
        return "locked"

    def _is_route_step_current(self, step: MapRouteStepSpec, state: GameSessionState) -> bool:
        if step.node_id is not None:
            return step.node_id == state.node_id
        if state.node_id is not None and state.node_id in step.tracked_node_ids:
            return True
        if state.current_level_id is not None and state.current_level_id in step.level_ids:
            return True
        if step.challenge_id is not None and not step.tracked_node_ids:
            return step.challenge_id == state.challenge_id
        if step.scene_id is not None and not step.tracked_node_ids:
            return step.scene_id == state.scene_id
        return False

    def _is_route_step_completed(
        self,
        step: MapRouteStepSpec,
        completed_node_ids: set[str],
        cleared_level_ids: set[str],
        demo_seen_group_ids: set[str] | None = None,
        group_id: str | None = None,
    ) -> bool:
        if self._is_demo_step_counted_as_completed(step, group_id, demo_seen_group_ids):
            return True
        if step.level_ids:
            return all(level_id in cleared_level_ids for level_id in step.level_ids)
        if step.node_id is not None:
            return step.node_id in completed_node_ids
        if step.tracked_node_ids:
            return all(node_id in completed_node_ids for node_id in step.tracked_node_ids)
        return False

    @staticmethod
    def _is_demo_step_counted_as_completed(
        step: MapRouteStepSpec,
        group_id: str | None,
        demo_seen_group_ids: set[str] | None,
    ) -> bool:
        if group_id is None or demo_seen_group_ids is None:
            return False
        return step.step_type in {"challenge", "demo"} and group_id in demo_seen_group_ids

    def _is_route_step_available(
        self,
        step: MapRouteStepSpec,
        route_steps: tuple[MapRouteStepSpec, ...],
        completed_node_ids: set[str],
        cleared_level_ids: set[str],
        demo_seen_group_ids: set[str],
    ) -> bool:
        required_group_id = step.metadata.get("requires_demo_seen_group_id")
        if isinstance(required_group_id, str) and required_group_id not in demo_seen_group_ids:
            return False

        step_index = route_steps.index(step)
        if step_index == 0:
            return True
        for previous_step in route_steps[:step_index]:
            if previous_step.is_planned and not previous_step.level_ids and not previous_step.tracked_node_ids and previous_step.node_id is None:
                continue
            if not self._is_route_step_completed(previous_step, completed_node_ids, cleared_level_ids, demo_seen_group_ids):
                return False
        return True

    @staticmethod
    def _route_step_status_label(status_key: str) -> str:
        if status_key == "current":
            return "Current"
        if status_key == "completed":
            return "Completed"
        if status_key == "reviewing":
            return "Reviewing"
        if status_key == "available":
            return "Available"
        if status_key == "planned":
            return "Planned"
        return "Locked"

    def _route_group(self, group_id: str) -> GroupMapRoutesSpec | None:
        route_spec = self._route_spec_for_current_quest()
        if route_spec is None:
            return None
        for group in route_spec.groups:
            if group.group_id == group_id:
                return group
        return None

    def _sync_demo_seen_from_runtime(self) -> None:
        route_spec = self._route_spec_for_current_quest()
        runtime_state = self.runtime.current_state()
        if route_spec is None or runtime_state is None:
            return

        current_node_id = runtime_state.node.node_id
        completed_node_ids = set(self.runtime.completed_node_ids)
        for group in route_spec.groups:
            for step in group.demo_route:
                if step.step_type not in {"challenge", "demo"}:
                    continue
                if step.node_id == current_node_id:
                    self.demo_seen_group_ids.add(group.group_id)
                    break
                tracked_ids = set(step.tracked_node_ids)
                if tracked_ids and tracked_ids & completed_node_ids:
                    self.demo_seen_group_ids.add(group.group_id)
                    break

    def _jump_to_node(self, node_id: str) -> None:
        if node_id not in self.runtime.quest.node_ids:
            raise GameSessionError(f"Node {node_id} is not part of quest {self.runtime.quest.quest_id}")
        self.runtime.current_node_id = node_id
        self.last_submission = None
        self.scene_seen_node_ids.discard(node_id)

    @staticmethod
    def _entry_node_id_for_steps(
        route_steps: tuple[MapRouteStepSpec, ...],
        *,
        allowed_step_types: set[str] | None = None,
    ) -> str | None:
        for step in route_steps:
            if step.target_page == "map":
                continue
            if allowed_step_types is not None and step.step_type not in allowed_step_types:
                continue
            if step.node_id is not None:
                return step.node_id
        return None

    def _first_uncleared_level_id(self, challenge: ResolvedChallengeSpec) -> str | None:
        for level in challenge.levels:
            if not self.app.is_cleared(level.level_id):
                return level.level_id
        return challenge.levels[0].level_id if challenge.levels else None

    def _is_placeholder_auto_ac_level(self, level_id: str) -> bool:
        level = self.runtime.game_slice.levels.get(level_id)
        if level is None:
            return False
        return bool(level.metadata.get("placeholder_auto_ac", False))

    @staticmethod
    def _should_auto_clear_on_enter(level: LevelSpec) -> bool:
        return bool(level.metadata.get("auto_clear_on_enter", False))

