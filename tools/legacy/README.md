# Legacy Tools

這個資料夾保留舊流程的啟動腳本，方便查舊文件、回歸驗證或暫時維護歷史入口。

目前包含：

- `run_demo.ps1`：舊 CLI demo 入口
- `run_ui.ps1`：舊 PySide6 UI 入口
- `run_game_session_demo.ps1`：舊 GameSession demo 入口

這些腳本不再是目前主線開發入口。現在主線請優先使用：

- `tools/setup_dev_env.ps1`
- `tools/run_godot_poc.ps1`
- `tools/run_tests.ps1`
