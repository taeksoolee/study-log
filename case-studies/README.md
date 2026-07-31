# 실전 사례 (Case Studies)

> 실제 프로덕션 프론트엔드(어드민/모니터링 SPA)를 개발·운영하며 마주친 버그와 판단을,
> "왜 그렇게 됐고 왜 그렇게 고쳤는가"까지 정리한 트러블슈팅 로그.

개념 커리큘럼([JavaScript](../javascript/README.md)·[React 상태관리](../frontend/react/03-state-management.md)·[테스트 전략](../frontend/testing/README.md) 등)이 **"무엇을·왜"**를 다룬다면,
이 섹션은 그 개념들이 **현실의 제약(캐시 TTL, 워크트리, PATH, 레이아웃 stacking) 속에서 어떻게 깨지고 어떻게 맞물리는지**를 다룬다.

각 문서는 다음 형식을 따른다.

- **실전 배경**: 어떤 증상/요구에서 출발했나
- **개념**: 그 밑에 깔린 원리(재현 가능한 최소 예제 포함)
- **판단 근거**: 왜 이 해법을 골랐나 (대안과 트레이드오프)
- **면접 포인트**: 같은 개념이 면접에서 어떻게 나오나

---

## 학습 목차

| # | 주제 | 연결 커리큘럼 | 상태 |
|---|------|--------------|------|
| 01 | [TanStack Query 캐시 무효화 & 로그아웃 세션 정리](./01-tanstack-query-cache-invalidation.md) | React 상태관리 · 성능 · 웹 스토리지 | ✅ |
| 02 | [회귀를 실제로 잡는 테스트 (복제본 함정 · E2E 3대 함정)](./02-tests-that-catch-regressions.md) | 테스트 전략 · E2E/CI | ✅ |
| 03 | [moment → dayjs 마이그레이션 (불변성 · 호환성 스펙)](./03-moment-to-dayjs-migration.md) | 날짜 유틸 · 리팩터링 | ✅ |
| 04 | [`env node` shebang · PATH · MCP가 안 붙던 이유](./04-shebang-node-path-mcp.md) | 빌드 도구 · AI/MCP · OS PATH | ✅ |
| 05 | [`position: sticky` 투명 배경 겹침 & CSS 변수 테마](./05-sticky-transparent-background.md) | 모던 CSS · Reflow/Repaint | ✅ |
| 06 | [스코프·레이어링 판단 (opt-in 플래그 · 순환참조 · 의존 방향)](./06-scope-and-layering.md) | 아키텍처 · 모듈 시스템 | ✅ |
| 07 | [HTTP 파일 다운로드: `Content-Disposition` 파싱 & Blob 다운로드](./07-content-disposition-file-download.md) | CS 네트워크(HTTP) · File/Blob API | ✅ |
| 08 | [로딩 UX: `keepPreviousData` · `isLoading` vs `isFetching`](./08-loading-ux-keep-previous-data.md) | React 성능 · 상태관리 | ✅ |
| 09 | [URL을 상태의 원천으로: 딥링크 · 필터 영속화 · 쿼리 동기화](./09-url-as-source-of-truth.md) | 라우팅 · SPA 상태관리 | ✅ |
| 10 | [디자인 시스템 테마: 토큰 상속 vs CSS 오버라이드](./10-design-system-theming.md) | 모던 CSS · 아키텍처 | ✅ |
| 11 | [Path Alias 일괄 마이그레이션 & 대규모 변경 검증](./11-path-alias-migration.md) | 빌드 도구 · 리팩터링 | ✅ |
| 12 | [AI 에이전트와 협업하는 개발 워크플로](./12-ai-agent-workflow.md) | AI/MCP · 방법론 | ✅ |

---

## 이 사례들을 관통하는 원칙

- **stale ≠ removed**: 캐시를 "무효화"하는 것과 "제거"하는 것은 전혀 다르다 (01).
- **테스트가 실제 코드를 태우는가**: 복제본을 검증하면 회귀를 못 잡는다. "코드를 되돌리면 테스트가 깨지는가"로 검출력을 검증한다 (02).
- **불변(immutable)이 기본이면 방어 코드가 사라진다**: `.clone()`이 no-op이 되는 이유 (03).
- **암묵적 조회(PATH·shebang)는 환경이 바뀌면 배신한다**: 절대경로로 못 박기 (04).
- **stacking과 paint를 이해하면 CSS 버그가 논리적으로 풀린다** (05, 10).
- **요청받은 스코프만 정확히 고친다**: 넓은 수정의 유혹과 대안 (06, 11).
- **추측하지 말고 실제로 관측한다**: 스펙보다 실서버 응답, 추측보다 실제 로그 (07, 04, 12).
- **"데이터가 있는가"와 "요청 중인가"는 다른 축이다**: 로딩 상태의 분해 (08).
- **URL이 곧 화면 상태의 직렬화된 표현이다**: 공유·복원되어야 할 것만 URL에 (09).

---

## 참고 자료

- **TanStack Query — Caching**: https://tanstack.com/query/latest/docs/framework/react/guides/caching
- **Playwright — Best Practices**: https://playwright.dev/docs/best-practices
- **Day.js — Immutable**: https://day.js.org/docs/en/parse/parse
- **MDN — `position: sticky`**: https://developer.mozilla.org/en-US/docs/Web/CSS/position#sticky_positioning
- **MDN — Stacking context**: https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_positioned_layout/Stacking_context
