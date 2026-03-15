# Block2Python（Demo）

本專案目標是做一個「積木式程式 → Python」的學習闖關 Demo，協助國中生建立從視覺化結構到文字語法的轉換思維。

## 快速開始

```powershell
# 1. 安裝依賴
pip install -e ".[dev]"

# 2. 執行測試
pytest

# 3. 啟動 GUI
python -m block2python.ui

# 4. 或啟動 CLI
python -m block2python
```

完整執行指南請見 [docs/QUICKSTART.md](docs/QUICKSTART.md)。

## 文件（Docs）

### 使用與開發
- **快速啟動指南**：[docs/QUICKSTART.md](docs/QUICKSTART.md)
- **環境與 Wasm 設定**：[docs/contributing/environment_setup.md](docs/contributing/environment_setup.md)
- **貢獻指南**：[docs/contributing.md](docs/contributing.md)

### 規劃與設計
- 產品內容：`docs/product/`
- 需求文件：`docs/requirements.md`
- 技術策略說明：`docs/technical_rationale.md`
- 專案架構：`docs/project_architecture.md`
- 開發計畫資料夾：`docs/development_plans/`
- 開發進度安排（待補）：`docs/development_timeline.md`
- 專案計畫：`docs/project_plan.md`
- 貢獻指南入口：`docs/contributing.md`
- 貢獻細則：`docs/contributing/`
- 規格（Specs）：`docs/specs/`
- UML：`docs/uml/`

## 測試

```powershell
# 執行所有測試
pytest

# Coverage 報告
pytest --cov-report=html
Start-Process htmlcov/index.html

# 快速 smoke test
python tests/smoke_wasm_judge.py
```

更多測試說明請見 [tests/README.md](tests/README.md)。

## Wasm Judge（進階）

專案已支援 WebAssembly 沙箱評測，預設會自動偵測：

```powershell
# 自動模式（找到 wasm 就用，否則回退 stub）
python -m block2python

# 強制 wasm 模式
$env:BLOCK2PYTHON_JUDGE_MODE = "wasm"
python -m block2python

# 強制 stub 模式
$env:BLOCK2PYTHON_JUDGE_MODE = "stub"
python -m block2python
```

完整配置指南請見 [docs/contributing/environment_setup.md](docs/contributing/environment_setup.md)。

## GameSession Demo

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_game_session_demo.ps1
```
