from __future__ import annotations

import ast

from dataclasses import dataclass, field

from .challenge_selection import ChallengeSelectionMixin
from .map_route_projection import MapRouteProjectionMixin
from .practice_review import PracticeReviewMixin
from .scene_progress_projection import SceneProgressProjectionMixin
from .session_models import (
    GameSessionError,
    GameSessionState,
    GroupRuntimeState,
    PracticeBatteryState,
    SessionMode,
)
from .session_state_resolution import SessionStateResolutionMixin
from .state_projection import build_game_state

from block2python.level_play import AppCore, SubmitOutcome
from block2python.content import AssembledGameSlice, GameRuntime
from block2python.contracts import AnalysisResult, AnalysisStatus, JudgeResult, JudgeStatus, Submission
from block2python.integration.contracts import (
    DemoState,
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
    active_practice_level_id_override: str | None = None
    next_enabled_level_id: str | None = None
    practice_battery_state: PracticeBatteryState | None = None

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
        self._reset_practice_action_state()
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

        target_node_id = self._entry_node_id_for_steps(group.demo_route, allowed_step_types={"demo"})
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
        self._ensure_group_demo_level_cleared(group_id)
        progress = self._progress_state()
        self._sync_group_runtime_states(progress, self.current_state())
        self._enable_practice_review_if_completed(group_id)
        target_node_id = self._entry_node_id_for_steps(group.practice_route)
        if target_node_id is None:
            raise GameSessionError(f"Group {group_id} has no practice entry node")

        self._jump_to_node(target_node_id)
        self._start_practice_battery_run(group_id)
        return self.current_state()

    def run_current_level(self, *, python_code: str, block_json: dict | None = None) -> tuple[GameSessionState, SubmitOutcome]:
        state = self.current_state()
        if state.mode is not SessionMode.CHALLENGE:
            raise GameSessionError("Current node is not a challenge")
        if state.current_level_id is None:
            raise GameSessionError("Challenge node has no current level")

        if self._is_placeholder_auto_ac_level(state.current_level_id):
            outcome = SubmitOutcome(
                analysis=AnalysisResult(status=AnalysisStatus.PASS, summary="Placeholder level dry-run"),
                judge=JudgeResult(status=JudgeStatus.AC, summary="Placeholder level dry-run"),
                cleared=False,
                block_passed=self.app.is_block_passed(state.current_level_id),
            )
        else:
            outcome = self.app.verify(
                Submission(level_id=state.current_level_id, python_code=python_code, block_json=block_json)
            )
        self.next_enabled_level_id = None
        self.last_submission = self._build_feedback(
            state.current_level_id,
            outcome,
            kind="run_result",
            status_label="Run Passed" if outcome.judge.status is JudgeStatus.AC else "Run Needs Work",
            output_prefix="Run output",
            from_toolbox=False,
            emitted_output=self._submission_emitted_output(python_code=python_code, block_json=block_json, from_toolbox=False),
        )
        return self.current_state(), outcome

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
        if outcome.cleared:
            self.active_practice_level_id_override = state.current_level_id
            self.next_enabled_level_id = state.current_level_id
            self._award_practice_battery_for_level(state.current_level_id)
        else:
            self.next_enabled_level_id = None
        self.last_submission = self._build_feedback(
            state.current_level_id,
            outcome,
            kind="submission",
            status_label="Passed" if outcome.cleared else "Needs Work",
            output_prefix="Submit output",
            from_toolbox=False,
            emitted_output=self._submission_emitted_output(python_code=python_code, block_json=block_json, from_toolbox=False),
        )
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
            raise GameSessionError("Toolbox run is only available in practice challenges")

        outcome = self.app.verify(
            Submission(level_id=state.current_level_id, python_code=python_code, block_json=block_json)
        )
        self.toolbox_used_level_ids.add(state.current_level_id)
        self.next_enabled_level_id = None
        self.last_submission = self._build_feedback(
            state.current_level_id,
            outcome,
            kind="toolbox_run",
            status_label="Toolbox Run Passed" if outcome.judge.status is JudgeStatus.AC else "Toolbox Run Needs Work",
            output_prefix="Tool Kit output",
            from_toolbox=True,
            emitted_output=self._submission_emitted_output(python_code=python_code, block_json=block_json, from_toolbox=True),
        )
        return self.current_state(), outcome

    def next_practice_level(self) -> GameSessionState:
        state = self.current_state()
        if state.mode is not SessionMode.CHALLENGE:
            raise GameSessionError("Current node is not a challenge")
        if state.current_level_id is None:
            raise GameSessionError("Challenge node has no current level")
        if self.next_enabled_level_id != state.current_level_id:
            raise GameSessionError("Next level is only available after a successful submit")

        runtime_state = self.runtime.current_state()
        if runtime_state is None or runtime_state.challenge is None:
            raise GameSessionError("Current node is not a challenge")
        group_id = self._group_id_for_level_id(state.current_level_id)
        runtime_group = self.group_runtime_states.get(group_id) if group_id is not None else None

        self.next_enabled_level_id = None
        self.last_submission = None

        if runtime_group is not None and runtime_group.practice_reviewing:
            self._advance_review_practice_level(state)
            return self.current_state()

        next_level_id = self._next_uncleared_level_id(runtime_state.challenge, state.current_level_id)
        self.active_practice_level_id_override = next_level_id
        if next_level_id is None:
            self._reset_practice_battery_run()
        return self.current_state()

    def _start_practice_battery_run(self, group_id: str) -> None:
        self.practice_battery_state = PracticeBatteryState(group_id=group_id)

    def _reset_practice_battery_run(self) -> None:
        self.practice_battery_state = None

    def current_practice_battery_percent(self, group_id: str | None) -> int:
        if group_id is None:
            return 0
        if self.practice_battery_state is None:
            return 0
        if self.practice_battery_state.group_id != group_id:
            return 0
        return self.practice_battery_state.battery_percent

    def current_toolbox_block_ids(self) -> tuple[str, ...]:
        return self._toolbox_block_ids_for_group(self.current_highest_toolbox_group_id())

    def current_highest_toolbox_group_id(self) -> str:
        route_spec = self._route_spec_for_current_quest()
        if route_spec is None or not route_spec.groups:
            return "group-01"

        current_group_id = self._current_mainline_group_id()
        if current_group_id is not None:
            return current_group_id

        highest_completed_group_id: str | None = None
        for group in route_spec.groups:
            runtime_group = self.group_runtime_states.get(group.group_id)
            if runtime_group is None:
                continue
            if runtime_group.completed or runtime_group.practice_reviewing:
                highest_completed_group_id = group.group_id
        if highest_completed_group_id is not None:
            return highest_completed_group_id

        return route_spec.groups[0].group_id

    def _toolbox_block_ids_for_group(self, group_id: str | None) -> tuple[str, ...]:
        resolved_group_id = group_id or "group-01"
        challenge = self._practice_challenge_for_group_id(resolved_group_id)
        if challenge is not None and challenge.toolbox_policy is not None:
            return challenge.toolbox_policy.unlocked_block_ids
        if resolved_group_id != "group-01":
            fallback_challenge = self._practice_challenge_for_group_id("group-01")
            if fallback_challenge is not None and fallback_challenge.toolbox_policy is not None:
                return fallback_challenge.toolbox_policy.unlocked_block_ids
        return ()

    def _practice_challenge_for_group_id(self, group_id: str):
        group = self._route_group(group_id)
        if group is None:
            return None
        for step in group.practice_route:
            if step.challenge_id is None:
                continue
            return self.runtime.game_slice.challenges.get(step.challenge_id)
        return None

    def _ensure_group_demo_level_cleared(self, group_id: str) -> None:
        group = self._route_group(group_id)
        if group is None:
            return
        for step in group.demo_route:
            if step.challenge_id is None:
                continue
            challenge = self.runtime.game_slice.challenges.get(step.challenge_id)
            if challenge is None or not challenge.levels:
                continue
            demo_level_id = challenge.levels[0].level_id
            if not self.app.is_cleared(demo_level_id):
                self.app.mark_cleared(demo_level_id)
            return

    def current_practice_toolbox_penalty_percent(self, group_id: str | None) -> int | None:
        if group_id is None:
            return None
        challenge = self._practice_challenge_for_group_id(group_id)
        if challenge is None or challenge.battery_policy is None:
            return None
        return challenge.battery_policy.toolbox_reward_percent

    def confirm_toolbox_open_for_current_level(self) -> None:
        state = self.current_state()
        if state.mode is not SessionMode.CHALLENGE:
            raise GameSessionError("Current node is not a challenge")
        if state.current_level_id is None:
            raise GameSessionError("Challenge node has no current level")

        runtime_state = self.runtime.current_state()
        if runtime_state is None or runtime_state.challenge is None:
            raise GameSessionError("Current node is not a challenge")
        if runtime_state.challenge.challenge_type != "practice":
            raise GameSessionError("Toolbox is only available in practice challenges")

        group_id = self._group_id_for_level_id(state.current_level_id)
        penalty_percent = self.current_practice_toolbox_penalty_percent(group_id)
        if penalty_percent is None:
            raise GameSessionError("Toolbox penalty is not configured for this level")

        self.mark_toolbox_opened_for_current_level()

    def mark_toolbox_opened_for_current_level(self) -> None:
        state = self.current_state()
        if state.mode is not SessionMode.CHALLENGE or state.current_level_id is None:
            return
        group_id = self._group_id_for_level_id(state.current_level_id)
        if group_id is None:
            return
        if self.practice_battery_state is None or self.practice_battery_state.group_id != group_id:
            self._start_practice_battery_run(group_id)
        assert self.practice_battery_state is not None
        self.practice_battery_state.toolbox_opened_level_ids.add(state.current_level_id)

    def was_toolbox_opened_for_level(self, level_id: str) -> bool:
        group_id = self._group_id_for_level_id(level_id)
        if group_id is None:
            return False
        if self.practice_battery_state is None or self.practice_battery_state.group_id != group_id:
            return False
        return level_id in self.practice_battery_state.toolbox_opened_level_ids

    def _award_practice_battery_for_level(self, level_id: str) -> None:
        group_id = self._group_id_for_level_id(level_id)
        if group_id is None:
            return
        if self.practice_battery_state is None or self.practice_battery_state.group_id != group_id:
            self._start_practice_battery_run(group_id)
        assert self.practice_battery_state is not None
        if level_id in self.practice_battery_state.awarded_level_ids:
            return
        reward_percent = 20
        if self.was_toolbox_opened_for_level(level_id):
            penalty_reward_percent = self.current_practice_toolbox_penalty_percent(group_id)
            if penalty_reward_percent is not None:
                reward_percent = penalty_reward_percent
        self.practice_battery_state.awarded_level_ids.add(level_id)
        self.practice_battery_state.battery_percent = min(100, self.practice_battery_state.battery_percent + reward_percent)

    def _next_uncleared_level_id(self, challenge, current_level_id: str) -> str | None:
        current_index = -1
        for index, level in enumerate(challenge.levels):
            if level.level_id == current_level_id:
                current_index = index
                break
        for level in challenge.levels[current_index + 1 :]:
            if self._should_auto_clear_on_enter(level):
                self.app.mark_cleared(level.level_id)
                continue
            if not self.app.is_cleared(level.level_id):
                return level.level_id
        return None

    def _build_feedback(
        self,
        level_id: str,
        outcome: SubmitOutcome,
        *,
        kind: str,
        status_label: str,
        output_prefix: str,
        from_toolbox: bool,
        emitted_output: bool,
    ) -> SubmissionFeedback:
        display_output = self._display_output_text(outcome, kind)
        return SubmissionFeedback(
            level_id=level_id,
            cleared=outcome.cleared,
            block_passed=outcome.block_passed,
            analysis_status=outcome.analysis.status.value,
            kind=kind,
            status_label=status_label,
            analysis_summary=outcome.analysis.summary,
            judge_status=outcome.judge.status.value,
            judge_summary=outcome.judge.summary,
            verification_only=False,
            answer_correct=outcome.judge.status is JudgeStatus.AC,
            output_text=display_output,
            details={
                "analysis_status": outcome.analysis.status.value,
                "judge_status": outcome.judge.status.value,
                "from_toolbox": from_toolbox,
                "output_prefix": output_prefix,
                "stdout": outcome.judge.stdout,
                "stderr": outcome.judge.stderr,
                "emitted_output": emitted_output,
            },
        )
    def _submission_emitted_output(self, *, python_code: str, block_json: dict | None, from_toolbox: bool) -> bool:
        if from_toolbox:
            if block_json is not None and self._toolbox_block_json_emits_output(block_json):
                return True
            return self._python_code_emits_output(python_code)
        return self._python_code_emits_output(python_code)

    def _python_code_emits_output(self, python_code: str) -> bool:
        if not python_code.strip():
            return False
        try:
            tree = ast.parse(python_code)
        except SyntaxError:
            return False

        for node in ast.walk(tree):
            if not isinstance(node, ast.Call):
                continue
            func = node.func
            if isinstance(func, ast.Name) and func.id == "print":
                return True
        return False

    def _toolbox_block_json_emits_output(self, block_json: dict | None) -> bool:
        if block_json is None:
            return False

        def _walk(value: object) -> bool:
            if isinstance(value, dict):
                block_type = value.get("type")
                if isinstance(block_type, str) and block_type in {"print_expr", "text_print"}:
                    return True
                for nested in value.values():
                    if _walk(nested):
                        return True
                return False
            if isinstance(value, list):
                for nested in value:
                    if _walk(nested):
                        return True
            return False

        return _walk(block_json)

    def _display_output_text(self, outcome: SubmitOutcome, kind: str) -> str:
        stdout_text = outcome.judge.stdout.strip()
        if stdout_text:
            return stdout_text

        stderr_text = outcome.judge.stderr.strip()
        if stderr_text:
            return stderr_text

        if outcome.analysis.status in {AnalysisStatus.SYNTAX_ERROR, AnalysisStatus.INTERNAL_ERROR}:
            return outcome.analysis.summary

        if kind in {"run_result", "toolbox_run"}:
            return ""

        return outcome.judge.summary or outcome.analysis.summary


    def _reset_practice_action_state(self) -> None:
        self.active_practice_level_id_override = None
        self.next_enabled_level_id = None

    def _require_opening_flow_completed(self) -> None:
        if not self.player_profile.profile_created:
            raise GameSessionError("player profile must be created before entering main flow")
        if not self.intro_completed:
            raise GameSessionError("opening intro must be completed before entering main flow")

    def _jump_to_node(self, node_id: str) -> None:
        state = self.current_state()
        if state.mode is SessionMode.CHALLENGE:
            self._reset_practice_battery_run()
        if node_id not in self.runtime.quest.node_ids:
            raise GameSessionError(f"Node {node_id} is not part of quest {self.runtime.quest.quest_id}")
        self.runtime.current_node_id = node_id
        self.last_submission = None
        self.scene_seen_node_ids.discard(node_id)
        self._reset_practice_action_state()
