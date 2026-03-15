from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum

from block2python.challenge import AppCore, SubmitOutcome
from block2python.content import AssembledGameSlice, GameRuntime
from block2python.contracts import LevelSpec, Submission


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


@dataclass(slots=True)
class GameSession:
    app: AppCore
    runtime: GameRuntime
    scene_seen_node_ids: set[str] = field(default_factory=set)

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
            )

        return GameSessionState(
            mode=SessionMode.SCENE,
            quest_id=self.runtime.quest.quest_id,
            node_id=node.node_id,
            node_title=node.title,
            scene_id=runtime_state.scene.scene_id if runtime_state.scene else None,
        )

    def advance(self) -> GameSessionState:
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
        return self.current_state(), outcome

    def _current_level_for_challenge(self, challenge) -> LevelSpec | None:
        for level in challenge.levels:
            if not self.app.is_cleared(level.level_id):
                return level
        return None
