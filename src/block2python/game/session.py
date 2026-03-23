from __future__ import annotations

from dataclasses import dataclass, field

from .challenge_selection import ChallengeSelectionMixin
from .map_route_projection import MapRouteProjectionMixin
from .practice_review import PracticeReviewMixin
from .scene_progress_projection import SceneProgressProjectionMixin
from .session_models import GameSessionError, GameSessionState, GroupRuntimeState, SessionMode
from .session_state_resolution import SessionStateResolutionMixin
from .state_projection import build_game_state

from block2python.level_play import AppCore, SubmitOutcome
from block2python.content import AssembledGameSlice, GameRuntime
from block2python.contracts import AnalysisResult, AnalysisStatus, JudgeResult, JudgeStatus, Submission
from block2python.integration.contracts import (
    AvailableActions,
    ChallengeState,
    DemoState,
    GameMode,
    GameState,
    PlayerProfileState,
    SubmissionFeedback,
)


@dataclass(slots=True)
class GameSession(MapRouteProjectionMixin, PracticeReviewMixin, SceneProgressProjectionMixin, ChallengeSelectionMixin, SessionStateResolutionMixin):
    app: AppCore
    runtime: GameRuntime
    scene_seen_node_ids: set[str] = field(default_factory=set)
    demo_seen_group_ids: set[str] = field(default_factory=set)
    toolbox_used_level_ids: set[str] = field(default_factory=set)
    group_runtime_states: dict[str, GroupRuntimeState] = field(default_factory=dict)
    last_submission: SubmissionFeedback | None = None
    player_profile: PlayerProfileState = field(default_factory=PlayerProfileState)
    intro_completed: bool = False

    @classmethod
    def start(cls, *, app: AppCore, game_slice: AssembledGameSlice, quest_id: str) -> GameSession:
        return cls(app=app, runtime=GameRuntime.start(game_slice, quest_id=quest_id))

    def current_game_state(self) -> GameState:
        return build_game_state(self)

    @staticmethod
    def _session_mode_scene() -> SessionMode:
        return SessionMode.SCENE

    @staticmethod
    def _session_mode_demo() -> SessionMode:
        return SessionMode.DEMO

    @staticmethod
    def _session_mode_complete() -> SessionMode:
        return SessionMode.COMPLETE

    @staticmethod
    def _session_mode_challenge() -> SessionMode:
        return SessionMode.CHALLENGE

    @staticmethod
    def _session_state(*, mode: SessionMode, quest_id: str, node_id: str | None = None, node_title: str = "", scene_id: str | None = None, demo_id: str | None = None, challenge_id: str | None = None, current_level_id: str | None = None, current_level_title: str | None = None, current_level_prompt: str | None = None) -> GameSessionState:
        return GameSessionState(
            mode=mode,
            quest_id=quest_id,
            node_id=node_id,
            node_title=node_title,
            scene_id=scene_id,
            demo_id=demo_id,
            challenge_id=challenge_id,
            current_level_id=current_level_id,
            current_level_title=current_level_title,
            current_level_prompt=current_level_prompt,
        )

    @staticmethod
    def _session_error(message: str) -> GameSessionError:
        return GameSessionError(message)

    def create_player_profile(self, *, name: str, gender: str) -> GameState:
        normalized_name = name.strip()
        if not normalized_name:
            raise GameSessionError("player name is required")

        normalized_gender = gender.strip().lower()
        if normalized_gender not in {"male", "female"}:
            raise GameSessionError("player gender must be male or female")

        self.player_profile = PlayerProfileState(
            name=normalized_name,
            gender=normalized_gender,
            profile_created=True,
        )
        self.intro_completed = False
        self.last_submission = None
        return self.current_game_state()

    def complete_intro(self) -> GameState:
        if not self.player_profile.profile_created:
            raise GameSessionError("player profile must be created before intro")
        self.intro_completed = True
        self.last_submission = None
        return self.current_game_state()

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

        if state.mode is SessionMode.DEMO and state.current_level_id is not None:
            self.app.mark_cleared(state.current_level_id)

        self.runtime.complete_current_node()
        return self.current_state()

    def start_group_demo(self, group_id: str) -> GameSessionState:
        self._require_opening_flow_completed()
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
        self._require_opening_flow_completed()
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
        self._require_opening_flow_completed()
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
        self._enable_practice_review_if_completed(group_id)
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

    def _require_opening_flow_completed(self) -> None:
        if not self.player_profile.profile_created:
            raise GameSessionError("player profile must be created before entering main flow")
        if not self.intro_completed:
            raise GameSessionError("opening intro must be completed before entering main flow")

    def _jump_to_node(self, node_id: str) -> None:
        if node_id not in self.runtime.quest.node_ids:
            raise GameSessionError(f"Node {node_id} is not part of quest {self.runtime.quest.quest_id}")
        self.runtime.current_node_id = node_id
        self.last_submission = None
        self.scene_seen_node_ids.discard(node_id)


