# AI Tutor Phase 3 Demo and QA Record

更新日期: 2026-03-30

## 1. 目的

本文件提供 Phase 3 (UI 串接與本機 Demo) 的可重跑驗證紀錄，包含:

- Tutor request 契約與資料流驗證
- 本機 bridge demo 流程驗證
- Godot 專案啟動健康檢查
- QA 回歸執行命令與結果

## 2. 自動化驗證結果

### 2.1 Tutor 契約 + AI Service 測試

執行命令:

```powershell
c:/Users/tange/Desktop/all_project/比賽/Block2Python/.venv/Scripts/python.exe -m pytest tests/test_integration_contract_models.py tests/test_integration_tutor_contract_serialize.py tests/test_bridge_stdio.py tests/test_integration_http_api.py tests/ai/test_context_builder.py tests/ai/test_service.py tests/ai/test_template_provider.py
```

結果:

- collected: 50
- passed: 50
- failed: 0
- 用時: 3.15s

### 2.2 Bridge 本機 Demo Smoke

執行命令:

```powershell
powershell -ExecutionPolicy Bypass -File tools/smoke_bridge.ps1
```

結果摘要:

- ok=true: 3
- ok=false: 0
- flow 由 scene -> demo -> challenge 正常推進

### 2.3 Godot 啟動檢查

先重建 import cache:

```powershell
$repo = (Get-Location).Path
$exe = Join-Path $repo ".block2python\godot\4.6.1\Godot_v4.6.1-stable_win64_console.exe"
& $exe --path (Join-Path $repo "godot_poc") --editor --quit
```

再執行 headless 啟動:

```powershell
$repo = (Get-Location).Path
$exe = Join-Path $repo ".block2python\godot\4.6.1\Godot_v4.6.1-stable_win64_console.exe"
& $exe --headless --path (Join-Path $repo "godot_poc") --quit
```

結果:

- 專案可啟動
- 無 script parse error
- 僅有既存 ext_resource UID warning (Godot 會 fallback 到文字路徑)

## 3. P3 驗收對應

- Tutor UI 輸入/送出/取消流程: 已完成
- Provider 設定與本地儲存: 已完成
- 串流顯示與費用統計: 已完成
- 回覆類型視覺標記: 已完成
- recent feedback 串入 tutor request: 已完成
- 本機 demo 流程與 QA 可重跑命令: 已完成

## 4. 每次回歸建議指令

```powershell
# 1) 契約與 AI tutor 核心回歸
c:/Users/tange/Desktop/all_project/比賽/Block2Python/.venv/Scripts/python.exe -m pytest tests/test_integration_tutor_contract_serialize.py tests/test_bridge_stdio.py tests/ai/test_service.py tests/ai/test_template_provider.py

# 2) bridge smoke
powershell -ExecutionPolicy Bypass -File tools/smoke_bridge.ps1

# 3) Godot 啟動檢查
$repo = (Get-Location).Path
$exe = Join-Path $repo ".block2python\godot\4.6.1\Godot_v4.6.1-stable_win64_console.exe"
& $exe --headless --path (Join-Path $repo "godot_poc") --quit
```
