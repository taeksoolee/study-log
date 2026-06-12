# 1. Box Model

## 목차
1. [CSS Box Model 개념](#1-css-box-model-개념)
2. [box-sizing 속성](#2-box-sizing-속성)
3. [Margin Collapsing (마진 병합)](#3-margin-collapsing-마진-병합)
4. [padding vs margin 사용 가이드](#4-padding-vs-margin-사용-가이드)
5. [outline vs border 차이](#5-outline-vs-border-차이)
6. [CSS 단위 기초](#6-css-단위-기초)
7. [면접 포인트](#7-면접-포인트)

---

## 1. CSS Box Model 개념

모든 HTML 요소는 사각형 박스로 구성되며, CSS Box Model은 이 박스의 구조를 정의한다.
박스는 안쪽에서 바깥쪽으로 4개의 영역으로 구성된다.

```
┌──────────────────────────────────────┐
│              margin                  │
│   ┌──────────────────────────────┐   │
│   │           border             │   │
│   │   ┌──────────────────────┐   │   │
│   │   │       padding        │   │   │
│   │   │   ┌──────────────┐   │   │   │
│   │   │   │   content    │   │   │   │
│   │   │   └──────────────┘   │   │   │
│   │   └──────────────────────┘   │   │
│   └──────────────────────────────┘   │
└──────────────────────────────────────┘
```

| 영역 | 설명 |
|------|------|
| content | 텍스트, 이미지 등 실제 내용이 담기는 공간 |
| padding | content와 border 사이의 내부 여백 |
| border | padding을 감싸는 테두리 |
| margin | border 바깥의 외부 여백. 다른 요소와의 간격 |

```css
.box {
  width: 200px;       /* content 너비 */
  height: 100px;      /* content 높이 */
  padding: 20px;      /* 상하좌우 내부 여백 */
  border: 2px solid #333; /* 테두리 */
  margin: 16px;       /* 상하좌우 외부 여백 */
}
```

위 예시에서 실제 요소가 차지하는 너비는 다음과 같다.

```
총 너비 = margin(16*2) + border(2*2) + padding(20*2) + content(200)
        = 32 + 4 + 40 + 200
        = 276px
```

---

## 2. box-sizing 속성

### content-box (기본값)

`width`와 `height`가 **content 영역**만을 의미한다.
padding과 border가 추가되면 요소의 실제 크기가 커진다.

```css
.content-box {
  box-sizing: content-box; /* 기본값 */
  width: 200px;
  padding: 20px;
  border: 2px solid black;
  /* 실제 너비: 200 + 40 + 4 = 244px */
}
```

### border-box

`width`와 `height`가 **border까지 포함한 전체 크기**를 의미한다.
padding과 border를 추가해도 요소의 전체 크기가 변하지 않는다.

```css
.border-box {
  box-sizing: border-box;
  width: 200px;
  padding: 20px;
  border: 2px solid black;
  /* 실제 너비: 200px (content는 200 - 40 - 4 = 156px) */
}
```

### 전역 설정 권장 패턴

현대 CSS에서는 `border-box`를 전역으로 적용하는 것이 일반적이다.
레이아웃 계산이 직관적이고 예측 가능해진다.

```css
/* 권장 방식 */
*,
*::before,
*::after {
  box-sizing: border-box;
}
```

### content-box vs border-box 비교

```css
/* 동일한 width: 300px 설정 시 */

.content-box-example {
  box-sizing: content-box;
  width: 300px;
  padding: 30px;
  border: 5px solid blue;
  /* 화면에 차지하는 너비: 300 + 60 + 10 = 370px */
}

.border-box-example {
  box-sizing: border-box;
  width: 300px;
  padding: 30px;
  border: 5px solid red;
  /* 화면에 차지하는 너비: 300px (content는 300 - 60 - 10 = 230px) */
}
```

---

## 3. Margin Collapsing (마진 병합)

마진 병합이란 인접한 블록 요소들의 수직 마진이 합산되지 않고, 더 큰 값 하나로 합쳐지는 현상이다.

### 발생 조건 1: 인접한 형제 요소

```html
<div class="box-a">A</div>
<div class="box-b">B</div>
```

```css
.box-a { margin-bottom: 30px; }
.box-b { margin-top: 20px; }
/* 실제 간격: 30px (30+20=50px이 아니라 max(30, 20)=30px) */
```

### 발생 조건 2: 부모와 첫 번째/마지막 자식 요소

```html
<div class="parent">
  <div class="child">첫 번째 자식</div>
</div>
```

```css
.parent { margin-top: 0; }
.child { margin-top: 40px; }
/*
  부모에 border, padding, overflow가 없으면
  child의 margin-top이 parent 밖으로 빠져나옴
*/
```

### 마진 병합 방지 방법

```css
/* 방법 1: 부모에 padding 추가 */
.parent { padding-top: 1px; }

/* 방법 2: 부모에 border 추가 */
.parent { border-top: 1px solid transparent; }

/* 방법 3: 부모에 overflow 설정 */
.parent { overflow: hidden; }

/* 방법 4: 부모에 display: flow-root 설정 (BFC 생성) */
.parent { display: flow-root; }
```

> 마진 병합은 수직 방향(top/bottom)에서만 발생한다. 수평 방향(left/right)에서는 발생하지 않는다.

---

## 4. padding vs margin 사용 가이드

| 상황 | 권장 속성 | 이유 |
|------|-----------|------|
| 요소 내부 여백 (배경색 영역 포함) | padding | 배경색과 클릭 영역이 padding까지 확장됨 |
| 요소 간 외부 간격 | margin | 레이아웃 흐름에서 다른 요소와의 거리 |
| 버튼의 클릭 영역 확장 | padding | 사용자 경험 향상 |
| 섹션 간 여백 | margin | 섹션 구분용 간격 |
| 컴포넌트 내부 공간 확보 | padding | 내부 레이아웃 제어 |

```css
/* 버튼 예시: padding으로 클릭 영역 확보 */
.btn {
  padding: 12px 24px; /* 클릭 영역이 텍스트보다 큼 */
  background-color: #007bff;
  color: white;
}

/* 카드 컴포넌트 예시 */
.card {
  padding: 20px;     /* 내부 콘텐츠 여백 */
  margin-bottom: 16px; /* 다음 카드와의 간격 */
}
```

---

## 5. outline vs border 차이

### border

- Box Model의 일부로, 레이아웃 공간을 차지한다.
- `border-width`, `border-style`, `border-color`를 개별 설정 가능하다.
- 각 방향(top/right/bottom/left)마다 다르게 설정 가능하다.

### outline

- 레이아웃 공간을 차지하지 않는다 (Box Model 외부에 그려짐).
- 주로 접근성을 위한 포커스 스타일에 사용된다.
- `border-radius`를 따르지 않는다 (브라우저마다 다를 수 있음).
- 방향별 개별 설정이 불가능하다.

```css
/* border: 레이아웃에 영향 줌 */
.with-border {
  border: 3px solid blue;
  /* 요소 크기가 border-box 기준으로 달라짐 */
}

/* outline: 레이아웃에 영향 없음 */
.with-outline {
  outline: 3px solid red;
  outline-offset: 2px; /* outline과 요소 사이의 간격 */
  /* 요소 크기 변화 없음 */
}

/* 포커스 스타일 예시 */
button:focus {
  outline: 2px solid #005fcc;
  outline-offset: 3px;
}

/* outline 제거 시 반드시 대체 스타일 제공 */
button:focus {
  outline: none;
  box-shadow: 0 0 0 3px rgba(0, 95, 204, 0.4); /* 대체 포커스 표시 */
}
```

---

## 6. CSS 단위 기초

### 절대 단위

| 단위 | 설명 | 사용 시나리오 |
|------|------|--------------|
| `px` | 픽셀. 화면의 1픽셀 | 고정 크기가 필요한 border, shadow |

### 상대 단위

| 단위 | 기준 | 설명 |
|------|------|------|
| `%` | 부모 요소 | 부모의 너비/높이에 대한 비율 |
| `em` | 현재 요소의 font-size | 중첩 시 복리 계산되어 예측이 어려움 |
| `rem` | 루트 요소(html)의 font-size | 전역 기준으로 일관성 있는 크기 조절 |

```css
/* px: 고정값 */
.px-example {
  width: 300px;     /* 항상 300px */
  border: 1px solid gray;
}

/* %: 부모 기준 */
.percent-example {
  width: 50%;       /* 부모 너비의 50% */
}

/* em: 현재 요소 font-size 기준 */
.em-example {
  font-size: 16px;
  padding: 1em;     /* 16px */
  margin: 1.5em;    /* 24px */
}

/* rem 중첩 문제 없음 */
html { font-size: 16px; }

.parent-em { font-size: 1.5em; }        /* 24px */
.child-em  { font-size: 1.5em; }        /* 36px (중첩!) */

.parent-rem { font-size: 1.5rem; }      /* 24px */
.child-rem  { font-size: 1.5rem; }      /* 24px (항상 root 기준) */
```

### 실용 단위 선택 기준

```css
/* 레이아웃 너비: % 또는 고정 px */
.container {
  max-width: 1200px;
  width: 100%;
}

/* 폰트 크기: rem 권장 */
body { font-size: 1rem; }       /* 16px */
h1   { font-size: 2rem; }       /* 32px */
h2   { font-size: 1.5rem; }     /* 24px */

/* 컴포넌트 내부 여백: em (폰트 크기에 비례) */
.button {
  font-size: 1rem;
  padding: 0.75em 1.5em; /* 폰트 크기에 비례하여 확장 */
}
```

---

## 7. 면접 포인트

**Q. CSS Box Model을 설명하고, content-box와 border-box의 차이를 말해주세요.**

> Box Model은 HTML 요소를 content, padding, border, margin 4개의 영역으로 구분하는 모델입니다.
> `content-box`는 `width`/`height`가 content 영역만을 의미하여 padding과 border가 추가되면 전체 크기가 커집니다.
> `border-box`는 `width`/`height`가 border까지 포함한 전체 크기를 의미하여 padding과 border를 추가해도 전체 크기가 유지됩니다. 레이아웃 계산이 직관적이기 때문에 현대 CSS에서는 전역에 `border-box`를 적용하는 것이 일반적입니다.

**Q. Margin Collapsing(마진 병합)이란 무엇인가요?**

> 인접한 블록 요소들의 수직 방향 마진이 합산되지 않고, 두 값 중 큰 값 하나로 합쳐지는 현상입니다. 형제 요소 사이 또는 부모-자식 요소 사이에서 발생합니다. 수직(top/bottom) 방향에서만 발생하며, 수평(left/right) 방향에서는 발생하지 않습니다.

**Q. outline과 border의 차이를 설명해주세요.**

> `border`는 Box Model의 일부로 레이아웃 공간을 차지하지만, `outline`은 레이아웃 공간을 차지하지 않고 요소 외부에 그려집니다. `outline`은 주로 키보드 포커스 표시 등 접근성 목적으로 사용되며, `outline: none` 사용 시 반드시 대체 포커스 스타일을 제공해야 합니다.

**Q. em과 rem의 차이는 무엇이고, 언제 사용하나요?**

> `em`은 현재 요소의 `font-size`를 기준으로 하여 중첩될 경우 복리처럼 누적되는 문제가 있습니다. `rem`은 항상 루트(`html`) 요소의 `font-size`를 기준으로 하여 중첩 영향 없이 일관된 크기를 유지합니다. 폰트 크기와 전역 여백에는 `rem`을, 컴포넌트 내부에서 폰트 크기에 비례하는 여백에는 `em`을 사용하는 것이 일반적입니다.

**Q. box-sizing: border-box를 전역으로 설정할 때 권장 방법은?**

> `* { box-sizing: border-box }` 보다는 가상 요소를 포함한 아래 패턴을 권장합니다.
>
> ```css
> *, *::before, *::after {
>   box-sizing: border-box;
> }
> ```
>
> `::before`, `::after` 가상 요소도 함께 적용하여 일관성을 보장합니다.
