from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum

from block2python.challenge import AppCore, SubmitOutcome
from block2python.content import AssembledGameSlice, GameRuntime, ResolvedChallengeSpec, SceneSpec
from block2python.contracts import LevelSpec, Submission
from block2python.integration.contracts import (
    AvailableActions,
    ChallengeState,
    DialogueBlockState,
    GameMode,
    GameState,
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
    last_submission: SubmissionFeedback | None = None

    @classmethod
    def start(cls, *, app: AppCore, game_slice: AssembledGameSlice, quest_id: str) -> GameSession:
        return cls(app=app, runtime=GameRuntime.start(game_slice, quest_id=quest_id))

    def current_state(self) -> GameSessionState:
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

        if state.mode is SessionMode.COMPLETE or runtime_state is None:
            return GameState(
                mode=GameMode.COMPLETE,
                quest_id=self.runtime.quest.quest_id,
                progress=self._progress_state(),
                available_actions=AvailableActions(),
                last_submission=self.last_submission,
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
            progress=self._progress_state(),
            available_actions=actions,
            last_submission=self.last_submission,
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

    def submit_current_level(self, *, python_code: str, block_json: dict | None = None) -> tuple[GameSessionState, SubmitOutcome]:
        state = self.current_state()
        if state.mode is not SessionMode.CHALLENGE:
            raise GameSessionError("Current node is not a challenge")
        if state.current_level_id is None:
            raise GameSessionError("Challenge node has no current level")

        self.app.mark_block_passed(state.current_level_id)
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
            if not self.app.is_cleared(level.level_id):
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
        )