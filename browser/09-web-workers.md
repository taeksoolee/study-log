# 9. Web Workers

## 목차
1. Web Worker 개요
2. Web Worker 생성 및 통신
3. Service Worker 개요 및 생명주기
4. Service Worker 캐싱 전략
5. Shared Worker
6. Web Worker vs Service Worker vs Shared Worker 비교
7. PWA 기초
8. 면접 포인트

---

## 1. Web Worker 개요

브라우저의 JavaScript는 기본적으로 **싱글 스레드**로 동작합니다. 무거운 연산이 메인 스레드에서 실행되면 UI가 블로킹되어 사용자 경험이 저하됩니다. Web Worker는 이 문제를 해결하기 위해 **백그라운드 스레드**에서 스크립트를 실행할 수 있게 해주는 브라우저 API입니다.

### 특징

- 메인 스레드와 **독립된 실행 컨텍스트**를 가집니다.
- DOM에 직접 접근할 수 없습니다.
- `window`, `document` 객체를 사용할 수 없습니다.
- `postMessage` / `onmessage`를 통해 메인 스레드와 통신합니다.
- `fetch`, `XMLHttpRequest`, `setTimeout`, `IndexedDB` 등은 사용 가능합니다.

### 사용 시나리오

- 대용량 데이터 정렬 / 필터링
- 이미지 처리 / 압축
- 암호화 연산
- 실시간 데이터 파싱 (CSV, JSON 대용량 파일)

---

## 2. Web Worker 생성 및 통신

### 메인 스레드 코드

```javascript
// main.js

// Worker 생성 - 별도 파일로 분리된 스크립트를 로드합니다
const worker = new Worker('./worker.js');

// Worker로 메시지 전송
worker.postMessage({ type: 'COMPUTE', data: [1, 2, 3, 4, 5] });

// Worker로부터 메시지 수신
worker.onmessage = function (event) {
  console.log('Worker 결과:', event.data);
  // { type: 'RESULT', result: 15 }
};

// Worker 오류 처리
worker.onerror = function (error) {
  console.error('Worker 오류:', error.message);
};

// Worker 종료 (더 이상 필요 없을 때)
// worker.terminate();
```

### Worker 스크립트

```javascript
// worker.js

// 메인 스레드로부터 메시지 수신
self.onmessage = function (event) {
  const { type, data } = event.data;

  if (type === 'COMPUTE') {
    // 무거운 연산 수행 (메인 스레드를 블로킹하지 않음)
    const result = data.reduce((sum, num) => sum + num, 0);

    // 결과를 메인 스레드로 전송
    self.postMessage({ type: 'RESULT', result });
  }
};
```

### Transferable Objects (고성능 데이터 전송)

기본적으로 `postMessage`는 데이터를 **복사(structured clone)**합니다. 대용량 `ArrayBuffer`를 전송할 때는 복사 대신 **소유권 이전(transfer)**을 사용하면 성능이 향상됩니다.

```javascript
// main.js - ArrayBuffer 소유권을 Worker로 이전
const buffer = new ArrayBuffer(1024 * 1024 * 32); // 32MB
worker.postMessage({ buffer }, [buffer]); // 두 번째 인자: transferable list

// 이전 후 main.js에서 buffer는 더 이상 접근 불가 (byteLength === 0)
console.log(buffer.byteLength); // 0
```

### Inline Worker (Blob URL 사용)

별도 파일 없이 인라인으로 Worker를 생성할 수 있습니다.

```javascript
const workerCode = `
  self.onmessage = function(event) {
    const result = event.data * 2;
    self.postMessage(result);
  };
`;

const blob = new Blob([workerCode], { type: 'application/javascript' });
const workerUrl = URL.createObjectURL(blob);
const worker = new Worker(workerUrl);

worker.postMessage(10);
worker.onmessage = (e) => console.log(e.data); // 20

// 사용 후 URL 해제
URL.revokeObjectURL(workerUrl);
```

---

## 3. Service Worker 개요 및 생명주기

Service Worker는 브라우저와 네트워크 사이의 **프록시 역할**을 하는 스크립트입니다. 네트워크 요청을 가로채고, 캐시를 관리하며, 오프라인 경험과 푸시 알림을 구현할 수 있습니다.

### 특징

- HTTPS 또는 localhost에서만 동작합니다.
- DOM에 접근할 수 없습니다.
- 브라우저가 닫혀도 백그라운드에서 동작할 수 있습니다.
- 완전히 비동기로 동작하며 `Promise` 기반 API를 사용합니다.
- 네트워크 요청을 **인터셉트(fetch 이벤트)**할 수 있습니다.

### 생명주기

```
[등록] → [설치(install)] → [활성화(activate)] → [유휴/실행(fetch, push, sync)]
              ↓
         [대기(waiting)] → 기존 Service Worker가 있을 경우 대기
```

### Service Worker 등록

```javascript
// main.js

if ('serviceWorker' in navigator) {
  window.addEventListener('load', async () => {
    try {
      const registration = await navigator.serviceWorker.register('/sw.js', {
        scope: '/' // 제어할 경로 범위 (기본값: sw.js 파일 위치 기준)
      });
      console.log('Service Worker 등록 성공:', registration.scope);
    } catch (error) {
      console.error('Service Worker 등록 실패:', error);
    }
  });
}
```

### Service Worker 스크립트 (생명주기 이벤트)

```javascript
// sw.js

const CACHE_NAME = 'my-app-v1';
const ASSETS_TO_CACHE = [
  '/',
  '/index.html',
  '/styles.css',
  '/app.js',
  '/logo.png'
];

// install 이벤트: Service Worker 설치 시 정적 자산 캐싱
self.addEventListener('install', (event) => {
  console.log('Service Worker 설치 중...');

  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      console.log('캐시 열기 성공');
      return cache.addAll(ASSETS_TO_CACHE);
    })
  );

  // 즉시 활성화 (대기 상태 건너뜀)
  self.skipWaiting();
});

// activate 이벤트: 이전 버전 캐시 정리
self.addEventListener('activate', (event) => {
  console.log('Service Worker 활성화 중...');

  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames
          .filter((name) => name !== CACHE_NAME)
          .map((name) => {
            console.log('이전 캐시 삭제:', name);
            return caches.delete(name);
          })
      );
    })
  );

  // 현재 열린 모든 클라이언트를 즉시 제어
  self.clients.claim();
});
```

---

## 4. Service Worker 캐싱 전략

### Cache First (캐시 우선)

캐시에 있으면 캐시를 반환하고, 없으면 네트워크 요청을 합니다. 정적 자산(이미지, CSS, JS)에 적합합니다.

```javascript
self.addEventListener('fetch', (event) => {
  event.respondWith(
    caches.match(event.request).then((cachedResponse) => {
      if (cachedResponse) {
        return cachedResponse; // 캐시 히트
      }
      // 캐시 미스: 네트워크 요청 후 캐시에 저장
      return fetch(event.request).then((networkResponse) => {
        return caches.open(CACHE_NAME).then((cache) => {
          cache.put(event.request, networkResponse.clone());
          return networkResponse;
        });
      });
    })
  );
});
```

### Network First (네트워크 우선)

네트워크 요청을 먼저 시도하고, 실패하면 캐시를 반환합니다. API 응답처럼 최신 데이터가 중요한 경우에 적합합니다.

```javascript
self.addEventListener('fetch', (event) => {
  event.respondWith(
    fetch(event.request)
      .then((networkResponse) => {
        // 네트워크 성공: 캐시 업데이트
        const responseClone = networkResponse.clone();
        caches.open(CACHE_NAME).then((cache) => {
          cache.put(event.request, responseClone);
        });
        return networkResponse;
      })
      .catch(() => {
        // 네트워크 실패: 캐시 반환
        return caches.match(event.request);
      })
  );
});
```

### Stale While Revalidate

캐시를 즉시 반환하면서 백그라운드에서 네트워크 요청으로 캐시를 갱신합니다. 응답 속도와 최신성을 동시에 고려할 때 적합합니다.

```javascript
self.addEventListener('fetch', (event) => {
  event.respondWith(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.match(event.request).then((cachedResponse) => {
        const fetchPromise = fetch(event.request).then((networkResponse) => {
          cache.put(event.request, networkResponse.clone());
          return networkResponse;
        });
        // 캐시가 있으면 즉시 반환, 없으면 네트워크 응답 대기
        return cachedResponse || fetchPromise;
      });
    })
  );
});
```

---

## 5. Shared Worker

Shared Worker는 **동일 출처(origin)의 여러 탭, iframe, 창**이 공유하는 단일 Worker 인스턴스입니다. 탭 간 상태 공유나 WebSocket 연결 공유 등에 활용합니다.

### 특징

- 여러 페이지/탭이 동일한 Worker 인스턴스를 공유합니다.
- 메시지 통신에 `MessagePort`를 사용합니다.
- 모든 연결이 끊기면 Worker가 종료됩니다.

### 메인 스레드 코드

```javascript
// page1.js, page2.js 동일하게 사용

const sharedWorker = new SharedWorker('./shared-worker.js');

// SharedWorker는 port를 통해 통신
sharedWorker.port.start();

sharedWorker.port.postMessage({ type: 'INCREMENT' });

sharedWorker.port.onmessage = function (event) {
  console.log('공유 카운터:', event.data.count);
};
```

### Shared Worker 스크립트

```javascript
// shared-worker.js

let count = 0;
const connectedPorts = new Set();

// 새 탭/페이지가 연결될 때마다 호출
self.onconnect = function (event) {
  const port = event.ports[0];
  connectedPorts.add(port);

  port.start();

  port.onmessage = function (e) {
    if (e.data.type === 'INCREMENT') {
      count++;
      // 연결된 모든 포트(탭)에 업데이트 브로드캐스트
      connectedPorts.forEach((p) => {
        p.postMessage({ count });
      });
    }
  };

  // 포트 연결 해제 감지 (명시적 처리 필요)
  port.addEventListener('close', () => {
    connectedPorts.delete(port);
  });
};
```

---

## 6. Web Worker vs Service Worker vs Shared Worker 비교

| 항목 | Web Worker | Service Worker | Shared Worker |
|------|-----------|----------------|---------------|
| 주요 목적 | CPU 집약 연산 오프로딩 | 네트워크 프록시, 캐싱, 오프라인 | 여러 탭 간 상태/리소스 공유 |
| 인스턴스 수 | 탭당 여러 개 생성 가능 | 출처당 1개 | 출처당 1개 |
| DOM 접근 | 불가 | 불가 | 불가 |
| 네트워크 인터셉트 | 불가 | 가능 (fetch 이벤트) | 불가 |
| 브라우저 종료 후 동작 | 불가 | 가능 (제한적) | 불가 |
| 통신 방식 | postMessage / onmessage | postMessage / clients | MessagePort |
| HTTPS 필요 | 불필요 | 필요 (localhost 제외) | 불필요 |
| 지원 범위 | 광범위 | 광범위 | 일부 제한 (Firefox, Chrome) |
| 사용 예시 | 이미지 처리, 암호화 | PWA, 오프라인 앱 | 탭 간 카운터, 공유 WebSocket |

---

## 7. PWA 기초

Progressive Web App(PWA)은 웹 기술로 만들어진 앱이 네이티브 앱처럼 동작하게 하는 방식입니다. Service Worker와 Web App Manifest가 핵심 구성 요소입니다.

### Web App Manifest (manifest.json)

홈 화면 추가, 앱 아이콘, 스플래시 화면, 실행 모드 등을 정의합니다.

```json
{
  "name": "My PWA App",
  "short_name": "MyApp",
  "description": "PWA 예제 애플리케이션",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#ffffff",
  "theme_color": "#2196F3",
  "orientation": "portrait",
  "icons": [
    {
      "src": "/icons/icon-192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "any maskable"
    },
    {
      "src": "/icons/icon-512.png",
      "sizes": "512x512",
      "type": "image/png"
    }
  ]
}
```

```html
<!-- index.html에 manifest 연결 -->
<link rel="manifest" href="/manifest.json" />
<meta name="theme-color" content="#2196F3" />
<meta name="apple-mobile-web-app-capable" content="yes" />
```

### 오프라인 지원 전략

```javascript
// sw.js - 오프라인 폴백 페이지 제공
const OFFLINE_PAGE = '/offline.html';

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll([...ASSETS_TO_CACHE, OFFLINE_PAGE]);
    })
  );
});

self.addEventListener('fetch', (event) => {
  // HTML 요청인 경우에만 오프라인 폴백 적용
  if (event.request.mode === 'navigate') {
    event.respondWith(
      fetch(event.request).catch(() => {
        return caches.match(OFFLINE_PAGE);
      })
    );
    return;
  }

  // 그 외 요청: Cache First 전략
  event.respondWith(
    caches.match(event.request).then((cached) => {
      return cached || fetch(event.request);
    })
  );
});
```

### PWA 설치 조건 (Chrome 기준)

- HTTPS로 서빙되어야 합니다.
- `manifest.json`에 `name`, `short_name`, `start_url`, `icons`(192px, 512px)가 포함되어야 합니다.
- Service Worker가 등록되어 있어야 합니다.
- `display` 값이 `standalone`, `fullscreen`, `minimal-ui` 중 하나여야 합니다.

### 설치 프롬프트 제어

```javascript
let deferredPrompt;

window.addEventListener('beforeinstallprompt', (event) => {
  // 기본 설치 프롬프트를 막고 나중에 직접 트리거
  event.preventDefault();
  deferredPrompt = event;

  // 커스텀 설치 버튼 표시
  document.getElementById('install-btn').style.display = 'block';
});

document.getElementById('install-btn').addEventListener('click', async () => {
  if (!deferredPrompt) return;

  deferredPrompt.prompt();
  const { outcome } = await deferredPrompt.userChoice;
  console.log('설치 선택:', outcome); // 'accepted' | 'dismissed'
  deferredPrompt = null;
});
```

---

## 8. 면접 포인트

### Q1. Web Worker와 Service Worker의 차이점은 무엇인가요?

Web Worker는 메인 스레드에서 무거운 연산을 분리하기 위한 백그라운드 스레드입니다. 특정 탭/페이지에 종속되며 CPU 집약적인 작업(이미지 처리, 암호화 등)에 사용합니다. Service Worker는 브라우저와 네트워크 사이의 프록시로 동작하며, 네트워크 요청을 인터셉트해 캐싱 및 오프라인 지원을 구현합니다. Service Worker는 HTTPS가 필요하고, 브라우저가 닫혀도 제한적으로 동작할 수 있습니다.

### Q2. Service Worker의 생명주기를 설명해주세요.

1. **등록(Register)**: `navigator.serviceWorker.register()`로 등록합니다.
2. **설치(Install)**: `install` 이벤트에서 정적 자산을 캐싱합니다. `skipWaiting()`으로 대기 단계를 건너뛸 수 있습니다.
3. **대기(Waiting)**: 기존 Service Worker가 있으면 새 버전이 대기합니다.
4. **활성화(Activate)**: `activate` 이벤트에서 이전 캐시를 정리합니다. `clients.claim()`으로 현재 탭을 즉시 제어합니다.
5. **실행(Running)**: `fetch`, `push`, `sync` 등의 이벤트를 처리합니다.

### Q3. PWA란 무엇이며 구성 요소는 무엇인가요?

PWA(Progressive Web App)는 웹 기술로 네이티브 앱과 유사한 경험을 제공하는 웹 애플리케이션입니다. 핵심 구성 요소는 세 가지입니다. 첫째, **HTTPS**로 안전한 통신을 보장합니다. 둘째, **Web App Manifest**(`manifest.json`)로 앱 이름, 아이콘, 시작 URL, 디스플레이 모드를 정의합니다. 셋째, **Service Worker**로 오프라인 캐싱, 백그라운드 동기화, 푸시 알림을 구현합니다.

### Q4. postMessage를 통한 데이터 전달 시 성능 최적화 방법은?

기본적으로 `postMessage`는 structured clone 알고리즘으로 데이터를 복사합니다. 대용량 `ArrayBuffer`, `MessagePort`, `OffscreenCanvas` 같은 Transferable Objects는 두 번째 인자로 전달하면 복사 없이 소유권이 이전됩니다. 이전 후 원본 컨텍스트에서는 해당 객체에 접근할 수 없습니다.

### Q5. Shared Worker는 언제 사용하나요?

여러 탭이나 iframe이 동일한 데이터나 연결을 공유해야 할 때 사용합니다. 예를 들어 탭 간 공유 카운터, 단일 WebSocket 연결을 여러 탭에서 재사용, 탭 간 사용자 인증 상태 동기화 등의 시나리오에 적합합니다. 단, Safari에서 지원이 제한적이므로 크로스 브라우저 호환성을 고려해야 합니다.

### Q6. Service Worker 캐싱 전략 중 Stale While Revalidate는 언제 적합한가요?

응답 속도(즉각적인 캐시 반환)와 데이터 최신성(백그라운드 네트워크 업데이트) 두 가지를 모두 고려할 때 사용합니다. 완전히 최신 데이터가 아니어도 되지만 오래된 데이터는 다음 요청 전에 갱신되어야 하는 콘텐츠(뉴스 피드, 프로필 이미지 등)에 적합합니다.
