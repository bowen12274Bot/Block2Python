# group-01-input-gate

This workspace is generated for CF-style authoring and Block2Python integration.

## Paths

- Scripts and references: tools/level/group-01-input-gate
- Level definition: assets/levels/group-01-practice-01.yaml
- Level cases: assets/levels/cases/group-01-practice-01

## Next Steps

1. Update statement.md with the final problem statement.
2. Implement testlib files under testlib/.
3. Generate `.in/.out` files into assets/levels/cases/group-01-practice-01/.
4. Replace placeholder sample cases and tune judge_policy in assets/levels/group-01-practice-01.yaml.

## Strict Validation

Run strict testlib-style validation (generator + validator + solution-vs-brute + checker):

```powershell
powershell -ExecutionPolicy Bypass -File tools/level/group-01-input-gate/scripts/verify_testlib.ps1 -CaseCount 80
```
