# 代碼規範

- 文件版本：0.1.0
- 更新日期：2026-03-08

本文件整理 Block2Python 目前的最低一致性規範。專案建立期暫不強制綁定 formatter 或 linter，但所有提交仍應遵守下列基本原則。

## 1. 命名與分層

- 模組分層以 `src/block2python/` 為主
- 跨層交換資料應走 `src/block2python/contracts/`
- 避免讓 UI、Judge、Analysis 直接依賴彼此的內部實作
- 若建立期需要先用 stub 打通流程，仍需保留可替換介面

## 2. Python 風格

- 盡量補上 type hints，尤其是跨模組介面與資料結構
- 避免在 import 時執行 I/O、讀檔或初始化全域狀態
- 優先使用 `pathlib.Path` 處理路徑
- 文字檔案編碼以 UTF-8 為主

## 3. 變更原則

- 優先做聚焦且可驗證的修改
- 若程式變更影響既有工作流程、文件或使用方式，應同步更新附近最相關的文件
- 若需求牽涉功能落點或模組邊界，先回頭檢查 `docs/project_architecture.md`
