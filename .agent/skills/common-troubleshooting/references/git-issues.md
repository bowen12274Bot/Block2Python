# Git 與 Commit 問題

## `.git/objects` 寫入失敗

常見症狀：

- `git add` 因 `.git/objects` 無法寫入而失敗

處理方式：

1. 不要在 sandbox 內反覆重試
2. 直接改用 escalation 執行 `git add`
3. 若 commit 也卡在相同路徑，`git commit` 也同樣改用 escalation

## 建議排查順序

1. 先確認是不是 PowerShell 指令串接問題，而不是 git 本身錯誤
2. 若錯在 `.git/objects`，優先判定為權限 / sandbox 問題
3. git 操作完成後再用 `git status --short` 檢查工作樹狀態
