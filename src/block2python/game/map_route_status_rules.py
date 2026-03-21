from __future__ import annotations

from typing import TYPE_CHECKING

from block2python.content import GroupMapRoutesSpec, MapRouteStepSpec
from block2python.integration.contracts import MapRouteStepState, ProgressState

if TYPE_CHECKING:
    from .session_models import GameSessionState, GroupRuntimeState


class MapRouteStatusRulesMixin:
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
        return MapRouteStatusRulesMixin._route_step_status_label(status_key)

    @staticmethod
    def _first_uncleared_level_id_from_list(level_ids: tuple[str, ...], cleared_level_ids: set[str]) -> str | None:
        for level_id in level_ids:
            if level_id not in cleared_level_ids:
                return level_id
        return None

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
        if (
            step.is_planned
            and not step.tracked_node_ids
            and not step.level_ids
            and step.node_id is None
            and step.challenge_id is None
        ):
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
            if (
                previous_step.is_planned
                and not previous_step.level_ids
                and not previous_step.tracked_node_ids
                and previous_step.node_id is None
            ):
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
