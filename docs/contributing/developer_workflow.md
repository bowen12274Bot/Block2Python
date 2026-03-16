# 開發工作流程

<<<<<<< HEAD
- 文件版本：0.2.1
=======
- 文件版本：0.2.0
>>>>>>> merge/judge_introduction_branch
- 更新日期：2026-03-11

本文件整理 Git 工作流程、commit / PR 準則、驗證方式，以及 Definition of Done。

## 1. 分支原則

- 預設開發分支：`main`
- 不直接在 `main` 上做正式修改
- `docs/`、`.agent/skills/`、`assets/levels/` 的變更也應走分支與 PR

建議命名：

- `feature/<topic>`
- `fix/<topic>`
- `refactor/<topic>`
- `docs/<topic>`
- `chore/<topic>`

## 2. 基本流程

```text
從 main 建立分支 -> 在分支上修改 -> 自行驗證 -> 整理 commit -> 開 PR -> 合併回 main
```

原則：

- 一個 PR 盡量只處理一個主題
- 若變更跨模組，PR 描述需清楚說明範圍
- 合併前至少附上一組可重現的驗證結果

## 3. Commit 規則

建議採用 Conventional Commits：

```text
<type>(<scope>): <summary>
```

<<<<<<< HEAD
但目前 repo 的實務寫法更常見的是較簡化的：

```text
<type>: <繁體中文描述>
```

原則如下：

- `scope` 視需要才使用，不強制
- 若最近歷史沒有一致使用 `scope`，優先沿用簡化格式
- commit subject 優先用簡短的繁體中文描述
- 若同一批變更同時包含功能與文件，通常仍以主要變更類型為準

常用 `type`：

- `feat`
- `fix`
- `refactor`
- `docs`
- `test`
- `chore`

例子：

```text
feat: 新增 GameSession 終端 demo 入口
feat: 新增遊戲內容 loader 與 runtime 骨架
docs: 新增遊戲內容 loader 計畫
feat(levels): add yaml-backed prototype levels
fix(judge): handle wasm runner timeout correctly
refactor(app): unify runtime composition
docs(contributing): align pytest workflow
```

## 4. PR 原則

PR 描述至少應包含：

- 做了什麼
- 為什麼這樣做
- 影響範圍
- 如何驗證

若有尚未處理的限制，也應明寫。

## 5. 驗證原則

目前專案以 `pytest` 為主要驗證入口，smoke scripts 為輔助驗證。

### 5.1 驗證層級

- 小範圍修改：跑最相關的 `pytest` 測試檔或單一測試
- 一般修改：至少跑一次 `.\.venv\Scripts\python.exe -m pytest`
- 影響 Wasm 路徑：補跑 `requires_wasm` 測試或 Wasm smoke script
- 影響 Godot 前端：可額外跑 `tools/run_godot_poc.ps1`
- 影響舊 CLI / PySide6 流程：再視需要跑 `tools/legacy/run_demo.ps1` 或 `tools/legacy/run_ui.ps1`

### 5.2 基本指令

```powershell
# 全部測試
.\.venv\Scripts\python.exe -m pytest

# 單一檔案
.\.venv\Scripts\python.exe -m pytest tests/test_levels_loader.py

# 單一測試
.\.venv\Scripts\python.exe -m pytest tests/test_wasm_judge.py::TestWasmJudge::test_ac_status

# Wasm 相關測試
.\.venv\Scripts\python.exe -m pytest -m requires_wasm -v
```

### 5.3 Smoke scripts 的定位

以下腳本仍可用，但不再作為主要自動化測試入口：

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_godot_poc.ps1
powershell -ExecutionPolicy Bypass -File tools/run_wasm_smoke.ps1
```

用途：

- Godot 前端人工確認
- Wasm 環境額外 sanity check

若要驗證舊 CLI / PySide6 流程，請改用：

```powershell
powershell -ExecutionPolicy Bypass -File tools/legacy/run_demo.ps1
powershell -ExecutionPolicy Bypass -File tools/legacy/run_ui.ps1
```

## 6. Definition of Done

=======
常用 `type`：

- `feat`
- `fix`
- `refactor`
- `docs`
- `test`
- `chore`

例子：

```text
feat(levels): add yaml-backed prototype levels
fix(judge): handle wasm runner timeout correctly
refactor(app): unify runtime composition
docs(contributing): align pytest workflow
```

## 4. PR 原則

PR 描述至少應包含：

- 做了什麼
- 為什麼這樣做
- 影響範圍
- 如何驗證

若有尚未處理的限制，也應明寫。

## 5. 驗證原則

目前專案以 `pytest` 為主要驗證入口，smoke scripts 為輔助驗證。

### 5.1 驗證層級

- 小範圍修改：跑最相關的 `pytest` 測試檔或單一測試
- 一般修改：至少跑一次 `.\.venv\Scripts\python.exe -m pytest`
- 影響 Wasm 路徑：補跑 `requires_wasm` 測試或 Wasm smoke script
- 影響 UI / demo 展示：可額外跑 `tools/run_demo.ps1` 或 `tools/run_ui.ps1`

### 5.2 基本指令

```powershell
# 全部測試
.\.venv\Scripts\python.exe -m pytest

# 單一檔案
.\.venv\Scripts\python.exe -m pytest tests/test_levels_loader.py

# 單一測試
.\.venv\Scripts\python.exe -m pytest tests/test_wasm_judge.py::TestWasmJudge::test_ac_status

# Wasm 相關測試
.\.venv\Scripts\python.exe -m pytest -m requires_wasm -v
```

### 5.3 Smoke scripts 的定位

以下腳本仍可用，但不再作為主要自動化測試入口：

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_demo.ps1
powershell -ExecutionPolicy Bypass -File tools/run_ui.ps1
powershell -ExecutionPolicy Bypass -File tools/run_wasm_smoke.ps1
```

用途：

- demo 展示前人工確認
- UI 常駐流程或 Blockly 整合檢查
- Wasm 環境額外 sanity check

## 6. Definition of Done

>>>>>>> merge/judge_introduction_branch
以下條件至少應大致成立：

- 變更已整理成可理解的 commit / PR
- 已執行與改動範圍相符的 `pytest` 驗證
- 若有 UI / demo / Wasm 風險，已補充對應 smoke 或人工驗證
- 若修改使用方式、文件結構或 skill 指引，已同步更新相關文件
- 回報中有清楚的驗證結論與剩餘風險

## 7. 相關文件

- `docs/contributing.md`
- `docs/QUICKSTART.md`
- `docs/contributing/environment_setup.md`
- `tests/README.md`
