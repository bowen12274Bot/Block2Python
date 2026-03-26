from __future__ import annotations

from block2python.content import ResolvedChallengeSpec
from block2python.contracts import LevelSpec


class ChallengeSelectionMixin:
    def _current_level_for_challenge(self, challenge: ResolvedChallengeSpec) -> LevelSpec | None:
        review_level = self._review_level_for_challenge(challenge)
        if review_level is not None:
            return review_level
        if challenge.challenge_type == "demo":
            return challenge.levels[0] if challenge.levels else None

        pinned_level = self._pinned_practice_level_for_challenge(challenge)
        if pinned_level is not None:
            return pinned_level

        for level in challenge.levels:
            if self.app.is_cleared(level.level_id):
                continue
            if self._should_auto_clear_on_enter(level):
                self.app.mark_cleared(level.level_id)
                continue
            return level
        return None

    def _pinned_practice_level_for_challenge(self, challenge: ResolvedChallengeSpec) -> LevelSpec | None:
        target_level_id = self.active_practice_level_id_override
        if target_level_id is None:
            return None
        for level in challenge.levels:
            if level.level_id == target_level_id:
                return level
        return None
