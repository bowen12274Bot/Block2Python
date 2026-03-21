from __future__ import annotations

from block2python.content import SceneSpec
from block2python.contracts import LevelSpec
from block2python.integration.contracts import DialogueBlockState, ProgressState, SceneState


class SceneProgressProjectionMixin:
    def _opening_intro_scene(self) -> SceneState:
        scene = self.runtime.game_slice.scenes.get("opening-intro")
        if scene is None:
            raise self._session_error("opening intro scene is missing from game content")
        scene_state = self._scene_state(scene)
        if scene_state is None:
            raise self._session_error("opening intro scene could not be mapped into SceneState")
        return scene_state

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
            level_id
            for level_id in self.runtime.game_slice.levels
            if self.app.is_cleared(level_id) and not self._is_demo_level_id(level_id)
        )
        return ProgressState(
            completed_node_ids=completed_node_ids,
            cleared_level_ids=cleared_level_ids,
            demo_seen_group_ids=tuple(sorted(self.demo_seen_group_ids)),
            toolbox_used_level_ids=tuple(sorted(self.toolbox_used_level_ids)),
        )

    def _is_demo_level_id(self, level_id: str) -> bool:
        level = self.runtime.game_slice.levels.get(level_id)
        if level is None:
            return False
        return str(level.metadata.get("slot", "")) == "demo"

    def _is_placeholder_auto_ac_level(self, level_id: str) -> bool:
        level = self.runtime.game_slice.levels.get(level_id)
        if level is None:
            return False
        return bool(level.metadata.get("placeholder_auto_ac", False))

    @staticmethod
    def _should_auto_clear_on_enter(level: LevelSpec) -> bool:
        return bool(level.metadata.get("auto_clear_on_enter", False))
