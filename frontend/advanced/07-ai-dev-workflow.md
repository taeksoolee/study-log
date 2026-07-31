# AI 활용 개발 워크플로 심화

> AI 코딩 도구를 실무에 효과적으로 활용하는 구체적 기법과 패턴을 정리합니다.

## 개요

[case-studies/12](../../case-studies/12-ai-dev-workflow.md)에서 AI 에이전트와의 협업 워크플로 개요를 다뤘다면, 이 문서에서는 **구체적인 기법과 패턴**에 집중한다.

---

## AI 코딩 도구 생태계 (2024~2025)

### 코드 자동완성

| 도구 | 특징 | 비고 |
|------|------|------|
| GitHub Copilot | VS Code 통합, 컨텍스트 기반 제안 | 가장 넓은 사용자층 |
| Cursor | AI-first 에디터, chat + compose 모드 | 다중 파일 동시 편집 |
| Codeium | 무료 대안, 다중 IDE 지원 | 빠른 응답 속도 |

**선택 기준**:
- 기존 IDE를 유지하고 싶다 → Copilot
- AI 중심 워크플로로 전환할 의향 → Cursor
- 비용 최소화 → Codeium

### AI 에이전트

| 도구 | 특징 |
|------|------|
| Claude Code (CLI) | 터미널 기반, 파일 수정·실행·테스트 자동화, CLAUDE.md로 규칙 설정 |
| Cursor Composer | IDE 내 다중 파일 편집, diff 기반 적용 |
| Devin / SWE-Agent | 자율 에이전트 (이슈→PR), 아직 실험적 단계 |

### MCP (Model Context Protocol)

AI가 외부 도구/데이터에 접근하는 **표준 프로토콜**.

- JSON-RPC 기반, Tool/Resource/Prompt 세 가지 primitives
- 활용 예: Supabase MCP(DB 조회), Vercel MCP(배포 관리), GitHub MCP(이슈/PR)
- 설정: [ai/mcp-setup.md](../../ai/mcp-setup.md) 참고

```json
{
  "mcpServers": {
    "supabase": {
      "command": "npx",
      "args": ["-y", "@supabase/mcp-server"],
      "env": { "SUPABASE_ACCESS_TOKEN": "your-token" }
    }
  }
}
```

---

## 프롬프트 엔지니어링 for 코드 생성

### 5가지 핵심 원칙

| # | 원칙 | 설명 |
|---|------|------|
| 1 | 명확한 컨텍스트 제공 | 기존 코드, 코딩 스타일, 기술 제약을 함께 전달 |
| 2 | 구체적인 아웃풋 형식 지정 | "TypeScript로", "함수형으로", "JSDoc 포함" |
| 3 | 단계별 분할 | 큰 작업을 작은 단위로 나눠서 요청 |
| 4 | 예시 기반 (Few-shot) | 원하는 결과물의 예시를 먼저 보여주기 |
| 5 | 제약 조건 명시 | "~하지 마" 보다 "~해"로 긍정형 지시 |

### 효과적인 프롬프트 패턴

#### 패턴 1: 기존 코드 기반 확장

```
"이 컴포넌트 구조를 유지하면서 페이지네이션 기능을 추가해줘.
기존 패턴: [코드 붙여넣기]
요구사항: 페이지당 10개, URL 파라미터로 상태 관리, props 인터페이스 유지"
```

→ 기존 코드를 보여주면 스타일·네이밍·패턴을 자동으로 따라간다.

#### 패턴 2: 리팩터링 요청

```
"이 코드를 Custom Hook으로 리팩터링해줘.
제약: 외부 인터페이스 변경 없이, 기존 테스트 통과 필수.
[리팩터링 대상 코드]"
```

→ "외부 인터페이스 변경 없이"라는 제약이 안전한 리팩터링을 유도한다.

#### 패턴 3: 테스트 생성

```
"이 함수의 테스트를 작성해줘. 프레임워크: Vitest.
포함: 정상 입력, 빈 배열, null/undefined, 경계값.
[테스트 대상 함수]"
```

→ 엣지 케이스를 명시적으로 나열하면 누락을 방지한다.

#### 패턴 4: 디버깅

```
"이 에러가 발생한다: [에러 메시지]
관련 코드: [코드]
재현 조건: API 응답이 늦을 때만 발생
원인과 수정을 제안해줘."
```

→ 에러 메시지 + 코드 + 재현 조건을 함께 주면 정확도가 크게 올라간다.

#### 패턴 5: 아키텍처 설계

```
"다음 요구사항에 맞는 폴더 구조와 모듈 분리를 제안해줘.
바로 코드를 작성하지 말고, 설계만 먼저.
요구사항: [목록]"
```

→ "코드 작성하지 말고"로 설계 단계를 분리한다.

---

## AI 코드 리뷰 자동화

### GitHub Actions + AI

```yaml
# .github/workflows/ai-review.yml
name: AI Code Review
on:
  pull_request:
    types: [opened, synchronize]
jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: coderabbitai/ai-pr-reviewer@latest
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
```

### AI 리뷰가 감지하는 것

| 카테고리 | 예시 |
|----------|------|
| 보안 취약점 | SQL 인젝션, XSS, 하드코딩된 시크릿 |
| 성능 이슈 | 불필요한 리렌더, N+1 쿼리, 메모리 릭 |
| 컨벤션 위반 | 네이밍 규칙, import 순서, 미사용 변수 |
| 버그 가능성 | 레이스 컨디션, off-by-one, null 체크 누락 |

### 도구

| 도구 | 특징 |
|------|------|
| CodeRabbit | 가장 상세한 리뷰, 컨텍스트 이해 우수 |
| Sourcery | Python 특화, 리팩터링 제안 |
| GitHub Copilot PR Review | GitHub 네이티브 통합 |

---

## AI와 효과적으로 협업하는 패턴

### Plan → Review → Implement → Verify (PRIV)

```
┌────────┐    ┌────────┐    ┌────────────┐    ┌────────┐
│  Plan  │ →  │ Review │ →  │ Implement  │ →  │ Verify │
│ 계획   │    │ 검토   │    │ 단계별구현 │    │ 테스트 │
└────────┘    └────────┘    └────────────┘    └────────┘
```

1. **Plan**: AI에게 바로 코드 X → 먼저 계획을 세우게 한다
2. **Review**: AI 계획을 검토하고 방향 수정
3. **Implement**: 확정된 계획에 따라 단계별 구현 요청
4. **Verify**: 각 단계 결과를 테스트로 검증

```
// 나쁜 예: "로그인 기능 만들어줘"
// 좋은 예: "로그인 기능을 구현하려고 해. 필요한 컴포넌트, 상태,
//          API 호출의 목록과 순서를 정리해줘. 코드는 아직 작성하지 마."
```

### 점진적 정제 (Iterative Refinement)

```
1차: "유저 목록 컴포넌트를 만들어줘"
2차: "여기에 검색 필터를 추가해줘"
3차: "검색은 debounce 적용하고, 빈 상태 UI도 추가해줘"
4차: "이 컴포넌트의 테스트를 작성해줘"
```

한 번에 모든 요구사항을 넣지 않고, 동작하는 기본부터 점진적으로 확장.

### 컨텍스트 관리 전략

#### 프로젝트 규칙 파일 활용

```markdown
<!-- CLAUDE.md / .cursorrules -->
## 프로젝트 컨벤션
- TypeScript strict, 함수형 컴포넌트 + hooks
- 상태관리: Zustand / 스타일: Tailwind / 테스트: Vitest
- any 금지, console.log 커밋 금지
```

#### 컨텍스트 최적화

- ✅ 관련 파일만 선택적 포함 + 타입 정의 함께 제공
- ❌ 프로젝트 전체 덤프 / 관련 없는 파일 / 이전 대화 맥락 의존

---

## AI 활용의 한계 & 주의점

### 할 수 있는 것

- 보일러플레이트 생성 (CRUD, form, 설정 파일)
- 패턴 기반 코드 작성 (기존 패턴 따르는 새 모듈)
- 테스트 케이스 생성 (유닛 테스트, 엣지 케이스 도출)
- 문서화 (JSDoc, README, API 문서)
- 리팩터링 제안 / 디버깅 보조

### 주의해야 할 것

1. **생성 코드 맹신 금지** — 반드시 검증할 것:

```typescript
// AI가 생성한 debounce — 동작하는 것 같지만...
function debounce(fn: Function, delay: number) {
  let timer: NodeJS.Timeout;
  return (...args: any[]) => {
    clearTimeout(timer);
    timer = setTimeout(() => fn(...args), delay);
  };
}
// 문제: 타입 안전성 없음, this 바인딩 누락, 취소 기능 없음
```

   타입 정확성, 엣지 케이스, 메모리 릭, 에러 핸들링 모두 확인
2. **최신 정보 부정확** — 학습 데이터 이후 변경된 API, 공식 문서로 최종 확인
3. **보안 코드는 전문가 리뷰 필수** — 인증/인가, 암호화, 접근 제어 정책
4. **비즈니스 로직은 개발자가 판단** — "기능이 비즈니스적으로 맞는가"는 AI가 판단 못함
5. **라이선스 이슈** — AI 생성 코드 저작권 불명확, 회사 정책 확인 필요

---

## 실전 워크플로 예제

### 예제 1: 새 기능 개발

```
1. 요구사항 정리 — AI와 대화로 명확화, 빠진 것 질문받기
2. API 인터페이스 설계 — AI 제안 → 검토 → 확정
3. 구현 — AI 생성 → 수정 → 테스트 작성/실행
4. 리뷰 — AI 코드 리뷰(1차) → 사람 최종 확인
```

### 예제 2: 레거시 리팩터링

```
1. 기존 코드 분석 요청 — 상태/사이드이펙트 목록화
2. 리팩터링 계획 수립 — 제약 명시 (테스트 통과, 인터페이스 유지)
3. 단계별 변환 — 각 단계마다 테스트 실행으로 회귀 확인
4. 회귀 테스트 — 전체 테스트 스위트 + E2E 시나리오 확인
```

---

## 면접 포인트

### Q1: "AI 도구를 개발에 어떻게 활용하고 있나요?"

```
답변 프레임워크:
1. 어떤 도구를 어떤 용도로 (도구명 + 구체적 활용)
2. 워크플로에 어떻게 녹였는지 (프로세스)
3. 생산성 향상 체감 사례 (구체적 숫자/예시)
```

- "코드 생성"만이 아닌 다양한 활용 언급 (리뷰, 테스트, 문서화, 디버깅)
- PRIV 패턴 등 자신만의 방법론이 있으면 좋다

### Q2: "AI가 생성한 코드의 품질을 어떻게 보장하나요?"

- 자동화된 검증 (테스트, 린트, 타입체크)
- 단계별 검증, AI 1차 리뷰 → 사람 최종 리뷰

### Q3: "AI 활용의 한계는 무엇이라고 생각하나요?"

- 비즈니스 로직 판단은 사람 영역
- 보안/인증 코드 전문가 리뷰 필수
- "도구를 사용하되 의존하지 않는" 태도

### Q4: "프롬프트 엔지니어링에서 중요한 것은?"

- 컨텍스트의 질 = 결과의 질
- 제약 조건 명시 + 단계별 분할 + 기존 패턴 예시 제공

---

## 참고 자료

### 공식 문서
- [GitHub Copilot Docs](https://docs.github.com/en/copilot)
- [Cursor Docs](https://docs.cursor.com)
- [Model Context Protocol Spec](https://modelcontextprotocol.io)
- [Claude Code Docs](https://docs.anthropic.com/en/docs/claude-code)

### 아티클
- "Prompt Engineering for Developers" — OpenAI
- "AI-Enhanced Development Workflows" — Vercel Blog
- "The AI Coding Assistant Landscape" — ThoughtWorks Tech Radar

### 관련 문서 (이 프로젝트)
- [case-studies/12 — AI 에이전트와 협업하는 개발 워크플로](../../case-studies/12-ai-dev-workflow.md)
- [ai/mcp-setup.md — MCP 연결 가이드](../../ai/mcp-setup.md)

---

> **핵심 요약**: AI 도구는 "개발자를 대체"하는 것이 아니라 "개발자의 생산성을 증폭"하는 도구다.
> 명확한 지시, 단계별 검증, 최종 판단은 사람이 한다는 원칙을 지켜야 한다.
