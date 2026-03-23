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

## 標準流程（CF 模式）

1. 先凍結題目規格：輸入格式、輸出格式、限制範圍、答案定義。
2. 寫 `validator.cpp`，先把合法輸入空間釘死。
3. 寫 `solution.cpp`（預期正式解）與 `brute.cpp`（對拍基準）。
4. 寫 `generator.cpp`，支援多組 seed 與子族群參數。
5. 用小規模資料做 `solution` vs `brute` 對拍。
6. 完成 `checker.cpp`（如果不是唯一輸出題型）。
7. 生成 samples / pretests / system tests，跑完整回歸。
8. 做打包前自檢：可重現性、極端測資覆蓋、時間風險。

## 操作指引

- 先用 `references/cf_testlib_workflow.md` 確定流程細節與常見坑。
- 需要快速開題骨架時，使用 `scripts/scaffold_problem.py`。
- C++ 模板可直接從 `assets/templates/` 複製後修改。
- 所有隨機生成器必須吃 seed，確保測資可重現。
- validator 不做解題邏輯，只做格式與範圍驗證。
- checker 只比較輸出語義，不應重算完整最優解（除非題型需要）。

## 驗證

- 至少完成一次 `solution` vs `brute` 壓力對拍。
- 至少覆蓋：最小值、最大值、退化結構、隨機大資料、對抗資料。
- 確認生成指令在相同 seed 下可重現完全相同輸入。
- 如有 checker，至少測三類：正確答案、格式錯誤、語義錯誤。

## 資源

- `references/cf_testlib_workflow.md`
  CF/testlib 工作流、命名慣例、檢查清單。
- `scripts/scaffold_problem.py`
  一鍵建立題目資料夾與模板檔。
- `assets/templates/*.cpp`
  generator / validator / checker / solution / brute 模板。
