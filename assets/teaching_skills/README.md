# Teaching Skills

This directory stores runtime teaching skills for the in-game tutor.

## File layout

- One JSON file per skill: `assets/teaching_skills/<skill-id>.json`
- Optional index file is supported but not required.

## Required fields

Each skill file should include at least:

- `skill_id`
- `title`
- `hint_ladder`

The current loader also supports:

- `version`
- `description`
- `applies_to.level_ids`
- `applies_to.concepts`
- `student_level`
- `learning_goals`
- `allowed_concepts`
- `forbidden_concepts`
- `common_mistakes`
- `refusal_rules`
- `answer_style`

## Notes

- Keep tutor content data-driven in these JSON files.
- Avoid mixing development-only prompts or agent workflow notes here.
