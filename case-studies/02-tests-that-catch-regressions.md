# 02. 회귀를 실제로 잡는 테스트 (복제본 함정 · E2E 3대 함정)

> 실전 배경: 라우터 가드에 세션 정리(`clearSessionData`) 호출을 새로 넣었다.
> 테스트는 8건 모두 초록불. 그런데 자세히 보니 **그 새 호출을 지워도 테스트가 하나도 안 깨졌다.**
> 테스트가 "실제 가드"가 아니라 "가드의 복사본"을 검증하고 있었기 때문이다.

## 목차
1. [복제본을 테스트하면 회귀를 못 잡는다](#1-복제본을-테스트하면-회귀를-못-잡는다)
2. [검출력 검증: "코드를 되돌리면 테스트가 깨지는가"](#2-검출력-검증-코드를-되돌리면-테스트가-깨지는가)
3. [E2E 함정 ① 워크트리/포트 재사용이 엉뚱한 코드를 검증한다](#3-e2e-함정--워크트리포트-재사용이-엉뚱한-코드를-검증한다)
4. [E2E 함정 ② toHaveCount(0)의 시점 단정](#4-e2e-함정--tohavecount0의-시점-단정)
5. [E2E 함정 ③ full reload가 버그를 가린다](#5-e2e-함정--full-reload가-버그를-가린다)
6. [면접 포인트](#6-면접-포인트)

---

## 1. 복제본을 테스트하면 회귀를 못 잡는다

문제의 테스트는 이렇게 생겼었다.

```ts
// auth.spec.ts (안티패턴)
// NOTE: src/router/index.ts의 실제 가드 로직 복제
function authGuardCopy(to, from, next) {
  // ...실제 가드와 "비슷하게" 손으로 옮겨 적은 로직...
}

it('비로그인 사용자를 로그인으로 보낸다', () => {
  authGuardCopy(protectedRoute, from, next); // ← 복사본을 부른다
  expect(next).toHaveBeenCalledWith('/login');
});
```

실제 가드는 `router/index.ts`의 `beforeEach` 안에 있는데, 테스트는 그걸 부르지 않고 파일 안에 손으로 옮겨 적은 복사본을 부른다. 이 구조에서는 **실제 가드가 어떻게 바뀌든 테스트는 계속 통과한다.** 실제 가드에 `clearSessionData`를 추가해도, 복사본엔 없으니 아무 테스트도 그 변경을 태우지 못했다.

이건 "구현 세부를 테스트한다"보다 더 나쁜, **아예 프로덕션 코드를 실행하지 않는 테스트**다. 커버리지 리포트에도 실제 가드는 안 잡힌다.

해법은 가드를 **테스트 가능한 순수 단위로 추출**하고, 테스트가 그 실제 구현을 등록하는 것.

```ts
// guards.ts — 실제 구현 (index.ts와 spec이 공유)
export function authGuard(to, from, next) { /* 진짜 로직 */ }

// index.ts — 배선만
router.beforeEach((to, from, next) => {
  applyDocumentTitle(to);
  authGuard(to, from, next);
});

// auth.spec.ts — 복사본 삭제, 실제 authGuard를 등록
import { authGuard } from './guards';
it('refresh 실패 시 세션을 정리한다', () => {
  authGuard(protectedRoute, from, next);
  expect(clearSessionData).toHaveBeenCalled();
});
```

> 전부(`beforeEach` 통째)를 export하면 복제 위험이 완전히 사라지지만, jsdom이 `window.scrollTo`를 구현하지 않아 스크롤 처리를 spec에 태우면 "Not implemented" 노이즈가 낀다. 그래서 auth·title 관심사만 분리했다 — **테스트 용이성과 노이즈 사이의 현실적 절충.**

---

## 2. 검출력 검증: "코드를 되돌리면 테스트가 깨지는가"

테스트를 추가한 뒤 초록불이 떴다고 끝이 아니다. **그 테스트가 실제로 회귀를 잡는지**를 증명해야 한다. 방법은 간단하다. **고치기 전 상태로 되돌려 테스트가 빨간불이 되는지 확인**한다.

```bash
# 방식 A: 커밋 전이면
git stash push -- src/ && pnpm test && git stash pop

# 방식 B: 이미 커밋했다면 (stash는 담길 게 없어 무효!)
git checkout origin/develop -- src/   # 수정 전 코드로 되돌림
pnpm test                             # ← 여기서 새 테스트가 깨져야 정상
git checkout HEAD -- src/             # 복구
```

이 사례에선 "`guards.ts`에서 `clearSessionData` 호출 2곳을 제거하면 유닛 2건과 e2e 1건이 모두 실패한다"를 확인해 검출력을 증명했다. **전환 전 구조에서는 같은 제거가 아무 테스트도 안 건드렸다** — 이 대비가 곧 "복제본 테스트는 가짜였다"의 증거다.

> 커밋 이후 `git stash push -- src/`로 비교하려던 실수도 있었다. 변경이 이미 커밋되면 stash에 담길 게 없어 수정된 코드를 그대로 테스트하고, 뒤따르는 `git stash pop`이 다른 브랜치의 기존 stash를 꺼내 충돌을 만든다. **커밋 이후 비교는 반드시 `git checkout <base> -- src/` 방식**으로.

유닛과 e2e를 둘 다 둔 이유도 명확하다. 유닛은 `clearSessionData`가 **호출됐는지**만(모킹) 검증하고, e2e는 실제 브라우저에서 **IndexedDB가 실제로 비는지**까지 검증한다. 층위가 다르다.

---

## 3. E2E 함정 ① 워크트리/포트 재사용이 엉뚱한 코드를 검증한다

증상: **이유 없이 e2e 실패 조합이 실행마다 바뀐다.**

원인: 다른 git 워크트리에서 켜둔 `pnpm dev`가 8080을 점유하고 있었고, Playwright의 `reuseExistingServer: !process.env.CI`(로컬에서 `true`)가 그 서버를 재사용했다. 결과적으로 **현재 브랜치가 아닌 다른 워크트리의 소스를 테스트**하고 있었다.

확인법:

```bash
# 지금 8080이 서빙하는 소스가 이 워크트리 것인지 직접 확인
curl -s "http://localhost:8080/src/features/auth/composables/useLogout.ts" | head
# 8080을 누가 잡고 있나
lsof -ti :8080 | xargs -I{} ps -o pid,command -p {}
```

대책: 그 서버를 끄거나, `baseURL`·`webServer`만 다른 포트(예: 8091)로 바꾼 config로 격리 실행한다. **CI에서만 `reuseExistingServer`를 끄는 기본값이 로컬 멀티 워크트리 환경에선 함정**이 된다.

---

## 4. E2E 함정 ② toHaveCount(0)의 시점 단정

```ts
// ❌ 즉시 0이면 그냥 통과 — 렌더 타이밍을 놓친다
await expect(page.getByText(prevUserResource)).toHaveCount(0);
```

`toHaveCount(0)`은 "지금 이 순간 0개"면 통과하는 **시점 단정**이다. 계정 전환 버그처럼 "이전 데이터가 잠깐 떴다가 사라지는" 현상은, 그 잠깐을 놓치면 그냥 통과해버린다. 즉 **버그가 있어도 초록불**이 뜬다.

대책: 새 세션 응답을 인위적으로 지연시키고, 그 구간을 **연속 샘플링**해 "한 번도 이전 데이터가 뜨지 않았는가"를 검증한다.

```ts
await page.route('**/api/resource-list', async (route) => {
  await new Promise((r) => setTimeout(r, 800)); // 응답 지연
  await route.continue();
});
// 지연 구간 동안 이전 사용자 데이터가 단 한 프레임도 안 뜨는지 반복 확인
```

---

## 5. E2E 함정 ③ full reload가 버그를 가린다

계정 전환 버그(01번 문서)는 **in-memory 캐시에 남은 이전 데이터**가 원인이다. 그런데 `page.goto()`는 전체 페이지 리로드라 in-memory 캐시가 초기화되어 **버그가 사라진다.**

```ts
// ❌ 전체 리로드 → 메모리 캐시 초기화 → 버그 재현 안 됨
await page.goto('/g/resource-list');

// ✅ 클라이언트 사이드 이동 → 메모리 캐시 유지 → 버그 재현
await page.getByRole('tab', { name: '자원 목록' }).click();
```

**메모리 상태에 의존하는 버그는 반드시 SPA 내부 네비게이션(클릭)으로 재현**해야 한다. E2E 시나리오를 "사용자가 실제로 하는 동선"으로 짜야 하는 이유가 여기 있다 — 사용자는 계정 전환할 때 주소창을 새로 치지 않는다.

---

## 6. 면접 포인트

**Q. 테스트가 초록불인데 회귀를 못 잡는 경우가 있나요?**
> 있다. 테스트가 실제 코드가 아니라 그 로직의 복사본이나 목(mock)만 검증하면, 실제 구현이 바뀌어도 통과한다. 그래서 "고치기 전 코드로 되돌렸을 때 테스트가 깨지는지"로 검출력을 확인한다. 안 깨지면 그 테스트는 아무것도 지키지 못하는 것이다.

**Q. 테스트의 검출력(회귀 감지 능력)을 어떻게 검증하나요?**
> 뮤테이션 테스팅의 축소판으로, 프로덕션 코드의 핵심 라인을 일부러 되돌리거나 제거하고 테스트가 실패하는지 본다. 커밋 전이면 stash, 커밋 후면 `git checkout <base> -- src`로 되돌려 확인한다.

**Q. E2E가 실행마다 다른 결과를 낼 때 의심할 것은?**
> flaky의 전형이다. 타이밍 의존(고정 sleep, 시점 단정), 테스트 간 상태 공유, 그리고 환경 오염 — 특히 dev 서버 포트 재사용으로 엉뚱한 빌드를 테스트하는 경우. 실제로 다른 워크트리 서버를 재사용해 실패 조합이 매번 바뀐 적이 있다.

**Q. 메모리 캐시에 의존하는 버그를 E2E로 재현하려면?**
> page.goto 같은 전체 리로드는 메모리를 초기화해 버그를 가린다. 사용자 실제 동선대로 클라이언트 사이드 네비게이션(클릭)으로 이동해야 한다. 또 "잠깐 떴다 사라지는" 현상은 toHaveCount(0) 같은 시점 단정으로는 못 잡으니, 응답을 지연시켜 그 구간을 연속 샘플링한다.

**Q. 같은 동작을 유닛과 E2E로 중복 검증하는 게 낭비 아닌가요?**
> 층위가 다르면 낭비가 아니다. 유닛은 "정리 함수가 호출됐는가"를 빠르게(모킹), E2E는 "실제 브라우저에서 IndexedDB가 비었는가"를 느리지만 진짜로 검증한다. 모킹한 유닛만으로는 실제 저장소가 비는 것까지 보장하지 못한다.
