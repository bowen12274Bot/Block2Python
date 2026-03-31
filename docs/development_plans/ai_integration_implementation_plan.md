# AI 助理串接實施計畫

- 文件版本：0.3
- 日期：2026-03-30
- 相關規格文件：
  - `docs/development_plans/ai_tutor_skills_plan.md`
  - `docs/product/worldbuilding.md`
  - `docs/requirements/gameplay_requirements.md`
  - `docs/development_plans/game_architecture_transition_plan.md`
  - `docs/specs/levels_schema_v0_1.md`

## 0. 概述

本文件基於既有的 `ai_tutor_skills_plan.md`，進一步明確化 AI 教練系統的實施路線、技術決策、與工作分解。

### 0.1 核心原則（引自既有SPEC）

- **分離原則**：開發用 skills (`.agent/skills/`) vs 教學用 skills (`assets/teaching_skills/`) 嚴格分離
- **結構化為主**：不用巨大自由 prompt，以結構化檢索與上下文組裝為主
- **提示優先**：AI 應給提示、階梯式引導，而非直接完整解答
- **內容驅動**：邏輯寫在 teaching skills JSON，不寫死在 Python 程式碼

### 0.2 角色定位（引自 worldbuilding.md）

- **Byte**：協助學生學習的 AI 小幫手，代表「輔助工具不應代替人類理解」的價值觀
- **不應做的**：直接提供完整解答、引入超綱概念、接受要求放棄思考

### 0.3 實作狀態快照（2026-03-30）

- Phase 1：已完成（本地 selector 已接入 OpenAI-compatible 推理路徑，可對接 Ollama）
- Phase 2：已完成（核心服務、Provider、契約、測試可用）
- Phase 3：已完成（Godot UI 串接、QA 與 demo 驗證完成）
- Phase 4：尚未開始（高階邊界強化與遠端 LLM 品質工程）

## 1. 架構決策

### 1.1 層級決策

**決策項**：AI 助教在遊戲系統中的層級

根據 `game_architecture_transition_plan.md` 的待決事項，提議如下架構：

```
┌─ Godot Client (game_flow)
│  └─ ChallengeScreen
│     ├─ BlocklyEditor
│     ├─ CodeEditor
│     ├─ FeedbackPanel
│     └─ TutorPanel ◄─── 新增
│
├─ Backend (block2python)
│  ├─ LevelService (負責載入 LevelSpec + teaching_skill_ids)
│  └─ ai/TutorService (新增)
│     ├─ TeachingSkillLoader (載入 assets/teaching_skills/)
│     ├─ ContextBuilder (組裝 tutor context)
│     ├─ Policy (決定回覆邊界)
│     └─ Provider (呼叫本地輕模型或 OpenAI 相容供應商)
│
└─ Content Layer
   └─ assets/teaching_skills/
      ├─ index.json
      ├─ input-output-basics.json
      └─ ...
```

**決策**：
- TutorService 在 backend 層（Python），Godot 透過 API 呼叫
- Teaching skills 存放於 assets，由 TutorService 載入
- Level 新增 `teaching_skill_ids` 欄位關聯
- 支援單關卡對話歷史，並提供歷史壓縮機制（避免 token 膨脹）

### 1.2 LLM Provider 選型

**決策項**：AI 模型供應商選擇

根據最新決策，採用「可預期模板回覆 + 本地輕模型選模板 + OpenAI 相容介面」路線：

| Phase | 方案 | 用途 | 特點 |
|-------|------|------|------|
| 1-2 | `TemplateTutorProvider` + `LocalTemplateSelector (Qwen3.5:0.8b)` | 保持可預期回覆，且可接聊天框 | 模板輸出穩定；本地模型只負責選模板/提示層級 |
| 2-3 | `OpenAICompatibleProvider` | 使用 OpenAI API 相容格式 | 可切 OpenAI/其他相容供應商 |
| 4+ | 多供應商路由 | 供應商備援與品質優化 | 可動態切換模型與端點 |

**已定項目**：
- [x] 先實作 OpenAI API 相容寫法（Provider 可替換）
- [x] 前端提供供應商選擇 + API KEY 設定介面
- [x] API KEY 採本地檔案明文保存（單機使用場景）
- [x] 不做配額限制，但要顯示費用資訊
- [x] 錯誤重試策略：retry 3 次後回覆使用者「目前無法使用」
- [x] 回傳可使用預設友好回應（friendly fallback）
- [x] 請求總限時 60 秒，並使用串流輸出與前端可取消請求

備註：Stub 與 Template 皆保留；Template 為主要產品路徑，Stub 供測試與除錯。

## 2. 資料模型設計

### 2.1 Teaching Skill Schema

**檔案位置**：`assets/teaching_skills/<skill-id>.json`（簡潔單層布局，見 5.1 版本策略）

**完整 Schema**（引自 ai_tutor_skills_plan.md，已完善）：

```json
{
  "skill_id": "string (e.g. 'input-output-basics')",
  "title": "string",
  "description": "string (optional)",
  
  "applies_to": {
    "level_ids": ["string"],
    "concepts": ["string"]
  },
  
  "student_level": "beginner | intermediate | advanced",
  "learning_goals": ["string"],
  
  "allowed_concepts": ["string"],
  "forbidden_concepts": ["string"],
  
  "hint_ladder": [
    "string (第一層提示 - 最寬鬆)",
    "string (第二層提示)",
    "string (第三層提示 - 最具體)"
  ],
  
  "common_mistakes": [
    {
      "pattern": "string (常見錯誤型式)",
      "diagnosis": "string (診斷說明)",
      "hint": "string (回覆提示)"
    }
  ],
  
  "refusal_rules": [
    "string (例：不要直接提供完整最終解答)",
    "string (例：不要引入超出 allowed_concepts 的新概念)"
  ],
  
  "answer_style": {
    "tone": "clear | friendly | formal",
    "max_steps": 3,
    "max_response_length": 500
  }
}
```

**範例**：見 Section 6.1

### 2.2 Tutor Request / Response Models

**Python dataclass（暫定位置）**：`src/block2python/ai/models.py`

```python
@dataclass
class TutorRequest:
    """AI 助教請求物件"""
    level_id: str
    provider: str  # "local" | "openai_compatible"
    user_question: str
    current_code: str
    current_blocks: dict  # 或 BlockJSON
    conversation_id: Optional[str] = None
    conversation_history: Optional[List[dict]] = None
    history_summary: Optional[str] = None
    analysis_result: Optional[AnalysisResult] = None
    judge_result: Optional[JudgeResult] = None
    submission_history: Optional[List[str]] = None

@dataclass
class TutorResponse:
    """AI 助教回覆物件"""
    reply_type: Literal[
        "concept_explanation",    # 概念解釋
        "next_step_hint",         # 下一步提示
        "debug_hint",             # 除錯提示
        "scope_refusal",          # 超綱拒答
        "solution_refusal"        # 解答拒答
    ]
    content: str
    metadata: dict = field(default_factory=dict)  # 可選的額外訊息
```

### 2.3 Tutor Context 物件

**目的**：標準化 AI 助教回覆前的上下文組裝

```python
@dataclass
class TutorContext:
    """AI 助教上下文（由 ContextBuilder 組裝）"""
    
    # 關卡身分
    level_id: str
    level_title: str
    level_prompt: str
    
    # 教學內容
    learning_markdown: str
    learning_goals: List[str]
    
    # Teaching Skill 內容
    teaching_skill_id: Optional[str]
    allowed_concepts: Set[str]
    forbidden_concepts: Set[str]
    hint_ladder: List[str]
    common_mistakes: List[dict]
    refusal_rules: List[str]
    answer_style: dict
    
    # 學生狀態
    student_question: str
    current_code: str
    current_blocks: dict
    
    # 系統訊號
    analysis_status: str
    analysis_violations: Optional[List[str]]
    judge_status: str
    failed_cases_summary: Optional[str]
```

### 2.4 Level Schema 擴充

**重要**：因為 `assets/levels/` 已統一為 YAML 格式（見 `docs/specs/levels_schema_v0_1.md`），教學技能 ID 應直接在 YAML level 檔新增，而不是修改 JSON schema 文件。

**修改檔案**：每個 `assets/levels/<level>.yaml` 檔案

應在現有 YAML level 定義新增以下欄位：

```yaml
level_id: group-01-demo
title: "..."

teaching_skill_ids:
  - input-output-basics

tutor_policy:
  allow_full_solution: false
  max_hint_steps: 3
  response_tone: clear

# 既有欄位保持不變
prompt: "..."
learning_markdown: "..."

**載入整合**：`LevelsLoader` 應在 YAML 解析時將 `teaching_skill_ids` 與 `tutor_policy` 納入 `LevelSpec` 物件，以便 `TutorService` 後續查詢

## 3. 系統元件設計

### 3.0 依賴管理與初始化

TutorService 由 4 個主要依賴組成，建議採用以下初始化方式（暫時不用 DI 框架）：

```python
# 建構時依賴推導
skill_loader = TeachingSkillLoader(skills_dir=Path("assets/teaching_skills"))
context_builder = TutorContextBuilder(
    skill_loader=skill_loader,  # 傳入相同 loader 以保持一致快取
    analyzer=ast_analyzer  # 可選，用於 policy 檢查
)

tutor_service = TutorService(
    skill_loader=skill_loader,
    context_builder=context_builder,
    policy=TutorPolicy(),
    provider=LocalTemplateSelector(
        template_provider=TemplateTutorProvider(),
        model_name="qwen3.5:0.8b",
        endpoint_url="http://127.0.0.1:11434/v1/chat/completions",
    )
)
```

**決策**：
- 不引入 DI 框架，先以手動建構維持可讀性與低複雜度
- 使用全域單例 `tutor_service`（singleton）供全系統共用

### 3.1 Teaching Skill Loader

**檔案**：`src/block2python/ai/teaching_skill_loader.py`

**責任**：
- 從 `assets/teaching_skills/` 載入 JSON 檔案
- 驗證 schema 合法性
- 快取已載入的 skills
- 提供查詢介面（by skill_id、by level_id、by concept）

**公開 API**：

```python
class TeachingSkillLoader:
    def load_skill(self, skill_id: str) -> TeachingSkill: ...
    def load_skills_for_level(self, level_id: str) -> List[TeachingSkill]: ...
    def find_skills_by_concept(self, concept: str) -> List[TeachingSkill]: ...
    def validate_skill_file(self, file_path: str) -> bool: ...
```

### 3.2 Context Builder

**檔案**：`src/block2python/ai/context_builder.py`

**責任**：
- 從 Level、Submission、Analysis、Judge 組裝 TutorContext
- 確保 teaching_skill 正確關聯
- 抽取關鍵訊號（syntax errors、failed cases、constraints）

**公開 API**：

```python
class TutorContextBuilder:
    def build(
        self,
        level: LevelSpec,
        submission: Submission,
        analysis_result: Optional[AnalysisResult] = None,
        judge_result: Optional[JudgeResult] = None,
        question: str = ""
    ) -> TutorContext: ...
```

### 3.3 Policy Layer

**檔案**：`src/block2python/ai/policy.py`

**責任**：
- 決定回覆類型（concept_explanation、next_step_hint、debug_hint、拒答）
- 套用 refusal_rules 與 allowed/forbidden concepts
- 決定要回傳哪一層 hint_ladder

**公開 API**：

```python
class TutorPolicy:
    def determine_reply_type(
        self,
        context: TutorContext,
        question: str
    ) -> str: ...
    
    def get_allowed_content(
        self,
        context: TutorContext
    ) -> dict: ...
    
    def check_refusal_triggers(
        self,
        context: TutorContext,
        question: str
    ) -> Optional[str]: ...
```

### 3.4 Provider 抽象層

**檔案**：`src/block2python/ai/providers/base.py`

**責任**：
- 定義 provider 介面
- 支援多種實作（測試 stub、模板回覆、本地模板選擇器、OpenAI 相容供應商）

**公開 API**：

```python
class TutorProvider(ABC):
    @abstractmethod
    async def reply(
        self,
        context: TutorContext,
        reply_type: str
    ) -> TutorResponse: ...

class StubTutorProvider(TutorProvider):
    """完全可預期的測試回覆"""
    async def reply(...) -> TutorResponse: ...

class TemplateTutorProvider(TutorProvider):
    """固定模板產生最終回覆，確保可預期"""
    async def reply(...) -> TutorResponse: ...

class LocalTemplateSelector(TutorProvider):
    """本地輕模型（例如 qwen3.5:0.8b）只負責選模板 ID / hint 層級"""
    async def reply(...) -> TutorResponse: ...

class OpenAICompatibleProvider(TutorProvider):
    """OpenAI API 相容供應商（可接 OpenAI 或相容端點）"""
    async def reply(...) -> TutorResponse: ...
```

### 3.5 Tutor Service（公開入口）

**檔案**：`src/block2python/ai/service.py`

**責任**：
- 對外提供簡潔的 tutor 入口
- 協調各元件工作流
- 錯誤處理與超時管控

**公開 API 與完整實作樣版**：

```python
import asyncio
from typing import Optional
import logging

logger = logging.getLogger(__name__)

class TutorService:
    TOTAL_TIMEOUT_SEC = 60.0  # 單次請求總上限
    ATTEMPT_TIMEOUT_SEC = 30.0
    MAX_RETRY = 3
    
    def __init__(
        self,
        skill_loader: TeachingSkillLoader,
        context_builder: TutorContextBuilder,
        policy: TutorPolicy,
        provider: TutorProvider
    ):
        self.skill_loader = skill_loader
        self.context_builder = context_builder
        self.policy = policy
        self.provider = provider
    
    async def reply(
        self,
        level: LevelSpec,
        submission: Submission,
        question: str,
        analysis_result: Optional[AnalysisResult] = None,
        judge_result: Optional[JudgeResult] = None
    ) -> TutorResponse:
        """
        主要入口：組裝 context、套用 policy、呼叫 provider (with timeout)
        
        錯誤策略：
        - 若 teaching_skill 檔遺失: warning log，但不拋例外；改以空 skill list 繼續
        - 若 provider 超時 (>30s): 進入 retry（最多 3 次，受總時限 60s 約束）
        - retry 3 次仍失敗: 回傳「目前無法使用」
        - 若 retry 失敗: 可回傳 friendly fallback
        - 若 context_builder 失敗: 回傳 scope_refusal
        """
        try:
            # 1. 取得 teaching skills（含容錯）
            skill_ids = getattr(level, 'teaching_skill_ids', []) or []
            skills = self._load_skills_safe(skill_ids)
            
            # 2. 組裝 context
            context = self.context_builder.build(
                level=level,
                submission=submission,
                analysis_result=analysis_result,
                judge_result=judge_result,
                question=question,
                skills=skills  # 可能為空，context_builder 應 fallback
            )
            
            # 3. 判斷回覆類型
            reply_type = self.policy.determine_reply_type(context, question)
            
            # 4. 處理拒答
            if reply_type in ["scope_refusal", "solution_refusal"]:
                return self._handle_refusal(context, reply_type)
            
            # 5. 呼叫 provider (with timeout + retry + total deadline)
            last_error = None
            started = asyncio.get_event_loop().time()
            for attempt in range(1, self.MAX_RETRY + 1):
                if asyncio.get_event_loop().time() - started > self.TOTAL_TIMEOUT_SEC:
                    break
                try:
                    response = await asyncio.wait_for(
                        self.provider.reply(context, reply_type),
                        timeout=self.ATTEMPT_TIMEOUT_SEC
                    )
                    return response
                except Exception as e:
                    last_error = e
                    logger.warning(
                        f"Tutor provider failed (attempt={attempt}/{self.MAX_RETRY}) for level {level.level_id}: {e}"
                    )

            return TutorResponse(
                reply_type="scope_refusal",
                content="目前 AI 助教暫時無法使用，先給你一個方向：先檢查題目要求、輸入輸出與變數是否對齊。",
                metadata={"error": str(last_error), "error_code": "provider_unavailable", "fallback": "friendly_default"}
            )
                
        except Exception as e:
            logger.error(f"Unexpected error in tutor reply: {e}", exc_info=True)
            return TutorResponse(
                reply_type="scope_refusal",
                content="抱歉，系統發生內部錯誤，助教暫時無法回答。請回報開發團隊。",
                metadata={"error": str(e), "error_code": "internal_error"}
            )
    
    def _load_skills_safe(self, skill_ids: list[str]) -> list[TeachingSkill]:
        \"\"\"安全載入 skills，缺失只記警告，不拋例外\"\"\"
        skills = []
        for sid in skill_ids:
            try:
                skill = self.skill_loader.load_skill(sid)
                skills.append(skill)
            except FileNotFoundError:
                logger.warning(f"Teaching skill '{sid}' not found; skipping")
            except Exception as e:
                logger.warning(f"Error loading skill '{sid}': {e}")
        return skills
    
    def _handle_refusal(self, context: TutorContext, reply_type: str) -> TutorResponse:
        \"\"\"Handle refusal responses\"\"\"
        if reply_type == "scope_refusal":
            return TutorResponse(
                reply_type="scope_refusal",
                content="這個問題超出了被教學之外。你可以先學習上一章的內容。"
            )
        else:  # solution_refusal
            return TutorResponse(
                reply_type="solution_refusal",
                content="我不會直接給出答案，但我可以為你提供提示。請讓我知道你卡住的地方！"
            )
```

### 3.6 超時與錯誤策略

**超時設定**：
- `TutorService.reply()` 請求總上限：**60 秒**
    - 單次 attempt 上限：30 秒
    - 最多 retry 3 次，但受 60 秒總時限約束
    - 前端採串流輸出，避免長等待無回饋
    - 前端可隨時取消請求

**錯誤與 fallback**：

| 場景 | 處理方式 | 回傳結構 |
|------|---------|---------|
| teaching_skill 檔遺失 | 略過該 skill，log warning，skills list 可能為空 | 正常流程，context 會 fallback |
| Context builder 失敗 | 終止回覆流程，回傳 scope_refusal | `reply_type="scope_refusal"` |
| Provider 核心邏輯失敗 | 回傳系統內部錯誤訊息 | `reply_type="scope_refusal", error_code="internal_error"` |
| Provider 超時/網路錯誤 | retry 3 次，仍失敗則回覆不可用 | `metadata.error_code="provider_unavailable"` |
| Provider 不可用但需持續教學 | 回傳預設友好回應（方向提示） | `metadata.fallback="friendly_default"` |
| 內容違反 policy | 回傳 solution_refusal 或 scope_refusal | `reply_type="solution_refusal"` |
| 內部未知例外 | 記錄堆疊跡象，回傳安全訊息 | `error_code="internal_error"` |

**金鑰與費用策略**：
- API KEY 以本地檔案明文儲存（例如 user config 檔）
- 不做配額限制（學生自有金鑰）
- 後端保留 usage/cost 欄位回傳，前端顯示本次請求費用與累積費用
- 模型單價可由 OpenRouter 模型資料查詢（price per input/output token）並快取，後端依 usage 計算 request_cost

**對話歷史壓縮策略**：
- 目標：壓縮後保留約 **10K tokens**
- 觸發門檻：歷史超過 **20K tokens** 時啟動壓縮
- 壓縮方式：保留最近對話 + 舊歷史摘要（summary-based）
- 限制：僅單關卡內壓縮，不跨關卡合併

**錯誤契約對齊 SPEC**：
- 參考 `godot_client_contract_surface_v0_1.md` / `bridge_stdio_protocol_v0_1.md` 既有 envelope 風格
- 待在 `docs/development_plans/ai_tutor_api_contract.md` 明確化 tutor API 的 error mapping（如 `provider_unavailable`、`internal_error`）

**API 端點錯誤回應示例**：

```python
@router.post("/api/tutor/reply")
async def tutor_reply(request: TutorReplyRequest) -> dict | tuple:
    try:
        response = await tutor_service.reply(...)
        return {
            "reply_type": response.reply_type,
            "content": response.content,
            "metadata": response.metadata
        }, 200
    except Exception as e:
        logger.error(f"API error: {e}")
        return {"error": str(e), "error_code": "api_error"}, 500
```

## 4. UI 串接設計

### 4.1 Godot 客戶端側

**新增元件**：`godot_poc/scenes/tutor_panel.tscn`

**互動流程**：

```
┌─ ChallengeScreen
│  ├─ BlocklyEditor + CodeEditor
│  ├─ FeedbackPanel (既有)
│  └─ TutorPanel (新增)
│     ├─ OptionButton (AI Provider 選擇: local/openai-compatible)
│     ├─ LineEdit (API KEY 輸入)
│     ├─ Button (儲存設定到本地檔案)
│     ├─ TextEdit (問題輸入框)
│     ├─ Button (Ask Tutor)
│     ├─ Button (Cancel Request)
│     ├─ Label (本次請求費用)
│     ├─ Label (累積費用)
│     ├─ RichTextLabel (串流輸出區)
│     ├─ Label (回覆類型標記 - optional)
│     └─ TextEdit (回覆顯示區 - 唯讀)
```

**API 呼叫**：

```python
# Godot GDScript 等價虛擬碼
player_question = tutor_input.get_text()

# 向後端呼叫
POST /api/tutor/reply
{
    "level_id": "group-01-demo",
    "provider": "openai_compatible",
    "question": player_question,
    "current_code": code_editor.get_text(),
    "current_blocks": blockly_state,
    "conversation_id": current_conversation_id,
    "conversation_history": chat_history,
    "history_summary": chat_summary,
    "stream": true,
    "analysis_result": last_analysis,
    "judge_result": last_judge
}

# 回覆
{
    "reply_type": "next_step_hint",
    "content": "先想清楚你要先讀進來的值是什麼。",
    "metadata": {
        "usage": {"input_tokens": 123, "output_tokens": 48},
        "cost": {"request_cost": 0.00012, "accumulated_cost": 0.00231}
    }
}

# 在 UI 顯示
tutor_output.set_text(response.content)
if show_reply_type:
    type_label.set_text(f"[{response.reply_type}]")
```

### 4.2 後端 API 端點

**新增路由**：可整合到既有 API 系統中

```python
@router.post("/api/tutor/reply")
async def tutor_reply(request: TutorReplyRequest) -> TutorReplyResponse:
    """AI 助教回覆端點"""
    level = app_core.levels[request.level_id]  # AppCore 提供 levels dict
    submission = Submission(
        level_id=request.level_id,
        python_code=request.current_code,
        block_json=request.current_blocks
    )
    
    response = await tutor_service.reply(
        level=level,
        submission=submission,
        question=request.question,
        analysis_result=request.analysis_result,
        judge_result=request.judge_result
    )
    
    return TutorReplyResponse(
        reply_type=response.reply_type,
        content=response.content,
        metadata=response.metadata
    )
```

## 5. 內容管理策略

### 5.1 Teaching Skills 版本管理

**建議結構（簡潔單層）**：為避免路徑複雜化和 loader 邏輯分散，暫時採用扁平結構，版本號在 skill JSON 內部維護：

```
assets/teaching_skills/
├── README.md (說明檔與版本控制指南)
├── index.json (所有 skills 的中繼索引，可選)
├── input-output-basics.json
├── variables.json
├── conditionals.json
└── loops.json
```

**每份 skill 檔內部版本欄位**：

```json
{
  "skill_id": "input-output-basics",
  "version": "1.0",
  "title": "輸入輸出基礎",
  "applies_to": {...},
  ...
}
```

**實作優先級**：
1. 直接在 `assets/teaching_skills/` 放置 JSON 檔，loader 透過 glob 或直接指定名單載入
2. 若未來需要版本分支（v2+），再考慮引入子目錄結構（v1/、v2/），視需要升級 loader
3. `index.json` 可暫時不實作，改由程式碼在 level YAML 的 `teaching_skill_ids` 直接指定

### 5.2 內容審核流程

**建議**：
- Teaching skill 由教學設計 + 開發人員共同撰寫
- 新增或修改前應 review 是否：
  - 符合該關卡的教學目標
  - 遵守 allowed/forbidden concepts 邊界
  - Hint ladder 確實是梯級式漸進
  - 拒答規則清晰且有執行力
  - 測試是否會誤導或遺漏

### 5.3 初期範例 Skills

建議先實作 2-3 個示範 skills，驗證架構可行性：

1. **input-output-basics**：group-01-demo 關卡
2. **variables**：group-01-practice-01 關卡
3. **conditionals**：group-02-demo 關卡（待後續）

## 6. 分階段實施路線

### Phase 1: 定義教學技能內容與資料模型

**目標**：建立 teaching skill 的載入、驗證、查詢能力；確保 YAML level 檔與 tutor service 的資料流暢通

**交付清單**：

- [x] `TeachingSkillLoader` 實作完成（支援 glob 或名單載入）
- [x] Teaching skill JSON schema 定義與文件化
- [x] `assets/teaching_skills/` 目錄結構建立（扁平結構）
- [x] 至少 2 份示範 teaching skill 檔案（input-output-basics、variables）
- [x] `TemplateTutorProvider` 實作（最終文字輸出可預期）
- [x] `LocalTemplateSelector` 實作（預設 `qwen3.5:0.8b`，支援 OpenAI-compatible selector；失敗回退規則式）
- [x] 對話歷史資料結構與壓縮策略（summary-based）
- [x] **[協調項] levels_loader.py 修改計畫確認：** 如何在 YAML 解析時將 `teaching_skill_ids` 與 `tutor_policy` 納入 LevelSpec 物件
  - 策略 A (推薦)：仍由 levels_loader 負責，新增欄位解析邏輯
  - 策略 B (替代)：不改 levels_loader，改由 TutorService 層從 level.metadata 提取
- [x] **[協調項] API 契約同步：** Godot 與 Python 端應先確認 `/api/tutor/reply` 的 JSON 格式，避免 Phase 3 整合失敗
- [x] YAML level 檔新增 `teaching_skill_ids` 欄位（至少 group-01-demo.yaml）
- [x] `LevelSpec` 資料類型確認是否擴充（或用 metadata）
- [x] 單元測試覆蓋 loader 的正常與異常路徑：
  - 成功載入現存 skill
  - 缺失的 skill 檔遺失時的 fallback
  - 讀取 YAML 時 teaching_skill_ids 欄位的處理

**工期估計**：3-5 天 *(含 levels_loader 協調與測試)*

**驗收標準**：
- ```python
  skills = loader.load_skills_for_level("group-01-demo")
  assert len(skills) >= 1
  assert "allowed_concepts" in skills[0]
  assert "hint_ladder" in skills[0]
  ```
- levels_loader 正確解析 YAML 中的 teaching_skill_ids，且 LevelSpec 物件可查詢

### Phase 2: 實作可聊天的 Tutor Service（模板可預期 + 模型選模板）

**目標**：建立完整的 tutor 架構與策略層，支援模板輸出、本地選模板模型與 OpenAI 相容 provider，並支援對話歷史壓縮

**交付清單**：

- [x] `TutorContext`、`TutorRequest`、`TutorResponse` dataclass
- [x] `ContextBuilder` 完整實作
- [x] `TutorPolicy` 與 refusal rule engine
- [x] `StubTutorProvider`、`TemplateTutorProvider`、`LocalTemplateSelector`、`OpenAICompatibleProvider` 實作
- [x] retry 3 次 + 不可用回覆邏輯
- [x] friendly fallback 預設回應邏輯
- [x] 對話歷史壓縮器（例如摘要壓縮）
- [x] `TutorService` 主要協調邏輯
- [x] 完整單元測試（涵蓋各回覆類型、邊界情況）
- [x] API 端點實作

**工期估計**：5-7 天

**驗收標準**：
- Tutor 能根據 level + teaching skill 輸出合理的提示
- 不會輸出超綱內容
- 能正確偵測並拒答不適當請求
- API 可獨立測試，回覆穩定可重現

### Phase 3: UI 串接與本機 Demo

**目標**：建立玩家可見的 tutor UI 互動流程

**交付清單**：

- [x] Godot 端 TutorPanel 場景與腳本（整合於 `PracticeScreen` 的 AssistantPanel）
- [x] 輸入框、按鈕、輸出區 UI 件連接
- [x] API 呼叫邏輯（GDScript）
- [x] Provider 選擇 + API KEY 設定頁（本地檔案儲存）
- [x] 請求取消（Cancel Request）與串流輸出顯示
- [x] 費用顯示（本次/累積）
- [x] 回覆類型的 UI 標記與視覺區分
- [x] 本機 demo 流程驗證
- [x] QA 與使用者體驗測試

驗證紀錄：`docs/development_plans/ai_tutor_phase3_demo_qa.md`

**工期估計**：4-6 天

**驗收標準**：
- 玩家能在關卡中提問
- 助教回覆即時出現
- UI 清晰無誤，回覆內容可讀
- Demo 可展示完整流程

### Phase 4: 強化邊界與遠端 LLM 整合

**目標**：完善邊界控制，接入真實語言模型

**交付清單**：

- [ ] 擴充 `concept_policy` 與 AST 檢查整合
- [ ] `RemoteTutorProvider` 實作（選定供應商）
- [ ] LLM 提示詞設計與測試
- [ ] 錯誤重試、超時、配額控制
- [ ] 完整迴歸測試
- [ ] 效能監控與日誌記錄
- [ ] 文件與範例更新

**工期估計**：7-10 天

**驗收標準**：
- 遠端 LLM 回覆品質穩定
- 不會超綱或洩漏解答
- 系統穩定可用且成本可控
- 準備好進入 Beta 測試

## 7. 風險與緩解措施

| 風險 | 可能性 | 影響 | 緩解措施 |
|------|--------|------|---------|
| Teaching skill 內容品質不穩定 | 中 | 高 | 先以 Template 輸出保證可預期，再調整模板內容；嚴格的 review 流程 |
| LLM 費用不可預期 | 中 | 中 | 前端顯示每次請求與累積費用；提醒學生自行控管金鑰成本 |
| 邊界控制不足，AI 洩漏解答 | 低 | 高 | 建立 refusal rules 單元測試；定期安全審計；人工抽查 |
| UI 互動流程過於複雜 | 中 | 中 | 先固定核心流程（提問/串流/取消/費用）再疊加其他功能 |
| 系統延遲影響學習體驗 | 中 | 中 | 設定清晰的超時與重試策略；提前載入預熱 |
| **levels_loader 修改延遲** | **中** | **高** | Phase 1 一開始就提列協調清單；可先保守做法（檔案結構先不改） |
| **Godot 與 Python 序列化格式不同步** | **中** | **中** | 提早約定 API 契約 (JSON schema)；先提供 mock API 供 Godot 開發人員串接 |
| **Teaching skill 內容創建跟不上實作進度** | **中** | **中** | Phase 1～2 只編寫 1～2 份示範內容；足夠 demo 即可 |
| Provider 可用性 | 中 | 中 | 本地輕模型優先；遠端供應商失敗時 retry 3 次後顯示不可用 |
| **levels_loader 串接延遲** | 中 | 高 | Phase 1 即確認 levels_loader 修改路徑，若有爭議先用替代策略 B |
| **Godot/Python API 契約不一致** | 中 | 中 | 先定出 JSON Schema，Phase 2 結束前完成聯調驗證 |
| **LLM 幻覺 (Hallucination)** | 中 | 高 | 透過 policy layer 的 refusal rules 與 allowed_concepts 進行後處理攔截 |
| **API key 洩漏** | 中 | 高 | 僅允許本地檔案保存，UI 明確警示「請勿共用裝置帳號」 |

## 8. 相關協作項目

### 8.1 與既有模組的整合點

| 模組 | 整合方式 | 依賴性 | 優先順序 |
|------|---------|--------|---------|
| `LevelsLoader` | **[優先]** 須支援 YAML 中的 `teaching_skill_ids` 與 `tutor_policy` 欄位解析 | 強（Phase 1 阻斷項） | 1 |
| `LevelSpec` | 可選：直接新增欄位或由 TutorService 層從 metadata 提取 | 中（設計決策需確定） | 2 |
| `AnalysisResult` | TutorContext 會包含 analysis 結果用於 debug hints | 強（用於 debug hints） | 3 |
| `JudgeResult` | TutorContext 會包含 judge 結果用於失敗案例提示 | 中（用於失敗案例提示） | 3 |
| `API Router` | 提供 /api/tutor/reply 端點 | 強（Phase 3） | 4 |
| `AstAnalyzer` | Policy layer 可選用於邊界檢查（先 skip） | 弱（可選） | 5+ |
| `UserConfig` | 保存 provider 與 API KEY（本地檔案明文） | 強（Phase 3） | 4 |

### 8.2 與遊戲系統的協調

- **Game Architecture Plan**：確認 AI 層級決策（本文 1.1）
- **Story Presentation**：Byte 是否有特殊表情/動畫（待 UI/美術決策）
- **Data Model**：Level schema 擴充需要協調發布時機
- **Save/Load**：單關卡對話歷史先採記憶體保存；是否持久化到本地檔案待後續決策

### 8.3 跨客戶端協調

**Godot 與 Python 版本同步風險**：

前期應建立 API 契約 (JSON Schema) 作為 contract，讓 Godot 與 Python 端人員可獨立開發：

```python
# 建議 first draft
TutorReplyRequest = TypedDict({
    "level_id": str,
    "question": str,
    "current_code": str,
    "current_blocks": dict,
    "conversation_id": str,
    "conversation_history": list,
    "history_summary": str | None,
    "stream": bool,
    "analysis_result": dict | None,
    "judge_result": dict | None,
})

TutorReplyResponse = TypedDict({
    "reply_type": str,  # "concept_explanation" | "next_step_hint" | ...
    "content": str,
    "metadata": dict,  # {"error": ..., "error_code": ...}
})
```

**Godot 開發人員可先使用 mock API**（不依賴真實 backend），等 Phase 2 完成時切換至真實實作。

## 9. 測試策略

### 9.1 單元測試

**涵蓋範圍**：

```
tests/ai/
├── test_teaching_skill_loader.py
│   ├── test_load_skill_success
│   ├── test_load_skill_not_found
│   ├── test_load_skills_for_level
│   └── test_validate_skill_schema
├── test_context_builder.py
│   ├── test_build_with_skills
│   ├── test_build_without_skills (fallback)
│   └── test_extract_signals_from_analysis
├── test_policy.py
│   ├── test_determine_reply_type
│   ├── test_check_refusal_triggers
│   └── test_boundary_enforcement
├── test_template_provider.py
├── test_local_template_selector.py
├── test_openai_compatible_provider.py
├── test_history_compressor.py
└── test_service.py
    ├── test_reply_success
    ├── test_reply_retry_3_then_unavailable
    ├── test_reply_friendly_fallback
    ├── test_total_timeout_60s
    ├── test_reply_skill_missing
    └── test_reply_error_handling
```

**最低覆蓋率**：80%

### 9.2 整合測試

**端到端流程**：
- Level 載入 (YAML) → Teaching skill lookup → TutorContext 組裝 → Policy 判斷 → Provider 回覆
- 核心用例：student asking Q about concept → system returns hint

**邊界情況**（至少選 5 個測）：
- teaching_skill_ids 欄位缺失 (should fallback gracefully)
- skill 檔遺失 (should log warning, not crash)
- 超綱提問 (should detect and refusal)
- provider 超時 (should return timeout response)
- levels_loader 讀取失敗 (should 中止 fail-fast 策略於 Phase 1，未來 Phase 3 可加 graceful fallback)

**API 層測試**：
- POST /api/tutor/reply 端點呼叫正常
- 請求驗證與 400 響應
- 回應格式檢驗

### 9.3 人工測試清單

- [ ] LocalTemplateSelector（qwen3.5:0.8b）可正確決定模板與提示層級（已接入本地模型路徑，待人工端到端驗證）
- [x] Template provider 回覆固定且可預期
- [x] Stub provider 回覆固定且可預期
- [x] OpenAI compatible provider 可正常切換與回覆
- [x] API KEY 可從前端設定並保存到本地檔案
- [x] 費用資訊顯示正確（本次/累積）
- [x] 可取消請求，取消後 UI 不再接收串流片段
- [x] Godot UI 可正確輸入提問、顯示回覆
- [ ] 不同 teaching skill 之間的隔離良好（skill A 的 forbidden_concepts 不影響 skill B）
- [x] 超綱提問被正確拒絕（例如要求 import，但 allowed_concepts 不包含）
- [x] LevelSpec 從 YAML 載入時包含 teaching_skill_ids（驗證 levels_loader）
- [x] 如果沒有 teaching skill，系統仍可正常運作但不提供助教協助

### 9.4 安全審計清單（Phase 4）

- [ ] AI 回覆不會包含完整程式碼段落（refusal rules 執行力）
- [ ] AI 回覆不會超綱引入新概念（allowed_concepts 檢查）
- [ ] 多題提問情境下，context 仍保持單一關卡（不跨級汙染）

## 10. 文件需求

在實施過程中應持續更新以下文件：

- [x] `docs/development_plans/ai_integration_implementation_plan.md` (本文) - 主實施文件
- [x] `docs/specs/teaching_skill_schema.md` - Teaching skill JSON 詳細規格
- [x] `docs/development_plans/ai_tutor_api_contract.md` - Tutor API 與資料契約
- [x] `src/block2python/ai/README.md` - 開發者指南與架構說明
- [x] `docs/contributing/ai_tutor_guidelines.md` - 教學內容編寫指南

## 11. 決策記錄

### 決策 D1: 分離開發用 vs 教學用 Skills

**決策**：嚴格分離，教學用 skills 放在 `assets/teaching_skills/`，開發用放在 `.agent/skills/`

**理由**：
- 避免團隊開發提示污染學生教學體驗
- 教學內容應是版本控制的應用資料，不是工具流程

**備選方案**：
- 統一使用 `.agent/skills/`（被否決：會造成概念混淆）

### 決策 D2: 導入順序（模板可預期輸出 + 本地模型選模板）

**決策**：Phase 1-2 以 Template 輸出為主；本地輕模型（qwen3.5:0.8b）只負責選模板；同步建立 OpenAI API 相容 provider

**理由**：
- 模板輸出可保持教學口徑一致且可預期
- 本地輕模型可提供聊天框下的語境判斷（選模板）
- OpenAI API 相容層可保留供應商彈性
- 可同時滿足低成本試跑與未來擴充

### 決策 D3: 支援單關卡對話歷史與壓縮

**決策**：MVP 支援單關卡多輪對話歷史，並以摘要方式壓縮舊歷史

**理由**：
- 簡化架構與測試
- 避免上下文污染
- 關卡數有限，每關獨立提問是合理流程

**邊界**：不做跨關卡共用歷史，避免學習上下文污染

## 12. 常見問題 (FAQ)

**Q1: 為什麼要分離 teaching skills 和開發 skills？**

A: 教學 skills 是應用執行時的內容配置（應該與關卡、評估規則一起版本控制），而開發 skills 是開發團隊的工作流工具。混在一起會造成概念混淆，也容易讓團隊提示影響學生體驗。

**Q2: Phase 4 該選哪個 LLM 供應商？**

A: 暫時未決，待後續商務/技術評估。建議先完成 Phase 1-3，再基於成本、延遲、品質評估（OpenAI、Claude、本地 Llama 等都是候選）。

**Q3: 能否在 Phase 1 就接 LLM？**

A: 可以，而且本計畫已採用。Phase 1 會先接本地輕模型（qwen3.5:0.8b）作為模板選擇器，最終回覆仍由 Template provider 產生；並保留 OpenAI API 相容 provider 介面。

**Q4: Teaching skill 檔案格式能改嗎？**

A: 可以，但應在 Phase 1 確定，之後改動會影響已編寫的內容。建議在 phase 1 demo 時與教學設計人員共同定版。

**Q5: 如果玩家問超綱問題，系統怎麼回應？**

A: 根據 refusal_rules 判定是「超綱」(scope_refusal) 還是「要求完整解答」(solution_refusal)，回覆類型會不同，UI 可視需要標記。

---

## 附錄：Tentative Timeline

| Phase | 預期工期 | 起始時間 | 完成時間 | 主要交付 |
|-------|---------|---------|---------|---------|
| 1 | 3-5 天 | 2026-03-23 | 2026-03-30 | Teaching Skill Loader + 示範內容 |
| 2 | 5-7 天 | 2026-03-30 | 2026-04-10 | Tutor Service + Local/OpenAI-compatible providers |
| 3 | 4-6 天 | 2026-04-10 | 2026-04-20 | Godot UI 串接 + 本機 demo |
| 4 | 7-10 天 | 2026-04-20 | 2026-05-05 | 遠端 LLM 整合 + 品質測試 |

**注**：預估含審查、測試、文件。實際工期視人力分配與決策進度調整。
