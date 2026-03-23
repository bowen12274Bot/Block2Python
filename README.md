# Block2Python（Demo）

本專案的目標是做一個「積木式程式 -> Python」的學習闖關 Demo，協助學生從視覺化結構逐步過渡到文字程式語法。

## 快速開始

```powershell
# 1. 安裝依賴
pip install -e ".[dev]"

# 2. 執行測試
pytest

# 3. 啟動 Godot 主 client
powershell -ExecutionPolicy Bypass -File tools/run_godot_client.ps1

# 4. 啟動 legacy PySide6 client
python -m block2python.clients.pyside6
```

完整啟動與環境說明請見 [docs/QUICKSTART.md](docs/QUICKSTART.md)。

## 文件

### 使用與開發
- **快速啟動指南**：[docs/QUICKSTART.md](docs/QUICKSTART.md)
- **環境與 Wasm 設定**：[docs/contributing/environment_setup.md](docs/contributing/environment_setup.md)
- **開發流程**：[docs/contributing/developer_workflow.md](docs/contributing/developer_workflow.md)
- **貢獻指南**：[docs/contributing.md](docs/contributing.md)

### 規劃與設計
- 產品內容：`docs/product/`
- 需求文件：`docs/requirements.md`
- 技術策略說明：`docs/technical_rationale.md`
- 專案架構：`docs/project_architecture.md`
- 開發計畫：`docs/development_plans/`
- 專案計畫：`docs/project_plan.md`
- 規格：`docs/specs/`
- UML：`docs/uml/`

## 主要結構

- `src/block2python/`
  Python 核心邏輯，包含 content、level_play、game、judge、integration、clients。
- `assets/`
  關卡、劇情、地圖路線、toolbox、Wasm 等內容資料。
- `godot_poc/`
  目前的 Godot 主 client prototype。
- `tests/`
  Python 測試。
- `tools/`
  開發、驗證與 legacy 啟動腳本。

## 測試

```powershell
# 執行所有測試
pytest

# Coverage 報告
pytest --cov-report=html
Start-Process htmlcov/index.html

# Wasm smoke test
python tests/smoke_wasm_judge.py
```

更多測試說明請見 [tests/README.md](tests/README.md)。

## Wasm Judge

專案支援 WebAssembly 沙箱評測。常用模式如下：

```powershell
# 自動模式（找到 wasm 就用，否則回退 stub）
python -m block2python.clients.cli.main

# 強制 wasm 模式
$env:BLOCK2PYTHON_JUDGE_MODE = "wasm"
python -m block2python.clients.cli.main

# 強制 stub 模式
$env:BLOCK2PYTHON_JUDGE_MODE = "stub"
python -m block2python.clients.cli.main
```

完整設定請見 [docs/contributing/environment_setup.md](docs/contributing/environment_setup.md)。

## 其他入口

```powershell
# GameSession demo
powershell -ExecutionPolicy Bypass -File tools/legacy/run_game_session_demo.ps1

# Legacy CLI demo
powershell -ExecutionPolicy Bypass -File tools/legacy/run_cli_demo.ps1
```
