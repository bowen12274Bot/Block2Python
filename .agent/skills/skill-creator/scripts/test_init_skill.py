#!/usr/bin/env python3
"""Regression tests for project-specific skill initialization."""

import shutil
import tempfile
from pathlib import Path
from unittest import TestCase, main

import init_skill as init_skill_module


class TestInitSkill(TestCase):
    def setUp(self):
        self.temp_dir = Path(tempfile.mkdtemp(prefix="test_init_skill_"))
        self.project_root = self.temp_dir / "repo"
        self.project_root.mkdir()
        self.project_skills_dir = self.project_root / ".agent" / "skills"
        self.project_skills_dir.mkdir(parents=True)
        for root_name in (".agents", ".claude", ".codex"):
            (self.project_root / root_name / "skills").mkdir(parents=True)

        self.original_project_root = init_skill_module.PROJECT_ROOT
        self.original_project_skills_dir = init_skill_module.PROJECT_SKILLS_DIR
        init_skill_module.PROJECT_ROOT = self.project_root
        init_skill_module.PROJECT_SKILLS_DIR = self.project_skills_dir

    def tearDown(self):
        init_skill_module.PROJECT_ROOT = self.original_project_root
        init_skill_module.PROJECT_SKILLS_DIR = self.original_project_skills_dir
        shutil.rmtree(self.temp_dir)

    def test_default_init_creates_only_canonical_skill(self):
        skill_dir = init_skill_module.init_skill("demo-skill")

        self.assertEqual(skill_dir, self.project_skills_dir / "demo-skill")
        self.assertTrue((skill_dir / "SKILL.md").exists())
        self.assertIn("## 範圍", (skill_dir / "SKILL.md").read_text(encoding="utf-8"))
        for root_name in (".agents", ".claude", ".codex"):
            adapter_dir = self.project_root / root_name / "skills" / "demo-skill"
            self.assertFalse(adapter_dir.exists())

    def test_custom_path_creates_skill_under_requested_root(self):
        custom_root = self.project_root / "tmp-skills"
        custom_root.mkdir(parents=True)

        skill_dir = init_skill_module.init_skill(
            "custom-skill",
            path=custom_root,
        )

        self.assertEqual(skill_dir, custom_root / "custom-skill")
        self.assertTrue((skill_dir / "SKILL.md").exists())
        for root_name in (".agents", ".claude", ".codex"):
            adapter_dir = self.project_root / root_name / "skills" / "custom-skill"
            self.assertFalse(adapter_dir.exists())


if __name__ == "__main__":
    main()
