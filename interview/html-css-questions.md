# 12. HTML/CSS 면접 질문 25개

## 목차

### HTML
1. [시맨틱 HTML이란 무엇이고 왜 쓰나요?](#1-시맨틱-html이란-무엇이고-왜-쓰나요)
2. [`<script>`의 `defer`와 `async` 차이는?](#2-script의-defer와-async-차이는)
3. [블록 요소와 인라인 요소의 차이는?](#3-블록-요소와-인라인-요소의-차이는)
4. [`data-*` 속성은 무엇인가요?](#4-data--속성은-무엇인가요)
5. [meta viewport는 무슨 역할인가요?](#5-meta-viewport는-무슨-역할인가요)

### 박스 모델 & 레이아웃
6. [박스 모델과 `box-sizing`은?](#6-박스-모델과-box-sizing은)
7. [`margin collapse`(마진 병합)란?](#7-margin-collapse마진-병합란)
8. [BFC(Block Formatting Context)란?](#8-bfcblock-formatting-context란)
9. [`position` 속성 5가지 차이는?](#9-position-속성-5가지-차이는)
10. [stacking context(쌓임 맥락)와 z-index는?](#10-stacking-context쌓임-맥락와-z-index는)
11. [Flexbox와 Grid의 차이와 선택 기준은?](#11-flexbox와-grid의-차이와-선택-기준은)
12. [요소를 가운데 정렬하는 방법은?](#12-요소를-가운데-정렬하는-방법은)

### 선택자 & 캐스케이드
13. [CSS 명시도(specificity) 계산은?](#13-css-명시도specificity-계산은)
14. [캐스케이드와 상속은?](#14-캐스케이드와-상속은)
15. [`:where()`와 `:is()`의 차이는?](#15-where와-is의-차이는)
16. [의사 클래스와 의사 요소의 차이는?](#16-의사-클래스와-의사-요소의-차이는)

### 단위 & 반응형
17. [`px`, `em`, `rem`, `%`, `vw/vh` 차이는?](#17-px-em-rem--vwvh-차이는)
18. [모바일 우선 vs 데스크탑 우선?](#18-모바일-우선-vs-데스크탑-우선)
19. [`rem` 기반 설계의 장점은?](#19-rem-기반-설계의-장점은)

### 시각 & 기타
20. [`display: none`과 `visibility: hidden`, `opacity: 0` 차이는?](#20-display-none과-visibility-hidden-opacity-0-차이는)
21. [요소를 시각적으로만 숨기되 스크린리더엔 남기려면?](#21-요소를-시각적으로만-숨기되-스크린리더엔-남기려면)
22. [`transition`과 `animation` 차이는?](#22-transition과-animation-차이는)
23. [리플로우를 유발하지 않는 애니메이션 속성은?](#23-리플로우를-유발하지-않는-애니메이션-속성은)
24. [CSS 변수(커스텀 속성)의 장점은?](#24-css-변수커스텀-속성의-장점은)
25. [반응형에서 이미지 어떻게 다루나요?](#25-반응형에서-이미지-어떻게-다루나요)

---

## 1. 시맨틱 HTML이란 무엇이고 왜 쓰나요?

**답변:**
의미를 가진 태그(`header`, `nav`, `main`, `article`, `footer`)로 문서 구조를 표현하는 것. 접근성(스크린리더 랜드마크), SEO, 유지보수성이 좋아지고 CSS/JS 선택도 명확해진다. `div` 남용은 의미를 잃는다.

## 2. `<script>`의 `defer`와 `async` 차이는?

**답변:**
둘 다 다운로드를 병렬로 해 파서를 막지 않는다. `defer`는 HTML 파싱 완료 후 **문서 순서대로** 실행(DOMContentLoaded 전), `async`는 **다운로드 끝나는 즉시** 순서 무관 실행. 의존성 있는 앱 번들은 `defer`, 독립적 분석 스크립트는 `async`.

## 3. 블록 요소와 인라인 요소의 차이는?

**답변:**
블록(`div`, `p`)은 가로 전체를 차지하고 줄바꿈되며 width/height·수직 margin이 적용된다. 인라인(`span`, `a`)은 콘텐츠 폭만 차지하고 width/height·수직 margin이 무시된다. `inline-block`은 인라인처럼 배치되되 박스 속성이 적용된다.

## 4. `data-*` 속성은 무엇인가요?

**답변:**
커스텀 데이터를 마크업에 담는 표준 속성. JS에서 `element.dataset.key`로 접근, CSS에서 `[data-state="open"]`로 선택. 상태·식별자를 비표준 속성 대신 안전하게 저장한다.

## 5. meta viewport는 무슨 역할인가요?

**답변:**
`<meta name="viewport" content="width=device-width, initial-scale=1">`은 모바일에서 뷰포트 폭을 기기 폭에 맞춰 반응형이 동작하게 한다. 없으면 데스크탑 폭(980px)으로 렌더 후 축소돼 글씨가 작아진다.

## 6. 박스 모델과 `box-sizing`은?

**답변:**
요소는 content + padding + border + margin으로 구성된다. 기본 `content-box`는 width가 content만 의미해 padding/border가 더해져 실제 크기가 커진다. `border-box`는 width에 padding+border를 포함해 크기 계산이 직관적이라 보통 전역 적용한다.

## 7. `margin collapse`(마진 병합)란?

**답변:**
인접한 블록의 수직 margin이 합쳐지지 않고 **더 큰 값 하나로 병합**되는 현상(부모-자식, 형제 간). 가로 margin·flex/grid 아이템에는 없다. BFC 생성, padding/border 삽입, flex 레이아웃으로 회피한다.

## 8. BFC(Block Formatting Context)란?

**답변:**
독립적인 블록 레이아웃 영역. 내부 요소가 외부에 영향을 주지 않는다. `overflow: hidden/auto`, `display: flow-root`, float, flex/grid 컨테이너 등이 BFC를 만든다. float 해제, margin collapse 방지, 텍스트가 float를 감싸지 않게 할 때 쓴다.

## 9. `position` 속성 5가지 차이는?

**답변:**
`static`(기본, 흐름대로), `relative`(자기 위치 기준 이동, 공간 유지), `absolute`(가장 가까운 positioned 조상 기준, 흐름 이탈), `fixed`(뷰포트 기준 고정), `sticky`(스크롤 임계점까지 relative였다가 fixed처럼 붙음).

## 10. stacking context(쌓임 맥락)와 z-index는?

**답변:**
z-index는 같은 쌓임 맥락 안에서만 비교된다. `position`+z-index, `opacity<1`, `transform`, `filter`, `will-change` 등이 새 쌓임 맥락을 만든다. 그래서 z-index를 아무리 높여도 부모 맥락에 갇혀 다른 맥락 위로 못 올라가는 일이 생긴다.

## 11. Flexbox와 Grid의 차이와 선택 기준은?

**답변:**
Flexbox는 1차원(행 또는 열) 배치, Grid는 2차원(행과 열 동시) 배치. 콘텐츠 흐름·정렬 위주는 Flex(네비, 버튼 그룹), 페이지/카드 레이아웃처럼 행·열 격자는 Grid. 둘을 중첩해 함께 쓴다.

## 12. 요소를 가운데 정렬하는 방법은?

**답변:**
가장 간단: 부모에 `display: flex; justify-content: center; align-items: center;` (또는 `display: grid; place-items: center;`). 블록 가로 중앙은 `margin: 0 auto`+width. 인라인은 `text-align: center`.

## 13. CSS 명시도(specificity) 계산은?

**답변:**
(인라인, ID, 클래스/속성/의사클래스, 요소/의사요소) 네 자리 가중치로 비교한다. 예: `#id`(1,0,0) > `.a.b`(0,2,0) > `div`(0,0,1). 같으면 나중 선언이 이긴다. `!important`는 이를 무시(남용 금지), `:where()`는 명시도 0이라 덮어쓰기 쉬운 기본값에 좋다.

## 14. 캐스케이드와 상속은?

**답변:**
캐스케이드는 여러 규칙이 충돌할 때 출처(origin)·레이어·명시도·선언 순서로 승자를 정하는 것. 상속은 일부 속성(color, font 등)이 자식으로 전달되는 것. `inherit`/`initial`/`unset`/`revert`로 명시 제어한다.

## 15. `:where()`와 `:is()`의 차이는?

**답변:**
둘 다 선택자 목록을 묶어 간결하게 한다. 차이는 명시도: `:is()`는 인자 중 가장 높은 명시도를 따르고, `:where()`는 항상 명시도 0이다. 덮어쓰기 쉬운 라이브러리 기본 스타일에는 `:where()`가 유용하다.

## 16. 의사 클래스와 의사 요소의 차이는?

**답변:**
의사 클래스(`:hover`, `:focus`, `:nth-child`)는 요소의 **상태·위치**를 선택. 의사 요소(`::before`, `::after`, `::first-line`)는 존재하지 않는 **가상 요소**를 만들거나 일부를 선택. 의사 요소는 `::`(이중 콜론) 표기.

## 17. `px`, `em`, `rem`, `%`, `vw/vh` 차이는?

**답변:**
`px` 절대값, `em` 부모 폰트 크기 기준(중첩 시 누적), `rem` 루트(html) 폰트 크기 기준(예측 가능), `%` 부모 기준 비율, `vw/vh` 뷰포트 기준. 접근성(사용자 폰트 확대)을 위해 폰트·간격은 `rem`을 권장한다.

## 18. 모바일 우선 vs 데스크탑 우선?

**답변:**
모바일 우선은 기본을 모바일로 두고 `min-width`로 키운다(점진적 향상). 데스크탑 우선은 기본을 데스크탑으로 두고 `max-width`로 줄인다. 모바일 우선이 성능(작은 화면에 불필요 스타일 안 줌)과 유지보수에 유리해 표준이다.

## 19. `rem` 기반 설계의 장점은?

**답변:**
모든 크기가 루트 폰트 크기에 비례해, 루트만 바꾸면 전체 스케일이 일관되게 조정된다. 사용자가 브라우저 기본 폰트를 키우면 레이아웃이 함께 커져 접근성에 좋다. `em`의 중첩 누적 문제도 없다.

## 20. `display: none`과 `visibility: hidden`, `opacity: 0` 차이는?

**답변:**
`display: none`은 렌더 트리에서 제거(공간 X, 접근성 트리 X, 포커스 X). `visibility: hidden`은 공간 유지하되 안 보임(포커스 X). `opacity: 0`은 공간·이벤트·포커스 모두 유지하되 투명. 클릭 가능 여부·레이아웃 유지 여부로 선택한다.

## 21. 요소를 시각적으로만 숨기되 스크린리더엔 남기려면?

**답변:**
`display:none`/`visibility:hidden`은 스크린리더에서도 사라진다. 시각적으로만 숨기려면 `.sr-only` 패턴(절대 위치 + 1px 클립 + overflow hidden)을 쓴다. 스킵 링크 라벨, 아이콘 버튼의 대체 텍스트 등에 사용.

## 22. `transition`과 `animation` 차이는?

**답변:**
`transition`은 상태 변화(hover 등) 시 A→B로 보간, 트리거 필요·단방향. `animation`은 `@keyframes`로 다단계·반복·자동재생 가능, 트리거 없이 동작. 단순 상태 전환은 transition, 복잡한 시퀀스는 animation.

## 23. 리플로우를 유발하지 않는 애니메이션 속성은?

**답변:**
`transform`과 `opacity`. 이 둘은 레이아웃·페인트를 건너뛰고 GPU 컴포지터에서 처리돼 60fps에 유리하다. `width/height/top/left`로 애니메이션하면 매 프레임 reflow가 발생해 버벅인다.

## 24. CSS 변수(커스텀 속성)의 장점은?

**답변:**
`--color: #1a73e8;` / `var(--color)`로 값을 한곳에서 관리하고 런타임에 JS로 변경 가능(다크모드·테마). Sass 변수와 달리 **상속·캐스케이드를 따르고 런타임에 살아있다**. 미디어쿼리·`:root`로 동적 토큰을 만든다.

## 25. 반응형에서 이미지 어떻게 다루나요?

**답변:**
`max-width:100%; height:auto`로 넘침 방지, `srcset`+`sizes`로 기기별 해상도 제공, `<picture>`로 아트 디렉션·포맷 분기(AVIF/WebP). `width/height` 또는 `aspect-ratio`로 CLS를 막고, off-screen 이미지는 `loading="lazy"`.
