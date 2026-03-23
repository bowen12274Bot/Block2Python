from __future__ import annotations


class SessionStateResolutionMixin:
    def current_state(self):
        self._sync_demo_seen_from_runtime()
        runtime_state = self.runtime.current_state()
        if runtime_state is None:
            return self._session_state(
                mode=self._session_mode_complete(),
                quest_id=self.runtime.quest.quest_id,
            )

        node = runtime_state.node
        scene_id = runtime_state.scene.scene_id if runtime_state.scene else None
        challenge_id = runtime_state.challenge.challenge_id if runtime_state.challenge else None
        if runtime_state.scene is not None and node.node_id not in self.scene_seen_node_ids:
            return self._session_state(
                mode=self._session_mode_scene(),
                quest_id=self.runtime.quest.quest_id,
                node_id=node.node_id,
                node_title=node.title,
                scene_id=scene_id,
                challenge_id=challenge_id,
            )

        if runtime_state.challenge is not None:
            current_level = self._current_level_for_challenge(runtime_state.challenge)
            if current_level is None:
                self.runtime.complete_current_node()
                return self.current_state()
            if runtime_state.challenge.challenge_type == "demo":
                return self._session_state(
                    mode=self._session_mode_demo(),
                    quest_id=self.runtime.quest.quest_id,
                    node_id=node.node_id,
                    node_title=node.title,
                    scene_id=scene_id,
                    demo_id=runtime_state.challenge.challenge_id,
                    current_level_id=current_level.level_id,
                    current_level_title=current_level.title,
                    current_level_prompt=current_level.prompt,
                )
            return self._session_state(
                mode=self._session_mode_challenge(),
                quest_id=self.runtime.quest.quest_id,
                node_id=node.node_id,
                node_title=node.title,
                scene_id=scene_id,
                challenge_id=runtime_state.challenge.challenge_id,
                current_level_id=current_level.level_id,
                current_level_title=current_level.title,
                current_level_prompt=current_level.prompt,
            )

        return self._session_state(
            mode=self._session_mode_scene(),
            quest_id=self.runtime.quest.quest_id,
            node_id=node.node_id,
            node_title=node.title,
            scene_id=scene_id,
        )
