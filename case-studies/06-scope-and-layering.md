# 06. 스코프·레이어링 판단 (opt-in 플래그 · 순환참조 · 의존 방향)

> 실전 배경: 세 가지 서로 다른 상황에서 같은 질문이 반복됐다 —
> **"요청받은 것만 고칠 것인가, 더 일반적으로 고칠 것인가?"** 그리고
> **"이 코드/타입은 어느 레이어가 소유해야 하는가?"** 넓게 고치는 게 늘 옳은 건 아니다.

## 목차
1. [opt-in 1회성 플래그 vs 전역 수정](#1-opt-in-1회성-플래그-vs-전역-수정)
2. [순환 참조를 끊는 법: 더 하위에 의존하기](#2-순환-참조를-끊는-법-더-하위에-의존하기)
3. [레이어 의존 방향과 소유권](#3-레이어-의존-방향과-소유권)
4. [부채는 옮기지 말고 명시하라 (FIXME의 쓸모)](#4-부채는-옮기지-말고-명시하라-fixme의-쓸모)
5. [면접 포인트](#5-면접-포인트)

---

## 1. opt-in 1회성 플래그 vs 전역 수정

증상: 상세 드로어를 열면 URL 쿼리스트링이 바뀌는데(`router.replace`로 딥링크 동기화), 그때마다 페이지가 최상단으로 스크롤됐다. 원인은 전역 라우터 훅.

```ts
// 모든 네비게이션에서 스크롤을 top으로 — query만 바뀌는 replace도 여기 걸린다
router.beforeEach((to, from, next) => {
  if (!to.meta.preventScrollBehavior) window.scrollTo(window.scrollX, 0);
  next();
});
```

**넓은 해법**은 "`to.path === from.path`(같은 라우트, query만 다름)면 스크롤을 건너뛰자"였다. 한 줄이면 되고 일반적이다. 하지만 이건 앱 전역의 **모든** 쿼리스트링 동기화(탭 전환, 테이블 필터 등)에 영향을 준다 — 요청받지 않은 화면의 동작까지 바꾼다.

**선택한 해법**은 딥링크 케이스에만 적용되는 **1회성 opt-in 플래그**다.

```ts
let skipNextScroll = false;
export function skipScrollResetOnce() { skipNextScroll = true; }

router.beforeEach((to, from, next) => {
  if (skipNextScroll) { skipNextScroll = false; }      // 1회 소비
  else if (!to.meta.preventScrollBehavior) window.scrollTo(window.scrollX, 0);
  next();
});

// 드로어를 여는/닫는 "의도를 아는 지점"에서만 호출
function openDetail() { skipScrollResetOnce(); /* ...상태 변경 → replace */ }
```

판단 근거: **"요청받은 스코프만 정확히 고친다."** 스크롤 리셋이 유효한 다른 케이스(탭 전환 등)와 명확히 구분되고, "드로어 여는 의도를 아는 곳"에서만 플래그를 세팅해 정확도가 높다. 대신 트레이드오프도 명시했다 — 같은 tick에 무관한 네비게이션이 끼어들면 그게 대신 플래그를 소비할 수 있으나, 실사용 흐름상 가능성이 낮다.

> 넓은 수정은 코드가 짧아 매력적이지만 **블라스트 반경(blast radius)**이 크다. "지금 요청의 의도"에 정확히 매핑되는 좁은 해법이, 회귀 위험 면에서 대개 낫다.

---

## 2. 순환 참조를 끊는 법: 더 하위에 의존하기

로그아웃 세션 정리를 만들다가 **순환 참조**가 드러났다.

```
useLogout → clearSessionData → useAlertStore → useAuth → useLogout
                                                  ↑___________|
```

`useAlertStore`가 `useAuth`를 쓰는데, `useAuth`가 `useLogout`을 끌어오고, `useLogout`이 다시 `clearSessionData → useAlertStore`로 돌아온다. ESM 순환 참조는 로드 순서에 따라 `undefined`를 참조하는 런타임 오류로 이어진다.

끊는 법: `useAlertStore`가 실제로 필요한 건 `isAuthenticated` **값 하나**였다. 그렇다면 `useLogout`까지 끌어오는 무거운 `useAuth` 대신, **더 하위의 `useAuthStore`에 직접 의존**하면 된다.

```ts
// ❌ useAuth는 useLogout을 import → 순환
import { useAuth } from '@/features/auth';

// ✅ 필요한 값만 주는 하위 스토어에 직접 의존 → 순환 끊김
import { useAuthStore } from '@/features/auth/store';
const { isAuthenticated } = storeToRefs(useAuthStore());
```

원리: **의존 사이클은 "필요 이상으로 상위(무거운) 모듈에 의존"할 때 잘 생긴다.** 진짜 필요한 최소 단위(하위 스토어)로 의존을 낮추면 사이클이 풀린다. 값 자체는 동일하다(`useAuth`도 결국 `storeToRefs(useAuthStore())`를 노출).

---

## 3. 레이어 의존 방향과 소유권

API 오류 규격이 `error_message`(서버가 준 문자열)에서 `error_code`(코드 + 프론트가 문구 매핑)로 바뀌면서, "이 코드 enum을 어느 레이어가 가질 것인가"가 쟁점이 됐다.

레이어 구조(위 → 아래):

```
app (const/text, 화면 문구)
  └─ features (도메인 UI)
       └─ infrastructure (API 계약 = zod 스키마)
```

기존엔 상태 enum들이 `app/const`(상위)에 있고, `infrastructure`(하위)의 zod 스키마가 그걸 **역참조**했다. 하위가 상위를 참조하는 **역방향 의존**이다.

신규 `error_code` enum은 **이 API 계약에서만 쓰는 값**이므로, 계약을 소유한 `infrastructure`가 직접 소유하게 했다.

```ts
// infrastructure — API 계약이 코드를 소유 (정방향)
export const KpxVerificationErrorCode = Object.freeze({
  DB_DATA_MISSING: 'DB_DATA_MISSING',
  // ...
});
export const KpxVerificationErrorCodeSchema = z.nativeEnum(KpxVerificationErrorCode);

// app/const/text — 상위가 하위(계약)를 import해 "문구"를 매핑 (정방향)
import { KpxVerificationErrorCode } from '@/infrastructure/.../schema';
const TextMap = {
  [KpxVerificationErrorCode.DB_DATA_MISSING]: 'DB 데이터가 없습니다',
};
```

- **소유권 원칙**: "그 값이 태어난 곳"이 소유한다. API 응답 코드는 API 계약(infrastructure)의 것이다.
- **의존 방향**: 상위(app)가 하위(infrastructure)를 참조하는 건 정방향이라 괜찮다. 그 반대(하위가 상위 참조)가 냄새다.
- **문구는 여전히 중앙 집중**: 코드는 계약이 갖되, 화면 문구는 하드코딩하지 않고 `text.ts`의 매핑을 통해 `t(key)`로 조회한다(관심사 분리).

---

## 4. 부채는 옮기지 말고 명시하라 (FIXME의 쓸모)

기존 3개 enum도 역방향 의존이라 "옮기는 게 맞다". 하지만 이미 여러 파일이 참조 중이라, 지금 옮기면 **요청받지 않은 대규모 리팩터링**이 이번 변경에 섞인다.

```ts
// FIXME: 이 enum은 API 계약이므로 infrastructure로 이전해야 함(역방향 의존).
//        현재 다수 참조로 이번 스코프에서는 이동하지 않고 부채로 표시함.
export const KpxSettlementPhase = Object.freeze({ /* ... */ });
```

판단: **실제 이동은 하지 않고 `FIXME` 주석으로 부채를 명시**했다. 이유는 1절과 같다 — 무관한 대규모 변경을 섞으면 리뷰가 어려워지고 회귀 위험이 커진다. 부채를 "인지했고 의도적으로 미뤘다"고 코드에 남기는 것이, 조용히 넓게 고치는 것보다 정직하고 안전하다.

> 마찬가지로, 실제 소비처가 없는데 "미래에 필요할 것 같아서" 매핑 테이블을 선제적으로 만드는 것도 **불필요한 추상화**로 보고 보류했다. 필요해지는 시점에 추가한다(YAGNI).

---

## 5. 면접 포인트

**Q. 버그를 좁게 고칠지 넓게 고칠지 어떻게 판단하나요?**
> 블라스트 반경으로 판단한다. 넓은 수정은 코드가 짧아도 요청받지 않은 다른 동작까지 바꿔 회귀 위험이 크다. "지금 요청의 의도"에 정확히 매핑되는 좁은 해법(예: 특정 케이스에만 걸리는 opt-in 플래그)을 우선하고, 트레이드오프를 명시한다. 넓은 리팩터링이 정말 필요하면 별도 스코프로 분리한다.

**Q. ESM 순환 참조는 왜 생기고 어떻게 끊나요?**
> 모듈 A가 B를, B가 다시 A를 (간접적으로) import하면 로드 순서에 따라 undefined 참조 오류가 난다. 대개 "필요 이상으로 상위/무거운 모듈에 의존"할 때 생긴다. 진짜 필요한 최소 단위(예: 값 하나를 주는 하위 스토어)로 의존을 낮추면 사이클이 풀린다.

**Q. 타입/상수는 어느 레이어가 소유해야 하나요?**
> 그 값이 태어난 곳이 소유한다. API 응답 코드는 API 계약(인프라/스키마 레이어)의 것이다. 상위 레이어가 하위를 참조하는 정방향은 괜찮지만, 하위가 상위를 참조하는 역방향은 냄새다. 화면 문구 같은 표현은 코드와 분리해 중앙 매핑으로 관리한다.

**Q. 알고 있는 기술 부채를 이번 작업에서 다 고치지 않는 게 맞나요?**
> 무관한 대규모 변경을 스코프에 섞으면 리뷰가 어렵고 회귀 위험이 커진다. 부채는 FIXME 등으로 "인지했고 의도적으로 미뤘다"를 명시하고 별도 티켓으로 다룬다. 반대로 실제 소비처 없는 선제적 추상화도 YAGNI로 보류한다.
