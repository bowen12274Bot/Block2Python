# CF/Testlib Workflow Reference

這份文件是 `cf-testlib-problem-generation` 的長版流程參考。

## 建議資料夾結構

```text
problem-name/
  statement.md
  solutions/
    solution.cpp
    brute.cpp
  testlib/
    generator.cpp
    validator.cpp
    checker.cpp
  tests/
    samples/
    pretests/
    system/
```

## 常見角色分工

- `validator.cpp`
  - 確保輸入格式與限制正確
  - 不負責判斷答案對錯
- `generator.cpp`
  - 產生各種測資族群
  - 必須可重現（seed + 參數）
- `checker.cpp`
  - 用於多解題、浮點誤差題、輸出順序可變題
  - 單解且完全匹配題可直接用比對器，不一定要自訂 checker

## testlib 慣例提示

- `registerValidation();` 用在 validator
- `registerGen(argc, argv, 1);` 用在 generator
- `registerTestlibCmd(argc, argv);` 用在 checker
- 解析參數時使用 `opt<T>("name")`
- 讀入數值優先用 `inf.readInt(l, r, "var")`

## 生成策略建議

1. 先列出要打的錯誤演算法類型（例如貪心錯、邊界漏判、溢位）。
2. 每種錯法至少一組「定向對抗測資」。
3. 隨機測資要有多種分佈，而不是只有 uniform。
4. 大資料至少含一組貼近最壞情況。

## 對拍流程（建議）

1. 隨機生成小資料（可暴力驗證）。
2. `solution` 與 `brute` 比較輸出。
3. 發現不一致時保存反例，最小化後回灌 regression。

## 打包前檢查清單

- 限制與複雜度一致，無隱藏超時。
- statement 的 sample 來自真實執行，不手抄。
- seeds 與參數有紀錄，可重建 tests。
- validator 可阻擋非法格式與越界輸入。
- checker 對錯訊息可讀，且不誤判。
