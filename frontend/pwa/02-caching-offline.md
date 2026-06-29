# 2. 캐싱 전략 · 오프라인 · 업데이트

## 목차
1. [Cache API 기초](#1-cache-api-기초)
2. [5가지 캐싱 전략](#2-5가지-캐싱-전략)
3. [리소스 유형별 전략 선택](#3-리소스-유형별-전략-선택)
4. [오프라인 폴백](#4-오프라인-폴백)
5. [캐시 버전 관리와 업데이트](#5-캐시-버전-관리와-업데이트)
6. [저장소 비교: Cache vs IndexedDB](#6-저장소-비교-cache-vs-indexeddb)
7. [면접 포인트](#7-면접-포인트)

---

## 1. Cache API 기초

서비스 워커가 쓰는 **요청/응답 저장소**. localStorage와 달리 `Request`→`Response` 쌍을 통째로 저장(비동기, 대용량).

```js
const cache = await caches.open('app-v1');
await cache.addAll(['/', '/app.js']);          // 여러 개 한 번에
await cache.put(request, response.clone());     // 응답은 한 번만 읽히므로 clone
const hit = await cache.match(request);         // 조회
await caches.delete('app-v0');                  // 버전 캐시 삭제
```

> `Response` 본문은 **스트림이라 한 번만 소비**된다. 캐시에 넣고 브라우저에도 주려면 `response.clone()`이 필수다.

---

## 2. 5가지 캐싱 전략

`fetch` 이벤트에서 캐시와 네트워크를 어떻게 조합하느냐의 패턴.

| 전략 | 동작 | 적합 |
|------|------|------|
| **Cache First** | 캐시 있으면 그것, 없으면 네트워크 | 정적 자산(JS/CSS/폰트, 해시 파일명) |
| **Network First** | 네트워크 먼저, 실패 시 캐시 | 자주 바뀌는 데이터(뉴스 피드) |
| **Stale-While-Revalidate** | 캐시 즉시 반환 + 뒤에서 갱신 | 자주 보지만 최신성 덜 중요(아바타, 목록) |
| **Network Only** | 항상 네트워크 | 비멱등 요청(POST), 결제 |
| **Cache Only** | 항상 캐시 | 프리캐시된 셸 |

```js
// Cache First
self.addEventListener('fetch', (e) => {
  e.respondWith(caches.match(e.request).then(c => c || fetch(e.request)));
});

// Stale-While-Revalidate
self.addEventListener('fetch', (e) => {
  e.respondWith(caches.open('rt').then(async (cache) => {
    const cached = await cache.match(e.request);
    const network = fetch(e.request).then(res => { cache.put(e.request, res.clone()); return res; });
    return cached || network;            // 캐시 즉시, 동시에 백그라운드 갱신
  }));
});
```

---

## 3. 리소스 유형별 전략 선택

- **앱 셸**(HTML/JS/CSS): 해시 파일명이면 Cache First(영구), `index.html`은 Network First 또는 SWR(새 배포 반영).
- **API 데이터**: 신선도 중요 → Network First(+오프라인 폴백). 변동 적으면 SWR.
- **이미지/폰트**: Cache First + 만료(LRU/최대 개수).
- **POST/결제**: Network Only(절대 캐시 금지).

> 흔한 실수: HTML을 Cache First로 하면 새 배포를 영영 못 본다. **콘텐츠 해시가 없는 진입 문서는 항상 네트워크 우선/검증**.

---

## 4. 오프라인 폴백

네트워크·캐시 모두 실패 시 보여줄 대체 페이지/이미지.

```js
self.addEventListener('fetch', (e) => {
  if (e.request.mode === 'navigate') {        // 페이지 이동 요청
    e.respondWith(
      fetch(e.request).catch(() => caches.match('/offline.html')) // 오프라인 폴백
    );
  }
});
```

- 설치 시 `/offline.html`을 프리캐시해 둔다.
- 이미지 깨짐엔 플레이스홀더 SVG 폴백.

---

## 5. 캐시 버전 관리와 업데이트

```js
const CACHE = 'app-v2';   // 배포마다 버전 올림
self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)))  // 옛 버전 제거
    )
  );
});
```

- 캐시 이름에 버전을 박아, 새 SW의 `activate`에서 옛 캐시를 청소.
- **무한 캐시 갇힘 방지**: 만료 시간·최대 항목 수(LRU) 정책. (Workbox `ExpirationPlugin`이 자동화.)
- 사용자에게 새 버전 알림 → 새로고침 유도(SW `waiting` 감지 → `postMessage('SKIP_WAITING')`).

---

## 6. 저장소 비교: Cache vs IndexedDB

| | Cache API | IndexedDB |
|--|-----------|-----------|
| 저장 단위 | Request/Response | 구조화된 객체(키-값/인덱스) |
| 용도 | 정적 자산·HTTP 응답 | 앱 데이터(폼·오프라인 큐·쿼리 결과) |
| 쿼리 | URL 매칭 | 키/인덱스 조회 |

> 오프라인 우선 앱: **자산은 Cache API, 동적 데이터는 IndexedDB**(예: 오프라인에서 작성한 글을 큐에 저장 후 온라인 시 동기화 → [03 백그라운드 동기화](./03-background-push-install.md)). localStorage는 동기·소용량이라 SW에서 못 쓴다.

---

## 7. 면접 포인트

**Q. Cache First와 Network First는 각각 언제 쓰나요?**
> Cache First는 해시 파일명을 가진 정적 자산처럼 안 변하는 리소스에(속도 우선), Network First는 뉴스 피드처럼 신선도가 중요한 데이터에(최신성 우선, 실패 시 캐시 폴백) 쓴다.

**Q. Stale-While-Revalidate는 무엇인가요?**
> 캐시된 응답을 즉시 반환해 빠르게 보여주고, 동시에 백그라운드로 네트워크에서 갱신해 다음 방문에 최신을 쓰는 전략. 아바타·목록처럼 자주 보지만 약간 오래돼도 괜찮은 자원에 적합하다.

**Q. HTML(진입 문서)을 Cache First로 하면 안 되는 이유는?**
> 콘텐츠 해시가 없는 진입 문서를 Cache First로 두면 새 배포를 영영 못 보고 옛 버전에 갇힌다. index.html은 Network First나 SWR로 검증해야 한다.

**Q. `response.clone()`이 왜 필요한가요?**
> Response 본문은 스트림이라 한 번만 읽힌다. 캐시에 넣으면서 브라우저에도 반환하려면 두 번 소비해야 하므로 clone으로 복제한다.

**Q. PWA에서 Cache API와 IndexedDB를 어떻게 나눠 쓰나요?**
> 정적 자산·HTTP 응답은 Cache API에, 폼 입력·오프라인 작업 큐·쿼리 결과 같은 구조화된 동적 데이터는 IndexedDB에 저장한다. localStorage는 동기·소용량이라 서비스 워커에서 쓸 수 없다.

**Q. 캐시에 갇히는(stale) 문제를 어떻게 막나요?**
> 캐시 이름에 버전을 넣어 새 SW의 activate에서 옛 캐시를 삭제하고, 이미지 등은 만료 시간·최대 개수(LRU) 정책을 둔다. 새 버전이 대기 중이면 사용자에게 알려 새로고침을 유도한다.
