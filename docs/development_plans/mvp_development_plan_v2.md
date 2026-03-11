# MVP 下一階段開發計畫 v2

- 文件版本：0.1
- 建立日期：2026-03-11
- 依據文件：
  - `docs/development_plans/mvp_development_plan.md`
  - `docs/development_plans/technical_introduction_plan_verification.md`
  - `docs/development_plans/ai_tutor_skills_plan.md`
  - `docs/requirements.md`
  - `docs/project_architecture.md`

## 0. 目的

本文件用於整理「第一版 MVP 骨架完成並經過後續整併後，下一階段應優先推進的開發方向」。

上一版計畫的重點是先把最小可展示的端到端骨架接起來；目前這一點已經基本完成，且後續又經過一次較大的整併，讓 repo 具備了 YAML 題庫、runtime 組裝流程、WasmJudge、較完整的 contracts，以及整理過的協作文檔。下一階段不再以「把技術先接上」為主，而是以 **對齊目前實際架構、補齊可持續擴充的內容與流程、收斂尚未定案的產品邊界** 為主。

## 1. 現況分析摘要

### 1.1 已具備能力

- 關卡已由 `assets/levels/index.yaml` 與各 `.yaml` 檔載入，prototype flow 已可串起來
- CLI / UI 均已改為透過 runtime 組裝流程啟動，而不再只依賴硬編碼 demo levels
- Blockly → Python → Analysis → Judge → Feedback 的主資料流已打通
- Judge 已不再只停留在 StubJudge，WasmJudge、normalization、testcases 與 smoke workflow 已存在
- 關卡解鎖、本地進度保存、提交結果與失敗 case 回饋已有基本可用版本
- `contracts/`、`analysis/`、`judge/`、`app/`、`ui/` 的分層已比第一版更清楚
- 開發用 agent skills、協作文檔、pytest / smoke workflow 已初步成形

### 1.2 目前主要缺口

- 題庫內容仍偏 prototype / sample，尚未形成穩定的關卡內容規格與擴充流程
- Blockly 支援範圍、generator 邊界、關卡 concept 範圍尚未正式對齊
- 目前 Blockly 產出的 Python 仍會直接回填 editor，與「積木作為前置練習、Python 仍由學生自行完成」的方向仍有張力
- UI 仍偏向開發驗證面板，尚未整理成接近正式學習流程的介面
- 教學頁、劇情入口、關卡內容與 schema 的責任切分還不夠清楚
- AI tutor 雖已有規劃文件，但 runtime 側尚未正式落地
- teaching skills 與開發用 skills 的資料流與管理方式仍停留在計畫層
- 文件結構已整理，但進度追蹤、後續主題拆分與實作順序仍未完全補齊

## 2. 下一階段核心目標

- 將目前的整併後骨架推進為「可持續開發的 MVP baseline」
- 優先完成會直接影響題庫擴充、Blockly 使用範圍、UI 主流程與 AI tutor 接入的功能
- 先收斂必要決策，再分拆各主題計畫進入規劃與實作

## 3. 下一階段需要決策的事項

### 3.1 題庫 schema 與內容邊界

- 關卡正式 schema 要承載到什麼程度：哪些欄位可以繼續留在 `metadata`，哪些應提升為正式欄位
- `prompt`、`learning_markdown`、`story_intro_markdown`、`story_outro_markdown`、`analysis_policy`、`judge_policy`、`concept_policy` 的責任邊界如何固定
- prototype levels 是否需要重新命名、重排順序，或分出示範用與正式教學用兩種題庫
- 關卡內容、劇情內容、教學內容與提示內容是否要分開管理
- 是否在下一階段引入 `teaching_skill_ids`、`tutor_policy` 等欄位

### 3.2 Blockly 教學範圍與表示方式

- 下一階段 Blockly 要正式支援到哪些積木：是否固定為 I/O、變數、運算、if/else、for range
- 是否需要自訂 blocks，或先以現成 Blockly blocks + 限制策略完成
- Blockly 關卡限制要如何資料驅動（允許/禁止 blocks、概念對齊）
- Blockly 轉 Python 在下一階段的定位：保留直接回填、改為預覽、還是改成對照/提示模式
- block JSON schema 與 generator 的版本管理要如何前進

### 3.3 UI 與學習流程策略

- UI 下一階段要做到什麼程度的學習流程感：維持工具型面板，或整理成較明確的章節/關卡操作流程
- 關卡列表、內容頁籤、Blockly 區、Python 編輯區與 feedback 區的優先順序如何調整
- 關卡鎖定、解鎖原因、block step、submit 結果是否需要更明確的 UI 呈現
- 開發期按鈕（reload/reset 等）是否保留在主畫面，或改為次要操作
- tutor 面板未來要放在 feedback 區下方、旁邊，還是獨立區塊

### 3.4 教學內容與劇情呈現策略

- 教學頁在下一階段的呈現形式：純文字、Markdown、分段卡片、或更明確的步驟式內容
- 劇情／任務入口要做到什麼程度：僅文字前後文，還是納入章節與任務節點
- 關卡資料是否需要擴充 schema，以承載教學內容、劇情節點、提示策略與 tutor 掛載資訊
- 教學頁內容與 teaching skills 的分工如何明確固定

### 3.5 AI tutor 與 teaching skills 策略

- AI tutor 在下一階段是否正式進入 Demo 流程，或先以 feature flag / 開發模式存在
- tutor 可讀取哪些上下文：學生程式碼、block JSON、關卡內容、Analysis/Judge 結果、teaching skill
- tutor 的拒答與防洩題策略要到什麼程度
- teaching skills 的最小資料格式與載入方式是否先固定為 `assets/teaching_skills/*.json`
- teaching skills 與 `.agent/skills/` 的開發用 skills 要如何保持邊界

### 3.6 測試與驗證策略

- 哪些 smoke script 應保留為手動驗證，哪些應轉成正式 pytest
- UI / tutor / levels schema 是否需要建立新的最小自動化測試
- 下一階段的 DoD 是否仍以 `pytest` 為主，smoke 為輔
- Wasm、UI、題庫內容與 tutor 的驗證命令如何整理成穩定流程

## 4. 下一階段待規劃的主題

以下項目建議各自拆成獨立計畫文件，而不是直接在本文件中展開細節。

### 4.1 關卡資料結構與內容規劃

- 關卡 schema 如何從目前的 prototype 狀態收斂成正式可擴充格式
- 教學頁、劇情、analysis/judge/tutor 相關欄位的資料關係
- `metadata` 內既有資訊是否上提為正式 schema 欄位

### 4.2 Blockly 範圍與資料流計畫

- MVP 必要積木集合
- toolbox 設計與分類
- generator 與 block JSON/schema 的演進策略
- Blockly 與 Python 編輯區的關係：哪些資料做驗證、哪些資料只做提示或對照

### 4.3 UI 主流程與互動計畫

- 關卡選取、內容閱讀、Blockly 操作、Python 提交、feedback 顯示的主流程
- 主畫面布局與區塊優先順序
- tutor 面板預留位置與互動方式

### 4.4 教學頁與劇情呈現計畫

- 教學頁資料來源與呈現方式
- 劇情／任務入口的最小流程
- 教學內容、任務目標、AI 提示間的對應方式

### 4.5 AI tutor 與 teaching skills 計畫

- teaching skill schema
- tutor context 組裝規格
- tutor policy、拒答策略與 provider 分層
- level 與 teaching skill 的掛載方式

### 4.6 驗證與測試基線計畫

- pytest 與 smoke script 的角色分工
- 題庫、UI、tutor、Blockly 資料流的最小測試集
- 後續功能的 Definition of Done 與驗證指引

## 5. 下一階段待實作的主軸

### 5.1 先收斂題庫與 schema

- 補齊關卡正式欄位邊界
- 讓 prototype 題庫不再依賴過多隱含規則或臨時 metadata
- 讓新增關卡的方式可以被文件化與重複使用

### 5.2 收斂 Blockly MVP 使用範圍

- 將 Blockly 支援範圍正式對齊目前目標教學內容
- 讓 Blockly block、generator、concept policy 與關卡要求一致
- 明確處理 Blockly 轉 Python 與學生手寫 Python 的關係

### 5.3 整理 UI 主流程

- 將目前偏驗證導向的 `MainWindow` 整理成較清楚的學習流程
- 補足關卡狀態、鎖定原因、提交結果與錯誤提示的可讀性
- 預留 tutor 接入後不會破壞主流程的 UI 結構

### 5.4 落地 AI tutor Phase 1

- 建立 teaching skills 檔案與 loader
- 建立 tutor request / response、context builder、policy、stub/template provider
- 在 UI 接上最小 tutor 面板

### 5.5 固化測試與 smoke baseline

- 補齊 levels loader、AppCore、tutor service、UI smoke 的最小測試
- 明確區分 unit / integration / requires_wasm
- 讓新功能有可重複的最低驗證流程

## 6. 下一階段待完善的部分

### 6.1 UI 與回饋呈現

- 關卡狀態資訊的可讀性
- Analysis / Judge 回饋區分與摘要
- Blockly 與 Python 的操作切換體驗
- tutor 回覆與既有 feedback 的關係

### 6.2 內容與資料一致性

- 關卡內容、劇情、教學頁、analysis 規則、judge 規則、tutor 邊界是否一致
- 關卡 schema、loader 與作者實際編寫方式是否一致
- Blockly 可用概念與關卡允許概念是否一致

### 6.3 觀測與除錯

- Demo 階段至少需要哪些 log / debug 資訊
- 發生錯誤時如何快速定位是題庫、Blockly、analysis、judge、還是 tutor 問題
- tutor 是否需要保留最小除錯資訊而不破壞使用者體驗

### 6.4 驗證與測試

- 哪些 smoke test 應被正式化
- tutor 與 teaching skill 是否需要獨立測試資料
- 後續是否引入更清楚的測試資料與 fixture 管理方式

## 7. 建議的推進順序

1. 先決策：題庫 schema 邊界、Blockly MVP 範圍、UI 主流程整理程度、teaching skills 掛載方式、tutor 邊界
2. 先規劃：拆出題庫 schema、Blockly、UI 流程、教學/劇情、AI tutor、驗證基線等個別計畫文件
3. 先實作主流程：題庫/schema 收斂、Blockly 範圍收斂、UI 主流程整理、AI tutor Phase 1
4. 再完善體驗：資料一致性、回饋可讀性、teaching skills 對齊、最小測試與觀測能力

## 8. 建議後續拆出的計畫文件

- `levels_content_schema_plan.md`
- `blockly_mvp_scope_plan.md`
- `game_ui_flow_plan.md`
- `learning_story_flow_plan.md`
- `interactive_mode_plan.md`
- `ai_tutor_skills_plan.md`
- `verification_baseline_plan.md`
