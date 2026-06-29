# 1. PWA 개념 · 매니페스트 · 서비스 워커 생명주기

## 목차
1. [PWA를 이루는 세 기둥](#1-pwa를-이루는-세-기둥)
2. [웹 앱 매니페스트](#2-웹-앱-매니페스트)
3. [서비스 워커란 — 네트워크 프록시](#3-서비스-워커란--네트워크-프록시)
4. [서비스 워커 등록](#4-서비스-워커-등록)
5. [생명주기: install → activate → fetch](#5-생명주기-install--activate--fetch)
6. [제약과 주의사항](#6-제약과-주의사항)
7. [면접 포인트](#7-면접-포인트)

---

## 1. PWA를 이루는 세 기둥

1. **HTTPS** — 서비스 워커는 보안 컨텍스트에서만 동작(localhost 예외).
2. **웹 앱 매니페스트** — 설치 시 앱 이름·아이콘·시작 URL·표시 모드.
3. **서비스 워커** — 백그라운드 스크립트로 네트워크 요청을 가로채 캐싱·오프라인·푸시 제공.

이 위에서 오프라인 동작, 홈 화면 설치, 푸시 알림, 백그라운드 동기화 같은 능력이 쌓인다.

---

## 2. 웹 앱 매니페스트

`manifest.json`(또는 `.webmanifest`)으로 앱의 설치 메타데이터를 선언한다.

```html
<link rel="manifest" href="/manifest.webmanifest">
```

```json
{
  "name": "내 앱",
  "short_name": "앱",
  "start_url": "/?source=pwa",
  "display": "standalone",        // 브라우저 UI 없이 앱처럼
  "background_color": "#ffffff",
  "theme_color": "#1a73e8",
  "icons": [
    { "src": "/icon-192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "/icon-512.png", "sizes": "512x512", "type": "image/png" },
    { "src": "/maskable.png", "sizes": "512x512", "type": "image/png", "purpose": "maskable" }
  ]
}
```

- `display: standalone`이면 주소창 없이 독립 창. `fullscreen`/`minimal-ui`도 가능.
- 설치 가능 조건: 매니페스트 + 등록된 서비스 워커 + HTTPS + 적절한 아이콘.
- `maskable` 아이콘은 안드로이드 적응형 아이콘 영역에 맞게 안전 영역을 둔 버전.

---

## 3. 서비스 워커란 — 네트워크 프록시

서비스 워커는 페이지와 별개로 도는 **워커 스레드**이자, 앱과 네트워크 사이의 **프로그래밍 가능한 프록시**다. 모든 `fetch`를 가로채 캐시에서 줄지 네트워크로 갈지 결정한다.

특징:
- 메인 스레드와 분리(논블로킹), **DOM 접근 불가**.
- 이벤트 기반: 필요할 때 깨어나고 유휴 시 종료된다(상태를 메모리에 오래 못 들고 있음 → IndexedDB/Cache에 저장).
- **스코프**: 등록된 경로 하위만 제어(`/`에 등록해야 전체 제어).

---

## 4. 서비스 워커 등록

```js
// 페이지(메인 스레드)에서
if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('/sw.js', { scope: '/' })
      .then(reg => console.log('등록됨', reg.scope))
      .catch(err => console.error('실패', err));
  });
}
```

> `sw.js`의 위치가 스코프 상한을 정한다. `/js/sw.js`에 두면 `/js/` 아래만 제어하므로 보통 **루트에 둔다**(또는 `Service-Worker-Allowed` 헤더로 확장).

---

## 5. 생명주기: install → activate → fetch

```js
// sw.js
const CACHE = 'app-v1';

self.addEventListener('install', (e) => {
  e.waitUntil(                          // 완료까지 install 유지
    caches.open(CACHE).then(c => c.addAll(['/', '/app.js', '/style.css'])) // 정적 캐싱(프리캐시)
  );
  // self.skipWaiting();  // 새 SW를 기다리지 않고 즉시 활성화(주의)
});

self.addEventListener('activate', (e) => {
  e.waitUntil(                          // 옛 캐시 정리
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)))
    )
  );
  // self.clients.claim();  // 기존 열린 탭도 즉시 제어
});

self.addEventListener('fetch', (e) => {
  e.respondWith(                        // 요청 가로채 응답 결정
    caches.match(e.request).then(cached => cached || fetch(e.request))
  );
});
```

생명주기 핵심:
1. **install**: 정적 자원 프리캐시. 성공해야 다음 단계로.
2. **waiting**: 이전 SW가 페이지를 제어 중이면 새 SW는 대기(기존 탭이 모두 닫혀야 활성화). `skipWaiting()`으로 건너뛸 수 있으나 버전 불일치 주의.
3. **activate**: 옛 캐시 청소. `clients.claim()`으로 기존 탭 즉시 제어.
4. **fetch**: 이후 모든 요청 가로채기.

> **업데이트 함정**: 새 SW는 기본적으로 기존 탭을 즉시 점령하지 않는다(안전). 그래서 배포 후에도 사용자가 옛 버전을 보다가 탭을 다 닫아야 갱신된다 → "새 버전 있음" UI로 새로고침 유도가 흔한 패턴.

---

## 6. 제약과 주의사항

- **DOM 접근 불가** — `postMessage`로 페이지와 통신.
- HTTPS 필수(localhost만 예외).
- `sw.js` 자체는 **캐시되면 안 됨**(또는 짧게) — 안 그러면 새 SW를 못 받음. 서버에서 `Cache-Control: no-cache`.
- 잘못 캐싱하면 "옛 자원에 갇힘" → 버전·청소 전략 필수.
- 개발 시 DevTools "Update on reload"·"Bypass for network"로 디버깅.

---

## 7. 면접 포인트

**Q. 서비스 워커란 무엇이고 무엇을 할 수 있나요?**
> 페이지와 별개로 도는 워커이자 앱과 네트워크 사이의 프로그래밍 가능한 프록시다. `fetch`를 가로채 캐시/네트워크를 제어해 오프라인·캐싱을 구현하고, 푸시·백그라운드 동기화의 기반이 된다. DOM 접근은 불가하고 HTTPS에서만 동작한다.

**Q. 서비스 워커 생명주기를 설명하세요.**
> install(정적 자원 프리캐시) → (이전 SW가 있으면) waiting → activate(옛 캐시 청소) → fetch(요청 가로채기). 기본적으로 새 SW는 기존 탭을 즉시 점령하지 않고, `skipWaiting()`/`clients.claim()`으로 즉시 활성화·점령할 수 있다.

**Q. 서비스 워커의 스코프란?**
> SW 파일 위치 하위 경로만 제어한다. 전체 앱을 제어하려면 루트(`/sw.js`)에 두거나 `Service-Worker-Allowed` 헤더로 스코프를 넓힌다.

**Q. PWA가 설치 가능하려면 무엇이 필요한가요?**
> HTTPS, 유효한 웹 앱 매니페스트(이름·아이콘 192/512·start_url·display), 등록된 서비스 워커가 필요하다.

**Q. 배포했는데 사용자가 옛 버전을 계속 보는 이유는?**
> 새 SW가 기본적으로 기존 탭을 즉시 점령하지 않고 waiting 상태로 대기하기 때문이다(모든 탭이 닫혀야 활성화). `sw.js`가 캐시돼도 새 SW를 못 받는다. "새 버전 있음" UI로 새로고침을 유도하거나 `skipWaiting`+`clients.claim`을 신중히 적용한다.
