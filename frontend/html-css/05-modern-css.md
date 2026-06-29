# 5. 모던 CSS

> 2023년 이후 모든 메이저 브라우저에 안착한 기능들. JS·미디어쿼리·전처리기로 우회하던 패턴을 CSS 네이티브로 대체한다.

## 목차
1. [Container Queries — 컴포넌트 단위 반응형](#1-container-queries--컴포넌트-단위-반응형)
2. [:has() — 부모/이전 선택자](#2-has--부모이전-선택자)
3. [Cascade Layers (@layer) — 우선순위 관리](#3-cascade-layers-layer--우선순위-관리)
4. [CSS Nesting — 네이티브 중첩](#4-css-nesting--네이티브-중첩)
5. [Subgrid](#5-subgrid)
6. [기타: clamp · aspect-ratio · 논리 속성 · 색상 함수](#6-기타-clamp--aspect-ratio--논리-속성--색상-함수)
7. [면접 포인트](#7-면접-포인트)

---

## 1. Container Queries — 컴포넌트 단위 반응형

미디어 쿼리는 **뷰포트**(화면 전체) 크기에만 반응한다. 하지만 같은 카드 컴포넌트가 사이드바(좁음)와 본문(넓음)에 동시에 놓이면, 컴포넌트는 *자신이 놓인 컨테이너*의 크기에 반응해야 한다. 그게 **컨테이너 쿼리**다.

```css
/* 부모를 쿼리 컨테이너로 선언 */
.card-list {
  container-type: inline-size;   /* 가로폭 기준으로 쿼리 */
  container-name: cards;         /* (선택) 이름 지정 */
}

/* 컨테이너 폭이 400px 이상이면 가로 배치 */
@container cards (min-width: 400px) {
  .card { display: grid; grid-template-columns: 120px 1fr; }
}
```

```css
/* 컨테이너 기준 단위: cqw/cqh/cqi/cqb (1cqi = 컨테이너 inline 크기의 1%) */
.card h3 { font-size: clamp(1rem, 5cqi, 1.5rem); }
```

> **핵심 차이:** 미디어 쿼리는 "화면이 얼마나 크냐", 컨테이너 쿼리는 "내가 놓인 자리가 얼마나 크냐". 진짜 재사용 가능한 컴포넌트엔 컨테이너 쿼리가 맞다.

---

## 2. :has() — 부모/이전 선택자

CSS에 오래 없던 "부모 선택자". `:has()`는 **조건을 만족하는 자식/후속 요소를 가진 요소**를 선택한다.

```css
/* 이미지를 포함한 figure에만 패딩 */
figure:has(img) { padding: 8px; }

/* 체크된 체크박스를 가진 라벨 강조 (이전엔 JS 필요) */
label:has(input:checked) { font-weight: bold; }

/* 다음에 단락이 오는 제목의 아래 여백 제거 */
h2:has(+ p) { margin-bottom: 0; }

/* 폼 검증: 잘못된 입력을 가진 form-group을 빨갛게 */
.field:has(input:invalid) { border-color: red; }
```

조합하면 강력하다 — "에러가 하나라도 있으면 제출 버튼 흐리게":

```css
form:has(:invalid) button[type="submit"] {
  opacity: 0.5;
  pointer-events: none;
}
```

> `:has()`는 부모뿐 아니라 형제 관계(`+`, `~`)도 거슬러 볼 수 있어 사실상 "관계 선택자"다. 상태 기반 UI의 상당수를 JS 없이 표현한다.

---

## 3. Cascade Layers (@layer) — 우선순위 관리

큰 프로젝트에서 CSS 우선순위는 명시도(specificity) 전쟁이 된다. `@layer`는 **레이어 단위로 우선순위를 명시적으로 계층화**해, 명시도와 무관하게 "어느 레이어가 이기는지"를 선언 순서로 정한다.

```css
/* 선언 순서 = 우선순위 (뒤 레이어가 이김) */
@layer reset, base, components, utilities;

@layer reset {
  * { margin: 0; }
}
@layer components {
  .btn { background: blue; }      /* 명시도 0,1,0 */
}
@layer utilities {
  .bg-red { background: red; }    /* 명시도 0,1,0 인데도 components를 이김 */
}
```

핵심 규칙:
- **레이어 간**에는 *선언된 순서*가 명시도보다 우선한다 (뒤 레이어 승).
- **레이어에 속하지 않은** 일반 규칙은 *모든 레이어보다 강하다*.
- `!important`는 레이어 순서가 **뒤집힌다** (앞 레이어의 important가 더 강함).

> 활용: 서드파티 라이브러리를 `@layer vendor`에 넣으면 내 `@layer app`이 명시도 싸움 없이 항상 이긴다.

---

## 4. CSS Nesting — 네이티브 중첩

Sass 없이 CSS가 중첩을 지원한다.

```css
.card {
  padding: 1rem;

  & h3 { font-size: 1.25rem; }   /* & 는 부모 선택자 */

  &:hover { box-shadow: 0 2px 8px #0002; }

  & .badge { color: tomato; }    /* 요소 선택자 앞엔 & 또는 결합자 필요 */

  @media (min-width: 600px) {     /* 미디어쿼리도 중첩 가능 */
    padding: 2rem;
  }
}
```

> Sass 중첩과 거의 같지만 차이: 네이티브 nesting은 타입 선택자(`h3`) 앞에 `&`나 결합자가 없으면 동작이 모호할 수 있어 `& h3` 형태를 권장. 그리고 중첩은 빌드 타임이 아니라 **브라우저가 직접 해석**한다.

---

## 5. Subgrid

중첩된 그리드의 자식이 **부모 그리드의 트랙 선을 그대로 따르게** 한다. 카드들의 제목/본문/푸터 높이를 카드 간에 정렬할 때 필수.

```css
.cards {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  grid-template-rows: repeat(3, auto);  /* 제목/본문/푸터 3개 행 트랙 (subgrid가 상속할 대상) */
}
.card {
  display: grid;
  grid-row: span 3;              /* 부모의 3개 행에 걸침 */
  grid-template-rows: subgrid;   /* 부모의 행 트랙을 상속 → 카드 간 줄 정렬 */
}
```

이제 모든 카드의 제목 줄·본문 줄·푸터 줄이 행마다 같은 높이로 맞춰진다. subgrid 없이는 각 카드가 독립 그리드라 줄이 들쭉날쭉했다.

---

## 6. 기타: clamp · aspect-ratio · 논리 속성 · 색상 함수

### clamp() — 반응형 타이포 한 줄

```css
/* min, 선호(뷰포트 비례), max */
h1 { font-size: clamp(1.5rem, 4vw + 1rem, 3rem); }
```

미디어쿼리 여러 개 없이 부드럽게 스케일된다.

### aspect-ratio — 비율 고정

```css
.thumb { aspect-ratio: 16 / 9; width: 100%; }  /* padding-top 핵 불필요 */
```

### 논리 속성 — 국제화 친화

물리 방향(left/right) 대신 흐름 방향(inline/block)으로. RTL 언어에서 자동으로 뒤집힌다.

```css
.box {
  margin-inline: auto;       /* = margin-left/right */
  padding-block: 1rem;       /* = padding-top/bottom */
  border-inline-start: 2px;  /* LTR=왼쪽, RTL=오른쪽 */
}
```

### 모던 색상 — color-mix() & 상대 색

```css
:root { --brand: #1a73e8; }
.btn:hover { background: color-mix(in srgb, var(--brand) 85%, black); }
```

`oklch()` 같은 지각 균등 색공간도 지원돼, 명도를 일정하게 유지한 팔레트를 만들기 쉽다.

---

## 7. 면접 포인트

**Q. 미디어 쿼리와 컨테이너 쿼리의 차이는?**
> 미디어 쿼리는 뷰포트(화면 전체) 크기에 반응하고, 컨테이너 쿼리는 요소가 놓인 부모 컨테이너 크기에 반응한다. 같은 컴포넌트가 사이드바·본문 등 다른 폭의 자리에 재사용될 때, 진짜 재사용 가능한 반응형은 컨테이너 쿼리로만 가능하다. (`container-type: inline-size` + `@container`)

**Q. `:has()`로 무엇이 가능해졌나요?**
> CSS에 없던 부모/관계 선택자. 특정 자식·형제를 가진 요소를 선택할 수 있어 `label:has(input:checked)`, `form:has(:invalid) button` 같은 상태 기반 UI를 JS 없이 표현한다.

**Q. `@layer`(Cascade Layers)가 해결하는 문제는?**
> 명시도(specificity) 전쟁. 레이어 간에는 선언 순서가 명시도보다 우선하므로, 서드파티 CSS를 앞 레이어에 두면 내 스타일이 명시도와 무관하게 항상 이긴다. 단 레이어 밖 규칙은 모든 레이어보다 강하고, `!important`는 레이어 순서가 역전된다는 점에 주의.

**Q. subgrid가 필요한 상황은?**
> 카드 그리드처럼 중첩된 그리드의 자식들이 부모의 같은 행/열 트랙에 정렬돼야 할 때. 일반 중첩 그리드는 각자 독립이라 카드별 제목·본문 높이가 어긋나는데, `grid-template-rows: subgrid`로 부모 트랙을 상속하면 줄이 맞춰진다.

**Q. 논리 속성(logical properties)을 쓰는 이유는?**
> `margin-inline`, `padding-block`처럼 물리 방향 대신 흐름 방향으로 지정하면 RTL(아랍어 등)·세로쓰기에서 자동으로 방향이 뒤집혀 국제화에 강하다.
