# Legacy Tools

這個目錄放的是舊的 Python client 啟動腳本。
目前產品主入口是 Godot，因此這些腳本只保留給開發、回歸檢查或舊流程驗證使用。

## 可用腳本

- `run_cli_demo.ps1`
  啟動舊的 CLI client flow。
- `run_pyside6_client.ps1`
  啟動舊的 PySide6 client。
- `run_game_session_demo.ps1`
  啟動 GameSession demo flow。

## 主線入口

如果你要跑目前正式主線，請優先使用：

- `tools/setup_dev_env.ps1`
- `tools/run_godot_client.ps1`
- `tools/run_tests.ps1`
