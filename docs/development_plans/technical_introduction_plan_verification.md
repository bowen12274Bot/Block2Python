# 技術引入計畫驗證書（Demo / Block2Python）

- 對應計畫：`docs/development_plans/technical_introduction_plan.md`（v0.1）
- 建立日期：2026-03-05
- 驗證範圍：專案建立期（以「能跑通端到端流程」與「可替換介面」為主，不追求最終判題/完整關卡）

## 0. 驗證方法（如何重現）

### 0.1 環境

依 `docs/contributing/environment_setup.md` 建立 `.venv`：

- `powershell -ExecutionPolicy Bypass -File tools/setup_dev_env.ps1`

### 0.2 Smoke（最小可重現）

- CLI（核心流程）：`powershell -ExecutionPolicy Bypass -File tools/run_demo.ps1`
- UI（桌面殼 + WebEngine/橋接）：`powershell -ExecutionPolicy Bypass -File tools/run_ui.ps1`

> UI 屬常駐視窗，啟動後請用手動操作驗證：切換關卡、積木頁送回 App、提交 Python、觀察回饋/解鎖/進度保存。

## 1. DoD（Definition of Done）覆核

計畫定義的引入成功判準（Contract / Verification / Observability）目前狀態如下：

- **Contract**：已建立並使用 `dataclass` 契約（`LevelSpec/Submission/JudgeResult/AnalysisResult` 等），跨層資料流已落在 `src/block2python/contracts/`。
- **Verification**：已有 CLI & UI 兩種可重現方式（見 0.2）。
- **Observability**：至少以 UI feedback/CLI print + `JudgeResult/AnalysisResult` 的 `summary/violations/debug` 提供定位資訊（仍屬建立期等級）。

## 2. Phase-by-Phase 驗證結果

### Phase 0：專案骨架與跨層契約（Contracts）

**計畫目標**
- 建立目錄骨架、資料契約、各層可替換介面。

**已做到**
- 目錄骨架已建立（`src/`、`assets/`、`tools/`、`tests/`）。
- `dataclass` 契約已建立並被各層使用：`src/block2python/contracts/models.py`。
- 介面（Protocol）已存在並可替換：Judge/Analyzer。

**未做到 / 延後**
- 契約尚未收斂成「嚴格 schema/驗證」（建立期刻意維持寬鬆，後續可引入 pydantic/jsonschema）。

**驗證方式**
- 以 CLI/UI 跑通端到端流程即視為完成建立期驗證。

---

### Phase 1：程式執行與判題（Execution / Judge）

**計畫目標（建立期版本）**
- 真實 sandbox/judge 未定前，以 StubJudge 繞過，但維持可替換介面與回傳格式。

**已做到**
- `Judge` 介面已建立：`src/block2python/judge/api.py`
- `StubJudge` 已能：
  - 讀取 `LevelSpec.testcases`
  - 產生 `JudgeResult.case_results` / `failed_case_index`
  - 透過 `metadata.stub_judge` 配置展示 `AC/WA/TLE/RE` 型態：`src/block2python/judge/stub.py`
- Levels schema 已補 stub 欄位（dev-only）：`docs/specs/levels_schema_v0_1.md`

**未做到 / 跳過**
- 真實執行（subprocess/sandbox/timeout/資源限制）未做（依計畫屬後續替換項）。
- 真實輸出比對與正規化策略未落地（仍停留在契約層）。

**驗證方式**
- 用關卡 `metadata.stub_judge` 配出不同狀態，UI feedback 會顯示測資差異（建立期驗證）。

---

### Phase 2：應用整合層（PySide6 App Shell）

**計畫目標**
- 最小頁面流程、關卡狀態、回饋面板、本地保存。

**已做到**
- UI（PySide6 Widgets）已可啟動，並展示：
  - 關卡列表與 LOCKED/UNLOCKED/CLEARED
  - 題目/教學/劇情（純文字）
  - Python 編輯 + 提交 + feedback：`src/block2python/ui/window.py`
- App 核心流程已存在（解鎖/提交/回饋串接）：`src/block2python/app/core.py`
- 進度保存已存在（`.block2python/progress.json`）：`src/block2python/app/progress.py`
- 建立期「積木步驟通過」stub gate 已存在（先積木再 Python）：UI 按鈕 / WebEngine 輸出可標記通過。

**未做到 / 跳過**
- 編輯器元件選型/美化未做（建立期刻意不做精細 UI）。
- 教學頁/劇情頁的正式呈現（Markdown 渲染/互動）未做。

**驗證方式**
- UI 手動操作：完成積木步驟通過 → Python submit → 看到 analysis/judge 回饋 → 通關解鎖下一關。

---

### Phase 3：程式分析層（AST 結構檢查）

**計畫目標（建立期版本）**
- Syntax check + out-of-scope 禁用 + required/forbidden keyword（可解釋回饋）。

**已做到**
- `AstAnalyzer` 已實作：
  - Syntax error（含 line/col）
  - out-of-scope 禁用（依 `docs/requirements.md`）：`import/def/while/class/list/dict/tuple`
  - per-level keyword required/forbidden（建立期簡化為字串包含）
  - 輸出 `AnalysisResult` + `violations`：`src/block2python/analysis/ast_analyzer.py`
- 「資料驅動管線」已就緒（不要求現在一定要有規則）：
  - `metadata.analysis.required_keywords/forbidden_keywords` → `LevelSpec.analysis_policy`：`src/block2python/app/levels_loader.py`
  - 規格補註：`docs/specs/levels_schema_v0_1.md`

**未做到 / 跳過**
- `for range` 形狀檢查、結構拓樸一致性、DiffProducer 精緻化：未做（依計畫屬後期擴充）。
- Blockly ↔ AST 映射：未做（依計畫屬後期擴充）。

**驗證方式**
- UI 提交含 `import/def/while/...` 的 code 會得到 FAIL + violations（建立期驗證）。

---

### Phase 4：視覺化編程層（Blockly）

**計畫目標（建立期調整後）**
- 以 `QWebEngineView` 嵌入本地 Web，打通 JS↔Python 橋接；最小積木集合先以 `print/數字/算術` 跑通即可。

**已做到**
- `QWebEngineView` + `QWebChannel` 橋接已完成：`src/block2python/ui/blockly_embed.py`
- 本地頁面 `assets/blockly/index.html`：
  - 可產出 Python code + Block JSON
  - Block JSON 已對齊 schema v0.1（`schema_version: "0.1"`，含 `workspace/generated/metadata`）：`docs/specs/block_json_schema_v0_1.md`
- UI 接收到 Web 輸出後會：
  - 回填 editor
  - 帶入 `Submission.block_json` / `Submission.block_schema_version`
  - 標記積木步驟通過（建立期 gate）
- Blockly 靜態檔 vendor 流程已文件化，並可用工具腳本從目錄/zip 匯入：
  - `tools/vendor_blockly.ps1` / `tools/vendor_blockly_from_dir.ps1`
  - `docs/contributing/environment_setup.md`

**未做到 / 跳過**
- 完整最小積木集合（I/O、變數、if/else、for range）未做（已在計畫中延後到後續階段）。
- 自訂 blocks / generator 與關卡限制策略未做（待關卡設計後規劃）。

**驗證方式**
- UI：在「積木（WebEngine）」頁生成 → 送回 App → 觀察 editor 回填與 block step 變 OK → submit 可進 AST/Judge。

---

### Phase 5：AI 語意輔助層（Hint）

**計畫目標**
- 最後再接 AI（可控、可關閉）。

**目前狀態**
- 未開始（符合計畫順序）。

## 3. 目前已達成的「端到端」能力摘要

- 以資料/契約串起：關卡載入 → UI 顯示 → 積木（WebEngine）產出 → Python 回填 → AST 檢查 → StubJudge → 回饋 → 解鎖 → 進度保存。
- 技術未定部分（sandbox/judge）已以 StubJudge 隔離，後續可替換而不破壞 UI/流程。

## 4. 被跳過 / 下一階段需續做事項（Backlog）

依「建立期已完成引入」為前提，下一階段建議續作：

### 4.1 真實 Execution/Judge（替換 StubJudge）

- Sandbox/judge 技術選型與實作（subprocess/隔離/timeout/資源限制）
- 多測資執行與輸出正規化策略
- `CaseResult.stderr/elapsed_ms/exit_code` 等資訊的真實填值

### 4.2 AST 分析擴充（教學型結構檢查）

- `for range` 形狀檢查、更多 AST node 級規則
- 更可解釋的 DiffProducer（結構差異摘要）
- Blockly ↔ AST 映射（支援「積木→Python」教學對齊）

### 4.3 Blockly 擴充（對齊需求範圍）

- 擴充 toolbox 與（必要時）自訂 blocks
- 生成器與 schema_version 演進（v0.2+）
- 關卡資料驅動限制（允許/禁止積木、概念對齊）

### 4.4 UI/內容呈現（不以建立期為目標）

- 編輯器元件選型與體驗優化
- 教學/劇情內容的正式呈現（Markdown/互動）
- 更完整的回饋 UI（測資 diff 視覺化、錯誤分類）

### 4.5 AI（Phase 5）

- AIClient/Gemini 串接（feature flag）
- hint policy/邊界規格與教案橋接（Agent Skill 等）
