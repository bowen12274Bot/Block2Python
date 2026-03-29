# Level Authoring Workspace

This directory stores per-problem generation scripts and testlib workspaces.

Recommended layout:

- tools/level/<problem_name>/
  - statement.md
  - README.md
  - solutions/
  - testlib/
  - tests/

For Block2Python runtime compatibility, each authored problem should also have:

- assets/levels/<level_id>.yaml
- assets/levels/cases/<level_id>/*.in and *.out

Use scaffold command:

```powershell
python .agent/skills/cf-testlib-problem-generation/scripts/scaffold_problem.py <problem_name>
```

Example:

```powershell
python .agent/skills/cf-testlib-problem-generation/scripts/scaffold_problem.py sum-array --level-id practice-sum-array --title "Practice: Sum Array"
```
