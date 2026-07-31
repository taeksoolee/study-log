# 웹 성능 실전 측정 & 최적화 전략

## 개요

2024년 3월부터 Google은 **FID(First Input Delay)**를 폐기하고 **INP(Interaction to Next Paint)**를 Core Web Vitals의 공식 응답성 지표로 채택했다. 이로써 Core Web Vitals는 **LCP · INP · CLS** 세 가지로 구성된다.

### 왜 성능이 비즈니스에 중요한가?

- **검색 순위**: Google은 Core Web Vitals를 페이지 경험 시그널로 사용 (ranking factor)
- **전환율**: LCP가 1초 개선되면 전환율이 최대 27% 증가 (Vodafone 사례)
- **이탈률**: 로딩이 3초를 넘으면 53%의 모바일 사용자가 이탈 (Google 조사)
- **수익**: Amazon은 100ms 지연당 매출 1% 감소를 보고

성능은 UX의 문제이자 비즈니스 KPI다. "느린 사이트 = 돈을 잃는 사이트"라는 공식이 데이터로 증명되고 있다.

---

## 핵심 지표 이해

### 1. LCP (Largest Contentful Paint)

**정의**: 뷰포트 내에서 가장 큰 콘텐츠 요소가 렌더링 완료된 시점

| 기준 | 값 |
|------|-----|
| Good | ≤ 2.5초 |
| Needs Improvement | 2.5초 ~ 4.0초 |
| Poor | > 4.0초 |

**측정 대상 요소**:
- `<img>` 요소
- `<video>` 요소의 포스터 이미지
- CSS `background-image`로 로드된 이미지
- 텍스트 노드를 포함하는 블록 레벨 요소 (`<h1>`, `<p>` 등)
- `<svg>` 내부의 `<image>` 요소

**LCP 후보 변경**: 브라우저는 더 큰 요소가 렌더링될 때마다 LCP 후보를 갱신한다. 사용자가 인터랙션(스크롤, 탭, 키 입력)을 하면 보고를 중단한다.

```
네비게이션 시작 → FCP → LCP 후보 1 → LCP 후보 2 (최종) → 사용자 인터랙션
                                                          ↑ 여기서 측정 종료
```

---

### 2. INP (Interaction to Next Paint)

**정의**: 페이지 수명 동안 발생한 모든 인터랙션의 지연 시간 중, 가장 느린 것(또는 이상치를 제외한 최악에 가까운 값)을 대표값으로 보고

| 기준 | 값 |
|------|-----|
| Good | ≤ 200ms |
| Needs Improvement | 200ms ~ 500ms |
| Poor | > 500ms |

**FID와의 핵심 차이**:

| 비교 항목 | FID | INP |
|-----------|-----|-----|
| 측정 범위 | 첫 번째 인터랙션만 | 모든 인터랙션 |
| 측정 구간 | Input Delay만 | Input Delay + Processing + Presentation Delay |
| 대표성 | 첫 로드 시점만 반영 | 페이지 전체 수명 반영 |

**INP의 3단계 분해**:

```
┌─────────────┬──────────────────┬────────────────────┐
│ Input Delay │   Processing     │ Presentation Delay │
│ (이벤트 큐  │ (이벤트 핸들러   │ (렌더링 ~          │
│  대기 시간) │  실행 시간)      │  다음 프레임 페인트)│
└─────────────┴──────────────────┴────────────────────┘
         ←────────── INP ──────────→
```

- **Input Delay**: 메인 스레드가 바쁠 때 이벤트가 큐에서 대기하는 시간
- **Processing Time**: 이벤트 핸들러(들)가 실행되는 시간
- **Presentation Delay**: 브라우저가 다음 프레임을 계산하고 페인트하는 시간

---

### 3. CLS (Cumulative Layout Shift)

**정의**: 페이지 수명 동안 발생하는 예상치 못한 레이아웃 이동의 누적 점수

| 기준 | 값 |
|------|-----|
| Good | ≤ 0.1 |
| Needs Improvement | 0.1 ~ 0.25 |
| Poor | > 0.25 |

**점수 계산 공식**:

```
Layout Shift Score = Impact Fraction × Distance Fraction
```

- **Impact Fraction**: 불안정 요소가 뷰포트에서 차지하는 면적 비율
- **Distance Fraction**: 불안정 요소가 이동한 최대 거리 / 뷰포트 크기

**Session Window 방식** (2021년 업데이트):
- 레이아웃 이동을 1초 이내 간격으로 묶어 "세션 윈도우" 생성
- 각 세션 윈도우는 최대 5초
- **가장 큰 세션 윈도우의 합계**가 CLS 값으로 보고

```
시간 →
[shift][shift][shift]  ← 세션 윈도우 1 (합: 0.08)
         ...1초 이상 간격...
              [shift][shift]  ← 세션 윈도우 2 (합: 0.12)

CLS = max(0.08, 0.12) = 0.12
```

> **참고**: 사용자 인터랙션 후 500ms 이내의 레이아웃 이동은 CLS에 포함되지 않는다 (예: 아코디언 열기).

---

## 측정 도구 & 방법

### Lab Data vs Field Data

| 구분 | Lab Data | Field Data |
|------|----------|------------|
| 환경 | 통제된 환경 (고정 네트워크/디바이스) | 실제 사용자 환경 |
| 도구 | Lighthouse, WebPageTest | CrUX, web-vitals, RUM |
| 장점 | 재현 가능, 디버깅 용이 | 실제 사용자 경험 반영 |
| 단점 | 실사용자 다양성 미반영 | 디버깅 어려움 |
| INP 측정 | ❌ (인터랙션 없음) | ✅ |

### 주요 도구

**1. Lighthouse (Lab)**
- Chrome DevTools → Lighthouse 탭
- CLI: `npx lighthouse https://example.com --output=json`
- Performance 점수 및 개선 기회 제시
- INP는 측정 불가 (사용자 인터랙션이 없으므로)

**2. Chrome DevTools Performance 패널**
- 프레임별 렌더링 타임라인 시각화
- Long Task 식별 (50ms 이상 빨간 삼각형)
- Layout Shift 발생 지점 확인
- Main Thread 점유 분석

**3. web-vitals 라이브러리 (Field / RUM)**
- Google 공식 JS 라이브러리
- 실제 사용자 데이터(Real User Monitoring) 수집
- LCP, INP, CLS, FCP, TTFB 지원

**4. PageSpeed Insights**
- Lab + Field 데이터 동시 제공
- CrUX 데이터 기반 실사용자 통계
- URL 단위 및 오리진 단위 분석

**5. CrUX (Chrome User Experience Report)**
- Chrome 사용자의 실제 성능 데이터 (28일 롤링)
- BigQuery, API, PageSpeed Insights에서 접근
- p75 기준으로 Good/NI/Poor 판정

---

## LCP 최적화 전략

### 1. Resource Hints 활용

```html
<!-- 크리티컬 이미지 선로딩 -->
<link rel="preload" as="image" href="/hero.webp" fetchpriority="high">

<!-- 외부 CDN 사전 연결 -->
<link rel="preconnect" href="https://cdn.example.com">
<link rel="dns-prefetch" href="https://analytics.example.com">
```

| Hint | 용도 | 비용 |
|------|------|------|
| `dns-prefetch` | DNS 조회만 미리 수행 | 낮음 |
| `preconnect` | DNS + TCP + TLS 미리 수행 | 중간 |
| `preload` | 리소스를 즉시 다운로드 | 높음 (대역폭 사용) |

### 2. fetchpriority로 우선순위 제어

```html
<!-- 히어로 이미지는 높은 우선순위 -->
<img src="/hero.webp" fetchpriority="high" alt="Hero">

<!-- 하단 이미지는 낮은 우선순위 -->
<img src="/below-fold.webp" fetchpriority="low" loading="lazy" alt="Below">
```

### 3. 이미지 최적화

- **차세대 포맷**: AVIF > WebP > JPEG (압축률 순)
- **반응형 이미지**: `srcset` + `sizes`로 적절한 크기 전달
- **CDN 리사이징**: Cloudflare Images, imgix 등 활용

```html
<picture>
  <source srcset="/hero.avif" type="image/avif">
  <source srcset="/hero.webp" type="image/webp">
  <img src="/hero.jpg" alt="Hero" width="1200" height="600" fetchpriority="high">
</picture>
```

### 4. 서버 응답 시간 (TTFB) 개선

- CDN 활용 (엣지 캐싱)
- 서버 사이드 캐시 (Redis, Varnish)
- 데이터베이스 쿼리 최적화
- Streaming SSR (React 18+ `renderToPipeableStream`)

### 5. Critical CSS 인라이닝

```html
<head>
  <!-- Above-the-fold CSS를 인라인으로 -->
  <style>
    .hero { ... }
    .nav { ... }
  </style>
  <!-- 나머지 CSS는 비동기 로드 -->
  <link rel="preload" href="/styles.css" as="style" onload="this.onload=null;this.rel='stylesheet'">
</head>
```

### 6. 렌더 블로킹 리소스 제거

```html
<!-- ❌ 렌더 블로킹 -->
<script src="/analytics.js"></script>

<!-- ✅ 비동기 로드 -->
<script src="/analytics.js" async></script>

<!-- ✅ DOM 파싱 후 실행 -->
<script src="/app.js" defer></script>
```

---

## INP 최적화 전략

### 1. Long Task 분할 (Yield to Main Thread)

50ms를 초과하는 작업은 Long Task로 분류된다. 메인 스레드를 독점하면 사용자 입력 처리가 지연된다.

```typescript
// ❌ 메인 스레드를 장시간 블로킹
function processAllItems(items: Item[]) {
  for (const item of items) {
    heavyComputation(item); // 전체가 하나의 Long Task
  }
}

// ✅ 청크 단위로 분할하여 양보
async function processAllItems(items: Item[]) {
  const CHUNK_SIZE = 5;
  for (let i = 0; i < items.length; i += CHUNK_SIZE) {
    const chunk = items.slice(i, i + CHUNK_SIZE);
    chunk.forEach(item => heavyComputation(item));
    // 메인 스레드에 양보
    await yieldToMain();
  }
}

function yieldToMain(): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, 0));
}
```

### 2. scheduler.yield() & scheduler.postTask()

```typescript
// scheduler.yield() — 우선순위를 유지하며 양보
async function handleClick() {
  doFirstPart();
  await scheduler.yield(); // 브라우저에 렌더 기회 제공
  doSecondPart();
  await scheduler.yield();
  doThirdPart();
}

// scheduler.postTask() — 우선순위별 작업 스케줄링
scheduler.postTask(() => analytics.track('click'), {
  priority: 'background', // user-blocking > user-visible > background
});
```

### 3. requestIdleCallback 활용

```typescript
// 유휴 시간에 비필수 작업 실행
function sendAnalytics(data: AnalyticsData) {
  if ('requestIdleCallback' in window) {
    requestIdleCallback(() => {
      navigator.sendBeacon('/analytics', JSON.stringify(data));
    }, { timeout: 2000 }); // 최대 2초 내 실행 보장
  } else {
    setTimeout(() => {
      navigator.sendBeacon('/analytics', JSON.stringify(data));
    }, 0);
  }
}
```

### 4. Web Worker로 Heavy Computation 분리

```typescript
// worker.ts
self.onmessage = (e: MessageEvent<{ items: Item[] }>) => {
  const result = e.data.items.map(item => expensiveTransform(item));
  self.postMessage(result);
};

// main.ts
const worker = new Worker(new URL('./worker.ts', import.meta.url));

function processInBackground(items: Item[]) {
  return new Promise<Result[]>((resolve) => {
    worker.onmessage = (e) => resolve(e.data);
    worker.postMessage({ items });
  });
}
```

### 5. React에서의 INP 최적화

```tsx
import { useDeferredValue, useTransition, useState } from 'react';

function SearchResults() {
  const [query, setQuery] = useState('');
  const deferredQuery = useDeferredValue(query);
  const [isPending, startTransition] = useTransition();

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    // 입력은 즉시 반영 (urgent update)
    setQuery(e.target.value);
  };

  // deferredQuery는 급하지 않은 업데이트로 처리됨
  // → 입력 응답성 유지하면서 무거운 리렌더링은 뒤로 미룸
  return (
    <>
      <input value={query} onChange={handleChange} />
      <ResultList query={deferredQuery} />
    </>
  );
}
```

### 6. 이벤트 핸들러 최적화

```typescript
// passive listener — 스크롤 성능 향상 (preventDefault 호출 안 함을 보장)
element.addEventListener('touchstart', handler, { passive: true });

// debounce — 연속 이벤트 간격 제한
function debounce<T extends (...args: any[]) => void>(fn: T, ms: number): T {
  let timer: ReturnType<typeof setTimeout>;
  return ((...args: Parameters<T>) => {
    clearTimeout(timer);
    timer = setTimeout(() => fn(...args), ms);
  }) as T;
}
```

---

## CLS 최적화 전략

### 1. 이미지/비디오에 명시적 크기 지정

```html
<!-- ✅ width/height 속성으로 브라우저가 공간 예약 -->
<img src="/photo.webp" width="800" height="450" alt="Photo">

<!-- ✅ CSS aspect-ratio 활용 -->
<style>
  .responsive-img {
    width: 100%;
    height: auto;
    aspect-ratio: 16 / 9;
  }
</style>
```

### 2. 웹 폰트 최적화

```css
/* font-display: swap — 시스템 폰트로 먼저 표시, 로드 후 교체 */
@font-face {
  font-family: 'CustomFont';
  src: url('/fonts/custom.woff2') format('woff2');
  font-display: swap;
  /* size-adjust로 fallback ↔ 실제 폰트 크기 차이 최소화 */
  size-adjust: 105%;
  ascent-override: 90%;
  descent-override: 20%;
  line-gap-override: 0%;
}
```

> **Tip**: `@next/font`(Next.js 13+)는 자동으로 size-adjust를 계산해준다.

### 3. 동적 콘텐츠 삽입 시 공간 예약

```css
/* 광고 슬롯 — 콘텐츠 로드 전에도 공간 확보 */
.ad-slot {
  min-height: 250px;
  /* contain: layout으로 내부 변경이 외부에 영향 주지 않도록 */
  contain: layout;
}

/* 스켈레톤 UI로 공간 예약 */
.skeleton {
  min-height: 200px;
  background: linear-gradient(90deg, #f0f0f0 25%, #e0e0e0 50%, #f0f0f0 75%);
  background-size: 200% 100%;
  animation: shimmer 1.5s infinite;
}
```

### 4. transform 애니메이션 사용

```css
/* ❌ top/left 변경 → Layout 트리거 → CLS 유발 가능 */
.bad-animation {
  position: absolute;
  top: 0;
  transition: top 0.3s;
}
.bad-animation.open {
  top: 100px;
}

/* ✅ transform → Compositor 레이어에서 처리 → Layout 안 건드림 */
.good-animation {
  transform: translateY(0);
  transition: transform 0.3s;
}
.good-animation.open {
  transform: translateY(100px);
}
```

### 5. bfcache 호환성

**bfcache**(Back/Forward Cache)는 페이지를 메모리에 보존해 뒤로/앞으로 이동 시 즉시 복원한다. bfcache에서 복원된 페이지는 CLS가 0으로 리셋된다.

**bfcache 차단 요인 피하기**:
- `unload` 이벤트 리스너 사용 금지 → `pagehide` 사용
- `Cache-Control: no-store` 지양
- `window.opener` 참조 제거

```typescript
// ✅ pagehide로 정리 작업 수행
window.addEventListener('pagehide', (event) => {
  if (event.persisted) {
    // bfcache에 저장됨 — 연결 정리 등
  }
});

// bfcache 복원 시 상태 갱신
window.addEventListener('pageshow', (event) => {
  if (event.persisted) {
    // bfcache에서 복원됨 — 데이터 재검증
    revalidateData();
  }
});
```

---

## 실전 코드 예제

### web-vitals로 RUM 수집 구현

```typescript
import { onLCP, onINP, onCLS, onFCP, onTTFB, type Metric } from 'web-vitals';

interface VitalPayload {
  name: string;
  value: number;
  rating: 'good' | 'needs-improvement' | 'poor';
  delta: number;
  id: string;
  navigationType: string;
}

function sendToAnalytics(metric: Metric) {
  const payload: VitalPayload = {
    name: metric.name,
    value: metric.value,
    rating: metric.rating,
    delta: metric.delta,
    id: metric.id,
    navigationType: metric.navigationType,
  };

  // Navigator.sendBeacon은 페이지 이탈 시에도 안정적으로 전송
  if (navigator.sendBeacon) {
    navigator.sendBeacon('/api/vitals', JSON.stringify(payload));
  } else {
    fetch('/api/vitals', {
      method: 'POST',
      body: JSON.stringify(payload),
      keepalive: true, // 페이지 이탈 시에도 요청 유지
    });
  }
}

// 모든 Core Web Vitals 수집
onLCP(sendToAnalytics);
onINP(sendToAnalytics);
onCLS(sendToAnalytics);

// 보조 지표
onFCP(sendToAnalytics);
onTTFB(sendToAnalytics);
```

### Performance Observer로 Long Task 감지

```typescript
// Long Task 감지 & 로깅
function observeLongTasks() {
  if (!('PerformanceObserver' in window)) return;

  const observer = new PerformanceObserver((list) => {
    for (const entry of list.getEntries()) {
      // 50ms 초과 시 Long Task
      console.warn(`⚠️ Long Task detected: ${entry.duration.toFixed(1)}ms`, {
        startTime: entry.startTime,
        duration: entry.duration,
        name: entry.name,
      });

      // 100ms 이상이면 RUM으로 전송
      if (entry.duration > 100) {
        sendToAnalytics({
          name: 'long-task',
          value: entry.duration,
          startTime: entry.startTime,
        });
      }
    }
  });

  observer.observe({ type: 'longtask', buffered: true });
  return observer;
}

// Layout Shift 관찰
function observeLayoutShifts() {
  const observer = new PerformanceObserver((list) => {
    for (const entry of list.getEntries() as PerformanceEntry[]) {
      const layoutShift = entry as any;
      if (!layoutShift.hadRecentInput) {
        console.log('Layout Shift:', {
          value: layoutShift.value,
          sources: layoutShift.sources?.map((s: any) => s.node),
        });
      }
    }
  });

  observer.observe({ type: 'layout-shift', buffered: true });
}
```

### Next.js에서의 이미지 최적화 설정

```tsx
// next.config.js
/** @type {import('next').NextConfig} */
const nextConfig = {
  images: {
    formats: ['image/avif', 'image/webp'],
    deviceSizes: [640, 750, 828, 1080, 1200, 1920, 2048],
    imageSizes: [16, 32, 48, 64, 96, 128, 256, 384],
    minimumCacheTTL: 60 * 60 * 24 * 30, // 30일
  },
};

// 컴포넌트에서 사용
import Image from 'next/image';

export function HeroSection() {
  return (
    <section>
      {/* LCP 대상 → priority로 preload 트리거 */}
      <Image
        src="/hero.jpg"
        alt="Hero banner"
        width={1200}
        height={600}
        priority  // fetchpriority="high" + preload 자동 추가
        sizes="100vw"
        quality={85}
      />

      {/* 스크롤 아래 이미지 → lazy loading (기본값) */}
      <Image
        src="/feature.jpg"
        alt="Feature"
        width={600}
        height={400}
        sizes="(max-width: 768px) 100vw, 50vw"
      />
    </section>
  );
}
```

### scheduler.yield() 폴리필 & 사용 예제

```typescript
// scheduler.yield() 폴리필
function yieldToMain(): Promise<void> {
  // 네이티브 scheduler.yield() 지원 시 사용
  if ('scheduler' in globalThis && 'yield' in (globalThis as any).scheduler) {
    return (globalThis as any).scheduler.yield();
  }
  // 폴리필: setTimeout(0)으로 매크로태스크 생성
  return new Promise(resolve => setTimeout(resolve, 0));
}

// 실전 사용: 대량 리스트 렌더링
async function renderLargeList(items: HTMLElement[], container: Element) {
  const BATCH = 20;

  for (let i = 0; i < items.length; i += BATCH) {
    const fragment = document.createDocumentFragment();
    const batch = items.slice(i, i + BATCH);

    for (const item of batch) {
      fragment.appendChild(item);
    }
    container.appendChild(fragment);

    // 각 배치 후 메인 스레드에 양보 → 입력 이벤트 처리 가능
    if (i + BATCH < items.length) {
      await yieldToMain();
    }
  }
}

// isInputPending()과 조합 (Chrome 한정)
async function processQueue(tasks: (() => void)[]) {
  while (tasks.length > 0) {
    const task = tasks.shift()!;
    task();

    // 대기 중인 입력이 있으면 즉시 양보
    if ((navigator as any).scheduling?.isInputPending?.()) {
      await yieldToMain();
    }
  }
}
```

---

## 성능 버짓 설정

### 번들 사이즈 버짓

| 리소스 | 버짓 (gzip) |
|--------|-------------|
| 초기 JS 번들 | ≤ 150KB |
| 초기 CSS | ≤ 50KB |
| 히어로 이미지 | ≤ 200KB |
| 총 페이지 무게 (initial load) | ≤ 500KB |
| 서드파티 스크립트 합계 | ≤ 100KB |

### Core Web Vitals 목표치

| 지표 | 목표 (p75) | 알림 기준 |
|------|-----------|-----------|
| LCP | ≤ 2.0초 | > 2.5초 시 경고 |
| INP | ≤ 150ms | > 200ms 시 경고 |
| CLS | ≤ 0.05 | > 0.1 시 경고 |
| TTFB | ≤ 800ms | > 1.2초 시 경고 |

### CI에서 Lighthouse CI로 자동 체크

```yaml
# .github/workflows/lighthouse.yml
name: Lighthouse CI
on: [pull_request]

jobs:
  lighthouse:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20

      - run: npm ci && npm run build

      - name: Run Lighthouse CI
        uses: treosh/lighthouse-ci-action@v11
        with:
          configPath: './lighthouserc.json'
          uploadArtifacts: true
```

```json
// lighthouserc.json
{
  "ci": {
    "collect": {
      "startServerCommand": "npm run start",
      "url": ["http://localhost:3000", "http://localhost:3000/products"],
      "numberOfRuns": 3
    },
    "assert": {
      "assertions": {
        "categories:performance": ["error", { "minScore": 0.9 }],
        "largest-contentful-paint": ["error", { "maxNumericValue": 2500 }],
        "cumulative-layout-shift": ["error", { "maxNumericValue": 0.1 }],
        "total-blocking-time": ["error", { "maxNumericValue": 300 }]
      }
    },
    "upload": {
      "target": "temporary-public-storage"
    }
  }
}
```

---

## 면접 포인트

### Q1: Core Web Vitals 3가지를 설명하고 각각의 최적화 방법은?

**LCP** — 가장 큰 콘텐츠 렌더링 시점 (2.5초 이하). preload, fetchpriority, 이미지 최적화, TTFB 개선.
**INP** — 전체 인터랙션 응답성 (200ms 이하). Long Task 분할, yield, Web Worker, React Concurrent 기능.
**CLS** — 예상치 못한 레이아웃 이동 (0.1 이하). 명시적 크기 지정, font-display, 공간 예약, transform 애니메이션.

### Q2: INP와 FID의 차이는?

FID는 **첫 번째 인터랙션의 Input Delay만** 측정. INP는 **모든 인터랙션의 전체 지연**(Input Delay + Processing + Presentation)을 측정하여 페이지 전체 수명의 응답성을 대표한다. INP가 더 실질적인 사용자 경험을 반영한다.

### Q3: LCP가 느린 원인을 어떻게 진단하는가?

1. DevTools Performance 패널에서 LCP 마커 확인 → 어떤 요소가 LCP인지 식별
2. TTFB 확인 (서버 응답 느린지)
3. Network 워터폴에서 LCP 리소스 로딩 지연 확인 (발견 시점, 우선순위)
4. 렌더 블로킹 리소스가 LCP를 지연시키는지 확인
5. web-vitals의 `attribution` 빌드로 병목 단계(TTFB, load delay, load time, render delay) 분해

### Q4: Long Task란 무엇이고 어떻게 분할하는가?

메인 스레드를 **50ms 이상** 점유하는 작업. 분할 방법:
- `setTimeout(0)` 또는 `scheduler.yield()`로 매크로태스크 경계 생성
- 작업을 청크 단위로 나누어 각 청크 사이에 양보
- 무거운 계산은 Web Worker로 오프로드
- React에서는 `useTransition`, `useDeferredValue`로 우선순위 분리

### Q5: CLS를 유발하는 일반적 원인 3가지는?

1. **크기 미지정 이미지/동영상**: 로드 후 공간이 확보되며 아래 콘텐츠 밀림
2. **웹 폰트 로드**: FOUT로 텍스트 크기 변경 → 주변 요소 이동
3. **동적 콘텐츠 삽입**: 광고, 배너, lazy-loaded 컴포넌트가 기존 콘텐츠 위에 삽입

### Q6: Lab data와 Field data의 차이는?

**Lab data**: 통제된 환경(고정 네트워크, 디바이스)에서 측정. 재현 가능하고 디버깅에 유리하나 실사용자 다양성을 반영 못 함. Lighthouse, WebPageTest가 대표적.
**Field data**: 실제 사용자의 브라우저에서 수집. CrUX(28일 롤링, p75), RUM 도구로 수집. 다양한 디바이스·네트워크 환경의 실제 경험을 반영. Google 검색 순위에 사용되는 것은 Field data.

---

## 참고 자료

- [web.dev - Core Web Vitals](https://web.dev/articles/vitals) — Google 공식 가이드
- [web.dev - INP](https://web.dev/articles/inp) — INP 상세 설명
- [web.dev - Optimize LCP](https://web.dev/articles/optimize-lcp) — LCP 최적화 가이드
- [web.dev - Optimize INP](https://web.dev/articles/optimize-inp) — INP 최적화 가이드
- [web.dev - Optimize CLS](https://web.dev/articles/optimize-cls) — CLS 최적화 가이드
- [web-vitals 라이브러리](https://github.com/GoogleChrome/web-vitals) — GitHub
- [Chrome for Developers - scheduler.yield()](https://developer.chrome.com/blog/introducing-scheduler-yield-origin-trial) — scheduler API
- [CrUX Dashboard](https://developer.chrome.com/docs/crux) — Chrome User Experience Report
- [Lighthouse CI](https://github.com/GoogleChrome/lighthouse-ci) — CI 자동화
- 《웹 성능 최적화 기법》 — 이고잉(저), 한빛미디어
