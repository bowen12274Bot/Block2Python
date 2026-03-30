# Bug Signal Scan

## Story

Bug King Castle is leaking anomaly signals.
You are given $n$ signal values. Each value can be positive, zero, or negative.

Your task is to compute the total signal sum.

## Input

- Line 1: one integer $n$.
- Line 2: $n$ integers $a_1, a_2, ..., a_n$.

## Output

- Print one integer: $a_1 + a_2 + ... + a_n$.

## Constraints

- $1 \le n \le 200000$
- $-10^9 \le a_i \le 10^9$

## Example

### Input

```text
5
4 -2 0 7 -3
```

### Output

```text
6
```

## Implementation Note

- Use 64-bit integer accumulation (`long long` / Python `int`).
