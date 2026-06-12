# 5. Reflow & Repaint

## 목차
1. Reflow와 Repaint 개념
2. Reflow 발생 원인
3. Repaint 발생 원인
4. Layout Thrashing
5. 최적화 기법
6. 성능 측정 도구
7. 면접 포인트

---

## 1. Reflow와 Repaint 개념

렌더링 파이프라인에서 변경이 발생하면 어느 단계부터 다시 처리해야 하는지가 성능에 직결됩니다.

```
변경 발생
    │
    ▼ 기하학적 속성(위치, 크기) 변경 시
[Reflow (Layout)]  ← 가장 비쌈
    │
    ▼ 항상
[Repaint (Paint)]
    │
    ▼ 항상
[Composite]

    또는

변경 발생
    │
    ▼ 색상, 배경 등 기하학적 변경 없을 때
[Repaint만]
    │
    ▼
[Composite]

    또는 (가장 빠름)

변경 발생
    │
    ▼ transform, opacity만 변경 시
[Composite만] ← Layout, Paint 건너뜀
```

### 비용 비교

| 단계 | 비용 | 예시 속성 |
|------|------|-----------|
| Reflow + Repaint + Composite | 가장 높음 | width, height, top, left, margin, padding, font-size |
| Repaint + Composite | 보통 | color, background-color, border-color, visibility, box-shadow |
| Composite만 | 가장 낮음 | transform, opacity |

---

## 2. Reflow 발생 원인

Reflow는 요소의 기하학적 정보(크기, 위치)가 변경되어 레이아웃을 다시 계산해야 할 때 발생합니다.

```javascript
// Reflow를 유발하는 CSS 속성 변경
el.style.width   = "200px";  // Reflow
el.style.height  = "100px";  // Reflow
el.style.margin  = "10px";   // Reflow
el.style.padding = "5px";    // Reflow
el.style.top     = "50px";   // Reflow (position 지정 시)
el.style.left    = "50px";   // Reflow
el.style.fontSize = "18px";  // Reflow (텍스트 크기 변경)
el.style.display = "none";   // Reflow + Render Tree 변경
el.style.display = "block";  // Reflow

// Reflow를 유발하는 DOM 조작
parent.appendChild(child);   // Reflow
parent.removeChild(child);   // Reflow
el.innerHTML = "<p>...</p>"; // Reflow

// Reflow를 유발하는 속성/메서드 읽기 (강제 동기 Reflow)
// 쓰기 후 즉시 읽으면 최신 값을 위해 즉시 Reflow 실행
const h = el.offsetHeight;          // Reflow
const w = el.offsetWidth;           // Reflow
const t = el.offsetTop;             // Reflow
const l = el.offsetLeft;            // Reflow
const sw = el.scrollWidth;          // Reflow
const sh = el.scrollHeight;         // Reflow
const rect = el.getBoundingClientRect(); // Reflow
const cs = window.getComputedStyle(el);  // Reflow
const sw2 = el.scrollTop;          // (read, no Reflow in Chrome but may vary)
```

### Reflow 범위

```
Reflow의 영향 범위는 변경된 요소에 따라 달라짐

document.body.style.fontSize = "20px"
→ 전체 페이지 Reflow (body는 모든 요소의 조상)

el.style.width = "300px" (position: fixed 요소)
→ 해당 레이어만 Reflow (독립 레이아웃 컨텍스트)

el.style.width = "300px" (일반 flow 요소)
→ 형제/자식 요소 포함 넓은 범위 Reflow
```

---

## 3. Repaint 발생 원인

Repaint는 요소의 시각적 모양이 변경되지만 기하학적 위치는 변경되지 않을 때 발생합니다.

```javascript
// Repaint를 유발하는 CSS 속성 (Layout 건너뜀)
el.style.color           = "red";
el.style.backgroundColor = "#fff";
el.style.borderColor     = "blue";
el.style.boxShadow       = "0 2px 4px rgba(0,0,0,0.1)";
el.style.outline         = "2px solid red";
el.style.visibility      = "hidden"; // Repaint O, Reflow X (공간 유지)
el.style.textDecoration  = "underline";
el.style.backgroundImage = "url(...)";
```

---

## 4. Layout Thrashing (레이아웃 스래싱)

쓰기(write)와 읽기(read)를 번갈아 가면서 강제로 여러 번 Reflow를 유발하는 패턴입니다. 가장 흔한 성능 저하 원인입니다.

```javascript
// 나쁜 패턴: 읽기-쓰기 교차 → 매 반복마다 Reflow
const boxes = document.querySelectorAll(".box");

for (const box of boxes) {
  const width = box.offsetWidth;   // 읽기 → Reflow 강제 실행
  box.style.width = width + 10 + "px"; // 쓰기 → 다음 읽기 때 Reflow 다시
}

// 좋은 패턴: 읽기 → 쓰기 분리 (배치 읽기, 배치 쓰기)
const boxes2 = document.querySelectorAll(".box");

// 1. 먼저 모든 읽기 작업
const widths = Array.from(boxes2).map(box => box.offsetWidth); // Reflow 1번

// 2. 그 다음 모든 쓰기 작업
boxes2.forEach((box, i) => {
  box.style.width = widths[i] + 10 + "px"; // Reflow 예약만 됨
}); // Reflow 1번으로 처리됨 (브라우저가 배치 처리)

// requestAnimationFrame으로 쓰기 작업 타이밍 맞추기
function updateLayout() {
  const width = el.offsetWidth; // 읽기 (이전 프레임의 값)

  requestAnimationFrame(() => {
    el.style.width = width + 10 + "px"; // 쓰기 (렌더링 직전)
  });
}

// FastDOM 라이브러리 패턴
// fastdom.measure(() => { const w = el.offsetWidth; })
// fastdom.mutate(() => { el.style.width = "..."; })
```

---

## 5. 최적화 기법

### 기법 1: CSS 클래스 전환 (한 번의 Reflow)

```javascript
// 나쁨: 여러 번 style 직접 수정
el.style.width    = "300px";
el.style.height   = "200px";
el.style.fontSize = "18px";
el.style.padding  = "20px"; // 4번의 Reflow 예약

// 좋음: 클래스 추가로 한 번에 처리
el.classList.add("expanded");
// .expanded { width: 300px; height: 200px; font-size: 18px; padding: 20px; }

// 또는 cssText로 한 번에
el.style.cssText = "width:300px; height:200px; font-size:18px; padding:20px;";
```

### 기법 2: DOM 요소를 분리해서 수정

```javascript
// DOM에서 분리 → 수정 → 다시 추가
el.style.display = "none";     // Reflow 1번
// 많은 수정 작업...
el.style.width = "200px";
el.style.height = "100px";
el.style.display = "block";    // Reflow 1번
// 총 2번의 Reflow (중간 수정은 화면에 없으므로 최적화됨)

// DocumentFragment 사용
const frag = document.createDocumentFragment();
for (let i = 0; i < 1000; i++) {
  const li = document.createElement("li");
  li.textContent = `Item ${i}`;
  frag.appendChild(li); // Fragment는 DOM 외부, Reflow 없음
}
list.appendChild(frag); // Reflow 1번
```

### 기법 3: CSS transform/opacity 활용

```css
/* 느린 애니메이션: Reflow 유발 */
.box {
  transition: left 0.3s, top 0.3s, width 0.3s;
}

/* 빠른 애니메이션: Composite만 */
.box {
  transition: transform 0.3s, opacity 0.3s;
}
.box.moved {
  transform: translateX(100px) translateY(50px);
}
```

```javascript
// 위치 이동은 left/top 대신 transform 사용
// 나쁨
el.style.left = `${x}px`;
el.style.top  = `${y}px`;

// 좋음 (Composite만)
el.style.transform = `translate(${x}px, ${y}px)`;
```

### 기법 4: will-change (적절히 사용)

```css
/* 애니메이션 시작 전에만 적용 */
.card {
  transition: transform 0.3s;
}
.card:hover {
  will-change: transform; /* 호버 시 GPU 레이어 승격 */
}

/* 또는 JS로 동적 관리 */
```

```javascript
// 애니메이션 시작 전 추가, 완료 후 제거
el.addEventListener("mouseenter", () => {
  el.style.willChange = "transform";
});
el.addEventListener("animationend", () => {
  el.style.willChange = "auto"; // 제거
});
```

### 기법 5: 가상화 (Virtual Scrolling)

```javascript
// 수천 개 아이템을 모두 DOM에 넣지 않고 보이는 것만 렌더링
// 라이브러리: react-window, react-virtual, @tanstack/virtual

// 핵심 원리
const visibleItems = items.slice(startIndex, endIndex);
// 나머지는 height만큼의 placeholder div로 대체
// 스크롤 시 startIndex, endIndex 업데이트
```

### 기법 6: Passive Event Listener

```javascript
// scroll, touchstart 등에 passive:true 추가
// 브라우저가 preventDefault()를 기다리지 않고 스크롤 즉시 처리
document.addEventListener("scroll", handler, { passive: true });
document.addEventListener("touchstart", handler, { passive: true });
```

---

## 6. 성능 측정 도구

```javascript
// Performance API
const t0 = performance.now();
// 측정할 작업
const t1 = performance.now();
console.log(`${t1 - t0}ms`);

// User Timing API
performance.mark("start");
// 작업
performance.mark("end");
performance.measure("task", "start", "end");
const measures = performance.getEntriesByType("measure");

// Long Tasks API (50ms 이상 걸리는 태스크 감지)
const observer = new PerformanceObserver((list) => {
  for (const entry of list.getEntries()) {
    console.warn("Long task:", entry.duration, "ms");
  }
});
observer.observe({ entryTypes: ["longtask"] });

// Layout Instability API (CLS 측정)
const clsObserver = new PerformanceObserver((list) => {
  for (const entry of list.getEntries()) {
    if (!entry.hadRecentInput) {
      console.log("Layout shift:", entry.value);
    }
  }
});
clsObserver.observe({ entryTypes: ["layout-shift"] });
```

### Chrome DevTools 활용

```
Performance 패널:
  - Record 후 분석
  - "Layout" 이벤트: Reflow 발생 위치
  - "Paint" 이벤트: Repaint 발생 위치
  - 빨간색 막대: Long Task (50ms 이상)

Rendering 패널:
  - Paint flashing: 노란색으로 Repaint 영역 표시
  - Layout Shift Regions: 파란색으로 Layout Shift 표시
  - FPS meter: 실시간 프레임율

Layers 패널:
  - 합성 레이어 시각화
  - 메모리 사용량 확인
```

---

## 7. 면접 포인트

### Q1. Reflow와 Repaint의 차이점은?

Reflow(Layout)는 요소의 기하학적 정보(크기, 위치, 레이아웃)가 변경되어 브라우저가 영향받는 모든 요소의 위치와 크기를 재계산해야 하는 과정입니다. Repaint는 기하학적 변화 없이 색상, 배경 등 시각적 표현만 바뀔 때 해당 영역을 다시 그리는 과정입니다. Reflow가 발생하면 Repaint도 항상 따라오지만, Repaint는 Reflow 없이 발생할 수 있습니다.

### Q2. Layout Thrashing이란 무엇이고 어떻게 방지하나요?

DOM 쓰기 후 즉시 레이아웃 정보를 읽으면 브라우저가 배치 처리(배칭)를 포기하고 강제로 동기 Reflow를 실행합니다. 이게 루프에서 반복되면 수십~수백 번의 Reflow가 발생합니다. 방지법: 모든 읽기(offsetWidth 등)를 먼저 수행하고, 이후에 모든 쓰기(style 변경)를 수행합니다. 또는 `requestAnimationFrame`으로 쓰기를 다음 프레임으로 미룹니다.

### Q3. CSS `transform`으로 이동하는 것이 `top/left` 변경보다 성능이 좋은 이유는?

`top/left` 변경은 Layout(Reflow) → Paint → Composite 전 단계를 거칩니다. 반면 `transform`은 합성 레이어에서 처리되므로 Composite 단계만 거치고, 이 작업은 GPU thread에서 처리됩니다. 결과적으로 main thread를 점유하지 않아 JS 실행과 겹쳐도 프레임이 떨어지지 않아 60fps를 유지하기 쉽습니다.

### Q4. `will-change`를 남용하면 생기는 문제는?

`will-change`가 설정된 요소는 별도의 GPU 합성 레이어로 승격됩니다. 레이어가 많을수록 GPU 메모리 사용량이 증가하고, 레이어 합성(Composite) 비용도 올라갑니다. 모바일처럼 메모리가 제한된 환경에서는 오히려 성능이 저하됩니다. 실제로 애니메이션하는 요소에만, 직전에 추가하고 직후에 제거하는 방식으로 사용해야 합니다.

### Q5. `display: none`과 `visibility: hidden`의 렌더링 차이는?

`display: none`은 Render Tree에서 요소를 완전히 제거합니다. 공간도 없고 이벤트도 발생하지 않습니다. 변경 시 Reflow가 발생합니다. `visibility: hidden`은 Render Tree에 남아 공간을 차지하지만 화면에는 보이지 않습니다. 변경 시 Reflow 없이 Repaint만 발생합니다. 자식 요소에 `visibility: visible`을 주면 부모가 hidden이어도 자식은 보입니다.
