# 4. Web Workers

## 목차
1. 개요 및 Worker 종류 비교
2. Dedicated Worker
3. Shared Worker
4. Service Worker
5. postMessage / Transferable Objects
6. Comlink 라이브러리
7. 면접 포인트

---

## 1. 개요 및 Worker 종류 비교

브라우저 JS는 기본적으로 단일 스레드다. Web Workers를 사용하면 백그라운드 스레드에서 무거운 작업을 실행해 메인 스레드(UI)를 블로킹하지 않을 수 있다.

| 항목 | Dedicated Worker | Shared Worker | Service Worker |
|------|-----------------|---------------|----------------|
| 인스턴스 공유 | 생성한 탭 전용 | 여러 탭/컨텍스트 공유 | 도메인 전체 공유 |
| DOM 접근 | 불가 | 불가 | 불가 |
| 네트워크 제어 | 불가 | 불가 | 가능 (fetch 가로채기) |
| 수명 | 소유 탭 종료 시 종료 | 모든 탭 종료 시 종료 | 백그라운드에서도 유지 |
| 주 용도 | 무거운 연산 오프로드 | 탭 간 상태 공유 | 오프라인 캐시, 푸시 알림 |

---

## 2. Dedicated Worker

```js
// main.js
const worker = new Worker('./worker.js');

worker.postMessage({ type: 'COMPUTE', data: largeArray });

worker.onmessage = (event) => {
  console.log('결과:', event.data);
};

worker.onerror = (error) => {
  console.error('Worker 에러:', error.message);
};

// 종료
worker.terminate();
```

```js
// worker.js — 전역 self = DedicatedWorkerGlobalScope
self.onmessage = (event) => {
  const { type, data } = event.data;

  if (type === 'COMPUTE') {
    const result = heavyComputation(data);
    self.postMessage({ type: 'RESULT', result });
  }
};

function heavyComputation(arr) {
  // 예: 정렬, 암호화, 이미지 처리 등
  return arr.reduce((sum, n) => sum + n, 0);
}
```

### Module Worker (모던 방식)

```js
// ES 모듈 문법 사용 가능
const worker = new Worker('./worker.js', { type: 'module' });
```

```js
// worker.js
import { computeHash } from './utils.js'; // 모듈 import 가능

self.onmessage = async ({ data }) => {
  const hash = await computeHash(data);
  self.postMessage(hash);
};
```

---

## 3. Shared Worker

```js
// tab1.js / tab2.js (같은 URL의 Worker를 공유)
const shared = new SharedWorker('./shared-worker.js');

shared.port.start();
shared.port.postMessage({ type: 'SUBSCRIBE', tabId: 'tab1' });

shared.port.onmessage = (event) => {
  console.log('공유 데이터:', event.data);
};
```

```js
// shared-worker.js
const ports = new Set();

self.onconnect = (event) => {
  const port = event.ports[0];
  ports.add(port);
  port.start();

  port.onmessage = (e) => {
    if (e.data.type === 'BROADCAST') {
      // 모든 연결된 탭에 브로드캐스트
      ports.forEach(p => p !== port && p.postMessage(e.data.payload));
    }
  };

  port.addEventListener('close', () => ports.delete(port));
};
```

---

## 4. Service Worker

```js
// 등록
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('/sw.js', { scope: '/' })
    .then(reg => console.log('SW 등록:', reg.scope))
    .catch(err => console.error('SW 등록 실패:', err));
}
```

```js
// sw.js — Service Worker 파일
const CACHE_NAME = 'v1';
const PRECACHE = ['/index.html', '/app.js', '/style.css'];

// 설치: 핵심 파일 사전 캐시
self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME).then(cache => cache.addAll(PRECACHE))
  );
  self.skipWaiting();
});

// 활성화: 구버전 캐시 정리
self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE_NAME).map(k => caches.delete(k)))
    )
  );
  self.clients.claim();
});

// fetch 가로채기: cache-first 전략
self.addEventListener('fetch', event => {
  event.respondWith(
    caches.match(event.request).then(cached =>
      cached || fetch(event.request)
    )
  );
});
```

---

## 5. postMessage / Transferable Objects

### 기본 postMessage (복사)

`postMessage`는 기본적으로 structured clone algorithm으로 데이터를 **복사**해 전달한다.
대용량 ArrayBuffer를 복사하면 성능 저하가 발생한다.

```js
// 느림: 100MB ArrayBuffer 복사
worker.postMessage({ buffer: largeArrayBuffer });
```

### Transferable Objects (이전)

소유권 자체를 이전하여 복사 없이 제로카피 전달. 이전 후 원본은 사용 불가.

```js
const buffer = new ArrayBuffer(100 * 1024 * 1024); // 100MB

// 두 번째 인자에 이전할 객체 배열 지정
worker.postMessage({ buffer }, [buffer]);

// 이전 후 buffer.byteLength === 0 (소유권 없음)
```

Transferable 가능 타입:
- `ArrayBuffer`
- `MessagePort`
- `ReadableStream` / `WritableStream` / `TransformStream`
- `ImageBitmap`
- `OffscreenCanvas`

### SharedArrayBuffer (공유 메모리)

```js
// 전송이 아닌 공유 — 양쪽에서 동시 접근 가능
const sab = new SharedArrayBuffer(Int32Array.BYTES_PER_ELEMENT * 10);
const arr = new Int32Array(sab);

worker.postMessage({ sab }); // 복사 없이 같은 메모리 참조

// 동기화는 Atomics 사용
Atomics.store(arr, 0, 42);
Atomics.wait(arr, 0, 42); // Worker 내에서 대기
Atomics.notify(arr, 0, 1); // 메인 스레드에서 깨우기
```

> SharedArrayBuffer는 COOP/COEP 헤더가 설정된 페이지에서만 사용 가능.

---

## 6. Comlink 라이브러리

Google이 만든 라이브러리로 RPC 스타일로 Worker를 사용할 수 있다.

```bash
npm install comlink
```

```js
// worker.js
import { expose } from 'comlink';

const api = {
  async computeFactorial(n) {
    let result = 1n;
    for (let i = 2n; i <= BigInt(n); i++) result *= i;
    return result.toString();
  },

  async processImage(imageData) {
    // 이미지 처리 로직
    return processedData;
  },
};

expose(api);
```

```js
// main.js
import { wrap } from 'comlink';

const worker = new Worker('./worker.js', { type: 'module' });
const api = wrap(worker);

// async/await으로 Worker 함수 호출 (postMessage 불필요)
const result = await api.computeFactorial(50);
console.log(result); // '30414093201713378043612608166979581188299763898377856000000000000'
```

### Comlink + Proxy 패턴

```js
// Worker 내 클래스도 사용 가능
import { expose } from 'comlink';

class Counter {
  #count = 0;
  increment() { this.#count++; }
  get value() { return this.#count; }
}

expose(Counter);
```

```js
import { wrap } from 'comlink';
const RemoteCounter = wrap(worker);

const counter = await new RemoteCounter();
await counter.increment();
console.log(await counter.value); // 1
```

---

## 7. 면접 포인트

**Q. Web Worker에서 접근할 수 없는 것은?**

DOM, `window`, `document`에 접근할 수 없다. 사용 가능한 것: `fetch`, `XMLHttpRequest`, `WebSocket`, `IndexedDB`, `Cache API`, `crypto`, `performance`, `setTimeout/setInterval`, 그리고 대부분의 Web API.

**Q. Service Worker의 update 과정은?**

새 SW 파일이 감지되면 "installing" 상태로 진입한다. 기존 SW가 제어하는 탭이 모두 닫힐 때까지 "waiting" 상태로 대기한다. `skipWaiting()`을 호출하면 즉시 "activating"으로 전환된다. 사용자 경험을 위해 업데이트 알림 UI를 표시 후 사용자가 새로고침할 때 `skipWaiting()`을 호출하는 패턴이 권장된다.

**Q. Transferable Objects를 사용해야 하는 상황은?**

1MB 이상의 바이너리 데이터(이미지, 오디오, 비디오 버퍼)를 Worker와 주고받을 때 반드시 사용해야 한다. 복사 방식은 데이터 크기에 비례해 시간이 증가하지만, 이전 방식은 O(1)이다.

**Q. Dedicated Worker와 Shared Worker 중 어떤 것을 선택해야 하나?**

단일 탭의 무거운 연산(이미지 처리, 암호화, 파싱) → Dedicated Worker. 여러 탭이 동일한 상태를 공유해야 하는 경우(실시간 데이터, 로그인 상태) → Shared Worker. 오프라인 지원, 백그라운드 동기화, 푸시 알림 → Service Worker.
