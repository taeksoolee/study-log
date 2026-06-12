# 2. Flexbox & Grid

## 목차
1. [Flexbox: Container 속성](#1-flexbox-container-속성)
2. [Flexbox: Item 속성](#2-flexbox-item-속성)
3. [Grid: Container 속성](#3-grid-container-속성)
4. [Grid: Item 속성](#4-grid-item-속성)
5. [실용 레이아웃 예시](#5-실용-레이아웃-예시)
6. [Flexbox vs Grid 선택 가이드](#6-flexbox-vs-grid-선택-가이드)
7. [면접 포인트](#7-면접-포인트)

---

## 1. Flexbox: Container 속성

Flexbox는 1차원 레이아웃 모델로, 행(row) 또는 열(column) 방향으로 아이템을 배치한다.

```css
.flex-container {
  display: flex; /* 또는 display: inline-flex */
}
```

### flex-direction

주축(main axis)의 방향을 정의한다.

```css
.container {
  flex-direction: row;            /* 기본값: 왼쪽 → 오른쪽 */
  flex-direction: row-reverse;    /* 오른쪽 → 왼쪽 */
  flex-direction: column;         /* 위 → 아래 */
  flex-direction: column-reverse; /* 아래 → 위 */
}
```

### flex-wrap

아이템이 컨테이너를 넘칠 때 줄바꿈 여부를 설정한다.

```css
.container {
  flex-wrap: nowrap;       /* 기본값: 줄바꿈 없음 (넘치면 축소) */
  flex-wrap: wrap;         /* 아래로 줄바꿈 */
  flex-wrap: wrap-reverse; /* 위로 줄바꿈 */
}
```

### justify-content

주축 방향의 아이템 정렬을 제어한다.

```css
.container {
  justify-content: flex-start;    /* 기본값: 주축 시작점 */
  justify-content: flex-end;      /* 주축 끝점 */
  justify-content: center;        /* 중앙 */
  justify-content: space-between; /* 양 끝 정렬, 아이템 사이 균등 간격 */
  justify-content: space-around;  /* 아이템 양쪽에 균등 간격 */
  justify-content: space-evenly;  /* 모든 간격 동일 */
}
```

### align-items

교차축(cross axis) 방향의 아이템 정렬을 제어한다 (단일 행/열).

```css
.container {
  align-items: stretch;     /* 기본값: 교차축 방향으로 늘림 */
  align-items: flex-start;  /* 교차축 시작점 */
  align-items: flex-end;    /* 교차축 끝점 */
  align-items: center;      /* 교차축 중앙 */
  align-items: baseline;    /* 텍스트 베이스라인 기준 */
}
```

### align-content

여러 행/열이 있을 때 교차축 방향의 행/열 간격을 제어한다 (`flex-wrap: wrap` 필요).

```css
.container {
  align-content: flex-start;
  align-content: flex-end;
  align-content: center;
  align-content: space-between;
  align-content: space-around;
  align-content: stretch; /* 기본값 */
}
```

### gap

아이템 사이의 간격을 설정한다.

```css
.container {
  gap: 16px;           /* 행/열 모두 16px */
  gap: 16px 24px;      /* row-gap: 16px, column-gap: 24px */
  row-gap: 16px;
  column-gap: 24px;
}
```

---

## 2. Flexbox: Item 속성

### flex-grow

여유 공간이 있을 때 아이템이 얼마나 늘어날지 비율을 설정한다.

```css
.item-a { flex-grow: 1; } /* 여유 공간의 1/3 차지 */
.item-b { flex-grow: 2; } /* 여유 공간의 2/3 차지 */
.item-c { flex-grow: 0; } /* 기본값: 늘어나지 않음 */
```

### flex-shrink

컨테이너가 부족할 때 아이템이 얼마나 줄어들지 비율을 설정한다.

```css
.item-a { flex-shrink: 1; } /* 기본값: 비율에 따라 축소 */
.item-b { flex-shrink: 0; } /* 축소되지 않음 */
.item-c { flex-shrink: 2; } /* 다른 아이템보다 2배 빠르게 축소 */
```

### flex-basis

아이템의 기본 크기를 설정한다 (주축 방향).

```css
.item {
  flex-basis: auto;   /* 기본값: content 크기 또는 width/height */
  flex-basis: 0;      /* 기본 크기 무시, flex-grow로만 크기 결정 */
  flex-basis: 200px;  /* 200px을 기본 크기로 */
  flex-basis: 30%;    /* 컨테이너의 30%를 기본 크기로 */
}
```

### flex (단축 속성)

`flex-grow`, `flex-shrink`, `flex-basis`를 하나로 설정한다.

```css
.item {
  flex: 1;         /* flex: 1 1 0 */
  flex: auto;      /* flex: 1 1 auto */
  flex: none;      /* flex: 0 0 auto */
  flex: 2 1 200px; /* grow: 2, shrink: 1, basis: 200px */
}
```

### align-self

개별 아이템의 교차축 정렬을 컨테이너의 `align-items`보다 우선하여 설정한다.

```css
.item {
  align-self: auto;       /* 기본값: 컨테이너의 align-items 따름 */
  align-self: flex-start;
  align-self: flex-end;
  align-self: center;
  align-self: stretch;
}
```

### order

아이템의 시각적 순서를 변경한다 (DOM 순서는 유지됨).

```css
.item-a { order: 2; }
.item-b { order: 1; } /* 가장 먼저 표시 */
.item-c { order: 3; }
/* 기본값은 0, 값이 작을수록 앞에 배치 */
```

---

## 3. Grid: Container 속성

Grid는 2차원 레이아웃 모델로, 행(row)과 열(column)을 동시에 제어한다.

```css
.grid-container {
  display: grid; /* 또는 display: inline-grid */
}
```

### grid-template-columns / grid-template-rows

열과 행의 크기를 정의한다.

```css
.container {
  /* 고정 크기 */
  grid-template-columns: 200px 200px 200px;

  /* 비율 단위 fr (fraction) */
  grid-template-columns: 1fr 2fr 1fr;

  /* 반복 함수 */
  grid-template-columns: repeat(3, 1fr);
  grid-template-columns: repeat(3, 200px);

  /* 혼합 */
  grid-template-columns: 250px 1fr;

  /* 행 높이 */
  grid-template-rows: 80px 1fr 60px;

  /* auto: 콘텐츠 크기에 맞춤 */
  grid-template-rows: auto 1fr auto;
}
```

### grid-gap (gap)

행/열 사이의 간격을 설정한다.

```css
.container {
  gap: 16px;           /* 행/열 모두 */
  gap: 20px 16px;      /* row-gap: 20px, column-gap: 16px */
  row-gap: 20px;
  column-gap: 16px;
}
```

### justify-items / align-items

각 셀 안에서 아이템의 수평/수직 정렬을 설정한다.

```css
.container {
  justify-items: start | end | center | stretch; /* 기본값: stretch */
  align-items:   start | end | center | stretch; /* 기본값: stretch */

  /* 단축 속성 */
  place-items: center;        /* align-items: center, justify-items: center */
  place-items: start center;  /* align: start, justify: center */
}
```

### grid-template-areas

이름을 붙여 영역을 정의한다.

```css
.container {
  display: grid;
  grid-template-columns: 200px 1fr;
  grid-template-rows: 60px 1fr 60px;
  grid-template-areas:
    "header  header"
    "sidebar main"
    "footer  footer";
}
```

---

## 4. Grid: Item 속성

### grid-column / grid-row

아이템이 차지할 열/행의 범위를 설정한다.

```css
.item {
  grid-column: 1 / 3;      /* 1번 라인에서 3번 라인까지 (2칸) */
  grid-column: 1 / span 2; /* 1번 라인에서 2칸 차지 */
  grid-column: 2;           /* 2번 열 1칸만 차지 */
  grid-column: 1 / -1;     /* 첫 라인부터 마지막 라인까지 (전체 너비) */

  grid-row: 1 / 3;
  grid-row: 2 / span 2;
}
```

### grid-area

`grid-template-areas`로 정의한 이름을 할당하거나, row/column 범위를 한 번에 설정한다.

```css
/* 이름 할당 */
.header  { grid-area: header; }
.sidebar { grid-area: sidebar; }
.main    { grid-area: main; }
.footer  { grid-area: footer; }

/* row-start / column-start / row-end / column-end */
.item {
  grid-area: 1 / 1 / 3 / 3;
}
```

---

## 5. 실용 레이아웃 예시

### 수직/수평 중앙 정렬

```css
/* Flexbox 방식 */
.center-flex {
  display: flex;
  justify-content: center;
  align-items: center;
  height: 100vh;
}

/* Grid 방식 */
.center-grid {
  display: grid;
  place-items: center;
  height: 100vh;
}
```

### 카드 그리드 레이아웃

```css
/* 고정 3열 그리드 */
.card-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 24px;
}

/* 반응형: 최소 280px, 남은 공간 자동 채움 */
.card-grid-responsive {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 24px;
}

.card {
  background: white;
  border-radius: 8px;
  padding: 20px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}
```

### 헤더-사이드바-메인 레이아웃

```html
<div class="layout">
  <header class="header">Header</header>
  <aside class="sidebar">Sidebar</aside>
  <main class="main">Main Content</main>
  <footer class="footer">Footer</footer>
</div>
```

```css
/* Grid Template Areas 활용 */
.layout {
  display: grid;
  grid-template-columns: 240px 1fr;
  grid-template-rows: 60px 1fr 60px;
  grid-template-areas:
    "header  header"
    "sidebar main"
    "footer  footer";
  min-height: 100vh;
}

.header  { grid-area: header; }
.sidebar { grid-area: sidebar; }
.main    { grid-area: main; }
.footer  { grid-area: footer; }

/* Flexbox로 동일 레이아웃 구현 */
.layout-flex {
  display: flex;
  flex-direction: column;
  min-height: 100vh;
}

.layout-flex .header { height: 60px; }
.layout-flex .body {
  display: flex;
  flex: 1;
}
.layout-flex .sidebar { width: 240px; flex-shrink: 0; }
.layout-flex .main    { flex: 1; }
.layout-flex .footer  { height: 60px; }
```

### Holy Grail 레이아웃 (Flexbox)

```css
.holy-grail {
  display: flex;
  flex-direction: column;
  min-height: 100vh;
}

.holy-grail__header,
.holy-grail__footer {
  flex-shrink: 0;
}

.holy-grail__body {
  display: flex;
  flex: 1;
}

.holy-grail__nav,
.holy-grail__ads {
  flex: 0 0 200px;
}

.holy-grail__content {
  flex: 1;
}
```

---

## 6. Flexbox vs Grid 선택 가이드

| 기준 | Flexbox | Grid |
|------|---------|------|
| 차원 | 1차원 (행 또는 열) | 2차원 (행 + 열 동시) |
| 레이아웃 제어 | 콘텐츠 중심 (아이템 크기에 맞춤) | 레이아웃 중심 (격자 먼저 정의) |
| 복잡한 정렬 | 단순한 경우 유리 | 복잡한 2D 레이아웃에 유리 |
| 브라우저 지원 | 매우 넓음 | 넓음 (IE11은 구 문법) |

### 사용 시나리오

```
Flexbox 사용:
  - 내비게이션 바 아이템 정렬
  - 버튼 그룹, 아이콘+텍스트 정렬
  - 카드 내부 콘텐츠 정렬
  - 동적으로 아이템 수가 변하는 리스트

Grid 사용:
  - 전체 페이지 레이아웃
  - 카드 그리드 (행/열 동시 제어)
  - 대시보드 위젯 배치
  - 복잡한 폼 레이아웃
```

---

## 7. 면접 포인트

**Q. Flexbox와 Grid의 차이점과 각각 어떤 상황에 사용하나요?**

> Flexbox는 1차원(한 방향) 레이아웃을 다루며 콘텐츠 크기에 따라 유연하게 배치합니다. Grid는 2차원(행과 열 동시) 레이아웃으로 격자 구조를 먼저 정의하고 아이템을 배치합니다. 내비게이션 바나 카드 내부처럼 단일 방향 정렬에는 Flexbox, 전체 페이지 레이아웃이나 카드 그리드처럼 행과 열을 동시에 제어해야 할 때는 Grid를 사용합니다.

**Q. flex: 1의 의미를 설명해주세요.**

> `flex: 1`은 `flex-grow: 1`, `flex-shrink: 1`, `flex-basis: 0`의 단축 표기입니다. 여유 공간이 있으면 1의 비율로 늘어나고, 공간이 부족하면 1의 비율로 줄어들며, 기본 크기는 0에서 시작합니다. 여러 아이템에 `flex: 1`을 설정하면 남은 공간을 균등하게 나눠 갖습니다.

**Q. Grid에서 fr 단위란 무엇인가요?**

> `fr`(fraction)은 Grid 컨테이너의 사용 가능한 여유 공간을 비율로 나누는 단위입니다. 예를 들어 `grid-template-columns: 1fr 2fr`는 전체 공간을 3등분하여 첫 번째 열이 1/3, 두 번째 열이 2/3를 차지합니다. 고정 크기(`px`)와 함께 사용하면 고정 공간을 제외한 나머지를 `fr`로 나눕니다.

**Q. justify-content와 align-items의 차이를 설명해주세요.**

> Flexbox 기준으로 `justify-content`는 주축(main axis) 방향의 아이템 정렬을 제어하고, `align-items`는 교차축(cross axis) 방향의 정렬을 제어합니다. `flex-direction: row`(기본값)일 때 주축은 수평, 교차축은 수직입니다. `flex-direction: column`이면 반대가 됩니다.

**Q. grid-template-areas를 사용하는 장점은 무엇인가요?**

> 레이아웃 구조를 코드에서 시각적으로 표현할 수 있어 가독성이 높습니다. 열/행 번호 대신 의미 있는 이름으로 영역을 정의하므로 유지보수가 쉽고, 미디어 쿼리에서 레이아웃을 변경할 때 영역 이름만 재정의하면 되어 구조 변경이 용이합니다.
