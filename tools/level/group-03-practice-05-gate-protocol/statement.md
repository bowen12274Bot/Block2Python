# If Canyon: Gate Protocol

## Statement

Read three integers on separate lines:

- `hp` (0..100)
- `key` (0 or 1)
- `alarm` (0 or 1)

Decision rules:

- If `key == 1` and `alarm == 0`, print `OPEN`
- Else if `hp >= 80` and `alarm == 0`, print `OVERRIDE`
- Else print `LOCKDOWN`