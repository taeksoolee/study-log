# 6. CSS 아키텍처

> CSS의 본질적 어려움은 **전역 네임스페이스**와 **명시도/캐스케이드**다. 큰 코드베이스에서 "이 클래스 지우면 어디 깨지지?"를 없애는 게 모든 방법론의 목표.

## 목차
1. [CSS가 확장에서 겪는 근본 문제](#1-css가-확장에서-겪는-근본-문제)
2. [BEM — 명명 규칙](#2-bem--명명-규칙)
3. [CSS Modules — 빌드 타임 스코프](#3-css-modules--빌드-타임-스코프)
4. [CSS-in-JS — 런타임/제로런타임](#4-css-in-js--런타임제로런타임)
5. [유틸리티 우선 — Tailwind](#5-유틸리티-우선--tailwind)
6. [비교와 선택 기준](#6-비교와-선택-기준)
7. [면접 포인트](#7-면접-포인트)

---

## 1. CSS가 확장에서 겪는 근본 문제

1. **전역 스코프** — 모든 셀렉터가 전역. 클래스명 충돌·의도치 않은 덮어쓰기.
2. **명시도 전쟁** — 못 이기면 `!important`, 그게 쌓이면 유지보수 불능.
3. **죽은 코드** — 어떤 클래스가 안 쓰이는지 알기 어려워 CSS가 무한 증식.
4. **결합도** — HTML 구조에 의존한 셀렉터(`.nav ul li a`)는 마크업 바뀌면 깨짐.

각 방법론은 이 네 가지를 서로 다른 방식으로 공략한다.

---

## 2. BEM — 명명 규칙

**B**lock **E**lement **M**odifier. 도구 없이 *명명 규칙만으로* 전역 충돌과 명시도를 통제한다.

```html
<div class="card card--featured">
  <h3 class="card__title">제목</h3>
  <button class="card__btn card__btn--primary">확인</button>
</div>
```

```css
.card { }                  /* Block: 독립 컴포넌트 */
.card__title { }           /* Element: 블록의 일부 (__) */
.card--featured { }        /* Modifier: 변형 상태 (--) */
.card__btn--primary { }
```

- **모든 셀렉터를 클래스 하나(명시도 0,1,0)로 평탄화** → 명시도 전쟁 종결.
- 자손 셀렉터(`.card .title`) 대신 `.card__title` → HTML 구조와 디커플링.
- 단점: 클래스명이 장황하고, 전역 스코프 자체는 여전함(규칙을 어기면 충돌).

> 빌드 도구 없이 순수 CSS로 규율을 세우는 가장 가벼운 방법. 디자인 시스템 토큰과 잘 어울린다.

---

## 3. CSS Modules — 빌드 타임 스코프

`.module.css` 파일의 클래스명을 빌드 시 **고유 해시로 변환**해 자동으로 지역 스코프를 만든다. 런타임 비용 0.

```css
/* Card.module.css */
.title { font-size: 1.25rem; }
.featured { border: 2px solid gold; }
```

```jsx
import styles from './Card.module.css';

function Card() {
  return <h3 className={styles.title}>제목</h3>;
  // 실제 출력: class="Card_title__a1b2c"  ← 충돌 불가능
}
```

- **충돌 원천 차단** — 같은 `.title`이 파일마다 달라짐.
- 순수 CSS 문법 그대로, 빌드 타임 처리라 런타임 오버헤드 없음.
- `composes`로 클래스 조합, `:global(...)`로 전역 탈출구 제공.
- 단점: 동적 스타일(props 기반)은 인라인 스타일/클래스 토글로 별도 처리.

---

## 4. CSS-in-JS — 런타임/제로런타임

JS 안에서 컴포넌트와 스타일을 함께 정의. props로 스타일을 동적 계산할 수 있다.

```jsx
// styled-components (런타임)
const Button = styled.button`
  background: ${props => props.primary ? '#1a73e8' : '#eee'};
  padding: 8px 16px;
`;
<Button primary>확인</Button>
```

- 장점: 컴포넌트 단위 캡슐화, props 기반 동적 스타일, 자동 critical CSS, 죽은 코드 자동 제거.
- 단점(**런타임 방식**): 브라우저에서 스타일을 파싱·주입 → 런타임 비용, 번들 증가, SSR 시 hydration 복잡.

**제로 런타임 CSS-in-JS** (vanilla-extract, Linaria, 그리고 Panda CSS)는 **빌드 타임에 정적 CSS 파일로 추출**해 런타임 비용을 없앤다 — CSS-in-JS의 DX와 CSS Modules의 성능을 결합.

```ts
// vanilla-extract: 타입 안전 + 빌드 타임 추출
import { style } from '@vanilla-extract/css';
export const button = style({
  background: '#1a73e8',
  padding: '8px 16px',
});
```

> 트렌드: React 서버 컴포넌트(RSC)와 런타임 CSS-in-JS가 잘 안 맞아(서버에서 스타일 주입 불가), 생태계가 **제로 런타임** 또는 Tailwind 쪽으로 이동 중이다.

---

## 5. 유틸리티 우선 — Tailwind

작은 단일 목적 클래스(`p-4`, `flex`, `text-red-500`)를 HTML에서 조합한다. 새 CSS를 거의 안 짠다.

```html
<div class="flex items-center gap-3 rounded-lg p-4 shadow hover:shadow-md">
  <img class="h-12 w-12 rounded-full" src="..." />
  <span class="text-sm font-medium text-gray-800">이름</span>
</div>
```

- 장점: 새 클래스명 작명·전역 충돌 자체가 사라짐. 디자인 토큰(spacing/color scale)이 강제돼 일관성↑. 빌드 시 안 쓰는 유틸리티는 **purge**되어 최종 CSS가 작다.
- 단점: HTML이 장황("클래스 수프"), 러닝커브, 반복은 `@apply`나 컴포넌트 추출로 관리.

> 비판처럼 보이는 "인라인 스타일 회귀" 논쟁이 있지만, 핵심 차이는 **제약된 디자인 토큰 집합**과 상태 변형(`hover:`, `md:`, `dark:`)을 클래스로 표현한다는 점이다. 인라인 스타일론 미디어쿼리·의사클래스를 못 쓴다.

---

## 6. 비교와 선택 기준

| 방법 | 스코프 격리 | 동적 스타일 | 런타임 비용 | 러닝커브 |
|------|-----------|-----------|-----------|---------|
| **BEM** | 규칙(수동) | CSS 변수 | 0 | 낮음 |
| **CSS Modules** | 빌드 타임(자동) | 클래스 토글 | 0 | 낮음 |
| **CSS-in-JS(런타임)** | 자동 | props로 자유 | 있음 | 중간 |
| **제로런타임 CSS-in-JS** | 자동 | 제한적(빌드 타임) | 0 | 중간 |
| **Tailwind** | 전역이나 충돌 없음 | 변형 클래스 | 0 | 중간 |

선택 가이드:
- 작은 프로젝트·디자인 시스템 기반 → **BEM** 또는 **Tailwind**.
- React/Vue 컴포넌트 + 성능 중시 → **CSS Modules** 또는 **제로런타임 CSS-in-JS**.
- 강한 동적 테마·런타임 분기가 핵심 → 런타임 CSS-in-JS (단, RSC 호환성 확인).
- 빠른 프로토타이핑·일관성 강제 → **Tailwind**.

> 정답은 없다. 공통 목표는 **전역 충돌 제거 + 명시도 평탄화 + 죽은 코드 제어**이며, 팀 규모·렌더링 전략(SSR/RSC)·디자인 시스템 유무로 결정한다.

---

## 7. 면접 포인트

**Q. CSS가 확장될 때 생기는 근본 문제는?**
> 전역 스코프(클래스 충돌), 명시도 전쟁(`!important` 남발), 죽은 코드 누적, HTML 구조 결합. 모든 CSS 방법론은 이 네 가지를 푸는 서로 다른 전략이다.

**Q. BEM은 명시도 문제를 어떻게 해결하나요?**
> 모든 스타일을 클래스 하나(명시도 0,1,0)로 평탄화하고 자손 셀렉터를 쓰지 않는다. 모든 규칙의 명시도가 같아지므로 "선언 순서"로만 경쟁해 예측 가능해진다. 다만 전역 스코프 자체는 명명 규칙에 의존한다.

**Q. CSS Modules와 CSS-in-JS의 핵심 차이는?**
> CSS Modules는 빌드 타임에 클래스명을 해시로 바꿔 스코프를 만들고 런타임 비용이 0이다. (런타임) CSS-in-JS는 JS에서 스타일을 정의해 props 기반 동적 스타일이 자유롭지만 브라우저에서 파싱·주입하는 런타임 비용이 있다. 그 단점을 없앤 게 빌드 타임 추출형(vanilla-extract 등) 제로런타임 CSS-in-JS다.

**Q. Tailwind는 인라인 스타일과 무엇이 다른가요?**
> 인라인 스타일은 미디어쿼리·의사클래스(`:hover`)·상태 변형을 쓸 수 없지만, Tailwind 유틸리티는 `hover:`, `md:`, `dark:` 같은 변형을 클래스로 제공하고, 임의값이 아닌 제약된 디자인 토큰 스케일을 강제해 일관성을 준다. 미사용 클래스는 빌드 시 purge돼 최종 CSS도 작다.

**Q. 런타임 CSS-in-JS가 최근 주춤하는 이유는?**
> React 서버 컴포넌트(RSC)에서 서버가 스타일을 런타임에 주입하기 어렵고, 런타임 파싱 비용·hydration 복잡성 때문이다. 생태계는 제로런타임(빌드 타임 추출) 방식이나 Tailwind로 이동 중이다.
