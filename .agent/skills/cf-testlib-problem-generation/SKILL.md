---
name: cf-testlib-problem-generation
description: 生成符合 Codeforces 標準流程的競程題目（CF 模式）。用於出題規格拆解、testlib generator/validator/checker 撰寫、測資分層、強弱解驗證、壓力測試與打包前自檢。
---

# CF Testlib Problem Generation

使用此 skill 產生符合 Codeforces 常見出題工作流的題目與測資資產。

## 範圍

- 由題意草稿整理成可驗證的正式規格（I/O、限制、子任務、邊界條件）
- 依 testlib 習慣建立 `generator.cpp`、`validator.cpp`、`checker.cpp`
- 建立 `solution.cpp`（預期解）與 `brute.cpp`（慢但可信的對拍解）
- 設計分層測資（samples / pretests / system tests）
- 執行 stress test 與最終打包前自檢

## 何時使用

- 使用者想「開新題」或「生成一題 CF 風格題目」
- 明確要求 testlib 寫法、Codeforces / Polygon 風格產物
- 需要可重複生成測資，而不是手寫固定資料

## 不適用情境

- 單純寫演算法解題教學（不需要出題資產）
- 只要一份敘述，不需 validator/checker/generator
- 非競程評測規則（例如教學互動題、人工評分題）

## 最小產出清單

- 問題規格（題意 + 限制 + corner cases）
- `solution.cpp`
- `brute.cpp`
- `generator.cpp`
- `validator.cpp`
- `checker.cpp`
- 測資分層規劃與生成指令
- Block2Python 相容的 `assets/levels/<level_id>.yaml`
- Block2Python 相容的 `assets/levels/cases/<level_id>/*.in|*.out`

## 標準流程（CF 模式）

1. 先凍結題目規格：輸入格式、輸出格式、限制範圍、答案定義。
2. 寫 `validator.cpp`，先把合法輸入空間釘死。
3. 寫 `solution.cpp`（預期正式解）與 `brute.cpp`（對拍基準）。
4. 寫 `generator.cpp`，支援多組 seed 與子族群參數。
5. 用小規模資料做 `solution` vs `brute` 對拍。
6. 完成 `checker.cpp`（如果不是唯一輸出題型）。
7. 生成 samples / pretests / system tests，跑完整回歸。
8. 做打包前自檢：可重現性、極端測資覆蓋、時間風險。

## 一次完成交付（Block2Python）

當需求是「直接完成一題」時，必須在單次流程內同時完成 CF 產物與 Block2Python 資產，不能停在中間狀態。

### 必要輸出

- 題目工作區：`tools/level/<problem_name>/`
- 關卡定義：`assets/levels/<level_id>.yaml`
- 正式案例：`assets/levels/cases/<level_id>/NN.in|NN.out`
- 可重跑驗證：`tools/level/<problem_name>/scripts/verify_testlib.ps1`

### 建議一步到位順序

1. 用 `scripts/scaffold_problem.py` 建立骨架（可同時產生 level 資產）。
2. 完成 `statement` + `validator` + `solution` + `brute` + `generator` + `checker`。
3. 跑嚴格驗證（generator -> validator -> solution-vs-brute -> checker positive/negative）。
4. 用 generator 重新回灌 `assets/levels/cases/<level_id>/` 正式測資。
5. 跑 `tests/test_levels_loader.py`，確認關卡 YAML 與案例目錄可載入。
6. 回報 case 組數、seed/參數、驗證摘要與已知風險。

### 完成定義（DoD）

- 不存在 placeholder 案例或只留 sample 的狀態
- 相同 seed 下可重現相同輸入
- validator 對非法輸入有明確拒絕
- checker 對錯誤答案有明確拒絕
- `assets/levels/<level_id>.yaml` 的 `testcase_dir` 指向正確且可讀取

## 操作指引

- 先用 `references/cf_testlib_workflow.md` 確定流程細節與常見坑。
- 需要快速開題骨架時，使用 `scripts/scaffold_problem.py`。
- 預設會建立：
  - `tools/level/<problem_name>/...`（testlib / solution / brute / statement）
  - `assets/levels/<level_id>.yaml`
  - `assets/levels/cases/<level_id>/01.in|01.out`
- 預設會把新 level 註冊到 `assets/levels/index.yaml`（若 id 已存在則跳過）。
- 若只想建立腳本骨架，不產生 Block2Python 關卡檔，可加 `--skip-level-assets`。
- C++ 模板可直接從 `assets/templates/` 複製後修改。
- 所有隨機生成器必須吃 seed，確保測資可重現。
- validator 不做解題邏輯，只做格式與範圍驗證。
- checker 只比較輸出語義，不應重算完整最優解（除非題型需要）。

### 常用指令

```powershell
python .agent/skills/cf-testlib-problem-generation/scripts/scaffold_problem.py sum-array
```

```powershell
python .agent/skills/cf-testlib-problem-generation/scripts/scaffold_problem.py sum-array --level-id practice-sum-array --title "Practice: Sum Array"
```

## 驗證

- 至少完成一次 `solution` vs `brute` 壓力對拍。
- 至少覆蓋：最小值、最大值、退化結構、隨機大資料、對抗資料。
- 確認生成指令在相同 seed 下可重現完全相同輸入。
- 如有 checker，至少測三類：正確答案、格式錯誤、語義錯誤。

若題目工作區已有嚴格驗證腳本，優先使用：

```powershell
powershell -ExecutionPolicy Bypass -File tools/level/<problem_name>/scripts/verify_testlib.ps1 -CaseCount 80
```

若在 Windows + MinGW 環境遇到非 ASCII 路徑編譯問題，改用 ASCII 暫存目錄（例如 `C:/Temp/...`）編譯與驗證，再把最終 `NN.in/.out` 回寫到 `assets/levels/cases/<level_id>/`。

## 資源

- `references/cf_testlib_workflow.md`
  CF/testlib 工作流、命名慣例、檢查清單。
- `scripts/scaffold_problem.py`
  一鍵建立題目資料夾與模板檔。
- `assets/templates/*.cpp`
  generator / validator / checker / solution / brute 模板。
