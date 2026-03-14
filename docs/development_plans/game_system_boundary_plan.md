# 遊戲系統責任邊界計畫

- 文件版本：0.1
- 更新日期：2026-03-14
- 文件定位：定義遊戲前端、程式挑戰核心與橋接層的責任邊界

## 1. 目的

本文件用於防止後續實作時，將遊戲流程、挑戰核心與狀態管理混寫在同一層。

本文件先定義責任邊界，不預設最終引擎與承載技術細節。

## 2. 分層原則

系統拆為三層：

- 遊戲前端層
- 程式挑戰核心層
- Challenge Bridge / 整合層

## 3. 遊戲前端層責任

遊戲前端層負責：

- 節點式主地圖
- 劇情對話與場景切換
- 節點解鎖演出與流程推進
- 玩家操作入口
- 存檔入口、讀檔入口與流程恢復
- 將當前遊戲節點映射為應進入哪一個挑戰流程

遊戲前端層不負責：

- AST 分析
- Judge / 測資驗證
- Blockly / Python 提交的正確性判定
- 程式挑戰規則計算細節

## 4. 程式挑戰核心層責任

程式挑戰核心層負責：

- 挑戰資料載入
- 示範關與練習關的規格承載
- 積木 / Python 提交接收
- 程式分析與評測
- 工具包規則計算
- 電池能量規則計算
- 回傳標準化挑戰結果

程式挑戰核心層不負責：

- 節點式主地圖呈現
- 劇情對話與演出
- 全遊戲進度 UI
- 場景切換與導覽

## 5. Challenge Bridge 責任

Bridge 層負責：

- 接收遊戲前端傳來的節點 / 關卡上下文
- 啟動對應的 challenge flow
- 將玩家提交送入挑戰核心
- 接收挑戰結果並轉換成遊戲可用事件
- 協調存檔資料的讀寫

Bridge 層不負責：

- 自己實作完整遊戲流程
- 取代挑戰核心的分析與評測能力
- 取代遊戲前端的畫面呈現

## 6. 資料交換邊界

### 6.1 遊戲前端送入 Bridge 的資訊

- 當前節點 / 任務 ID
- 玩家當前存檔狀態摘要
- 要啟動的 challenge 類型
- 當前是否屬於示範關或支線練習關

### 6.2 Bridge 送入挑戰核心的資訊

- ChallengeSpec / LevelSpec 對應識別
- 玩家提交內容
- 工具包使用狀態
- 當前練習關上下文

### 6.3 挑戰核心回傳的資訊

- 分析結果
- 評測結果
- 單題是否通過
- 工具包是否使用
- 當前或最終電池能量結果
- 練習關整組是否成功

### 6.4 Bridge 回寫給遊戲前端 / 存檔的資訊

- 節點是否解鎖
- 練習關是否完成
- 冷卻是否啟動
- 哪些內容需要更新到存檔

## 6.5 最小 Request / Response 草案

### 遊戲前端 -> Bridge

```json
{
  "current_node_id": "practice-basic-io",
  "quest_id": "quest-basic-io-repair",
  "challenge_id": "challenge-practice-basic-io",
  "challenge_type": "practice",
  "save_snapshot": {
    "current_node_id": "practice-basic-io",
    "unlocked_node_ids": ["map-entry", "story-intro", "demo-basic-io", "practice-basic-io"],
    "completed_node_ids": ["story-intro", "demo-basic-io"]
  }
}
```

### Bridge -> 挑戰核心

```json
{
  "challenge_id": "challenge-practice-basic-io",
  "level_id": "practice-basic-io-02",
  "submission": {
    "python_code": "print(sum(map(int, input().split())))",
    "block_json": null
  },
  "practice_context": {
    "question_index": 1,
    "toolbox_used": false,
    "current_battery_percent": 20
  }
}
```

### 挑戰核心 -> Bridge

```json
{
  "analysis_status": "PASS",
  "judge_status": "AC",
  "question_passed": true,
  "toolbox_used": false,
  "reward_percent": 20,
  "battery_percent_after_submit": 40,
  "practice_run_completed": false,
  "practice_run_passed": false
}
```

### Bridge -> 存檔 / 遊戲前端

```json
{
  "save_updates": {
    "current_node_id": "practice-basic-io",
    "practice_run_state": {
      "question_index": 2,
      "battery_percent": 40,
      "completed": false,
      "passed": false
    }
  },
  "ui_event": "practice_question_passed"
}
```

## 7. 邊界判準

若某功能主要回答「玩家在遊戲世界裡看到什麼、去哪裡、切到哪個場景」，歸遊戲前端層。

若某功能主要回答「玩家提交的程式是否符合規則、能量如何計算、哪題通過」，歸程式挑戰核心層。

若某功能主要回答「遊戲怎麼呼叫挑戰核心、挑戰結果怎麼映射回遊戲進度」，歸 Bridge 層。

## 8. 下一步

- 以本文件為基準定義第一個 vertical slice 的資料流
- 以本文件為基準設計最小資料模型
- 後續若決定遊戲前端技術，僅調整承載方式，不改變責任邊界原則

## 9. 第一個 slice 的最小資料流

1. 玩家在主地圖選擇 `story-intro`
2. 遊戲前端讀取 `scene-city-alarm`，播放後切到 `demo-basic-io`
3. Bridge 啟動 `challenge-demo-basic-io`
4. 示範關完成後，Bridge 更新存檔並解鎖 `practice-basic-io`
5. 玩家進入 `practice-basic-io`
6. 每題提交後，Bridge 接收 challenge result，更新 `PracticeRunState`
7. 第 5 題結束後，Bridge 計算整組結果並切到 `result-basic-io`
8. 若成功，Bridge 解鎖 `next-main-node`
9. 若失敗，Bridge 寫入冷卻並保留 `practice-basic-io` 為可重試入口
