# 遊戲內容 Loader 計畫

- 文件版本：0.1
- 更新日期：2026-03-14
- 文件定位：定義第一階段遊戲化內容如何被載入，以及新 loader 與既有 challenge loader 的分工

## 1. 目的

本文件用於回答以下問題：

- 第一個 vertical slice 的 YAML 樣板之後要放在哪裡
- 遊戲內容是否應沿用既有 `levels_loader.py`
- 遊戲節點、劇情、challenge group、toolbox、battery 與存檔狀態應如何組裝

本文件先處理 loader 分工與落點，不處理最終遊戲前端技術。

## 2. 現況判斷

### 2.1 既有 loader 的責任

目前 `src/block2python/app/levels_loader.py` 負責：

- 載入 `assets/levels/` 內的 challenge 題庫
- 解析 `LevelSpec`
- 組裝 testcase、judge policy、analysis policy

這個 loader 的責任邊界目前是正確的，因為它聚焦在程式挑戰內容，而不是遊戲內容。

### 2.2 為什麼不直接擴充 `levels_loader.py`

若直接把遊戲節點、劇情場景、challenge group、toolbox、battery 與 quest 全部塞進既有 `levels_loader.py`，會產生以下問題：

- `LevelSpec` 與遊戲內容模型責任混在一起
- 後續難以區分「挑戰內容錯誤」與「遊戲內容錯誤」
- 遊戲節點與 challenge 題庫的版本節奏不同
- 未來若遊戲前端獨立，仍需要一層專門理解遊戲內容的 loader

因此，第一階段應保留 `levels_loader.py` 作為 challenge loader，而不是把它升格成遊戲總 loader。

## 3. 分層決策

第一階段的 loader 分成兩層：

### 3.1 Challenge Loader

責任：

- 載入 `assets/levels/`
- 產生 `LevelSpec`
- 驗證 testcase / judge / analysis 相關資料

現況：

- 直接沿用 `src/block2python/app/levels_loader.py`

### 3.2 Game Content Loader

責任：

- 載入節點、劇情、quest、challenge group、toolbox、battery 等遊戲內容
- 組裝 `NodeSpec`、`SceneSpec`、`QuestSpec`、`ChallengeSpec`
- 將 `ChallengeSpec.level_ids` 映射到 challenge loader 載入出的 `LevelSpec`

現況：

- 第一階段尚未實作，需新增

## 4. 第一階段檔案落點

### 4.1 文件樣板層

目前已存在的 `docs/specs/examples/`：

- 只作為規格樣板
- 不視為 runtime source of truth
- 用於驗證 schema 與欄位設計是否合理

### 4.2 Runtime 資料層

第一階段建議新增：

```text
assets/game_content/
  index.yaml
  quests/
  nodes/
  scenes/
  challenges/
  toolbox/
  battery/
```

說明：

- `assets/levels/` 繼續只放 challenge 題庫
- `assets/game_content/` 專門放遊戲層內容
- 避免把 `LevelSpec` 與遊戲節點資料混在同一個目錄

## 5. Index 設計

第一階段建議使用單一入口索引：

檔案：

- `assets/game_content/index.yaml`

至少包含：

- `quests`
- `nodes`
- `scenes`
- `challenges`
- `toolbox`
- `battery`

範例：

```yaml
quests:
nodes:
scenes:
  - file: scenes/scene-city-alarm.yaml
  - file: scenes/scene-practice-unlock.yaml
  - file: scenes/scene-result-success.yaml
  - file: scenes/scene-result-fail.yaml
challenges:
toolbox:
battery:
```

## 6. 建議模組落點

第一階段建議新增：

```text
src/block2python/game_content/
  __init__.py
  models.py
  loader.py
  errors.py
```

### 為什麼放這裡

- 它屬於新遊戲內容層，不應塞進 `app/`
- 它不是 UI 邏輯，不應放進 `ui/`
- 它不是 challenge judge / analysis，不應放進 `judge/` 或 `analysis/`
- 它和未來 `ChallengeEngine` / Bridge 的整合最密切，但本身仍應先維持獨立模組

## 7. Loader API 草案

### 7.1 Challenge Loader 維持不變

```python
levels = load_levels(Path("assets/levels"))
```

### 7.2 Game Content Loader

```python
game_content = load_game_content(Path("assets/game_content"))
```

回傳內容建議至少包含：

```python
GameContentBundle(
    quests=...,
    nodes=...,
    scenes=...,
    challenges=...,
    toolbox=...,
    battery_policies=...,
)
```

### 7.3 組裝層

之後由更高一層做：

```python
levels = load_levels(levels_dir)
game_content = load_game_content(game_content_dir)
bundle = assemble_game_slice(game_content=game_content, levels=levels)
```

這裡的 `assemble_game_slice(...)` 負責：

- 確認 `ChallengeSpec.level_ids` 都能在 `levels` 中找到
- 確認 node / scene / challenge 的引用關係正確

## 8. 驗證策略

第一階段先做三層驗證：

### 8.1 檔案格式驗證

- YAML 可讀
- 必填欄位存在
- 型別基本正確

### 8.2 引用關係驗證

- `NodeSpec.scene_id` 是否存在
- `NodeSpec.challenge_group_id` 是否存在
- `ChallengeSpec.level_ids` 是否對應到 `LevelSpec`
- `QuestSpec.node_ids` 是否都存在

### 8.3 最小切片驗證

- 入口節點可導到劇情節點
- 劇情節點可導到示範關
- 示範關可導到練習關
- 練習關可導到結果節點

## 9. 實作順序

1. 將 `docs/specs/examples/` 複製成 `assets/game_content/` 第一版 runtime 內容
2. 在 `src/block2python/game_content/` 建立 `models.py`
3. 建立 `loader.py`
4. 建立最小測試，驗證 index 與引用關係
5. 再決定是否需要把 loader 接進 runtime 組裝流程

## 10. 第一階段不先做的事

- 把遊戲內容併進既有 `assets/levels/`
- 讓 `levels_loader.py` 直接讀所有遊戲資料
- 一開始就建立完整通用 content pipeline
- 一開始就支援多章節、多城市與多分支

## 11. 建議結論

- `levels_loader.py` 保持 challenge loader 身分
- 新增獨立的 `game_content` 模組與 loader
- `docs/specs/examples/` 繼續作為規格樣板
- 第一版 runtime 遊戲資料應落在 `assets/game_content/`
