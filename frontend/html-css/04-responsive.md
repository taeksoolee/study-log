# 4. 반응형 웹

## 목차
1. [반응형 웹 개념](#1-반응형-웹-개념)
2. [미디어 쿼리 문법과 브레이크포인트](#2-미디어-쿼리-문법과-브레이크포인트)
3. [모바일 우선 vs 데스크탑 우선 전략](#3-모바일-우선-vs-데스크탑-우선-전략)
4. [CSS 단위 비교](#4-css-단위-비교)
5. [rem 기반 설계](#5-rem-기반-설계)
6. [viewport meta 태그](#6-viewport-meta-태그)
7. [반응형 이미지](#7-반응형-이미지)
8. [면접 포인트](#8-면접-포인트)

---

## 1. 반응형 웹 개념

반응형 웹(Responsive Web Design)은 다양한 화면 크기와 기기에 맞게 레이아웃과 콘텐츠를 자동으로 조절하는 설계 방식이다. Ethan Marcotte가 2010년에 제안했으며, 세 가지 핵심 기술로 구성된다.

### Fluid Layout (유동적 레이아웃)

고정 픽셀 대신 유연한 단위(%, fr, vw 등)를 사용하여 컨테이너가 화면 크기에 맞게 늘어나고 줄어든다.

```css
/* 고정 레이아웃 (비권장) */
.container {
  width: 960px;
}

/* 유동 레이아웃 (권장) */
.container {
  max-width: 1200px;
  width: 100%;
  padding: 0 16px;
}

.column {
  width: 33.333%;  /* 픽셀 대신 % */
  float: left;
}
```

### Flexible Images (유연한 이미지)

이미지가 컨테이너를 넘치지 않도록 자동으로 크기를 조절한다.

```css
img {
  max-width: 100%;
  height: auto;
}
```

### Media Queries (미디어 쿼리)

화면 크기, 해상도, 방향 등 기기 특성에 따라 다른 CSS를 적용한다.

```css
@media (max-width: 768px) {
  .column { width: 100%; }
}
```

---

## 2. 미디어 쿼리 문법과 브레이크포인트

### 기본 문법

```css
@media [미디어 타입] and ([조건]) {
  /* 조건에 맞을 때 적용될 CSS */
}
```

```css
/* 미디어 타입 */
@media screen { }   /* 화면 (기본값) */
@media print  { }   /* 인쇄 */
@media all    { }   /* 모든 미디어 */

/* 조건 */
@media (max-width: 768px)  { }  /* 너비 768px 이하 */
@media (min-width: 768px)  { }  /* 너비 768px 이상 */
@media (width: 768px)      { }  /* 너비 정확히 768px */
@media (orientation: landscape) { } /* 가로 방향 */
@media (orientation: portrait)  { } /* 세로 방향 */

/* 논리 연산자 */
@media screen and (min-width: 768px) and (max-width: 1024px) { }
@media (max-width: 480px), (orientation: portrait) { }  /* OR */
@media not screen { }

/* 범위 구문 (CSS Media Queries Level 4) */
@media (480px <= width <= 768px) { }
@media (width >= 768px)          { }
```

### 일반적인 브레이크포인트

```css
/* 모바일 (기본) */
/* 스타일 코드 */

/* 태블릿 */
@media (min-width: 600px) {
  /* sm */
}

/* 소형 데스크탑 */
@media (min-width: 900px) {
  /* md */
}

/* 데스크탑 */
@media (min-width: 1200px) {
  /* lg */
}

/* 대형 화면 */
@media (min-width: 1536px) {
  /* xl */
}
```

### 주요 프레임워크 브레이크포인트 비교

| 이름 | Tailwind CSS | Bootstrap 5 | Material UI |
|------|-------------|-------------|-------------|
| xs | - | < 576px | < 600px |
| sm | 640px | 576px | 600px |
| md | 768px | 768px | 900px |
| lg | 1024px | 992px | 1200px |
| xl | 1280px | 1200px | 1536px |
| 2xl | 1536px | 1400px | - |

---

## 3. 모바일 우선 vs 데스크탑 우선 전략

### 모바일 우선 (Mobile First) - min-width

기본 스타일을 모바일 기준으로 작성하고, 화면이 넓어질수록 덮어쓴다.

```css
/* 모바일 우선: 기본 = 모바일 스타일 */
.container {
  padding: 16px;
}

.grid {
  display: grid;
  grid-template-columns: 1fr;   /* 모바일: 1열 */
  gap: 16px;
}

/* 태블릿 이상 */
@media (min-width: 768px) {
  .container {
    padding: 24px;
  }
  .grid {
    grid-template-columns: 1fr 1fr;  /* 태블릿: 2열 */
  }
}

/* 데스크탑 이상 */
@media (min-width: 1200px) {
  .container {
    padding: 32px;
    max-width: 1200px;
    margin: 0 auto;
  }
  .grid {
    grid-template-columns: repeat(3, 1fr);  /* 데스크탑: 3열 */
  }
}
```

### 데스크탑 우선 (Desktop First) - max-width

기본 스타일을 데스크탑 기준으로 작성하고, 화면이 좁아질수록 덮어쓴다.

```css
/* 데스크탑 우선: 기본 = 데스크탑 스타일 */
.grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);  /* 데스크탑: 3열 */
}

/* 태블릿 이하 */
@media (max-width: 1199px) {
  .grid {
    grid-template-columns: 1fr 1fr;   /* 태블릿: 2열 */
  }
}

/* 모바일 */
@media (max-width: 767px) {
  .grid {
    grid-template-columns: 1fr;       /* 모바일: 1열 */
  }
}
```

### 전략 비교

| 비교 항목 | 모바일 우선 | 데스크탑 우선 |
|----------|-----------|-------------|
| 기본 스타일 기준 | 모바일 | 데스크탑 |
| 미디어 쿼리 방향 | `min-width` (확장) | `max-width` (축소) |
| 성능 | 모바일에서 더 적은 CSS 로드 | 모바일이 불필요한 CSS 다운로드 |
| 현대 표준 | 권장 | 구형 프로젝트에서 사용 |
| 사고 방식 | 핵심 콘텐츠 우선 | 전체 레이아웃 우선 |

> 구글, W3C, Bootstrap 모두 **모바일 우선** 전략을 권장한다.

---

## 4. CSS 단위 비교

### 절대 단위

```css
.element {
  width: 300px;   /* 화면 크기와 무관한 고정 크기 */
}
```

| 단위 | 설명 | 사용 시나리오 |
|------|------|--------------|
| `px` | 화면 픽셀 | border, shadow, 최소/최대 너비 |

### 상대 단위

| 단위 | 기준 | 설명 |
|------|------|------|
| `%` | 부모 요소 크기 | 유동 레이아웃 너비 |
| `em` | 현재 요소의 font-size | 컴포넌트 내 여백 (중첩 주의) |
| `rem` | html의 font-size | 전역 폰트 크기, 일관된 여백 |
| `vw` | viewport 너비의 1% | 전체 너비 기반 크기 |
| `vh` | viewport 높이의 1% | 전체 높이 기반 크기 |
| `vmin` | vw와 vh 중 작은 값 | 정사각형, 회전 대응 크기 |
| `vmax` | vw와 vh 중 큰 값 | 화면 가득 채우기 |

```css
/* vw/vh 활용 예시 */
.hero {
  width: 100vw;
  height: 100vh;
  /* 뷰포트 전체를 채우는 히어로 섹션 */
}

.fluid-text {
  font-size: clamp(1rem, 2.5vw, 2rem);
  /* 최소 16px, 뷰포트 너비에 비례, 최대 32px */
}

/* clamp(): 최솟값, 우선값, 최댓값 */
.container {
  width: clamp(300px, 80%, 1200px);
}
```

### 단위 선택 기준 요약

```css
/* 레이아웃 너비 */
.container { max-width: 1200px; width: 100%; }

/* 폰트 크기 */
body { font-size: 1rem; }   /* rem 권장 */

/* 여백 (전역) */
.section { margin-bottom: 3rem; }

/* 여백 (컴포넌트 내부) */
.button { padding: 0.75em 1.5em; }  /* em: 폰트 크기에 비례 */

/* 화면 높이 기반 */
.modal { max-height: 90vh; }

/* 고정값 */
.border { border: 1px solid #ccc; }
```

---

## 5. rem 기반 설계

`rem`은 루트 요소(`html`)의 `font-size`를 기준으로 하는 단위이다.
기본 브라우저 폰트 크기는 16px이며, 사용자가 브라우저 설정으로 변경 가능하다.

### 기본 설정

```css
/* 방법 1: 직접 설정 (사용자 설정 무시하게 됨 - 비권장) */
html { font-size: 16px; }

/* 방법 2: 62.5% 트릭 (16px × 62.5% = 10px) */
html { font-size: 62.5%; }  /* 1rem = 10px */
body { font-size: 1.6rem; } /* body는 16px으로 복원 */

h1 { font-size: 3.2rem; }   /* 32px */
h2 { font-size: 2.4rem; }   /* 24px */

/* 방법 3: 브라우저 기본값 그대로 사용 (권장) */
html { font-size: 100%; }   /* 기본값: 16px */

h1 { font-size: 2rem; }     /* 32px */
h2 { font-size: 1.5rem; }   /* 24px */
p  { font-size: 1rem; }     /* 16px */
```

### rem 기반 간격 시스템

```css
:root {
  --spacing-1: 0.25rem;  /*  4px */
  --spacing-2: 0.5rem;   /*  8px */
  --spacing-3: 0.75rem;  /* 12px */
  --spacing-4: 1rem;     /* 16px */
  --spacing-6: 1.5rem;   /* 24px */
  --spacing-8: 2rem;     /* 32px */
  --spacing-12: 3rem;    /* 48px */
  --spacing-16: 4rem;    /* 64px */
}

.card {
  padding: var(--spacing-6);
  margin-bottom: var(--spacing-8);
}
```

### 접근성과 rem

```css
/* rem의 핵심 장점: 사용자 브라우저 폰트 설정을 존중 */

/* px 사용 시: 사용자가 브라우저 폰트를 20px로 설정해도 무시됨 */
html { font-size: 16px; }  /* 고정 */

/* rem 사용 시: 사용자 설정에 비례하여 모든 크기가 조정됨 */
html { font-size: 100%; }  /* 사용자 설정 반영 */
.text { font-size: 1rem; } /* 항상 사용자 기본 크기와 동일 */
```

---

## 6. viewport meta 태그

모바일 브라우저는 기본적으로 데스크탑 화면 너비(980px)로 페이지를 렌더링하고 축소한다.
`viewport` 메타 태그로 이를 제어한다.

```html
<!-- 반응형 웹을 위한 필수 설정 -->
<meta name="viewport" content="width=device-width, initial-scale=1.0">
```

| 속성 | 값 | 설명 |
|------|-----|------|
| `width` | `device-width` 또는 숫자 | viewport 너비 설정 |
| `initial-scale` | `1.0` | 초기 확대 비율 (1 = 100%) |
| `minimum-scale` | 숫자 | 최소 축소 비율 |
| `maximum-scale` | 숫자 | 최대 확대 비율 |
| `user-scalable` | `yes` / `no` | 사용자 확대/축소 허용 여부 |

```html
<!-- 기본 반응형 설정 -->
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<!-- 사용자 확대 금지 (접근성 저해로 비권장) -->
<meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
```

> `user-scalable=no`는 저시력 사용자의 접근성을 저해한다. WCAG 2.1에서는 200%까지 콘텐츠 크기 조절을 지원할 것을 권장한다.

---

## 7. 반응형 이미지

### srcset과 sizes 속성

해상도와 뷰포트 크기에 맞는 이미지를 브라우저가 선택하게 한다.

```html
<!-- 해상도 대응 (1x, 2x, 3x 디스플레이) -->
<img
  src="image-1x.jpg"
  srcset="image-1x.jpg 1x,
          image-2x.jpg 2x,
          image-3x.jpg 3x"
  alt="설명"
>

<!-- 너비 기반 (브라우저가 최적 이미지 선택) -->
<img
  src="image-800.jpg"
  srcset="image-400.jpg 400w,
          image-800.jpg 800w,
          image-1200.jpg 1200w"
  sizes="(max-width: 600px) 100vw,
         (max-width: 1200px) 50vw,
         33vw"
  alt="설명"
>
```

`sizes` 속성은 브라우저에게 각 브레이크포인트에서 이미지가 차지할 공간을 알려준다.
브라우저는 이를 참고하여 `srcset` 중 가장 적합한 이미지를 선택한다.

### picture 태그

아트 디렉션(화면 크기에 따라 다른 이미지 비율 사용)이 필요할 때 사용한다.

```html
<picture>
  <!-- 모바일: 정사각형 이미지 -->
  <source
    media="(max-width: 767px)"
    srcset="image-square-400.jpg 400w, image-square-800.jpg 800w"
    sizes="100vw"
  >
  <!-- 태블릿: 4:3 이미지 -->
  <source
    media="(max-width: 1199px)"
    srcset="image-4x3-800.jpg 800w, image-4x3-1200.jpg 1200w"
    sizes="80vw"
  >
  <!-- 데스크탑: 와이드스크린 이미지 (기본) -->
  <img
    src="image-wide-1200.jpg"
    srcset="image-wide-1200.jpg 1200w, image-wide-1800.jpg 1800w"
    sizes="(min-width: 1200px) 1200px, 100vw"
    alt="설명"
  >
</picture>
```

### WebP 포맷 대응

```html
<picture>
  <!-- WebP를 지원하면 WebP 사용 -->
  <source
    type="image/webp"
    srcset="image.webp 1x, image@2x.webp 2x"
  >
  <!-- 미지원 시 JPEG 폴백 -->
  <img src="image.jpg" srcset="image@2x.jpg 2x" alt="설명">
</picture>
```

### CSS 반응형 배경 이미지

```css
.hero {
  background-image: url('hero-mobile.jpg');
  background-size: cover;
  background-position: center;
}

@media (min-width: 768px) {
  .hero {
    background-image: url('hero-tablet.jpg');
  }
}

@media (min-width: 1200px) {
  .hero {
    background-image: url('hero-desktop.jpg');
  }
}

/* 고해상도 디스플레이 (Retina) */
@media (-webkit-min-device-pixel-ratio: 2), (min-resolution: 192dpi) {
  .hero {
    background-image: url('hero-2x.jpg');
  }
}
```

---

## 8. 면접 포인트

**Q. 반응형 웹의 3가지 핵심 기술을 설명해주세요.**

> 반응형 웹은 Fluid Layout(% 등 유연한 단위로 컨테이너가 화면에 맞게 조절), Flexible Images(`max-width: 100%`로 이미지가 컨테이너를 넘지 않게 제어), Media Queries(화면 크기에 따라 다른 CSS 적용)의 세 가지로 구성됩니다.

**Q. 모바일 우선 전략이란 무엇이고 왜 권장되나요?**

> 모바일 우선 전략은 기본 CSS를 모바일 기준으로 작성하고 `min-width` 미디어 쿼리로 큰 화면에서 덮어쓰는 방식입니다. 모바일 트래픽이 전체의 절반 이상을 차지하는 현황에서 핵심 콘텐츠를 먼저 설계하게 되고, 모바일 기기가 불필요한 CSS를 다운로드하지 않아 성능에 유리합니다. 구글, W3C, Bootstrap 모두 권장하는 표준 접근법입니다.

**Q. em과 rem의 차이를 설명하고, 반응형에서 rem이 왜 유용한가요?**

> `em`은 현재 요소의 `font-size` 기준으로 중첩 시 복리 계산되는 문제가 있지만, `rem`은 항상 루트(`html`) 요소의 `font-size` 기준이라 일관성이 있습니다. 반응형에서 `html { font-size: 100% }`로 설정하면 사용자의 브라우저 폰트 크기 설정을 존중하며, 폰트 크기를 미디어 쿼리로 조정할 때 `html`의 `font-size`만 변경하면 `rem`을 사용한 모든 요소가 비례하여 조정됩니다.

**Q. srcset과 sizes 속성의 역할을 설명해주세요.**

> `srcset`은 다양한 해상도나 크기의 이미지 후보 목록을 제공하고, `sizes`는 각 뷰포트 크기에서 이미지가 실제로 표시될 너비를 브라우저에게 알려줍니다. 브라우저는 현재 뷰포트 크기, `sizes`, 기기 픽셀 비율을 고려하여 `srcset` 중 가장 적합한 이미지를 선택합니다. 이를 통해 모바일에서는 작은 이미지를, 고해상도 디스플레이에서는 큰 이미지를 자동으로 로드하여 성능을 최적화합니다.

**Q. viewport meta 태그가 없을 때 어떤 문제가 발생하나요?**

> `viewport` 메타 태그가 없으면 모바일 브라우저는 페이지를 약 980px 너비의 가상 화면에 렌더링한 뒤 기기 화면에 맞춰 축소합니다. 텍스트가 매우 작게 보이고, 미디어 쿼리가 의도대로 동작하지 않으며, 사용자가 핀치 줌으로 콘텐츠를 확대해야 하는 불편함이 생깁니다. `width=device-width, initial-scale=1.0` 설정으로 기기의 실제 너비를 viewport 너비로 사용하게 해야 합니다.

**Q. picture 태그와 img srcset의 차이는 무엇인가요?**

> `img srcset`은 동일한 이미지를 다양한 해상도/크기로 제공하는 데 적합합니다. 브라우저가 자동으로 최적 이미지를 선택하며 아트 디렉션이 필요 없을 때 사용합니다. `picture` 태그는 뷰포트 크기에 따라 완전히 다른 구도나 비율의 이미지를 제공하는 아트 디렉션에 사용합니다. 또한 WebP처럼 브라우저 지원 여부에 따라 다른 포맷을 제공할 때도 활용합니다.
