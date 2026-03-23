from __future__ import annotations

from block2python.content import GroupMapRoutesSpec, MapRouteSpec, MapRouteStepSpec
from .session_models import GroupRuntimeState


class MapRouteLookupMixin:
    def _route_spec_for_current_quest(self) -> MapRouteSpec | None:
        quest_id = self.runtime.quest.quest_id
        for route in self.runtime.game_slice.map_routes.values():
            if route.quest_id == quest_id:
                return route
        return None

    def _route_group(self, group_id: str) -> GroupMapRoutesSpec | None:
        route_spec = self._route_spec_for_current_quest()
        if route_spec is None:
            return None
        for group in route_spec.groups:
            if group.group_id == group_id:
                return group
        return None

    def _group_id_for_state(self, state) -> str | None:
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

    def _group_practice_level_ids(self, group: GroupMapRoutesSpec) -> tuple[str, ...]:
        for step in group.practice_route:
            if step.level_ids:
                return step.level_ids
        return ()

    @staticmethod
    def _new_group_runtime_state(group_id: str) -> GroupRuntimeState:
        return GroupRuntimeState(group_id=group_id)
