from __future__ import annotations

from typing import TYPE_CHECKING

from block2python.content import GroupMapRoutesSpec, MapRouteStepSpec
from block2python.integration.contracts import (
    GroupMapRouteState,
    GroupSlotState,
    MapRouteState,
    MapRouteStepState,
    ProgressState,
)

from .map_route_lookup import MapRouteLookupMixin
from .map_route_runtime_sync import MapRouteRuntimeSyncMixin
from .map_route_status_rules import MapRouteStatusRulesMixin

if TYPE_CHECKING:
    from .session_models import GameSessionState, GroupRuntimeState


class MapRouteProjectionMixin(MapRouteLookupMixin, MapRouteStatusRulesMixin, MapRouteRuntimeSyncMixin):
    def _map_route_state(self, state: GameSessionState, progress: ProgressState) -> MapRouteState | None:
        route_spec = self._route_spec_for_current_quest()
        if route_spec is None:
            return None

        groups = tuple(self._group_map_route_state(group, state, progress) for group in route_spec.groups)
        return MapRouteState(
            route_id=route_spec.route_id,
            quest_id=route_spec.quest_id,
            title=route_spec.title,
            groups=groups,
        )

    def _group_map_route_state(
        self,
        group: GroupMapRoutesSpec,
        state: GameSessionState,
        progress: ProgressState,
    ) -> GroupMapRouteState:
        demo_route = tuple(self._map_route_step_state(step, state, progress, group.demo_route, group.group_id) for step in group.demo_route)
        practice_route = tuple(self._map_route_step_state(step, state, progress, group.practice_route, group.group_id) for step in group.practice_route)
        runtime_group = self.group_runtime_states[group.group_id]
        status_key = self._group_display_state(runtime_group, state)
        return GroupMapRouteState(
            group_id=group.group_id,
            title=group.title,
            status_key=status_key,
            status_label=self._group_status_label(status_key, self._is_planned_only_group(demo_route + practice_route)),
            is_enterable=runtime_group.unlock_state != "locked",
            current_label=self._group_current_label(status_key, demo_route + practice_route),
            demo_slot=self._group_slot_state("demo", "Demo", demo_route, runtime_group),
            practice_slot=self._group_slot_state("practice", "Practice", practice_route, runtime_group),
            demo_route=demo_route,
            practice_route=practice_route,
        )

    def _map_route_step_state(
        self,
        step: MapRouteStepSpec,
        state: GameSessionState,
        progress: ProgressState,
        route_steps: tuple[MapRouteStepSpec, ...],
        group_id: str,
    ) -> MapRouteStepState:
        status_key = self._route_step_status_key(step, state, progress, route_steps, group_id)
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

    def _group_slot_state(
        self,
        slot_key: str,
        title: str,
        route_steps: tuple[MapRouteStepState, ...],
        runtime_group: GroupRuntimeState,
    ) -> GroupSlotState:
        slot_status_key = self._slot_status_key(slot_key, route_steps, runtime_group)
        return GroupSlotState(
            slot_key=slot_key,
            title=title,
            status_key=slot_status_key,
            status_label=self._group_status_label(slot_status_key, False),
            is_unlocked=self._is_demo_slot_unlocked(route_steps, runtime_group) if slot_key == "demo" else runtime_group.practice_unlocked,
            viewed=runtime_group.demo_seen if slot_key == "demo" else False,
            completed_count=runtime_group.practice_completed_count if slot_key == "practice" else 0,
            total_count=runtime_group.practice_total_count if slot_key == "practice" else 0,
            next_level_id=runtime_group.practice_current_level_id if slot_key == "practice" else None,
            entry_level_id=runtime_group.practice_current_level_id if slot_key == "practice" else None,
        )
