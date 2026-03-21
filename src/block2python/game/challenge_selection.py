from __future__ import annotations

from block2python.content import ResolvedChallengeSpec
from block2python.contracts import LevelSpec


class ChallengeSelectionMixin:
    def _current_level_for_challenge(self, challenge: ResolvedChallengeSpec) -> LevelSpec | None:
        review_level = self._review_level_for_challenge(challenge)
        if review_level is not None:
            return review_level
        for level in challenge.levels:
            if self.app.is_cleared(level.level_id):
                continue
            if self._should_auto_clear_on_enter(level):
                self.app.mark_cleared(level.level_id)
                continue
            return level
        return None
