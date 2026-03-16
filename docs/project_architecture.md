# 專案架構

<<<<<<< HEAD
- 更新日期：2026-03-14
- 範圍：遊戲系統骨架重構後的目前專案結構
=======
- 最後更新：2026-03-11
- 本文件說明 Block2Python 專案目前的目錄結構、主要模組分工、靜態資源配置、工具腳本，以及 agent skills 的使用方式。
>>>>>>> merge/judge_introduction_branch

## 1. 儲存庫結構

```text
Block2Python/
  assets/                     # runtime 資源：levels、game_content、blockly、wasm
  docs/                       # 架構、計畫、規格、協作文件
  src/block2python/           # Python 原始碼
  tests/                      # 單元測試、整合測試、smoke tests
  tools/                      # PowerShell 輔助腳本
  .agent/ .agents/ .claude/ .codex/  # agent skills 與客戶端設定
```

## 2. 原始碼結構

目前的 source of truth 位於 `src/block2python/`。

```text
src/block2python/
  analysis/       # AST 分析與分析 API
  challenge/      # challenge 子系統：AppCore、judge factory、progress
  clients/        # client 入口：PySide6 與 CLI
  content/        # levels loader、game content loader、內容與 runtime 模型
  contracts/      # 現有 level/judge 領域契約
  game/           # GameSession、savegame、遊戲主流程控制
  integration/    # 對外邊界：contracts、dispatcher、bridge、adapters
  judge/          # judge 實作與 Wasm runner

  ai/             # 預留 AI 相關 package
  app/            # 舊路徑相容 shim
  blockly/        # Blockly 相關 package hooks
  game_content/   # content 層舊路徑相容 shim
  ui/             # 現有 PySide6 實作
```

## 3. 目前架構模型

目前專案遵守的邊界模型如下：

```text
clients -> integration -> game
                      -> challenge
                      -> content

game -> challenge
game -> content

challenge -> judge / analysis / contracts
content -> contracts
```

### 3.1 `challenge/`

用途：
- 負責單題提交流程與 challenge 級進度。
- 包含 `AppCore`、`JudgeFactory` 與 progress store 實作。

主要檔案：
- `src/block2python/challenge/app_core.py`
- `src/block2python/challenge/judge_factory.py`
- `src/block2python/challenge/progress.py`

### 3.2 `content/`

用途：
- 負責從 `assets/levels/` 與 `assets/game_content/` 載入並組裝遊戲內容。
- 持有 `GameSession` 會依賴的內容模型與 runtime helper。

主要檔案：
- `src/block2python/content/levels_loader.py`
- `src/block2python/content/loader.py`
- `src/block2python/content/models.py`
- `src/block2python/content/runtime.py`

### 3.3 `game/`

用途：
- 負責遊戲層級的流程控制與 session state。
- `GameSession` 是預定的遊戲應用層主入口。
- `SaveGame` 應屬於這一層，不屬於 challenge 子系統。

主要檔案：
- `src/block2python/game/session.py`
- `src/block2python/game/savegame.py`

### 3.4 `integration/`

用途：
- 作為 Godot 等外部 consumer 的正式邊界。
- 未來承接 `GameState`、`PlayerAction`、序列化、dispatch 與 bridge adapters。

目前結構：

```text
src/block2python/integration/
  contracts/
  service/
  bridge_stdio/
  godot_adapter/
```

目前狀態：
- 已建立骨架。
- 在 contract 與 bridge 開工前，會刻意保持輕量。

### 3.5 `clients/`

用途：
- 放 consumer 端入口與 adapter。
- PySide6 與 CLI 在架構上屬於 client，不是遊戲規則來源。

目前結構：

```text
src/block2python/clients/
  cli/
  pyside6/
```

## 4. 舊路徑相容 package

以下 package 仍然存在，但現在應視為相容層或舊實作：

- `app/`
  - 轉發或 re-export 到新骨架。
  - 讓既有 import 在遷移期間仍可運作。
- `game_content/`
  - 轉發到 `content/` 的相容層。
- `ui/`
  - 現有 PySide6 實作仍保留在這裡。
  - `clients/pyside6/` 目前是 wrapper，而不是整批取代它。

遷移原則：
- 新功能應優先落在 `challenge/`、`content/`、`game/`、`integration/`、`clients/`。
- 舊 package 只應在維持相容或完成遷移時修改。

## 5. 資源結構

```text
assets/
<<<<<<< HEAD
  blockly/          # 內嵌 Blockly 頁面與 vendor 資源
  game_content/     # quest / node / scene / challenge 內容
  levels/           # level index 與各 level 規格
  wasm/             # python.wasm 與相關執行資源
=======
  README.md
  blockly/
    README.md
    index.html
    vendor/
  levels/
    index.yaml
    demo-1.yaml
    add-two-numbers.yaml
    demo-2.yaml
    fizzbuzz-simple.yaml
    cases/
>>>>>>> merge/judge_introduction_branch
```

補充：
- `assets/levels/` 仍是 challenge 執行所使用的 level 規格來源。
- `assets/game_content/` 是 quest/node 流程所用的遊戲內容來源。
- `assets/wasm/` 供 Wasm judge 路徑使用。

<<<<<<< HEAD
## 6. 工具與測試
=======
- 儲存關卡索引與範例關卡資料。
- `index.yaml` 作為目前題庫入口。
- 關卡檔已統一為 `.yaml`。
- `demo-1.yaml`、`add-two-numbers.yaml`、`demo-2.yaml`、`fizzbuzz-simple.yaml` 共同組成目前的 prototype flow。
>>>>>>> merge/judge_introduction_branch

`tools/` 內包含環境初始化、smoke run、UI 啟動與 Wasm 驗證腳本。

`tests/` 目前主要覆蓋：
- challenge 流程
- levels 載入
- game content 載入
- `GameSession` 流程
- 骨架與舊 import 相容性

## 7. 架構約束

以下規則代表目前預期的架構方向：

- Godot 不應直接 import `game/`、`challenge/` 或 `content/`。
- 外部前端應依賴 `integration/`。
- `GameSession` 是遊戲流程主入口。
- `AppCore` 維持 challenge 子系統定位，不應膨脹成整個遊戲總控。
- PySide6 是開發 client 與過渡前端，不是長期產品邊界。
