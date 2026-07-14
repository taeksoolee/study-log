# Supabase · Vercel MCP 연결 가이드 (AI 에이전트 작업용)

배포·DB 상태를 AI 에이전트(Claude Code 등)로 **직접 조회·검증**하고 싶을 때,
**Supabase MCP** 와 **Vercel MCP** 를 붙이는 방법을 정리한다.

대표 활용 예시가 [Umami 셀프호스팅 셋업](../umami/README.md)이다 — 스키마 격리·권한·
테이블 생성 검증을 에이전트가 DB 를 직접 들여다보며 확인할 수 있다. 물론 그 외 어떤
Supabase/Vercel 프로젝트에도 동일하게 적용된다.

> **검증일: 2026-07-13.** 아래 엔드포인트·파라미터·인증 방식은 이 날짜에 Supabase /
> Vercel 공식 문서로 확인했다. 시간이 지났으면 [출처](#출처)를 재확인할 것.

---

## MCP 로 뭘 할 수 있나

| MCP | 활용 |
| --- | --- |
| **Supabase** | 스키마·테이블 생성 확인, 격리(권한/노출) 검증, DB 상태·통계 조회 |
| **Vercel** | 배포 상태·**빌드 로그 조회**로 배포 검증/디버깅을 에이전트에 맡길 때 |

**대개 Supabase MCP 만으로 충분하다.** DB 격리·권한·테이블 생성 검증이 핵심인 작업이면
Supabase MCP 가 실질적으로 도움이 된다. Vercel 은 배포 자체가 대시보드로 끝나므로, MCP 는
**AI 가 빌드 로그를 직접 읽고 배포를 디버깅해주길 원할 때만** 추가하면 된다.

---

## MCP 설정 방식 (Claude Code 기준)

Claude Code 는 프로젝트 루트의 **`.mcp.json`** 에 서버를 등록한다.

- 크리덴셜(토큰 등)이 들어가는 설정 파일은 **절대 커밋하지 않는다.**
  `.gitignore` 에 `.mcp.json` 을 넣거나, 크리덴셜을 **환경변수 참조**로만 두고 실제 값은
  별도의 gitignore 대상 파일(예: `.env.local`)에 둔다.
- 팀과 공유해야 한다면 **플레이스홀더만 든 템플릿**(예: `.mcp.example.json`)을 커밋하고,
  각자 로컬에서 실제 값을 채우는 방식을 권장한다.

> 크리덴셜 격리가 핵심이다. **토큰이 든 파일이 절대 git 에 올라가지 않도록** 먼저 확인할 것.

---

## 1. Supabase MCP (주력)

Supabase 공식 MCP 는 원격 HTTP 서버다. URL 쿼리 파라미터로 보안을 조인다.

### 1-1. 개인 액세스 토큰(PAT) 발급

Supabase Dashboard → **Account → Access Tokens** 에서 토큰을 생성한다.
(이 토큰은 계정 권한을 위임하므로 절대 커밋 금지)

### 1-2. `.mcp.json` 에 서버 추가

```json
{
  "mcpServers": {
    "supabase": {
      "type": "http",
      "url": "https://mcp.supabase.com/mcp?project_ref=<PROJECT_REF>&read_only=true&features=database,docs",
      "headers": {
        "Authorization": "Bearer <SUPABASE_ACCESS_TOKEN>"
      }
    }
  }
}
```

> `<PROJECT_REF>` / `<SUPABASE_ACCESS_TOKEN>` 은 실제 값이 커밋되지 않도록 주의한다.
> 환경변수 확장을 지원하는 설정이라면 `${SUPABASE_ACCESS_TOKEN}` 같은 참조로 두고
> 실제 값은 gitignore 대상 파일에 둔다.

보안 파라미터(권장):

- `read_only=true` — 읽기 전용 유저로 쿼리 실행. **기본으로 켠다.**
- `project_ref=<id>` — 특정 프로젝트로만 접근 제한.
- `features=database,docs` — 필요한 도구 그룹만 활성화(공격 표면 최소화).

> **파괴적 SQL(역할/스키마 생성 등)은 MCP 로 하지 말 것 (권장).** 그런 작업은
> Dashboard SQL Editor 에서 직접 실행하고, MCP 는 `read_only` 로 **검증·조회에만** 쓴다.
> (Umami 예시라면 [README 2단계](../umami/README.md#2단계--supabase-셋업) 참고)

---

## 2. Vercel MCP (선택 — 배포 로그 디버깅용)

> 배포는 fork → 대시보드 Import → push 자동배포로 충분하다. 이 MCP 는 **AI 가 빌드
> 로그/배포 상태를 직접 읽어 검증·디버깅하도록** 하고 싶을 때만 붙인다.

Vercel 공식 MCP 는 원격 HTTP + **OAuth** 방식이다. 토큰을 파일에 넣지 않고,
연결 시 브라우저 인증으로 승인한다.

### 2-1. `.mcp.json` 에 서버 추가

```json
{
  "mcpServers": {
    "vercel": {
      "type": "http",
      "url": "https://mcp.vercel.com"
    }
  }
}
```

- 별도 토큰 변수는 필요 없다 (OAuth 로 인증).
- ⚠️ 연결 시 **Vercel 사용자 계정과 동일한 접근 권한**을 에이전트에 부여하게 된다.
  공식 엔드포인트(`https://mcp.vercel.com`)가 맞는지 반드시 확인할 것.

---

## 3. 인증

`.mcp.json` 을 채운 뒤 Claude Code 에서 MCP 상태를 확인/인증한다.

```
/mcp
```

- **Supabase** — PAT 헤더로 즉시 인증되거나, 안내에 따라 승인.
- **Vercel** — 브라우저가 열리고 OAuth 승인 → 클라이언트별 명시적 동의가 필요하다.

---

## 보안 주의사항

- **프로덕션 조심.** Supabase MCP 는 되도록 **개발용 프로젝트**에 붙이고, 실데이터 접근 시
  `read_only=true` 를 켠다. (새 프로젝트를 쓰는 셋업 작업은 이 원칙과 잘 맞는다.)
- **최소 권한.** `project_ref` 로 프로젝트를 못박고, `features` 로 도구 그룹을 제한한다.
- **크리덴셜 격리.** PAT 등 토큰이 든 설정 파일은 커밋 금지. 커밋되는 건 플레이스홀더가
  든 템플릿뿐이어야 한다.
- **프롬프트 인젝션 인지.** 외부/신뢰 불가 입력이 MCP 도구를 악용해 데이터를 유출할 수 있다.
  워크플로에 **사람 확인(human confirmation)** 을 유지하고, 도구 호출 전에 검토한다.
- **공식 엔드포인트 확인.** Supabase `https://mcp.supabase.com/mcp`, Vercel `https://mcp.vercel.com`
  외의 "원클릭 설치" 링크는 도메인을 반드시 대조한다.

---

## 출처

- [Supabase – Model Context Protocol (MCP)](https://supabase.com/docs/guides/getting-started/mcp)
- [Vercel – Use Vercel's MCP server](https://vercel.com/docs/agent-resources/vercel-mcp)
- [Vercel MCP – Tools reference](https://vercel.com/docs/agent-resources/vercel-mcp/tools)
- [Claude Code – MCP](https://docs.claude.com/en/docs/claude-code/mcp)
