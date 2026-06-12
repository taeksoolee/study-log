# 3. 애니메이션

## 목차
1. [CSS transition 속성](#1-css-transition-속성)
2. [CSS animation과 @keyframes](#2-css-animation과-keyframes)
3. [transition vs animation 비교](#3-transition-vs-animation-비교)
4. [transform 속성](#4-transform-속성)
5. [3D transform](#5-3d-transform)
6. [will-change와 GPU 가속](#6-will-change와-gpu-가속)
7. [성능 최적화: transform과 opacity](#7-성능-최적화-transform과-opacity)
8. [JavaScript로 애니메이션 제어](#8-javascript로-애니메이션-제어)
9. [면접 포인트](#9-면접-포인트)

---

## 1. CSS transition 속성

`transition`은 CSS 속성 값이 변할 때 변화를 부드럽게 전환시켜준다.
상태 변화(hover, focus, class 추가 등)에 반응하는 단방향 애니메이션이다.

### 개별 속성

```css
.element {
  transition-property: all;          /* 전환할 CSS 속성명 */
  transition-duration: 0.3s;         /* 전환 지속 시간 */
  transition-timing-function: ease;  /* 속도 곡선 */
  transition-delay: 0s;              /* 시작 전 대기 시간 */
}
```

### 단축 속성

```css
/* transition: property duration timing-function delay */
.element {
  transition: all 0.3s ease 0s;

  /* 특정 속성만 전환 */
  transition: background-color 0.2s ease;

  /* 여러 속성 개별 설정 */
  transition:
    background-color 0.2s ease,
    transform 0.3s ease-out,
    opacity 0.2s linear;
}
```

### timing-function 종류

| 값 | 설명 |
|----|------|
| `ease` | 기본값. 빠르게 시작 후 감속 |
| `linear` | 일정한 속도 |
| `ease-in` | 느리게 시작 후 가속 |
| `ease-out` | 빠르게 시작 후 감속 (ease보다 완만) |
| `ease-in-out` | 느리게 시작, 빠르게 진행, 느리게 끝 |
| `cubic-bezier(x1,y1,x2,y2)` | 커스텀 베지어 곡선 |
| `steps(n, start|end)` | 계단식 전환 |

```css
/* 실용 예시: 버튼 hover 효과 */
.btn {
  background-color: #007bff;
  transform: translateY(0);
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
  transition:
    background-color 0.2s ease,
    transform 0.2s ease,
    box-shadow 0.2s ease;
}

.btn:hover {
  background-color: #0056b3;
  transform: translateY(-2px);
  box-shadow: 0 6px 12px rgba(0, 0, 0, 0.2);
}
```

---

## 2. CSS animation과 @keyframes

`animation`은 `@keyframes`로 정의한 여러 단계의 상태를 자동으로 반복 재생할 수 있다.
외부 트리거 없이 자동으로 실행되는 다단계 애니메이션이다.

### @keyframes 정의

```css
/* from/to 방식 */
@keyframes fadeIn {
  from { opacity: 0; }
  to   { opacity: 1; }
}

/* 퍼센트 방식 */
@keyframes slideUp {
  0%   { transform: translateY(30px); opacity: 0; }
  60%  { transform: translateY(-5px); opacity: 1; }
  100% { transform: translateY(0);    opacity: 1; }
}

@keyframes spin {
  0%   { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}
```

### animation 속성

```css
.element {
  animation-name: fadeIn;            /* @keyframes 이름 */
  animation-duration: 0.5s;          /* 지속 시간 */
  animation-timing-function: ease;   /* 속도 곡선 */
  animation-delay: 0s;               /* 시작 전 대기 */
  animation-iteration-count: 1;      /* 반복 횟수 (infinite 가능) */
  animation-direction: normal;       /* 재생 방향 */
  animation-fill-mode: none;         /* 시작/종료 후 상태 */
  animation-play-state: running;     /* 재생/일시정지 */
}
```

### 단축 속성

```css
/* animation: name duration timing-function delay iteration-count direction fill-mode */
.element {
  animation: fadeIn 0.5s ease 0s 1 normal forwards;

  /* 여러 애니메이션 동시 적용 */
  animation:
    fadeIn 0.5s ease forwards,
    slideUp 0.5s ease-out forwards;
}
```

### animation-direction

```css
.element {
  animation-direction: normal;            /* 기본값: 순방향 재생 */
  animation-direction: reverse;           /* 역방향 재생 */
  animation-direction: alternate;         /* 순방향 → 역방향 반복 */
  animation-direction: alternate-reverse; /* 역방향 → 순방향 반복 */
}
```

### animation-fill-mode

```css
.element {
  animation-fill-mode: none;      /* 기본값: 시작/종료 후 원래 상태 */
  animation-fill-mode: forwards;  /* 종료 후 마지막 keyframe 상태 유지 */
  animation-fill-mode: backwards; /* 대기 중에도 첫 keyframe 상태 적용 */
  animation-fill-mode: both;      /* backwards + forwards */
}
```

### 실용 예시: 로딩 스피너

```css
@keyframes spin {
  to { transform: rotate(360deg); }
}

.spinner {
  width: 40px;
  height: 40px;
  border: 4px solid #e0e0e0;
  border-top-color: #007bff;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}
```

---

## 3. transition vs animation 비교

| 구분 | transition | animation |
|------|-----------|-----------|
| 트리거 | 상태 변화 필요 (hover, class 추가 등) | 자동 실행 가능 |
| 단계 수 | 시작 → 끝 (2단계) | @keyframes로 여러 단계 정의 |
| 반복 | 불가 | `iteration-count`로 반복 가능 |
| 역방향 | 자동으로 원래 상태로 복귀 | `direction` 속성으로 제어 |
| 복잡도 | 단순 | 복잡한 시퀀스 표현 가능 |

```
transition 사용:
  - 버튼 hover 효과
  - 메뉴 펼침/접힘
  - 모달 등장/사라짐
  - 폼 포커스 스타일

animation 사용:
  - 로딩 스피너
  - 자동 슬라이드쇼
  - 스켈레톤 UI 펄스 효과
  - 복잡한 UI 인트로 애니메이션
```

---

## 4. transform 속성

`transform`은 요소의 위치, 회전, 크기, 기울기를 변환한다.
레이아웃을 재계산하지 않으므로 성능에 유리하다.

### 2D transform 함수

```css
.element {
  /* 이동 */
  transform: translate(50px, 20px);
  transform: translateX(50px);
  transform: translateY(20px);

  /* 회전 (시계방향 양수) */
  transform: rotate(45deg);
  transform: rotate(-90deg);

  /* 크기 조절 */
  transform: scale(1.5);       /* 가로세로 동일 */
  transform: scale(2, 0.5);    /* 가로 2배, 세로 0.5배 */
  transform: scaleX(1.5);
  transform: scaleY(0.8);

  /* 기울기 */
  transform: skew(10deg, 5deg);
  transform: skewX(15deg);
  transform: skewY(10deg);

  /* 여러 변환 동시 적용 (왼쪽부터 순서대로 적용됨) */
  transform: translateX(100px) rotate(45deg) scale(1.2);
}
```

### transform-origin

변환의 기준점을 설정한다.

```css
.element {
  transform-origin: 50% 50%;    /* 기본값: 중앙 */
  transform-origin: top left;
  transform-origin: 0 0;
  transform-origin: center bottom;
  transform-origin: 100% 0;     /* 우측 상단 */
}

/* 카드 뒤집기 예시 */
.card {
  transform-origin: left center;
  transition: transform 0.4s ease;
}
.card:hover {
  transform: rotateY(-15deg);
}
```

---

## 5. 3D transform

### perspective

3D 변환의 원근감(소실점까지의 거리)을 설정한다. 값이 작을수록 원근 효과가 강하다.

```css
/* 부모 요소에 perspective 설정 (자식 요소에 3D 효과 적용) */
.scene {
  perspective: 800px;
  perspective-origin: 50% 50%; /* 소실점 위치 */
}

/* 개별 요소에 적용 */
.element {
  transform: perspective(800px) rotateY(30deg);
}
```

### 3D 회전

```css
.element {
  transform: rotateX(45deg);   /* X축 기준 회전 */
  transform: rotateY(45deg);   /* Y축 기준 회전 */
  transform: rotateZ(45deg);   /* Z축 기준 회전 (= rotate()) */
  transform: rotate3d(1, 1, 0, 45deg); /* 임의 축 회전 */
}
```

### 카드 뒤집기 효과 (Card Flip)

```html
<div class="card-scene">
  <div class="card-3d">
    <div class="card-face card-front">앞면</div>
    <div class="card-face card-back">뒷면</div>
  </div>
</div>
```

```css
.card-scene {
  perspective: 600px;
}

.card-3d {
  position: relative;
  width: 200px;
  height: 300px;
  transform-style: preserve-3d;  /* 자식 요소를 3D 공간에 배치 */
  transition: transform 0.6s ease;
}

.card-scene:hover .card-3d {
  transform: rotateY(180deg);
}

.card-face {
  position: absolute;
  width: 100%;
  height: 100%;
  backface-visibility: hidden; /* 뒷면 숨김 */
}

.card-back {
  transform: rotateY(180deg);
}
```

---

## 6. will-change와 GPU 가속

### will-change

브라우저에게 요소가 어떤 속성이 변할 것임을 미리 알려 최적화를 준비하게 한다.

```css
.animating-element {
  will-change: transform;
  will-change: opacity;
  will-change: transform, opacity;
}
```

### 사용 주의사항

```css
/* 잘못된 사용: 모든 요소에 남발 */
* { will-change: transform; } /* 메모리 낭비 */

/* 올바른 사용: 실제로 애니메이션될 요소에만 */
.card {
  transition: transform 0.3s ease;
}
.card:hover {
  will-change: transform; /* hover 직전에 설정하는 것이 이상적 */
}

/* 또는 JavaScript로 동적 설정 */
```

```javascript
const card = document.querySelector('.card');

card.addEventListener('mouseenter', () => {
  card.style.willChange = 'transform';
});

card.addEventListener('mouseleave', () => {
  card.style.willChange = 'auto'; /* 애니메이션 종료 후 제거 */
});
```

### GPU 레이어 생성 조건

다음 속성들은 요소를 GPU 합성 레이어로 분리시킨다.

```css
.gpu-layer {
  transform: translateZ(0);   /* GPU 레이어 강제 생성 (해킹 기법) */
  transform: translate3d(0, 0, 0); /* 동일 효과 */
  will-change: transform;     /* 권장 방법 */
  opacity: 0.99;              /* opacity도 GPU 레이어 생성 (비권장) */
}
```

---

## 7. 성능 최적화: transform과 opacity

브라우저 렌더링 파이프라인은 다음 단계로 구성된다.

```
JavaScript → Style → Layout → Paint → Composite
```

| 속성 변경 | 발생하는 단계 | 비용 |
|-----------|-------------|------|
| `width`, `height`, `margin`, `top` | Layout → Paint → Composite | 높음 |
| `color`, `background`, `box-shadow` | Paint → Composite | 중간 |
| `transform`, `opacity` | Composite 만 | 낮음 (GPU 처리) |

### 권장 사항

```css
/* 나쁜 예: layout을 발생시키는 이동 애니메이션 */
@keyframes bad-move {
  from { left: 0; }
  to   { left: 200px; }
}

/* 좋은 예: transform은 composite만 발생 */
@keyframes good-move {
  from { transform: translateX(0); }
  to   { transform: translateX(200px); }
}

/* 나쁜 예: 크기 변화에 width 사용 */
.bad { transition: width 0.3s; }

/* 좋은 예: scale 사용 */
.good { transition: transform 0.3s; }
.good:hover { transform: scale(1.05); }
```

---

## 8. JavaScript로 애니메이션 제어

### classList로 CSS 애니메이션 트리거

```css
.box {
  opacity: 0;
  transform: translateY(20px);
  transition: opacity 0.4s ease, transform 0.4s ease;
}

.box.is-visible {
  opacity: 1;
  transform: translateY(0);
}
```

```javascript
const box = document.querySelector('.box');

// 클래스 토글로 애니메이션 트리거
box.classList.add('is-visible');

// Intersection Observer로 스크롤 애니메이션
const observer = new IntersectionObserver(
  (entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        entry.target.classList.add('is-visible');
      }
    });
  },
  { threshold: 0.1 }
);

document.querySelectorAll('.box').forEach((el) => observer.observe(el));
```

### requestAnimationFrame

브라우저의 다음 렌더링 프레임에 맞춰 애니메이션을 실행한다. `setInterval`보다 성능이 좋고 탭이 비활성화되면 자동으로 일시 정지된다.

```javascript
function animate(timestamp) {
  // timestamp: 페이지 로드 후 경과 시간 (ms)
  const element = document.querySelector('.box');
  const progress = (timestamp % 2000) / 2000; // 2초 주기

  element.style.transform = `translateX(${progress * 300}px)`;

  requestAnimationFrame(animate); // 다음 프레임 요청
}

requestAnimationFrame(animate);

// 중단하려면
let animId;
animId = requestAnimationFrame(animate);
cancelAnimationFrame(animId);
```

### Web Animations API

CSS animation과 JavaScript 제어를 결합한 현대적 API이다.

```javascript
const element = document.querySelector('.box');

const animation = element.animate(
  [
    { transform: 'translateX(0)', opacity: 0 },
    { transform: 'translateX(200px)', opacity: 1 },
  ],
  {
    duration: 1000,
    easing: 'ease-out',
    iterations: Infinity,
    direction: 'alternate',
  }
);

// 제어
animation.pause();
animation.play();
animation.cancel();
animation.finish();

// 완료 감지
animation.addEventListener('finish', () => {
  console.log('애니메이션 완료');
});
```

---

## 9. 면접 포인트

**Q. transition과 animation의 차이를 설명해주세요.**

> `transition`은 CSS 속성 값이 변경될 때(hover, class 토글 등 외부 트리거) 두 상태 사이를 부드럽게 전환합니다. `animation`은 `@keyframes`로 정의한 여러 단계를 트리거 없이 자동으로 실행할 수 있고, 반복, 역방향 재생 등 세밀한 제어가 가능합니다. 간단한 상태 전환에는 transition, 복잡하거나 자동 반복되는 애니메이션에는 animation을 사용합니다.

**Q. CSS 애니메이션 성능 최적화 방법을 설명해주세요.**

> 브라우저 렌더링 파이프라인(Layout → Paint → Composite) 중 `transform`과 `opacity`는 Composite 단계만 거쳐 GPU에서 처리됩니다. 반면 `width`, `height`, `top`, `left` 등은 Layout을 다시 발생시켜 비용이 큽니다. 따라서 이동에는 `left` 대신 `translateX`, 크기 변화에는 `width` 대신 `scale`을 사용하는 것이 권장됩니다. 추가로 `will-change` 속성으로 브라우저가 미리 GPU 레이어를 준비하게 할 수 있습니다.

**Q. will-change 속성의 역할과 주의사항을 말해주세요.**

> `will-change`는 브라우저에게 어떤 속성이 변할 것임을 미리 알려 GPU 합성 레이어를 미리 생성하게 합니다. 레이어 생성에 메모리가 소비되므로 실제로 애니메이션되는 요소에만 적용해야 하며, 애니메이션이 끝나면 `will-change: auto`로 제거하는 것이 좋습니다. 모든 요소에 남발하면 오히려 메모리 낭비와 성능 저하를 일으킵니다.

**Q. requestAnimationFrame을 사용하는 이유는 무엇인가요?**

> `requestAnimationFrame`은 브라우저의 실제 렌더링 주기(보통 60fps, 약 16.6ms)에 맞춰 콜백을 실행합니다. `setInterval`과 달리 브라우저가 최적 타이밍을 결정하므로 프레임 드랍이 적고, 탭이 비활성화되면 자동으로 일시 정지하여 CPU 낭비를 방지합니다. JavaScript로 부드러운 애니메이션을 구현할 때 권장되는 방법입니다.

**Q. transform: translateZ(0)의 역할을 설명해주세요.**

> `translateZ(0)`은 요소를 3D 변환 컨텍스트에 배치하면서 실질적으로 위치는 변경하지 않아, 브라우저가 해당 요소를 별도의 GPU 합성 레이어로 분리하게 만드는 해킹 기법입니다. 과거에 애니메이션 성능을 높이기 위해 자주 사용되었으나 현재는 `will-change: transform`을 사용하는 것이 권장됩니다.
