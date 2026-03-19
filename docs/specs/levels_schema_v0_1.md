# 關卡檔 Schema 規格（v0.1）

- 文件版本：0.1
- 更新日期：2026-03-11
- 適用範圍：目前 `assets/levels/` 的 prototype 題庫
- Source of truth：`src/block2python/app/levels_loader.py`

## 1. 目前採用的檔案格式

目前專案將 `assets/levels/` 統一為 YAML 題庫：

- `assets/levels/index.yaml`：關卡索引
- `assets/levels/<level>.yaml`：單一關卡定義
- `assets/levels/cases/**`：`.in/.out` 測資檔

`levels_loader` 仍保留對 `.json` 的相容讀取能力，主要用於測試或過渡資料；但目前 repo 內的正式題庫來源以 YAML 為主。

## 2. 索引檔規格

檔案：`assets/levels/index.yaml`

### 2.1 必填欄位

- `levels`：陣列
  - 每個元素為 object
  - `id`：關卡 id
  - `file`：相對於 `assets/levels/` 的檔名

### 2.2 範例

```yaml
levels:
  - id: group-01-demo
    file: group-01-demo.yaml
  - id: group-01-practice-01
    file: group-01-practice-01.yaml
  - id: judge-precision-sum-series
    file: judge-precision-sum-series.yaml
```

### 2.3 Loader 行為

- 先從 `BLOCK2PYTHON_LEVELS_DIR` 指向的目錄讀取
- 若未設定，預設讀取 `assets/levels/`
- 索引檔搜尋順序為 `index.json` → `index.yaml` → `index.yml`
- 目前 repo 已只保留 `index.yaml`

## 3. 關卡檔規格

檔案：`assets/levels/<level>.yaml`

### 3.1 必填欄位

- `level_id`：string
- `title`：string

### 3.2 常用欄位

- `chapter_id`：string
- `quest_id`：string
- `order_index`：int
- `prompt`：string
- `learning_markdown`：string
- `story_intro_markdown`：string
- `story_outro_markdown`：string
- `prerequisite_level_ids`：array[string]
- `next_level_ids`：array[string]
- `block_schema_version`：string
- `metadata`：object

### 3.3 Judge 與 testcase 欄位

- `testcases`：明確列出測資
- `testcase_dir`：用資料夾自動掃描 `.in/.out`
- `testcase_glob`：自動掃描時的 pattern，預設 `*.in`
- `judge_policy.time_limit_ms`
- `judge_policy.memory_limit_kb`
- `judge_policy.memory_limit_mb`
- `judge_policy.output_normalization.*`

### 3.4 testcase 支援的三種形式

#### 形式 A：inline testcase

```yaml
testcases:
  - name: basic
    stdin: |
      1 2
    expected_stdout: |
      3
```

#### 形式 B：檔案引用

```yaml
testcases:
  - name: case-01
    stdin_file: cases/fizzbuzz/01.in
    expected_stdout_file: cases/fizzbuzz/01.out
```

#### 形式 C：資料夾自動掃描

```yaml
testcase_dir: cases/judge-precision-sum-series
testcase_glob: "*.in"
```

Loader 會將 `01.in` 對應到 `01.out`。

## 4. Judge policy 規格

### 4.1 範例

```yaml
judge_policy:
  time_limit_ms: 1000
  memory_limit_mb: 64
  output_normalization:
    strip_trailing_whitespace: true
    normalize_newlines_to_lf: true
    strip_trailing_newline: true
```

### 4.2 欄位說明

- `time_limit_ms`：整數，至少為 1
- `memory_limit_kb`：整數，可選
- `memory_limit_mb`：整數，可選；loader 會轉為 `memory_limit_kb`
- `output_normalization.strip_trailing_whitespace`
- `output_normalization.normalize_newlines_to_lf`
- `output_normalization.strip_trailing_newline`

## 5. Analysis metadata hook

`metadata.analysis` 目前可驅動 AST 分析規則：

```yaml
metadata:
  analysis:
    required_keywords:
      - input
    forbidden_keywords:
      - import
```

支援欄位：

- `metadata.analysis.required_keywords`
- `metadata.analysis.forbidden_keywords`

## 6. Prototype / dev-only metadata

目前 prototype flow 仍保留 stub 路徑，因此 `metadata` 中可出現下列 dev-only 欄位：

- `metadata.stage`
- `metadata.track`
- `metadata.stub_judge`
- `metadata.stub_analysis`
- `metadata.block_schema_version_note`

其中：

- `metadata.stub_judge.status`：`AC` / `WA` / `TLE` / `RE`
- `metadata.stub_judge.summary`：顯示於 StubJudge 回饋
- `metadata.stub_analysis.status`：`PASS` / `FAIL` / `SYNTAX_ERROR`
- `metadata.stub_analysis.summary`

這些欄位屬於 demo / prototype 過渡用途，不應視為未來正式課程資料格式的穩定契約。

## 7. 範例

### 7.1 `group-01-demo.yaml`

```yaml
level_id: group-01-demo
title: 兩數相加（Stub）
prompt: 讀入兩個整數並輸出相加結果。
next_level_ids:
  - group-01-practice-01
testcases:
  - name: basic
    stdin: |
      1 2
    expected_stdout: |
      3
metadata:
  stage: prototype
  track: demo-flow
  stub_judge:
    status: AC
    summary: "StubJudge: forced AC for group-01-demo."
```

### 7.2 `judge-precision-sum-series.yaml`

```yaml
level_id: judge-precision-sum-series
title: 兩數相加（YAML 題庫）
prerequisite_level_ids:
  - group-01-demo
next_level_ids:
  - group-01-practice-01
testcase_dir: cases/judge-precision-sum-series
judge_policy:
  time_limit_ms: 1000
  memory_limit_mb: 64
metadata:
  stage: prototype
  track: yaml-judge
```

## 8. 相關文件

- `docs/QUICKSTART.md`
- `docs/contributing/environment_setup.md`
- `tests/test_levels_loader.py`
