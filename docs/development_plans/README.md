# 開發計畫（Development Plans）

> 本資料夾用於存放更細的開發計畫（例如：每週計畫、分工、里程碑拆解）。

- 技術引入計畫（Demo）：`docs/development_plans/technical_introduction_plan.md`
- 技術引入計畫驗證書：`docs/development_plans/technical_introduction_plan_verification.md`

## 規劃方式（建議）

- 一份計畫 = 一個主題（例如：技術引入、判題 sandbox、AI hint、關卡資料規格化）
- 計畫內容至少包含：
  - 目標與不做什麼（Scope / Non-goals）
  - DoD（怎樣算完成）
  - 引入順序與驗證方式（手動/自動）
  - 風險與替代方案（若選型未定，先 stub）

## 檔名/版本規則（建議）

- 檔名使用 `snake_case`：
  - `technical_introduction_plan.md`
  - `sandbox_plan.md`
- 若計畫需要凍結版本，使用後綴：
  - `*_v0_1.md`
- 若計畫有對應的驗證/盤點文件：
  - `*_verification.md`
