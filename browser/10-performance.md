# 10. 브라우저 성능 최적화

## 목차
1. Core Web Vitals 개요
2. LCP (Largest Contentful Paint)
3. FID (First Input Delay) / INP (Interaction to Next Paint)
4. CLS (Cumulative Layout Shift)
5. 성능 측정 도구
6. Lazy Loading
7. Code Splitting
8. 브라우저 캐싱 전략
9. 기타 최적화 기법
10. 면접 포인트

---

## 1. Core Web Vitals 개요

Core Web Vitals는 Google이 정의한 웹 페이지의 **사용자 경험 핵심 지표**입니다. 검색 엔진 순위(SEO)에도 영향을 미칩니다.

| 지표 | 측정 대상 | 좋음 | 개선 필요 | 나쁨 |
|------|----------|------|-----------|------|
| LCP | 로딩 성능 | ≤ 2.5s | 2.5s ~ 4.0s | > 4.0s |
| FID / INP | 상호작용 응답성 | ≤ 100ms / ≤ 200ms | ~300ms / ~500ms | > 300ms / > 500ms |
| CLS | 시각적 안정성 | ≤ 0.1 | 0.1 ~ 0.25 | > 0.25 |

> 2024년 3월부터 FID는 **INP(Interaction to Next Paint)**로 대체되었습니다.

---

## 2. LCP (Largest Contentful Paint)

뷰포트 내에서 **가장 큰 콘텐츠 요소**가 렌더링되는 시점을 측정합니다. 주로 히어로 이미지, 대형 텍스트 블록이 대상이 됩니다.

### LCP 대상 요소

- `<img>` 태그
- `<video>` 태그의 poster 이미지
- CSS `background-image`를 가진 블록 요소
- 대형 텍스트 블록 (`<p>`, `<h1>` 등)

### LCP 저하 원인 및 해결책

| 원인 | 해결 방법 |
|------|-----------|
| 느린 서버 응답 (TTFB) | CDN 사용, 서버 최적화 |
| 렌더링 블로킹 리소스 | CSS/JS `defer`, `async` 사용 |
| 느린 리소스 로드 | 이미지 최적화, `preload` 힌트 |
| 클라이언트 사이드 렌더링 | SSR/SSG 도입 |

### LCP 측정 코드

```javascript
// Performance Observer API로 LCP 측정
const observer = new PerformanceObserver((entryList) => {
  const entries = entryList.getEntries();
  const lastEntry = entries[entries.length - 1]; // 마지막 = 최종 LCP

  console.log('LCP 요소:', lastEntry.element);
  console.log('LCP 시간:', lastEntry.startTime, 'ms');
  console.log('LCP 크기:', lastEntry.size, 'px²');
});

observer.observe({ type: 'largest-contentful-paint', buffered: true });
```

### LCP 최적화: 히어로 이미지 preload

```html
<!-- 히어로 이미지를 최우선으로 로드 -->
<link
  rel="preload"
  href="/images/hero.webp"
  as="image"
  type="image/webp"
  fetchpriority="high"
/>

<!-- 반응형 이미지 preload (imagesrcset 사용) -->
<link
  rel="preload"
  as="image"
  imagesrcset="hero-400.webp 400w, hero-800.webp 800w, hero-1200.webp 1200w"
  imagesizes="100vw"
/>

<!-- 이미지 태그에 fetchpriority 적용 -->
<img
  src="/images/hero.webp"
  alt="히어로 이미지"
  fetchpriority="high"
  loading="eager"
  width="1200"
  height="600"
/>
```

---

## 3. FID / INP (상호작용 응답성)

### FID (First Input Delay)

사용자가 **처음으로 상호작용**(클릭, 탭, 키 입력)할 때부터 브라우저가 이벤트 핸들러를 실행하기 시작할 때까지의 지연 시간입니다.

### INP (Interaction to Next Paint)

페이지 방문 동안의 **모든 상호작용 지연 시간 중 대표값**을 측정합니다. FID보다 더 포괄적인 지표입니다.

### 저하 원인 및 해결책

- **긴 태스크(Long Task)**: 50ms 이상 메인 스레드를 점유하는 작업
- 해결: 긴 태스크를 작은 청크로 분할, Web Worker로 오프로딩

```javascript
// 긴 작업을 청크로 분할하여 메인 스레드 양보
async function processLargeDataset(data) {
  const CHUNK_SIZE = 1000;

  for (let i = 0; i < data.length; i += CHUNK_SIZE) {
    const chunk = data.slice(i, i + CHUNK_SIZE);
    processChunk(chunk);

    // 메인 스레드에 제어권을 양보 (브라우저가 다른 태스크 처리 가능)
    await new Promise((resolve) => setTimeout(resolve, 0));
    // 또는 scheduler.yield() (최신 API)
    // await scheduler.yield();
  }
}

// Long Task 감지
const longTaskObserver = new PerformanceObserver((entryList) => {
  entryList.getEntries().forEach((entry) => {
    console.warn('Long Task 감지:', entry.duration, 'ms', entry.attribution);
  });
});
longTaskObserver.observe({ type: 'longtask', buffered: true });
```

### INP 측정 코드

```javascript
const inpObserver = new PerformanceObserver((entryList) => {
  entryList.getEntries().forEach((entry) => {
    // entry.processingStart - entry.startTime: 입력 지연
    // entry.duration: 전체 상호작용 시간
    const inputDelay = entry.processingStart - entry.startTime;
    const processingTime = entry.processingEnd - entry.processingStart;
    const presentationDelay = entry.duration - processingTime - inputDelay;

    console.log({
      interactionType: entry.name,
      inputDelay: inputDelay.toFixed(2) + 'ms',
      processingTime: processingTime.toFixed(2) + 'ms',
      presentationDelay: presentationDelay.toFixed(2) + 'ms',
      totalDuration: entry.duration.toFixed(2) + 'ms'
    });
  });
});

inpObserver.observe({ type: 'event', buffered: true, durationThreshold: 16 });
```

---

## 4. CLS (Cumulative Layout Shift)

페이지 로드 과정에서 발생하는 **예기치 않은 레이아웃 이동**의 누적 점수입니다. 점수가 낮을수록 좋습니다.

### CLS 점수 계산

```
Layout Shift Score = Impact Fraction × Distance Fraction
```

- **Impact Fraction**: 이동한 요소가 뷰포트에서 차지하는 비율
- **Distance Fraction**: 요소가 이동한 거리(뷰포트 크기 대비)

### CLS 저하 원인 및 해결책

```html
<!-- 나쁜 예: 크기 미지정 이미지 (레이아웃 이동 발생) -->
<img src="/image.jpg" alt="이미지" />

<!-- 좋은 예: width/height 명시 (브라우저가 공간 사전 확보) -->
<img src="/image.jpg" alt="이미지" width="800" height="600" />

<!-- 좋은 예: aspect-ratio CSS 사용 -->
<style>
  .image-container {
    aspect-ratio: 4 / 3;
    width: 100%;
  }

  .image-container img {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }
</style>
```

```css
/* 동적으로 삽입되는 콘텐츠를 위한 공간 예약 */
.ad-placeholder {
  min-height: 250px; /* 광고가 로드되기 전 공간 확보 */
  background: #f0f0f0;
}

/* 폰트 로드 시 CLS 방지 */
@font-face {
  font-family: 'MyFont';
  src: url('/fonts/myfont.woff2') format('woff2');
  font-display: swap; /* 폰트 로드 전 fallback 폰트 사용 */
}
```

### CLS 측정 코드

```javascript
let clsScore = 0;

const clsObserver = new PerformanceObserver((entryList) => {
  entryList.getEntries().forEach((entry) => {
    // 사용자 입력 후 500ms 이내의 이동은 제외 (예상된 이동)
    if (!entry.hadRecentInput) {
      clsScore += entry.value;
      console.log('CLS 누적 점수:', clsScore.toFixed(4));

      // 이동한 요소 정보 출력
      entry.sources.forEach((source) => {
        console.log('이동 요소:', source.node, '이동 전:', source.previousRect, '이동 후:', source.currentRect);
      });
    }
  });
});

clsObserver.observe({ type: 'layout-shift', buffered: true });
```

---

## 5. 성능 측정 도구

### Lighthouse

Chrome DevTools 내장 도구로 Core Web Vitals를 포함한 종합 성능 점수를 제공합니다.

- **접근 방법**: Chrome DevTools → Lighthouse 탭
- **측정 항목**: Performance, Accessibility, Best Practices, SEO, PWA
- **CI 통합**: `lighthouse-ci` 패키지로 자동화 가능

```bash
# CLI로 Lighthouse 실행
npx lighthouse https://example.com --output html --output-path ./report.html

# lighthouse-ci 설정
npm install -g @lhci/cli

# lighthouserc.js
module.exports = {
  ci: {
    collect: { url: ['https://example.com'] },
    assert: {
      assertions: {
        'categories:performance': ['error', { minScore: 0.9 }],
        'first-contentful-paint': ['warn', { maxNumericValue: 2000 }],
        'largest-contentful-paint': ['error', { maxNumericValue: 2500 }]
      }
    }
  }
};
```

### Chrome DevTools Performance 탭

```javascript
// 코드에서 성능 마크 찍기 (DevTools에서 시각화)
performance.mark('myTask-start');

// 무거운 작업 수행
heavyComputation();

performance.mark('myTask-end');
performance.measure('myTask', 'myTask-start', 'myTask-end');

const measures = performance.getEntriesByName('myTask');
console.log('작업 소요 시간:', measures[0].duration, 'ms');
```

### Performance API (Navigation Timing)

```javascript
// 페이지 로드 타이밍 분석
window.addEventListener('load', () => {
  const [navEntry] = performance.getEntriesByType('navigation');

  const metrics = {
    // DNS 조회 시간
    dnsLookup: navEntry.domainLookupEnd - navEntry.domainLookupStart,
    // TCP 연결 시간
    tcpConnect: navEntry.connectEnd - navEntry.connectStart,
    // TTFB (Time to First Byte)
    ttfb: navEntry.responseStart - navEntry.requestStart,
    // 페이지 다운로드 시간
    download: navEntry.responseEnd - navEntry.responseStart,
    // DOM 파싱 시간
    domParsing: navEntry.domInteractive - navEntry.responseEnd,
    // DOM 완전 로드까지
    domComplete: navEntry.domComplete - navEntry.startTime,
    // 전체 페이지 로드
    pageLoad: navEntry.loadEventEnd - navEntry.startTime
  };

  console.table(metrics);
});
```

### web-vitals 라이브러리

```javascript
import { getLCP, getFID, getCLS, getINP, getTTFB, getFCP } from 'web-vitals';

function sendToAnalytics(metric) {
  // Google Analytics 4로 전송
  gtag('event', metric.name, {
    value: Math.round(metric.name === 'CLS' ? metric.value * 1000 : metric.value),
    event_category: 'Web Vitals',
    event_label: metric.id,
    non_interaction: true
  });
}

getLCP(sendToAnalytics);
getFID(sendToAnalytics);
getCLS(sendToAnalytics);
getINP(sendToAnalytics);
getTTFB(sendToAnalytics);
```

---

## 6. Lazy Loading

필요할 때까지 리소스 로드를 지연시켜 초기 로딩 성능을 향상시킵니다.

### 이미지 Lazy Loading

```html
<!-- 네이티브 lazy loading (브라우저 지원) -->
<img
  src="/images/photo.jpg"
  alt="사진"
  loading="lazy"
  width="800"
  height="600"
/>

<!-- iframe lazy loading -->
<iframe src="/embed/video" loading="lazy" width="560" height="315"></iframe>
```

### Intersection Observer를 이용한 커스텀 Lazy Loading

```javascript
// Intersection Observer로 뷰포트 진입 시 이미지 로드
const imageObserver = new IntersectionObserver(
  (entries, observer) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        const img = entry.target;
        // data-src에 실제 URL을 저장했다가 src로 교체
        img.src = img.dataset.src;
        img.removeAttribute('data-src');
        observer.unobserve(img); // 로드 후 관찰 중단
      }
    });
  },
  {
    rootMargin: '200px 0px' // 뷰포트 200px 전에 미리 로드
  }
);

document.querySelectorAll('img[data-src]').forEach((img) => {
  imageObserver.observe(img);
});
```

```html
<!-- HTML: data-src에 실제 이미지 URL, src에 플레이스홀더 -->
<img
  data-src="/images/photo.jpg"
  src="/images/placeholder.jpg"
  alt="사진"
  width="800"
  height="600"
/>
```

### React 컴포넌트 Lazy Loading

```jsx
import React, { Suspense, lazy } from 'react';

// 동적 임포트로 컴포넌트 지연 로드
const HeavyChart = lazy(() => import('./HeavyChart'));
const Dashboard = lazy(() => import('./Dashboard'));

function App() {
  return (
    <Suspense fallback={<div>로딩 중...</div>}>
      <HeavyChart />
    </Suspense>
  );
}

// 조건부 로딩 (특정 조건에서만 로드)
function ConditionalComponent({ showDashboard }) {
  return (
    <div>
      {showDashboard && (
        <Suspense fallback={<div className="skeleton" />}>
          <Dashboard />
        </Suspense>
      )}
    </div>
  );
}
```

---

## 7. Code Splitting

번들을 여러 청크로 분리해 필요한 코드만 로드합니다. 초기 번들 크기를 줄여 FCP와 LCP를 개선합니다.

### Dynamic Import

```javascript
// 정적 임포트 (항상 로드)
import { heavyFunction } from './heavy-module';

// 동적 임포트 (필요 시 로드)
async function handleClick() {
  const { heavyFunction } = await import('./heavy-module');
  heavyFunction();
}

// 라우트 기반 코드 분할 (React Router + Vite/Webpack)
const routes = [
  {
    path: '/',
    component: lazy(() => import('./pages/Home'))
  },
  {
    path: '/dashboard',
    component: lazy(() => import('./pages/Dashboard'))
  },
  {
    path: '/settings',
    component: lazy(() => import('./pages/Settings'))
  }
];
```

### Webpack/Vite 청크 최적화

```javascript
// vite.config.js - 수동 청크 분리
export default {
  build: {
    rollupOptions: {
      output: {
        manualChunks: {
          // 벤더 라이브러리를 별도 청크로 분리
          vendor: ['react', 'react-dom'],
          charts: ['recharts', 'd3'],
          utils: ['lodash', 'date-fns']
        }
      }
    }
  }
};

// Webpack - SplitChunksPlugin
module.exports = {
  optimization: {
    splitChunks: {
      chunks: 'all',
      cacheGroups: {
        vendor: {
          test: /[\\/]node_modules[\\/]/,
          name: 'vendors',
          chunks: 'all'
        }
      }
    }
  }
};
```

---

## 8. 브라우저 캐싱 전략

HTTP 캐시 헤더를 통해 리소스의 재사용을 제어합니다.

### Cache-Control 헤더

```
# 불변 정적 자산 (해시가 포함된 파일명: main.abc123.js)
Cache-Control: public, max-age=31536000, immutable

# HTML 파일 (항상 최신 버전 확인)
Cache-Control: no-cache

# 민감한 데이터 (캐시 금지)
Cache-Control: no-store

# API 응답 (30초 캐시, stale-while-revalidate)
Cache-Control: public, max-age=30, stale-while-revalidate=60

# CDN 캐시와 브라우저 캐시 분리
Cache-Control: public, max-age=0, s-maxage=3600
```

### 캐싱 전략별 설명

```
[긴 캐시 + 해시 파일명] - 권장 패턴
├── /index.html          → Cache-Control: no-cache
├── /assets/app.abc123.js → Cache-Control: max-age=31536000, immutable
├── /assets/style.def456.css → Cache-Control: max-age=31536000, immutable
└── /api/data            → Cache-Control: no-store (민감) 또는 max-age=60
```

### ETag와 조건부 요청

```
# 서버 응답 (최초 요청)
HTTP/1.1 200 OK
ETag: "abc123"
Last-Modified: Thu, 12 Jun 2025 10:00:00 GMT
Cache-Control: max-age=3600

# 캐시 만료 후 브라우저 재검증 요청
GET /resource HTTP/1.1
If-None-Match: "abc123"
If-Modified-Since: Thu, 12 Jun 2025 10:00:00 GMT

# 리소스 변경 없음 (304: 본문 전송 생략)
HTTP/1.1 304 Not Modified
```

```javascript
// Service Worker에서 캐시 전략 구현 시 Cache-Control 헤더 활용
self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);

  // 정적 자산: Cache First
  if (url.pathname.startsWith('/assets/')) {
    event.respondWith(cacheFirst(event.request));
    return;
  }

  // API: Network First
  if (url.pathname.startsWith('/api/')) {
    event.respondWith(networkFirst(event.request));
    return;
  }

  // HTML: Network First with 오프라인 폴백
  if (event.request.mode === 'navigate') {
    event.respondWith(networkFirstWithFallback(event.request));
  }
});
```

---

## 9. 기타 최적화 기법

### Resource Hints

```html
<!-- DNS Prefetch: 외부 도메인 DNS 미리 조회 -->
<link rel="dns-prefetch" href="//fonts.googleapis.com" />
<link rel="dns-prefetch" href="//cdn.example.com" />

<!-- Preconnect: DNS + TCP + TLS 핸드셰이크 미리 수행 -->
<link rel="preconnect" href="https://fonts.googleapis.com" />
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />

<!-- Preload: 현재 페이지에서 곧 필요한 리소스 우선 로드 -->
<link rel="preload" href="/fonts/main.woff2" as="font" type="font/woff2" crossorigin />
<link rel="preload" href="/critical.css" as="style" />
<link rel="preload" href="/hero.webp" as="image" />

<!-- Prefetch: 다음 페이지에서 필요할 가능성 높은 리소스 미리 다운로드 -->
<link rel="prefetch" href="/next-page.js" as="script" />

<!-- Prerender: 다음에 방문할 가능성 높은 페이지 미리 렌더링 (실험적) -->
<link rel="prerender" href="/next-page" />
```

### 이미지 최적화

```html
<!-- WebP 포맷 + 폴백 -->
<picture>
  <source srcset="/image.avif" type="image/avif" />
  <source srcset="/image.webp" type="image/webp" />
  <img src="/image.jpg" alt="이미지" width="800" height="600" loading="lazy" />
</picture>

<!-- 반응형 이미지 (srcset + sizes) -->
<img
  srcset="
    /image-400.webp  400w,
    /image-800.webp  800w,
    /image-1200.webp 1200w
  "
  sizes="(max-width: 600px) 400px, (max-width: 1024px) 800px, 1200px"
  src="/image-800.webp"
  alt="반응형 이미지"
  loading="lazy"
  decoding="async"
/>
```

### 압축 (Compression)

```
# Nginx 설정 - gzip 압축
gzip on;
gzip_types text/css application/javascript application/json image/svg+xml;
gzip_min_length 1024;
gzip_comp_level 6;

# Brotli 압축 (gzip보다 20~26% 더 효율적)
brotli on;
brotli_types text/css application/javascript application/json;
brotli_comp_level 6;
```

### Critical CSS 인라이닝

```html
<!-- 초기 렌더링에 필요한 Critical CSS를 인라인으로 삽입 -->
<head>
  <style>
    /* Critical CSS: 뷰포트 내 요소 스타일만 포함 */
    body { margin: 0; font-family: sans-serif; }
    .header { background: #333; color: white; padding: 1rem; }
    .hero { min-height: 400px; display: flex; align-items: center; }
  </style>
  <!-- 나머지 CSS는 비동기 로드 -->
  <link rel="preload" href="/styles.css" as="style" onload="this.onload=null;this.rel='stylesheet'" />
  <noscript><link rel="stylesheet" href="/styles.css" /></noscript>
</head>
```

### JavaScript 렌더링 블로킹 방지

```html
<!-- defer: DOM 파싱 완료 후 실행, 순서 보장 -->
<script src="/app.js" defer></script>

<!-- async: 다운로드 완료 즉시 실행, 순서 미보장 -->
<script src="/analytics.js" async></script>

<!-- type="module": 기본적으로 defer 동작 -->
<script type="module" src="/main.js"></script>
```

---

## 10. 면접 포인트

### Q1. Core Web Vitals의 세 가지 지표를 설명하고 개선 방법을 말해주세요.

**LCP(Largest Contentful Paint)**는 뷰포트 내 가장 큰 요소가 렌더링되는 시점으로 로딩 성능을 측정합니다. 2.5초 이내가 목표입니다. 히어로 이미지 preload, CDN 사용, 이미지 최적화로 개선합니다.

**INP(Interaction to Next Paint)**는 모든 사용자 상호작용의 응답 지연 대표값입니다. 200ms 이내가 목표입니다. 긴 태스크 분할, Web Worker 활용, 불필요한 JavaScript 제거로 개선합니다.

**CLS(Cumulative Layout Shift)**는 예기치 않은 레이아웃 이동 점수입니다. 0.1 이하가 목표입니다. 이미지/영상에 크기 지정, 동적 콘텐츠 공간 사전 확보, `font-display: swap` 사용으로 개선합니다.

### Q2. Lazy Loading의 구현 방법과 주의사항은?

구현 방법으로는 HTML `loading="lazy"` 속성 (네이티브), Intersection Observer API (커스텀), React `lazy()` + `Suspense` (컴포넌트)가 있습니다. 주의사항으로는 뷰포트 내 LCP 대상 이미지에는 `loading="lazy"` 대신 `fetchpriority="high"`를 사용해야 합니다. 또한 `rootMargin`을 설정해 실제 노출 전에 미리 로드하여 사용자가 빈 영역을 보는 것을 방지해야 합니다.

### Q3. Cache-Control 헤더 전략을 설명해주세요.

**해시 파일명 + 긴 캐시** 패턴이 가장 효율적입니다. 빌드 시 파일명에 콘텐츠 해시를 포함시키고(`app.abc123.js`) `max-age=31536000, immutable`로 설정합니다. HTML 파일은 `no-cache`로 설정해 항상 서버에서 최신 버전을 확인합니다. API 응답은 데이터 특성에 따라 `no-store`(민감), `max-age=60, stale-while-revalidate=300` 등을 선택합니다.

### Q4. Code Splitting이란 무엇이고 왜 필요한가요?

Code Splitting은 하나의 번들 파일을 여러 청크로 분리하는 기법입니다. 사용자가 방문한 페이지에 필요한 코드만 다운로드하므로 초기 로딩 시간이 단축됩니다. 구현 방법으로는 동적 `import()`, React `lazy()`, Webpack의 `SplitChunksPlugin`, Vite의 `manualChunks` 설정이 있습니다. 라우트 기반 분할이 가장 일반적이며, 벤더 라이브러리를 별도 청크로 분리하면 캐시 효율도 높아집니다.

### Q5. preload와 prefetch의 차이는?

**preload**는 현재 페이지에서 곧 필요한 리소스를 높은 우선순위로 미리 다운로드합니다. 폰트, 히어로 이미지, Critical JS 등에 사용합니다. 사용하지 않으면 콘솔 경고가 발생합니다.

**prefetch**는 다음 페이지 탐색 시 필요할 가능성 높은 리소스를 낮은 우선순위로 미리 다운로드합니다. 아이들 시간에 다운로드하며 다음 페이지의 JS, 이미지 등에 사용합니다. 브라우저 재량으로 다운로드하므로 강제성이 없습니다.

### Q6. Performance API에서 TTFB를 측정하는 방법은?

```javascript
const [navEntry] = performance.getEntriesByType('navigation');
const ttfb = navEntry.responseStart - navEntry.requestStart;
```

TTFB(Time to First Byte)는 요청 시작부터 서버의 첫 번째 바이트를 받기까지의 시간입니다. 200ms 이하가 좋은 수준이며, 높으면 서버 처리 속도, 네트워크 지연, CDN 설정 등을 점검해야 합니다.
