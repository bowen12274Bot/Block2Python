# 測試執行問題

## 正式測試入口

本 repo 的正式測試入口是：

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_tests.ps1
```

指定測試檔時：

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_tests.ps1 -Pattern "tests/test_game_session.py tests/test_game_content_loader.py"
```

## 本 repo 的 pytest 慣例

- `pyproject.toml` 會把 pytest cache 放到 `.tmp/pytest/cache`
- coverage data 放到 `.tmp/pytest/.coverage`
- coverage HTML 放到 `.tmp/pytest/htmlcov`
- `tools/run_tests.ps1` 會自動建立新的 `--basetemp`，位置在 `%LOCALAPPDATA%\Temp\Block2Python\pytest\run-<guid>`

## 常見症狀

- `pytest-of-<user>` 出現 `PermissionError`
- `.pytest_tmp*` 清理失敗
- pytest 在 session finish / basetemp 掃描階段爆掉
- pytest 不認得 `--cov` 或 `--cov-report`
- `.\.venv\Scripts\python.exe -m pytest` 顯示 `module not found`

## 建議排查順序

1. 先改用 `tools/run_tests.ps1`
2. 若必須直接跑 pytest，使用 `%LOCALAPPDATA%\Temp\Block2Python\pytest\...` 下的全新 `basetemp`
3. 檢查 `C:\Users\<user>\AppData\Local\Temp\pytest-of-<user>` 與 repo 內 `.pytest_tmp*` 是否殘留
4. 若已刪除壞掉的 temp 目錄，再直接跑一次 `python -m pytest ...` 驗證預設路徑是否恢復
5. 修完後檢查根目錄是否還有不該出現的 pytest artifact

## 套件缺失的解法

- 缺 `pytest`：安裝到 `.venv`
- 缺 `pytest-cov`：安裝到 `.venv`
