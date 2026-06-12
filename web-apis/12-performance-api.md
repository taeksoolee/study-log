# 12. Performance API

## 목차
1. 개요
2. Performance.mark / measure
3. PerformanceObserver
4. Navigation Timing API
5. User Timing API 실전 활용
6. 면접 포인트

---

## 1. 개요

Performance API는 페이지 로드, 리소스 로딩, 사용자 정의 타이밍 등 다양한 성능 지표를 측정하는 표준 인터페이스다.

```js
// 고해상도 타임스탬프 (ms, 소수점 이하 포함)
performance.now(); // 예: 1234.5678 (페이지 로드 이후 경과 시간)

// 모든 성능 항목 조회
performance.getEntries();
performance.getEntriesByType('mark');
performance.getEntriesByType('measure');
performance.getEntriesByType('resource');
performance.getEntriesByType('navigation');

// 특정 이름으로 조회
performance.getEntriesByName('my-mark');
```

### Performance Entry 타입

| type | 설명 |
|------|------|
| `navigation` | 페이지 로드 타이밍 |
| `resource` | 리소스(이미지, 스크립트 등) 로딩 |
| `mark` | 사용자 정의 타임스탬프 |
| `measure` | 두 mark 사이의 측정값 |
| `paint` | FP, FCP 시점 |
| `largest-contentful-paint` | LCP |
| `layout-shift` | CLS |
| `longtask` | 50ms 초과 태스크 |

---

## 2. Performance.mark / measure

```js
// mark: 특정 시점에 타임스탬프 찍기
performance.mark('fetch-start');
const data = await fetch('/api/data').then(r => r.json());
performance.mark('fetch-end');

// measure: 두 mark 사이의 시간 측정
performance.measure('fetch-duration', 'fetch-start', 'fetch-end');

// 결과 조회
const [measure] = performance.getEntriesByName('fetch-duration');
console.log(`fetch 소요: ${measure.duration.toFixed(2)}ms`);

// 정리
performance.clearMarks('fetch-start');
performance.clearMarks('fetch-end');
performance.clearMeasures('fetch-duration');
performance.clearMarks();    // 모든 mark 삭제
performance.clearMeasures(); // 모든 measure 삭제
```

### mark에 메타데이터 추가 (최신 API)

```js
performance.mark('component-render-start', {
  detail: {
    component: 'ProductList',
    itemCount: 50,
    userId: currentUser.id,
  },
});
```

---

## 3. PerformanceObserver

성능 항목이 추가될 때 비동기로 알림을 받는다. 타이밍 계산에 `performance.now()` 폴링이 필요 없다.

### 기본 사용

```js
const observer = new PerformanceObserver((list) => {
  for (const entry of list.getEntries()) {
    console.log(entry.name, entry.startTime, entry.duration);
  }
});

// entryTypes: 관찰할 타입 목록
observer.observe({ entryTypes: ['measure', 'mark'] });

// 개별 타입 (buffered: true → 이미 발생한 항목도 수신)
observer.observe({ type: 'largest-contentful-paint', buffered: true });
observer.observe({ type: 'layout-shift', buffered: true });
observer.observe({ type: 'longtask', buffered: true });

observer.disconnect();
```

### Core Web Vitals 측정

```js
function measureCoreWebVitals() {
  const vitals = {};

  // LCP (Largest Contentful Paint)
  new PerformanceObserver((list) => {
    const entries = list.getEntries();
    const last = entries[entries.length - 1];
    vitals.lcp = last.startTime;
    console.log(`LCP: ${vitals.lcp.toFixed(0)}ms`);
  }).observe({ type: 'largest-contentful-paint', buffered: true });

  // FID (First Input Delay) — 현재 사용 중단 예정, INP로 대체
  new PerformanceObserver((list) => {
    for (const entry of list.getEntries()) {
      vitals.fid = entry.processingStart - entry.startTime;
      console.log(`FID: ${vitals.fid.toFixed(0)}ms`);
    }
  }).observe({ type: 'first-input', buffered: true });

  // CLS (Cumulative Layout Shift)
  let clsValue = 0;
  let clsEntries = [];
  let sessionValue = 0;
  let sessionEntries = [];

  new PerformanceObserver((list) => {
    for (const entry of list.getEntries()) {
      if (!entry.hadRecentInput) {
        const firstEntry = sessionEntries[0];
        const lastEntry = sessionEntries[sessionEntries.length - 1];

        if (
          sessionValue &&
          entry.startTime - lastEntry.startTime < 1000 &&
          entry.startTime - firstEntry.startTime < 5000
        ) {
          sessionValue += entry.value;
          sessionEntries.push(entry);
        } else {
          sessionValue = entry.value;
          sessionEntries = [entry];
        }

        if (sessionValue > clsValue) {
          clsValue = sessionValue;
          clsEntries = sessionEntries;
        }
        console.log(`CLS: ${clsValue.toFixed(4)}`);
      }
    }
  }).observe({ type: 'layout-shift', buffered: true });

  // INP (Interaction to Next Paint) — Chrome 96+
  new PerformanceObserver((list) => {
    for (const entry of list.getEntries()) {
      if (entry.interactionId) {
        const inp = entry.processingEnd - entry.startTime;
        console.log(`INP candidate: ${inp.toFixed(0)}ms`);
      }
    }
  }).observe({ type: 'event', buffered: true, durationThreshold: 16 });

  return vitals;
}
```

---

## 4. Navigation Timing API

```js
const [navEntry] = performance.getEntriesByType('navigation');

// 주요 타이밍 포인트
const {
  startTime,           // 0 (기준점)
  fetchStart,          // 리소스 fetch 시작
  domainLookupStart,   // DNS 조회 시작
  domainLookupEnd,     // DNS 조회 완료
  connectStart,        // TCP 연결 시작
  connectEnd,          // TCP 연결 완료
  secureConnectionStart, // TLS 핸드셰이크 시작
  requestStart,        // HTTP 요청 전송
  responseStart,       // 첫 바이트 수신 (TTFB)
  responseEnd,         // 응답 완료
  domInteractive,      // HTML 파싱 완료, defer 스크립트 실행 전
  domContentLoadedEventStart, // DOMContentLoaded 이벤트 시작
  domContentLoadedEventEnd,
  domComplete,         // 모든 리소스 로드 완료
  loadEventStart,      // load 이벤트 시작
  loadEventEnd,        // load 이벤트 완료
} = navEntry;

console.log(`TTFB: ${(responseStart - fetchStart).toFixed(0)}ms`);
console.log(`DNS: ${(domainLookupEnd - domainLookupStart).toFixed(0)}ms`);
console.log(`TCP: ${(connectEnd - connectStart).toFixed(0)}ms`);
console.log(`DOM 파싱: ${(domInteractive - responseEnd).toFixed(0)}ms`);
console.log(`전체 로드: ${loadEventEnd.toFixed(0)}ms`);
```

### Resource Timing

```js
// 특정 리소스 타이밍 분석
const resources = performance.getEntriesByType('resource');

for (const res of resources) {
  if (res.initiatorType === 'script') {
    console.log({
      name: res.name,
      ttfb: res.responseStart - res.fetchStart,
      download: res.responseEnd - res.responseStart,
      total: res.duration,
      size: res.transferSize,
    });
  }
}

// 느린 리소스 찾기
const slowResources = resources
  .filter(r => r.duration > 500)
  .sort((a, b) => b.duration - a.duration);
```

---

## 5. User Timing API 실전 활용

### 컴포넌트 렌더링 측정

```js
class PerformanceTracker {
  #marks = new Map();

  start(label) {
    const markName = `${label}-start`;
    performance.mark(markName);
    this.#marks.set(label, markName);
  }

  end(label) {
    const startMark = this.#marks.get(label);
    if (!startMark) return;

    const endMark = `${label}-end`;
    const measureName = label;

    performance.mark(endMark);
    performance.measure(measureName, startMark, endMark);

    const [entry] = performance.getEntriesByName(measureName, 'measure');
    this.#marks.delete(label);

    // 정리
    performance.clearMarks(startMark);
    performance.clearMarks(endMark);
    performance.clearMeasures(measureName);

    return entry.duration;
  }
}

const tracker = new PerformanceTracker();

// React 예시 (Profiler API와 함께)
function DataTable({ data }) {
  tracker.start('DataTable-render');

  useEffect(() => {
    const duration = tracker.end('DataTable-render');
    if (duration > 100) {
      console.warn(`DataTable 렌더링 느림: ${duration.toFixed(1)}ms`);
      sendAnalytics('slow-render', { component: 'DataTable', duration });
    }
  });
  // ...
}
```

### 분석 데이터 전송

```js
function sendPerformanceData() {
  const navigation = performance.getEntriesByType('navigation')[0];
  const paints = performance.getEntriesByType('paint');

  const metrics = {
    ttfb: navigation?.responseStart,
    fcp: paints.find(p => p.name === 'first-contentful-paint')?.startTime,
    domInteractive: navigation?.domInteractive,
    loadTime: navigation?.loadEventEnd,
    url: location.href,
    timestamp: Date.now(),
  };

  // navigator.sendBeacon으로 페이지 언로드 시에도 전송 보장
  navigator.sendBeacon('/analytics/performance', JSON.stringify(metrics));
}

window.addEventListener('load', () => {
  // 모든 페인트가 완료된 후 측정
  setTimeout(sendPerformanceData, 0);
});
```

---

## 6. 면접 포인트

**Q. `performance.now()`와 `Date.now()`의 차이는?**

`Date.now()`는 Unix 타임스탬프(ms, 정수)로 시스템 시계에 영향 받는다. `performance.now()`는 페이지 로드 이후 경과 시간으로 소수점 이하 마이크로초 단위 정밀도를 가지며, 단조 증가(monotonic)해 시스템 시계 조정의 영향을 받지 않는다. 성능 측정에는 항상 `performance.now()`를 사용한다.

**Q. Core Web Vitals LCP, FID(INP), CLS가 무엇인가?**

- LCP (Largest Contentful Paint): 가장 큰 콘텐츠 요소가 렌더링되는 시간. 2.5초 이하 권장.
- INP (Interaction to Next Paint): 사용자 상호작용에서 다음 화면 갱신까지의 지연. 200ms 이하 권장.
- CLS (Cumulative Layout Shift): 페이지 수명 동안 발생하는 누적 레이아웃 이동. 0.1 이하 권장.

**Q. PerformanceObserver의 `buffered: true`는 무엇인가?**

Observer 등록 이전에 이미 발생한 항목도 콜백으로 전달받는다. LCP, FCP 같은 초기 로드 지표는 Observer 등록 전에 발생하므로 반드시 `buffered: true`를 설정해야 한다.

**Q. 롱태스크(Long Task)를 감지해야 하는 이유는?**

메인 스레드를 50ms 이상 차단하는 태스크는 사용자 입력을 블로킹해 FID/INP를 악화시킨다. `longtask` 타입을 관찰하면 어떤 코드가 병목인지 파악할 수 있다. 롱태스크는 코드 분할, 청크 단위 처리, Web Worker 오프로드로 해결한다.
