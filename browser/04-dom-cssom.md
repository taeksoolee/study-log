# 4. DOM & CSSOM

## 목차
1. DOM 개요와 구조
2. DOM API
3. CSSOM
4. MutationObserver
5. IntersectionObserver
6. ResizeObserver
7. 면접 포인트

---

## 1. DOM 개요와 구조

DOM(Document Object Model)은 HTML 문서를 프로그래밍적으로 접근하고 조작할 수 있는 트리 구조 API입니다.

```
Node (모든 DOM 노드의 기반)
  ├── Document (문서 루트)
  ├── Element (HTML 요소)
  │     ├── HTMLElement
  │     │     ├── HTMLDivElement
  │     │     ├── HTMLInputElement
  │     │     └── ...
  │     └── SVGElement
  ├── Attr (속성)
  ├── Text (텍스트 노드)
  ├── Comment (주석)
  └── DocumentFragment (가상 문서 조각)
```

### Node 타입 상수

```javascript
Node.ELEMENT_NODE       // 1: 요소 노드
Node.TEXT_NODE          // 3: 텍스트 노드
Node.COMMENT_NODE       // 8: 주석 노드
Node.DOCUMENT_NODE      // 9: document
Node.DOCUMENT_FRAGMENT_NODE // 11: DocumentFragment

// 확인
console.log(document.nodeType);          // 9
console.log(document.body.nodeType);     // 1
console.log(document.createTextNode("").nodeType); // 3
```

---

## 2. DOM API

### 노드 선택

```javascript
// 단일 요소 선택
const el1 = document.getElementById("myId");
const el2 = document.querySelector(".myClass");       // CSS 선택자
const el3 = document.querySelector("div > p.text");   // 복잡한 선택자

// 여러 요소 선택
const els1 = document.querySelectorAll("li");          // NodeList (정적)
const els2 = document.getElementsByClassName("item");  // HTMLCollection (동적)
const els3 = document.getElementsByTagName("div");     // HTMLCollection (동적)

// 정적 vs 동적 컬렉션
const staticList = document.querySelectorAll("p");  // 스냅샷, 이후 변경 미반영
const liveList = document.getElementsByTagName("p"); // 실시간 반영

// 탐색
const parent   = el.parentElement;
const children = el.children;              // HTMLCollection (요소만)
const childNodes = el.childNodes;          // NodeList (텍스트 포함)
const next     = el.nextElementSibling;
const prev     = el.previousElementSibling;
const first    = el.firstElementChild;
const last     = el.lastElementChild;

// closest: 가장 가까운 조상 찾기 (자신 포함)
const row = el.closest("tr");

// matches: CSS 선택자와 일치 여부
const isActive = el.matches(".active");
```

### 노드 생성과 조작

```javascript
// 요소 생성
const div = document.createElement("div");
const text = document.createTextNode("Hello");
const fragment = document.createDocumentFragment();

// 속성 조작
div.id = "container";
div.className = "box active";
div.setAttribute("data-id", "42");
const val = div.getAttribute("data-id");
div.removeAttribute("data-id");
div.hasAttribute("data-id"); // false

// classList API
div.classList.add("new-class");
div.classList.remove("old-class");
div.classList.toggle("active");
div.classList.contains("active"); // boolean
div.classList.replace("old", "new");

// 내용 조작
div.textContent = "안전한 텍스트"; // XSS 안전, HTML 이스케이프됨
div.innerHTML = "<span>위험!</span>"; // XSS 주의!
div.insertAdjacentHTML("beforeend", "<p>삽입</p>"); // innerHTML보다 안전하고 빠름
// beforebegin, afterbegin, beforeend, afterend

// DOM 조작 (Reflow 유발)
parent.appendChild(div);
parent.insertBefore(div, referenceNode);
parent.removeChild(div);
parent.replaceChild(newNode, oldNode);

// 현대적 API (더 직관적)
parent.append(div, "텍스트도 가능");
parent.prepend(div);
div.remove();
div.replaceWith(newNode);
div.before(newNode);
div.after(newNode);

// DocumentFragment로 배치 최적화
// 여러 번 DOM 변경 대신 Fragment에 모아서 한 번에 추가
const frag = document.createDocumentFragment();
for (let i = 0; i < 100; i++) {
  const li = document.createElement("li");
  li.textContent = `Item ${i}`;
  frag.appendChild(li); // Fragment는 DOM에 없으므로 Reflow 없음
}
ul.appendChild(frag); // 한 번의 Reflow

// cloneNode
const clone = div.cloneNode(true); // true: 자식 포함 깊은 복사
```

### 이벤트

```javascript
// 이벤트 등록
el.addEventListener("click", handler, { capture: false, once: true, passive: true });
el.removeEventListener("click", handler);

// 이벤트 위임 (Event Delegation): 부모에 등록해 동적 요소까지 처리
document.querySelector("ul").addEventListener("click", (e) => {
  const li = e.target.closest("li");
  if (!li) return;
  console.log("Clicked:", li.textContent);
});

// 이벤트 전파
// Capture 단계: 최상위(document) → 대상
// Target 단계: 이벤트 발생 요소
// Bubble 단계: 대상 → 최상위(document)
e.stopPropagation();  // 버블링/캡처 중단
e.stopImmediatePropagation(); // 같은 요소의 다른 리스너도 중단
e.preventDefault();   // 기본 동작 방지

// 커스텀 이벤트
const event = new CustomEvent("myEvent", {
  detail: { userId: 123 },
  bubbles: true,
  cancelable: true,
});
el.dispatchEvent(event);

el.addEventListener("myEvent", (e) => {
  console.log(e.detail.userId); // 123
});
```

---

## 3. CSSOM

CSSOM(CSS Object Model)은 CSS를 JavaScript로 조작하는 API입니다.

```javascript
// CSS 스타일 접근
const style = window.getComputedStyle(el);
console.log(style.fontSize);   // "16px" (계산된 최종 값)
console.log(style.color);      // "rgb(0, 0, 0)"

// inline style 직접 설정 (Reflow/Repaint 유발 주의)
el.style.color = "red";
el.style.transform = "translateX(100px)"; // Composite만 유발 (최적)
el.style.cssText = "color: red; font-size: 18px;"; // 한 번에 설정

// CSS 커스텀 프로퍼티(변수) 조작
document.documentElement.style.setProperty("--primary-color", "#007bff");
const color = style.getPropertyValue("--primary-color");

// StyleSheet API
const sheets = document.styleSheets;         // StyleSheetList
const sheet  = sheets[0];                    // CSSStyleSheet
const rules  = sheet.cssRules;               // CSSRuleList

// 규칙 동적 추가/삭제 (재파싱 없이 CSSOM 직접 수정)
const idx = sheet.insertRule(".highlight { background: yellow; }", sheet.cssRules.length);
sheet.deleteRule(idx);

// CSS Typed OM (현대적 API, 단위 정보 포함)
el.attributeStyleMap.set("opacity", 0.5);
el.attributeStyleMap.set("font-size", CSS.px(16));
const opacity = el.attributeStyleMap.get("opacity");
```

---

## 4. MutationObserver

DOM 트리의 변경(자식 추가/제거, 속성 변경, 텍스트 변경)을 비동기적으로 감지합니다. 구식 Mutation Events보다 성능이 좋습니다.

```javascript
// 기본 사용
const observer = new MutationObserver((mutations, obs) => {
  for (const mutation of mutations) {
    if (mutation.type === "childList") {
      console.log("자식 변경:", mutation.addedNodes, mutation.removedNodes);
    }
    if (mutation.type === "attributes") {
      console.log(`${mutation.attributeName} 속성 변경:`, mutation.oldValue);
    }
    if (mutation.type === "characterData") {
      console.log("텍스트 변경:", mutation.target.textContent);
    }
  }
});

observer.observe(document.body, {
  childList:     true,  // 직계 자식 추가/제거 감시
  subtree:       true,  // 모든 하위 노드 포함
  attributes:    true,  // 속성 변경 감시
  attributeFilter: ["class", "style"], // 특정 속성만
  attributeOldValue: true, // 변경 전 값 저장
  characterData:  true, // 텍스트 변경 감시
  characterDataOldValue: true,
});

observer.disconnect(); // 감시 중단
observer.takeRecords(); // 미처리 레코드 즉시 가져오기

// 실용 예시: 동적 컴포넌트 감지 (라이브러리/폴리필에서 사용)
const bodyObserver = new MutationObserver((mutations) => {
  for (const mutation of mutations) {
    mutation.addedNodes.forEach(node => {
      if (node.nodeType === Node.ELEMENT_NODE) {
        // 새로 추가된 요소에 초기화 로직 적용
        if ((node as Element).matches("[data-widget]")) {
          initWidget(node as Element);
        }
      }
    });
  }
});

bodyObserver.observe(document.body, { childList: true, subtree: true });
```

---

## 5. IntersectionObserver

요소가 뷰포트(또는 다른 요소)와 교차(intersect)하는지 비동기적으로 감지합니다. Scroll 이벤트보다 성능이 훨씬 좋습니다.

```javascript
// 기본 사용: lazy loading
const imageObserver = new IntersectionObserver(
  (entries, observer) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        const img = entry.target as HTMLImageElement;
        img.src = img.dataset.src!; // 실제 이미지 로드
        observer.unobserve(img);    // 한 번 로드 후 감시 해제
      }
    });
  },
  {
    root: null,         // null = 뷰포트
    rootMargin: "0px 0px 200px 0px", // 200px 아래에서 미리 로드
    threshold: 0.1,     // 10% 이상 보일 때 콜백 (0~1 또는 배열)
  }
);

document.querySelectorAll("img[data-src]").forEach(img => {
  imageObserver.observe(img);
});

// 무한 스크롤
const sentinel = document.querySelector("#load-more-sentinel");
const scrollObserver = new IntersectionObserver(entries => {
  if (entries[0].isIntersecting) {
    loadMoreItems();
  }
});
scrollObserver.observe(sentinel);

// 애니메이션 트리거
const animObserver = new IntersectionObserver(
  (entries) => {
    entries.forEach(entry => {
      entry.target.classList.toggle("animate", entry.isIntersecting);
    });
  },
  { threshold: 0.2 }
);

document.querySelectorAll(".animate-on-scroll").forEach(el => {
  animObserver.observe(el);
});

// entry 속성
// entry.isIntersecting: 교차 중인지
// entry.intersectionRatio: 교차 비율 (0~1)
// entry.boundingClientRect: 요소의 DOMRect
// entry.intersectionRect: 교차 영역
// entry.rootBounds: root 요소의 DOMRect
// entry.time: 교차 발생 타임스탬프
```

---

## 6. ResizeObserver

요소의 크기 변화를 감지합니다. `window.resize` 이벤트보다 세밀하고 효율적입니다.

```javascript
const resizeObserver = new ResizeObserver(entries => {
  for (const entry of entries) {
    const { width, height } = entry.contentRect;
    console.log(`Element size: ${width}px × ${height}px`);

    // contentBoxSize, borderBoxSize (TS 4.x+)
    const { inlineSize, blockSize } = entry.contentBoxSize[0];
  }
});

resizeObserver.observe(document.querySelector(".resizable"));
resizeObserver.unobserve(el);
resizeObserver.disconnect();

// 반응형 컴포넌트 예시
resizeObserver.observe(chart, {
  box: "border-box" // "content-box" (기본) | "border-box" | "device-pixel-content-box"
});
```

---

## 7. 면접 포인트

### Q1. `innerHTML`과 `textContent`의 차이와 XSS 위험성은?

`textContent`는 HTML 태그를 이스케이프해서 순수 텍스트로 삽입하므로 XSS 안전합니다. `innerHTML`은 HTML을 파싱해 삽입하므로 사용자 입력을 직접 넣으면 XSS 공격에 취약합니다. 사용자 입력을 표시할 때는 `textContent` 또는 DOMPurify 같은 sanitizer를 사용해야 합니다.

### Q2. MutationObserver와 구식 Mutation Events의 차이점은?

Mutation Events는 동기식으로 DOM 변경마다 즉시 이벤트를 발생시켜 레이아웃 스래싱(layout thrashing)을 유발하고 성능이 나빴습니다. MutationObserver는 비동기 배치 처리로, 변경 내역을 모아서 마이크로태스크 큐에서 한 번에 콜백으로 전달합니다. 성능이 크게 개선되었고, Mutation Events는 이미 deprecated 되었습니다.

### Q3. IntersectionObserver가 scroll 이벤트보다 좋은 이유는?

scroll 이벤트는 스크롤할 때마다 main thread에서 동기적으로 실행되어 `getBoundingClientRect()` 같은 레이아웃 읽기를 유발합니다. IntersectionObserver는 브라우저 내부(별도 스레드)에서 교차를 계산하고, 변경이 생겼을 때만 비동기로 콜백을 전달합니다. Scroll 이벤트 + throttle 조합보다 성능과 배터리 효율이 훨씬 좋습니다.

### Q4. `getComputedStyle`과 `element.style`의 차이는?

`element.style`은 인라인 스타일만 반환합니다. 값이 없으면 빈 문자열입니다. `getComputedStyle(el)`은 모든 CSS 출처(외부 스타일시트, 인라인, 기본값 등)가 적용된 최종 계산 값을 반환합니다. 단, `getComputedStyle` 호출은 Forced Layout을 유발할 수 있으므로, 루프 안에서 반복 호출은 피해야 합니다.
