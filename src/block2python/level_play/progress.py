from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Protocol


class ProgressStore(Protocol):
    def is_cleared(self, level_id: str) -> bool: ...

    def mark_cleared(self, level_id: str) -> None: ...

    def is_block_passed(self, level_id: str) -> bool: ...

    def mark_block_passed(self, level_id: str) -> None: ...


@dataclass(slots=True)
class InMemoryProgress(ProgressStore):
    cleared_level_ids: set[str]
    block_passed_level_ids: set[str]

    @classmethod
    def empty(cls) -> InMemoryProgress:
        return cls(cleared_level_ids=set(), block_passed_level_ids=set())

    def is_cleared(self, level_id: str) -> bool:
        return level_id in self.cleared_level_ids

    def mark_cleared(self, level_id: str) -> None:
        self.cleared_level_ids.add(level_id)

    def is_block_passed(self, level_id: str) -> bool:
        return level_id in self.block_passed_level_ids

    def mark_block_passed(self, level_id: str) -> None:
        self.block_passed_level_ids.add(level_id)


class JsonFileProgress(ProgressStore):
    def __init__(self, path: Path) -> None:
        self._path = path
        self._state = InMemoryProgress.empty()
        self._load_if_exists()

    def is_cleared(self, level_id: str) -> bool:
        return self._state.is_cleared(level_id)

    def mark_cleared(self, level_id: str) -> None:
        self._state.mark_cleared(level_id)
        self._save()

    def is_block_passed(self, level_id: str) -> bool:
        return self._state.is_block_passed(level_id)

    def mark_block_passed(self, level_id: str) -> None:
        self._state.mark_block_passed(level_id)
        self._save()

    def _load_if_exists(self) -> None:
        if not self._path.exists():
            return
        raw = json.loads(self._path.read_text(encoding="utf-8"))
        if not isinstance(raw, dict):
            return
        cleared = raw.get("cleared_level_ids", [])
        if isinstance(cleared, list):
            self._state.cleared_level_ids = {str(x) for x in cleared}
        block_passed = raw.get("block_passed_level_ids", [])
        if isinstance(block_passed, list):
            self._state.block_passed_level_ids = {str(x) for x in block_passed}

    def _save(self) -> None:
        self._path.parent.mkdir(parents=True, exist_ok=True)
        tmp = self._path.with_suffix(self._path.suffix + ".tmp")
        payload = {
            "schema_version": "0.2",
            "cleared_level_ids": sorted(self._state.cleared_level_ids),
            "block_passed_level_ids": sorted(self._state.block_passed_level_ids),
        }
        tmp.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        tmp.replace(self._path)
