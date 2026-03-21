from __future__ import annotations

from typing import TYPE_CHECKING

from block2python.content import MapRouteSpec
from block2python.integration.contracts import ProgressState

if TYPE_CHECKING:
    from .session_models import GameSessionState


class MapRouteRuntimeSyncMixin:
    def _ensure_group_runtime_states(self, route_spec: MapRouteSpec) -> None:
        for index, group in enumerate(route_spec.groups):
            runtime_group = self.group_runtime_states.get(group.group_id)
            if runtime_group is None:
                runtime_group = self._new_group_runtime_state(group.group_id)
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
            review_target = runtime_group.practice_current_level_id
            if runtime_group.practice_reviewing and state.current_level_id is not None and state.current_level_id in level_ids:
                review_target = state.current_level_id
            if runtime_group.practice_reviewing:
                if review_target in level_ids:
                    runtime_group.practice_current_level_id = review_target
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
