# block2python.ai 模組說明

本目錄提供 AI Tutor 的核心後端能力，包含：

- Teaching skill 載入與驗證
- Tutor context 組裝
- 回覆策略（policy）
- Provider 抽象與實作
- Tutor service 協調流程
- 對話歷史壓縮

## 1. 模組結構

- `models.py`：資料模型（TeachingSkill/TutorContext/TutorRequest/TutorResponse）
- `teaching_skill_loader.py`：teaching skill JSON 載入、驗證與查詢
- `context_builder.py`：將 level/submission/analysis/judge 組成 `TutorContext`
- `policy.py`：決定 reply type 與拒答規則
- `history.py`：對話歷史壓縮（summary-based）
- `providers/base.py`：
  - `TutorProvider`（抽象）
  - `StubTutorProvider`
  - `TemplateTutorProvider`
  - `LocalTemplateSelector`
  - `OpenAICompatibleProvider`
- `service.py`：`TutorService`，負責 end-to-end 協調

## 2. 執行流程

典型流程：

1. 由 `TeachingSkillLoader` 讀取 skill
2. `TutorContextBuilder` 整合 level + student 狀態
3. `TutorPolicy` 判斷 reply type
4. `TutorService` 呼叫 provider
5. 若 provider 失敗，套用 retry/fallback

## 3. TutorService 行為重點

- `TOTAL_TIMEOUT_SEC = 60.0`
- `MAX_RETRY = 3`
- provider 失敗時回傳安全 fallback（不直接丟出未處理例外）
- 缺失 skill 檔案時不中斷主流程，會在 metadata 註記

## 4. Provider 選擇

目前支援：

- `template`：固定模板，回覆可預期
- `stub`：測試用 deterministic provider
- `local`：本地選模板流程（目前由 `LocalTemplateSelector` 模擬）
- `openai_compatible`：OpenAI 相容協定

`openai_compatible` 需要：

- `endpoint_url`
- `model`
- `api_key`

## 5. 快速使用範例

```python
from pathlib import Path
import asyncio

from block2python.ai import (
    TeachingSkillLoader,
    TutorContextBuilder,
    TutorPolicy,
    TutorService,
    TemplateTutorProvider,
)
from block2python.contracts import LevelSpec, Submission

loader = TeachingSkillLoader(skills_dir=Path("assets/teaching_skills"))
service = TutorService(
    skill_loader=loader,
    context_builder=TutorContextBuilder(skill_loader=loader),
    policy=TutorPolicy(),
    provider=TemplateTutorProvider(),
)

level = LevelSpec(level_id="group-01-demo", title="Demo")
submission = Submission(level_id="group-01-demo", python_code="print(1)")

response = asyncio.run(
    service.reply(
        level=level,
        submission=submission,
        question="How should I start?",
    )
)
print(response.reply_type, response.content)
```

## 6. 測試

建議至少執行：

```powershell
c:/Users/tange/Desktop/all_project/比賽/Block2Python/.venv/Scripts/python.exe -m pytest tests/ai/test_teaching_skill_loader.py tests/ai/test_context_builder.py tests/ai/test_policy.py tests/ai/test_template_provider.py tests/ai/test_service.py
```

## 7. 契約與整合參考

- Tutor 請求/回應契約：`docs/development_plans/ai_tutor_api_contract.md`
- Teaching skill schema：`docs/specs/teaching_skill_schema.md`
- bridge 實作：`src/block2python/integration/bridge_stdio/server.py`
