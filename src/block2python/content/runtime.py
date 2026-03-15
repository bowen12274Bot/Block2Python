from __future__ import annotations

from dataclasses import dataclass, field

from .errors import GameContentError
from .models import AssembledGameSlice, NodeSpec, QuestSpec, ResolvedChallengeSpec, SceneSpec


class GameRuntimeError(GameContentError):
    """Raised when game runtime navigation is invalid."""


@dataclass(frozen=True, slots=True)
class GameNodeState:
    node: NodeSpec
    scene: SceneSpec | None = None
    challenge: ResolvedChallengeSpec | None = None
    is_completed: bool = False
    available_next_node_ids: tuple[str, ...] = ()


@dataclass(slots=True)
class GameRuntime:
    game_slice: AssembledGameSlice
    quest: QuestSpec
    current_node_id: str | None
    completed_node_ids: set[str] = field(default_factory=set)

    @classmethod
    def start(cls, game_slice: AssembledGameSlice, *, quest_id: str) -> GameRuntime:
        quest = game_slice.quests.get(quest_id)
        if quest is None:
            raise GameRuntimeError(f"Unknown quest_id: {quest_id}")

        entry_node_id = quest.entry_node_id or (quest.node_ids[0] if quest.node_ids else None)
        if entry_node_id is None:
            raise GameRuntimeError(f"Quest {quest_id} has no entry node")
        if entry_node_id not in game_slice.nodes:
            raise GameRuntimeError(f"Quest {quest_id} entry node missing from game slice: {entry_node_id}")

        return cls(game_slice=game_slice, quest=quest, current_node_id=entry_node_id)

    def current_state(self) -> GameNodeState | None:
        if self.current_node_id is None:
            return None

        node = self._get_node(self.current_node_id)
        scene = self.game_slice.scenes.get(node.scene_id) if node.scene_id else None
        challenge = self.game_slice.challenges.get(node.challenge_group_id) if node.challenge_group_id else None
        return GameNodeState(
            node=node,
            scene=scene,
            challenge=challenge,
            is_completed=node.node_id in self.completed_node_ids,
            available_next_node_ids=self._available_next_node_ids(node),
        )

    def complete_current_node(self, *, next_node_id: str | None = None) -> str | None:
        state = self.current_state()
        if state is None:
            raise GameRuntimeError("Game runtime is already complete")

        self.completed_node_ids.add(state.node.node_id)
        available_next = state.available_next_node_ids

        if not available_next:
            self.current_node_id = None
            return None

        if next_node_id is None:
            if len(available_next) != 1:
                raise GameRuntimeError(
                    f"Node {state.node.node_id} has multiple next nodes; next_node_id is required"
                )
            self.current_node_id = available_next[0]
            return self.current_node_id

        if next_node_id not in available_next:
            raise GameRuntimeError(
                f"Node {state.node.node_id} cannot advance to {next_node_id}; "
                f"available={list(available_next)}"
            )
        self.current_node_id = next_node_id
        return self.current_node_id

    def is_complete(self) -> bool:
        return self.current_node_id is None

    def _available_next_node_ids(self, node: NodeSpec) -> tuple[str, ...]:
        available: list[str] = []
        completed_after_current = set(self.completed_node_ids)
        completed_after_current.add(node.node_id)
        for next_node_id in node.next_node_ids:
            if next_node_id not in self.quest.node_ids:
                continue
            next_node = self._get_node(next_node_id)
            if all(prereq in completed_after_current for prereq in next_node.prerequisite_node_ids):
                available.append(next_node_id)
        return tuple(available)

    def _get_node(self, node_id: str) -> NodeSpec:
        node = self.game_slice.nodes.get(node_id)
        if node is None:
            raise GameRuntimeError(f"Unknown node_id: {node_id}")
        return node
