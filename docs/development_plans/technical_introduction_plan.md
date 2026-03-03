# 技術引入計畫（Demo / Block2Python）

- 文件版本：0.1
- 建立日期：2026-03-03
- 適用範圍：Demo（僅學生端）
- 參考文件：
  - 技術策略：`docs/technical_rationale_document.md`
  - 架構圖：`docs/uml/system_architecture.md`
  - 需求：`docs/requirements.md`

## 0. 定義「引入成功」的判準（DoD）

本計畫中的「引入」指：**把某一層/模組真正接到端到端流程上，並能被驗證（自動或手動）**。每個階段都需要同時滿足：

1. **有可呼叫的介面（Contract）**：輸入/輸出資料結構固定，錯誤型態可被處理。
2. **有可重複的驗證方式（Verification）**：至少一種（單元測試 / CLI / UI 操作步驟）可重現成功。
3. **有最小觀測（Observability）**：失敗時能定位在哪一層（log/錯誤碼/結果物）。

> 建議採用「Contract-first + Stub」：先定義跨層資料契約與介面，先用 stub 串通 UI，再逐步替換為真實實作。

---

## 1. 引入順序（建議從哪個開始）

以 Demo 端到端可展示為優先，建議順序是：

1. **程式執行與判題（Execution/Judge）**：先能跑、先能判定 AC/WA（這是所有回饋與解鎖的底座）
2. **應用整合層（PySide6 App Shell）**：先做關卡流程/頁面狀態/回饋面板（確保展示載體穩定）
3. **程式分析層（AST 結構檢查）**：補上「不只看輸出」的教學型驗證（與關卡目標對齊）
4. **視覺化編程層（Blockly 嵌入與資料流）**：把積木產物（Block JSON / 生成 Python）接進分析/判題
5. **AI 語意輔助層（Hint 生成）**：最後再接 AI（避免在核心流程未穩定前引入不確定性）

---

## 2. Phase 0：專案骨架與跨層契約（Contracts）

### 2.1 要引入什麼

- 專案目錄骨架（例如 `src/`、`tests/`、`assets/`、`tools/`）
- 跨層資料契約（建議用 `dataclass`/TypedDict/pydantic 擇一統一）
- 各層「可替換介面」：Judge、Analysis、BlocklyAdapter、AIClient

### 2.2 怎麼引入

- 先寫「資料契約」再寫「UI/功能」
- 先提供 stub 實作，回傳固定假資料，讓 UI 能先跑起來

### 2.3 如何確認成功（最小驗收）

- 有一個最小 CLI 或最小測試可以建立：
  - `LevelSpec`（關卡規格：測資、限制、允許/禁止概念）
  - `Submission`（學生提交：Python code / Block JSON）
  - `JudgeResult`（AC/WA/TLE/RE + 差異資訊）
  - `AnalysisResult`（結構檢查結果 + 差異摘要）
- UI/CLI 可以把 stub 的結果完整顯示出來（即使還沒真實判題/分析）

---

## 3. Phase 1：程式執行與判題（Execution / Judge）

### 3.1 要引入什麼

- `SandboxRunner`：以 subprocess 執行 Python、帶 timeout、擷取 stdout/stderr
- `TestcaseJudge`：多組測資執行 + 輸出正規化 + AC/WA
- `JudgeResult`：統一回傳格式（包含失敗測資索引、預期/實際、stderr、耗時）

### 3.2 怎麼引入

- 先只支援需求文件 MVP 範圍的 I/O（`input`/`print`）與純運算
- 先不做重型 sandbox（Demo 以 timeout + 基本隔離為主）；把「限制策略」抽象成選項，後續可加強

### 3.3 如何確認成功（最小驗收）

- 自動驗證：
  - 以 2～3 個測資測一題（例如：讀兩數相加輸出）
  - 測到至少 4 種結果：AC / WA / TLE / RE
- 手動驗證：
  - 在 UI/CLI 提交一段 Python，能看到：
    - 通過/失敗
    - 哪筆測資失敗與差異（正規化後）
    - 超時有明確訊息

---

## 4. Phase 2：應用整合層（PySide6 App Shell）

### 4.1 要引入什麼

- 最小頁面流程：關卡列表 → 關卡頁（積木/教學可先占位）→ Python 編輯 → 送出 → 回饋
- 關卡狀態：未解鎖/已解鎖/已通關（本地保存即可）
- 回饋面板：顯示 Judge/Analysis/AI 的結果（先接 Judge）

### 4.2 怎麼引入

- UI 先接 Phase 1 的 Judge，確保端到端 demo 能跑
- Editor 元件先用最簡可用（純文字輸入也可），避免早期被編輯器選型卡住

### 4.3 如何確認成功（最小驗收）

- 從啟動到通關至少 1 題的流程可重複跑通
- 通關後能解鎖下一題（即使下一題內容先占位）
- 任何失敗都能在 UI 明確顯示原因（WA/TLE/RE）

---

## 5. Phase 3：程式分析層（AST 結構檢查）

### 5.1 要引入什麼

- `ASTParser`：把 Python code 解析成 AST（語法錯誤要有可理解回傳）
- `StructureChecker`：支援以下「教學型」規則（先做最小集）
  - 必須包含關鍵字（例如 `for`、`input`）
  - 禁止關鍵字（對應 `docs/requirements.md` 的 out-of-scope，例如 `import`/`while`/`def`）
  - 基本結構檢查（例如 `for` 是否使用 `range`）
- `DiffProducer`：把結構差異整理成 UI/AI 可用的摘要格式（避免直接丟 AST）

### 5.2 怎麼引入

- 規則先以「關卡規格（LevelSpec）設定」驅動，而不是把規則寫死在程式碼各處
- 先做「可解釋」：回傳差異原因（哪條規則、哪個節點）比做很聰明的比對更重要

### 5.3 如何確認成功（最小驗收）

- 自動驗證：
  - 給定同一題的多種解法，能正確判斷「結果 AC 但結構不符合」（例如：不用 `for` 但輸出正確）
  - 語法錯誤能回傳可定位的錯誤（行/列）
- 手動驗證：
  - UI 能同時顯示「執行結果」與「結構檢查結果」

---

## 6. Phase 4：視覺化編程層（Blockly）

### 6.1 要引入什麼

- `BlocklyEmbed`：以 `QWebEngineView` 載入 Blockly（本地資源）
- JS ↔ Python 橋接：能取回
  - Block JSON
  - 生成的 Python code
- 最小積木集合：對齊 MVP scope（I/O、變數、運算、if/else、for range）

### 6.2 怎麼引入

- 先把「Block JSON/生成碼」能穩定拿回來，再談積木美術與互動細節
- 先做單向流程：
  - 積木 → 生成 Python → 交給 AST/Judge
  - 不急著做 Python → 積木 的逆向映射（Demo 後續再評估）

### 6.3 如何確認成功（最小驗收）

- 手動驗證（最重要）：
  - 拖一段積木 → 生成 Python → 在 Python 編輯區可直接提交 → Judge/AST 都能跑
- 資料一致性：
  - Block JSON 有版本欄位或 schema 版本策略（先預留欄位即可）

---

## 7. Phase 5：AI 語意輔助層（Hint）

### 7.1 要引入什麼

- `AIClient` 抽象介面 + Gemini 實作
- 上下文組裝（只餵必要資訊）：
  - 關卡 Allowed/Forbidden Concepts（可先人工寫死，後續再導入 Agent Skill 提取）
  - JudgeResult + AnalysisResult 的摘要
- 「不給完整解答」的守門機制（在程式端先做，再交給模型）

### 7.2 怎麼引入

- 用 feature flag：AI 可一鍵關閉（Demo 場控）
- 先做「模板化提示」再混入 LLM（確保最差情況仍能給可用回饋）

### 7.3 如何確認成功（最小驗收）

- 對同一個錯誤，提示內容可重複且不超綱
- 觸發拒答/邊界時，UI 仍能顯示可行動的替代訊息（例如提示方向而非答案）

---

## 8. 里程碑建議（以可展示為導向）

- M0：Phase 0 完成（Contracts + stub 串通 UI/CLI）
- M1：Phase 1 + Phase 2 完成（可走通 1 題：Python 提交 → Judge → 解鎖）
- M2：Phase 3 完成（補上結構檢查，能出「結構不符」的教學回饋）
- M3：Phase 4 完成（積木 → Python → Judge/AST 的端到端）
- M4：Phase 5 完成（AI 提示可控地接入）

## 9. 風險與對策（最常卡住的點）

- Sandbox/安全隔離：Demo 先做 timeout 與最小隔離；把強隔離列為後續加強項
- Blockly ↔ Desktop 橋接：先驗證 JS↔Python 通訊，再擴積木；避免先做大量積木定義
- 編輯器選型：先可用再優化；避免在 UI 體驗上過早重投入
- AI 不確定性：最後引入 + feature flag + 模板保底

