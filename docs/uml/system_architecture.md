# 系統架構圖（System Architecture Diagram）

> 依據 [技術策略說明文件](../technical_rationale_document.md) v0.1 繪製  
> 更新日期：2026-03-03

## 系統架構圖（圖片版）

![Block2Python 系統架構圖](system_architecture.png)

## 分層元件圖（Layered Component Diagram，互動版）

```mermaid
graph TB
    subgraph APP["應用整合層（Application Integration Layer）\nPySide6 / Qt6"]
        direction TB
        AppCtrl["AppController\n（關卡流程 / 頁面狀態管理）"]
        UI_Panel["UI Panels\n（關卡選單 / 回饋面板 / 解鎖流程）"]
        AppCtrl <--> UI_Panel
    end

    subgraph VIS["視覺化編程層（Visual Programming Layer）\nBlockly + QWebEngineView"]
        direction TB
        BlocklyEmbed["BlocklyEmbed\n（QWebEngineView 嵌入）"]
        BlockDef["CustomBlockDefs\n（關卡積木定義）"]
        BlockGen["Block → Python Generator\n（積木程式碼生成）"]
        BlocklyEmbed --> BlockDef
        BlocklyEmbed --> BlockGen
    end

    subgraph PY["Python 編程層（Python Programming Layer）\nPySide6 Editor Widget"]
        direction TB
        Editor["CodeEditor\n（程式碼輸入 / 編輯）"]
        Submitter["SubmitHandler\n（送出 / 執行觸發）"]
        FeedbackView["FeedbackView\n（結果 / 錯誤 / 提示呈現）"]
        Editor --> Submitter
        Submitter --> FeedbackView
    end

    subgraph ANALYSIS["程式分析層（Program Analysis Layer）\nPython ast"]
        direction TB
        ASTParser["ASTParser\n（Python → AST）"]
        StructChecker["StructureChecker\n（結構規則檢查）"]
        BlockMapper["Block ↔ AST Mapper\n（積木結構映射）"]
        DiffProducer["DiffProducer\n（差異資訊產出）"]
        ASTParser --> StructChecker
        ASTParser --> BlockMapper
        StructChecker --> DiffProducer
        BlockMapper --> DiffProducer
    end

    subgraph EXEC["程式執行與安全層（Execution & Security Layer）\nPython Sandbox"]
        direction TB
        Sandbox["SandboxRunner\n（隔離執行 / 資源限制 / 超時）"]
        TestJudge["TestcaseJudge\n（測資比對 / 正規化）"]
        JudgeResult["JudgeResult\n（AC / WA / 差異回傳）"]
        Sandbox --> TestJudge
        TestJudge --> JudgeResult
    end

    subgraph AI["AI 語意輔助層（Semantic Assistant Layer）\nGemini API + Agent Skill"]
        direction TB
        SkillExtractor["AgentSkill\n（教案綱要提取）"]
        HintGen["HintGenerator\n（提示語意生成）"]
        ErrExplainer["ErrorExplainer\n（錯誤說明 / 引導）"]
        SkillExtractor --> HintGen
        DiffInput(["DiffInput\n（差異資訊輸入）"])
        DiffInput --> HintGen
        DiffInput --> ErrExplainer
    end

    %% 跨層資料流
    APP -->|"載入關卡\n啟動積木環境"| VIS
    APP -->|"啟動 Python 編輯"| PY
    VIS -->|"Block JSON / 生成程式碼"| ANALYSIS
    PY -->|"Python 原始碼"| ANALYSIS
    PY -->|"Python 原始碼"| EXEC
    ANALYSIS -->|"結構差異 / AST 結果"| AI
    EXEC -->|"AC / WA / 執行差異"| AI
    EXEC -->|"判定結果"| PY
    AI -->|"語意提示 / 引導訊息"| PY
    ANALYSIS -->|"結構驗證結果"| APP
    EXEC -->|"最終判定"| APP
```

## 各層職責摘要

| 層別 | 核心技術 | 主要職責 |
|------|----------|----------|
| 應用整合層 | PySide6 / Qt6 | 關卡流程控制、頁面狀態管理、模組整合 |
| 視覺化編程層 | Blockly + QWebEngineView | 積木操作、自訂積木定義、積木→程式碼生成 |
| Python 編程層 | PySide6 Editor Widget | 程式碼編輯送出、結果與回饋呈現 |
| 程式分析層 | Python `ast` | AST 解析、結構規則檢查、積木↔AST 映射、差異產出 |
| 程式執行與安全層 | Python Sandbox | 隔離執行、測資比對、AC/WA 判定、超時控制 |
| AI 語意輔助層 | Gemini API + Agent Skill | 差異語意轉換、學習提示生成、錯誤說明引導 |

## 資料流說明

1. **積木 → 分析**：Blockly 輸出 Block JSON 或產生 Python 程式碼，送至程式分析層進行結構映射與驗證。
2. **Python → 執行**：學生送出程式碼後，沙盒執行並以測資比對取得 AC/WA 判定。
3. **差異 → AI 引導**：程式分析與執行層產出的結構差異與執行錯誤，輸入 AI 層轉為可理解之學習提示。
4. **提示 → 回饋呈現**：AI 語意提示回傳至 Python 編程層的回饋面板，呈現給學生。
5. **流程控制**：應用整合層統籌關卡解鎖與流程推進，接收驗證結果後決定是否進入下一關。
