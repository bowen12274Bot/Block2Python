# 系統架構圖

> 更新日期：2026-03-18
> 相關文件：[technical_rationale.md](../technical_rationale.md)

## 架構總覽

![Block2Python system architecture](system_architecture.png)

## 分層元件圖

```mermaid
graph TB
    subgraph CLIENTS["Clients Layer"]
        direction TB
        PySide6["PySide6 Client"]
        CLI["CLI Demo Client"]
        Godot["Future Godot Client"]
    end

    subgraph INTEGRATION["Integration Layer"]
        direction TB
        Contracts["Game Contracts\nGameState / PlayerAction"]
        Dispatcher["Dispatch Service"]
        Bridge["Bridge Adapter\nstdio / future transport"]
        GodotAdapter["Godot Adapter"]
        Contracts --> Dispatcher
        Dispatcher --> Bridge
        Dispatcher --> GodotAdapter
    end

    subgraph GAME["Game Layer"]
        direction TB
        Session["GameSession"]
        SaveGame["SaveGame"]
        Runtime["Game Runtime"]
        Session --> SaveGame
        Session --> Runtime
    end

    subgraph CONTENT["Content Layer"]
        direction TB
        Levels["Levels Loader"]
        GameContent["Game Content Loader"]
        Models["Content Models / Assembly"]
        Levels --> Models
        GameContent --> Models
    end

    subgraph CHALLENGE["Challenge Layer"]
        direction TB
        AppCore["AppCore"]
        Progress["Progress Store"]
        JudgeFactory["Judge Factory"]
        AppCore --> Progress
        AppCore --> JudgeFactory
    end

    subgraph EXEC["Execution Layer"]
        direction TB
        Analyzer["Analysis"]
        Judge["Judge"]
        Wasm["Wasm Runner"]
        Judge --> Wasm
    end

    CLIENTS --> INTEGRATION
    INTEGRATION --> GAME
    GAME --> CONTENT
    GAME --> CHALLENGE
    CHALLENGE --> Analyzer
    CHALLENGE --> Judge
```

## Action Flow
```mermaid
sequenceDiagram
    participant Client as Client / Future Godot
    participant Bridge as bridge_stdio
    participant Contracts as GameState / PlayerAction
    participant Dispatcher as dispatch()
    participant Session as GameSession
    participant Core as AppCore / Judge

    Client->>Bridge: JSON request
    Bridge->>Contracts: deserialize PlayerAction
    Contracts-->>Bridge: PlayerAction
    Bridge->>Dispatcher: dispatch(session, action)

    alt advance
        Dispatcher->>Session: advance()
    else submit_level
        Dispatcher->>Session: submit_current_level(...)
        Session->>Core: submit(...)
        Core-->>Session: SubmitOutcome
    end

    Session->>Contracts: current_game_state()
    Contracts-->>Bridge: GameState
    Bridge->>Contracts: serialize GameState
    Contracts-->>Bridge: JSON-ready state
    Bridge-->>Client: JSON response
```

- client 只送 `PlayerAction`
- dispatcher 只做 action 到 session 的轉接
- `GameSession` 負責真正的流程推進
- `bridge_stdio` 只負責 JSON stdin/stdout 運輸

## Package 對照

| Package | 角色 |
|---------|------|
| `block2python.clients` | PySide6 與 CLI consumer |
| `block2python.integration` | 對外 contract 與 bridge 邊界 |
| `block2python.game` | 遊戲主流程控制 |
| `block2python.content` | levels 與 game content 載入 |
| `block2python.level_play` | level submit 與 progress 子系統 |
| `block2python.analysis` | 靜態分析服務 |
| `block2python.judge` | judge 實作與 Wasm 執行 |

## 目前狀態

目前已完成：
- `level_play/`、`content/`、`game/`、`integration/`、`clients/` 骨架
- `game/` 內的 `GameSession`
- `level_play/` 內的 `AppCore`
- `content/` 內的 loaders
- `clients/` 內的 PySide6 與 CLI wrapper
- `app/` 與 `game_content/` 的相容 shim

目前僅預留、尚未完整實作：
- 正式 `integration/contracts` models
- dispatcher logic
- stdio bridge server
- Godot adapter 行為

## 架構解讀

- `GameSession` 是預定的遊戲主入口。
- `AppCore` 是 challenge 子系統，不是整個遊戲總控。
- `integration/` 是外部前端應依賴的正式邊界。
- `clients/` 是 consumer，不應定義遊戲模型本身。
- `app/`、`game_content/`、`ui/` 是過渡期保留的相容路徑。
