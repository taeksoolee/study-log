# 2. 렌더링 파이프라인

## 목차
1. 렌더링 파이프라인 개요
2. HTML 파싱 → DOM
3. CSS 파싱 → CSSOM
4. Render Tree 생성
5. Layout (Reflow)
6. Paint
7. Composite
8. 면접 포인트

---

## 1. 렌더링 파이프라인 개요

```
HTML 바이트
    │ 문자 디코딩
    ▼
토큰화 (Tokenization)
    │
    ▼
DOM Tree 생성 ◄──── CSS 파싱 ──── CSSOM Tree 생성
    │                                    │
    └──────────────┬─────────────────────┘
                   ▼
            Render Tree (렌더 트리)
                   │
                   ▼
              Layout (위치/크기 계산)
                   │
                   ▼
              Paint (픽셀 채우기)
                   │
                   ▼
           Composite (레이어 합성 → GPU)
                   │
                   ▼
              화면 출력
```

각 단계는 CPU에서 실행되며, Composite 단계는 GPU(Graphics Processing Unit)의 도움을 받습니다.

---

## 2. HTML 파싱 → DOM

### 파싱 과정

```
HTML 바이트 스트림
         │
         ▼ 바이트 → 문자 (인코딩 변환)
    "< h t m l > ..."
         │
         ▼ 토큰화 (Tokenizer)
    [StartTag: html] [StartTag: head] [EndTag: head] ...
         │
         ▼ 트리 구성 (Tree Constructor)
    DOM Tree
```

### DOM 트리 예시

```html
<!DOCTYPE html>
<html>
  <head><title>Hello</title></head>
  <body>
    <h1 id="title">Welcome</h1>
    <p class="text">Hello World</p>
  </body>
</html>
```

```
Document
  └── html (HTMLHtmlElement)
        ├── head (HTMLHeadElement)
        │     └── title (HTMLTitleElement)
        │           └── "Hello" (Text)
        └── body (HTMLBodyElement)
              ├── h1 (HTMLHeadingElement) [id="title"]
              │     └── "Welcome" (Text)
              └── p (HTMLParagraphElement) [class="text"]
                    └── "Hello World" (Text)
```

### 파서 차단 (Parser Blocking)

```javascript
// 인라인 스크립트는 파싱을 즉시 차단
// DOM이 완성되기 전에 실행되므로 이후 요소에 접근 불가

// 안전한 접근: DOMContentLoaded 후 실행
document.addEventListener('DOMContentLoaded', () => {
  const el = document.getElementById('title');
});
```

---

## 3. CSS 파싱 → CSSOM

HTML 파싱과 병렬로 진행되지만, **CSSOM이 완성될 때까지 렌더링을 차단**합니다. (스타일 없이 렌더링하면 FOUC 발생)

```css
body { font-size: 16px; }
h1   { font-size: 2em; color: #333; }
p    { color: blue; }
```

```
CSSOM Tree:
body [font-size: 16px]
  └── h1 [font-size: 32px, color: #333]  ← em은 부모 기준 계산됨
  └── p  [color: blue]
```

### 스타일 시트 우선순위 (캐스케이딩)

```
낮음 ←─────────────────────────────── 높음

브라우저 기본값  →  사용자 에이전트  →  작성자 CSS  →  inline  →  !important
                                        └── specificity(명시도) 순서
```

명시도(Specificity) 계산:
- `!important`: 최우선
- inline style: (1, 0, 0, 0)
- ID 선택자: (0, 1, 0, 0)
- 클래스/가상클래스/속성: (0, 0, 1, 0)
- 요소/가상요소: (0, 0, 0, 1)

---

## 4. Render Tree 생성

DOM과 CSSOM을 결합해 실제로 화면에 표시될 노드만 포함하는 트리를 만듭니다.

```
DOM Tree          CSSOM Tree
    │                  │
    └──────┬───────────┘
           ▼
      Render Tree
```

### 포함/제외 규칙

```css
/* DOM에는 있지만 Render Tree에서 제외 */
.hidden { display: none; }    /* 제외됨 - 공간도 없음 */
head { }                      /* 제외됨 */
script, meta { }              /* 제외됨 */

/* Render Tree에 포함 */
.invisible { visibility: hidden; } /* 포함됨 - 공간은 차지, 안 보임 */
.transparent { opacity: 0; }       /* 포함됨 - 공간 차지, 안 보임 */
```

```
Render Tree:
html
  └── body [font-size: 16px; margin: 8px]
        ├── h1 [font-size: 32px; color: #333]
        │     └── "Welcome"
        └── p [color: blue; font-size: 16px]
              └── "Hello World"
```

---

## 5. Layout (Reflow)

Render Tree의 각 노드에 대해 브라우저 뷰포트(viewport) 안에서의 **정확한 위치와 크기**를 계산합니다.

```
Layout 계산 대상:
- 요소의 (x, y) 좌표
- width, height
- margin, padding, border
- 부모-자식 간의 상대적 위치
- float, flex, grid 레이아웃
```

### Box Model

```
┌─────────────────────────────────────────┐
│                margin                   │
│   ┌─────────────────────────────────┐   │
│   │             border              │   │
│   │   ┌─────────────────────────┐   │   │
│   │   │         padding         │   │   │
│   │   │   ┌─────────────────┐   │   │   │
│   │   │   │     content     │   │   │   │
│   │   │   │   width×height  │   │   │   │
│   │   │   └─────────────────┘   │   │   │
│   │   └─────────────────────────┘   │   │
│   └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

```javascript
// Layout을 유발하는 읽기 작업 (Forced Synchronous Layout 주의)
const height = element.offsetHeight;  // Layout 유발
const width  = element.clientWidth;   // Layout 유발
const bounds = element.getBoundingClientRect(); // Layout 유발
```

---

## 6. Paint

Layout에서 계산된 정보를 바탕으로 각 요소를 **픽셀로 채우는** 단계입니다. 레이어(Layer) 단위로 처리됩니다.

```
Paint 대상:
- background-color / background-image
- border, box-shadow
- text (color, font)
- outline
- visibility
```

### Paint 레이어

브라우저는 특정 조건을 만족하는 요소를 별도 **합성 레이어(Composited Layer)**로 승격합니다.

```css
/* 레이어 생성 조건 */
.layer {
  transform: translateZ(0);       /* 또는 translate3d(0,0,0) */
  will-change: transform, opacity;
  position: fixed;
  /* CSS 필터, 비디오, Canvas, WebGL 등 */
}
```

```javascript
// DevTools에서 레이어 확인
// Chrome: DevTools > Layers 패널
// 또는 Rendering > Layer Borders 체크
```

---

## 7. Composite

각 레이어를 GPU에 전달해 최종 화면으로 합성합니다. **main thread 없이 GPU thread에서 처리**되므로 가장 성능이 좋은 단계입니다.

```
CPU (main thread)
  DOM → Style → Layout → Paint → Layer Tree 생성
                                        │
                                        ▼
CPU (compositor thread)
  Layer 목록 → 타일(Tile) 분할
                    │
                    ▼
GPU
  타일 래스터화 → Compositing → 화면 출력 (Swap)
```

### Composite 전용 속성 (가장 빠른 애니메이션)

```css
/* Layout, Paint를 건너뛰고 Composite만 유발하는 속성 */
.fast-animation {
  /* transform, opacity만 Composite 단계에서 처리됨 */
  transform: translateX(100px);
  opacity: 0.5;
}

/* 느린 애니메이션 - Layout을 유발 */
.slow-animation {
  left: 100px;   /* Layout → Paint → Composite */
  width: 200px;  /* Layout → Paint → Composite */
}
```

### 성능 지표와 렌더링 단계

| 지표 | 관련 단계 |
|------|-----------|
| FCP (First Contentful Paint) | 첫 Paint 완료 |
| LCP (Largest Contentful Paint) | 가장 큰 요소 Paint 완료 |
| CLS (Cumulative Layout Shift) | Layout 변화 누적 |
| FID / INP | JS 실행 시간 (main thread 점유) |

---

## 8. 면접 포인트

### Q1. DOM과 Render Tree의 차이점은?

DOM은 HTML 문서의 모든 노드(display:none, head, script 등 포함)를 트리로 표현합니다. Render Tree는 DOM + CSSOM을 결합해 실제 화면에 렌더링될 노드만 포함합니다. `display: none` 요소는 Render Tree에 없지만, `visibility: hidden`은 포함됩니다(공간을 차지하므로).

### Q2. Layout, Paint, Composite 중 어느 단계가 가장 비싸고, 어떻게 최적화하나요?

Layout(Reflow)이 가장 비쌉니다. 하나의 요소 변경이 다른 요소에 영향을 줄 수 있어 전체 재계산이 필요할 수 있습니다. Paint는 해당 레이어만 다시 그리므로 더 빠르고, Composite는 GPU가 처리하므로 가장 빠릅니다. `transform`과 `opacity`만 사용하는 애니메이션은 Layout과 Paint를 건너뛰고 Composite만 거치므로 60fps를 안정적으로 유지할 수 있습니다.

### Q3. `will-change` 속성의 올바른 사용법은?

`will-change: transform`은 브라우저에게 해당 요소가 곧 변경될 것임을 미리 알려 합성 레이어로 승격시킵니다. 하지만 남용하면 메모리 사용량이 늘고 오히려 성능이 저하됩니다. 실제 애니메이션이 시작되기 직전에 JavaScript로 추가하고, 끝난 후 제거하는 방식이 이상적입니다.

### Q4. 16ms(60fps) 프레임 예산이란?

60fps를 유지하려면 1초에 60개의 프레임을 그려야 하므로, 한 프레임당 약 16.67ms 안에 모든 렌더링 작업(JS 실행 + Style + Layout + Paint + Composite)을 완료해야 합니다. JS 실행이 길어지면 "Jank(버벅임)"가 발생합니다. `requestAnimationFrame`으로 렌더링 타이밍에 맞춰 JS를 실행하는 것이 권장됩니다.
