from __future__ import annotations

from typing import TYPE_CHECKING

from block2python.content import ResolvedChallengeSpec
from block2python.contracts import LevelSpec

if TYPE_CHECKING:
    from .session_models import GameSessionState


class PracticeReviewMixin:
    def _enable_practice_review_if_completed(self, group_id: str) -> None:
        runtime_group = self.group_runtime_states.get(group_id)
        if runtime_group is not None and runtime_group.completed:
            runtime_group.practice_reviewing = True

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
        next_level_id = level_ids[current_index + 1]
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
