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
class GameSession:
    app: AppCore
    runtime: GameRuntime
    scene_seen_node_ids: set[str] = field(default_factory=set)
    demo_seen_group_ids: set[str] = field(default_factory=set)
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
            actions = AvailableActions(advance=True)
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
        target_node_id = self._entry_node_id_for_steps(group.demo_route)
        if target_node_id is None:
            raise GameSessionError(f"Group {group_id} has no demo entry node")

        self.demo_seen_group_ids.add(group_id)
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
        )
        return self.current_state(), outcome

    def _current_level_for_challenge(self, challenge: ResolvedChallengeSpec) -> LevelSpec | None:
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
        )

    def _map_route_state(self, state: GameSessionState, progress: ProgressState) -> MapRouteState | None:
        route_spec = self._route_spec_for_current_quest()
        if route_spec is None:
            return None

        groups = tuple(
            self._group_map_route_state(group, state, progress)
            for group in route_spec.groups
        )
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
        return GroupMapRouteState(
            group_id=group.group_id,
            title=group.title,
            demo_route=tuple(self._map_route_step_state(step, state, progress, group.demo_route) for step in group.demo_route),
            practice_route=tuple(self._map_route_step_state(step, state, progress, group.practice_route) for step in group.practice_route),
        )

    def _map_route_step_state(
        self,
        step: MapRouteStepSpec,
        state: GameSessionState,
        progress: ProgressState,
        route_steps: tuple[MapRouteStepSpec, ...],
    ) -> MapRouteStepState:
        status_key = self._route_step_status_key(step, state, progress, route_steps)
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

    def _route_step_status_key(
        self,
        step: MapRouteStepSpec,
        state: GameSessionState,
        progress: ProgressState,
        route_steps: tuple[MapRouteStepSpec, ...],
    ) -> str:
        completed_node_ids = set(progress.completed_node_ids)
        cleared_level_ids = set(progress.cleared_level_ids)
        demo_seen_group_ids = set(progress.demo_seen_group_ids)

        if self._is_route_step_current(step, state):
            return "current"
        if self._is_route_step_completed(step, completed_node_ids, cleared_level_ids):
            return "completed"
        if step.is_planned and not step.tracked_node_ids and not step.level_ids and step.node_id is None and step.challenge_id is None:
            return "planned"
        if self._is_route_step_available(step, route_steps, completed_node_ids, cleared_level_ids, demo_seen_group_ids):
            return "available"
        return "locked"

    def _is_route_step_current(self, step: MapRouteStepSpec, state: GameSessionState) -> bool:
        if step.node_id is not None and step.node_id == state.node_id:
            return True
        if step.challenge_id is not None and step.challenge_id == state.challenge_id:
            return True
        if step.scene_id is not None and step.scene_id == state.scene_id:
            return True
        if state.node_id is not None and state.node_id in step.tracked_node_ids:
            return True
        if state.current_level_id is not None and state.current_level_id in step.level_ids:
            return True
        return False

    def _is_route_step_completed(
        self,
        step: MapRouteStepSpec,
        completed_node_ids: set[str],
        cleared_level_ids: set[str],
    ) -> bool:
        if step.level_ids:
            return all(level_id in cleared_level_ids for level_id in step.level_ids)
        if step.node_id is not None:
            return step.node_id in completed_node_ids
        if step.tracked_node_ids:
            return all(node_id in completed_node_ids for node_id in step.tracked_node_ids)
        return False

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
            if not self._is_route_step_completed(previous_step, completed_node_ids, cleared_level_ids):
                return False
        return True

    @staticmethod
    def _route_step_status_label(status_key: str) -> str:
        if status_key == "current":
            return "Current"
        if status_key == "completed":
            return "Completed"
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
                if step.step_type == "map":
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
    def _entry_node_id_for_steps(route_steps: tuple[MapRouteStepSpec, ...]) -> str | None:
        for step in route_steps:
            if step.target_page == "map":
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
