from __future__ import annotations

from block2python.content import ActorCue, NodeSpec, SceneSpec
from block2python.contracts import LevelSpec
from block2python.integration.contracts import ActorCueState, DialogueBlockState, ProgressState, SceneState


class SceneProgressProjectionMixin:
    def _opening_intro_scene(self) -> SceneState:
        scene = self.runtime.game_slice.scenes.get("opening-intro")
        if scene is None:
            raise self._session_error("opening intro scene is missing from game content")
        scene_state = self._scene_state(scene)
        if scene_state is None:
            raise self._session_error("opening intro scene could not be mapped into SceneState")
        return scene_state

    def _scene_state(self, scene: SceneSpec | None, node: NodeSpec | None = None) -> SceneState | None:
        if scene is None:
            return None
        mission_statement = self._mission_statement_scene(node)
        return SceneState(
            scene_id=scene.scene_id,
            title=scene.title,
            dialogue_blocks=tuple(
                DialogueBlockState(
                    speaker=block.speaker,
                    text=block.text,
                    portrait_id=block.portrait_id,
                    expression=block.expression,
                    background_id=block.background_id,
                    emphasis=block.emphasis,
                    speaker_side=block.speaker_side,
                    left_actor=self._actor_cue_state(block.left_actor),
                    center_actor=self._actor_cue_state(block.center_actor),
                    right_actor=self._actor_cue_state(block.right_actor),
                )
                for block in scene.dialogue_blocks
            ),
            mission_statement_scene_id=mission_statement.scene_id if mission_statement is not None else None,
            mission_statement_title=mission_statement.title if mission_statement is not None else "",
            mission_statement_text=self._mission_statement_text(mission_statement),
        )

    @staticmethod
    def _actor_cue_state(actor: ActorCue | None) -> ActorCueState | None:
        if actor is None:
            return None
        return ActorCueState(
            actor_id=actor.actor_id,
            display_name=actor.display_name,
            portrait_id=actor.portrait_id,
            expression_id=actor.expression_id,
            pose_id=actor.pose_id,
            visual_state=actor.visual_state,
            image_path=actor.image_path,
        )

    def _mission_statement_scene(self, node: NodeSpec | None) -> SceneSpec | None:
        if node is None or node.mission_statement_scene_id is None:
            return None
        return self.runtime.game_slice.scenes.get(node.mission_statement_scene_id)

    @staticmethod
    def _mission_statement_text(scene: SceneSpec | None) -> str:
        if scene is None:
            return ""
        lines = [block.text.strip() for block in scene.dialogue_blocks if block.text.strip() != ""]
        return "\n\n".join(lines)

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