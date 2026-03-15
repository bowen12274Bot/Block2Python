# 快取與 Temp 清理

## 根目錄常見測試殘留

以下通常可以刪除：

- `.pytest_cache/`
- `htmlcov/`
- `.coverage`
- `.pytest_tmp/`
- `.pytest_tmp_run_*`
- `pytest_tmp_run_*`
- `pytest-cache-files-*`

## `.tmp` 的定位

- `.tmp/` 是目前 repo 集中放測試快取與 coverage 的目錄
- 沒有工具正在使用時可以刪除
- 下次跑測試時會自動重建

## 收尾檢查

修完測試或 temp 問題後，確認根目錄不要再亂噴：

- `.pytest_cache`
- `htmlcov`
- `.coverage`
- `pytest-cache-files-*`
- `.pytest_tmp*`

目前預期只會集中出現在 `.tmp/`
