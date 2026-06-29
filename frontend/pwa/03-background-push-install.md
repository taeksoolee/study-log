# 3. 백그라운드 동기화 · 푸시 알림 · 설치 UX

## 목차
1. [Background Sync — 오프라인 작업 재시도](#1-background-sync--오프라인-작업-재시도)
2. [Periodic Background Sync](#2-periodic-background-sync)
3. [푸시 알림 — 구조](#3-푸시-알림--구조)
4. [푸시 구독과 권한](#4-푸시-구독과-권한)
5. [푸시 수신과 알림 표시](#5-푸시-수신과-알림-표시)
6. [설치 UX (beforeinstallprompt)](#6-설치-ux-beforeinstallprompt)
7. [면접 포인트](#7-면접-포인트)

---

## 1. Background Sync — 오프라인 작업 재시도

사용자가 오프라인에서 한 작업(메시지 전송, 폼 제출)을 **온라인 복귀 시 자동 재시도**한다. SW가 연결을 감지해 처리하므로 사용자가 앱을 닫아도 동작한다.

```js
// 페이지: 작업을 IndexedDB 큐에 넣고 sync 등록
async function queueMessage(msg) {
  await saveToIDB('outbox', msg);                  // 1) 큐에 저장
  const reg = await navigator.serviceWorker.ready;
  await reg.sync.register('send-messages');        // 2) sync 태그 등록
}

// sw.js: 연결되면 발화
self.addEventListener('sync', (e) => {
  if (e.tag === 'send-messages') {
    e.waitUntil(flushOutbox());                    // 큐를 비우며 서버 전송
  }
});
```

- 브라우저가 **연결·배터리 상황을 봐서** 재시도하고, 실패하면 백오프로 다시 시도.
- 미지원 브라우저 폴백: 온라인 이벤트(`window.addEventListener('online')`)로 직접 처리.

---

## 2. Periodic Background Sync

주기적으로 콘텐츠를 미리 갱신(뉴스 프리페치 등). 권한·설치·사용 빈도에 따라 브라우저가 허용 여부와 주기를 조절한다(남용 방지). 지원이 제한적이라 핵심 기능을 의존하지 말 것.

```js
const reg = await navigator.serviceWorker.ready;
await reg.periodicSync.register('refresh-feed', { minInterval: 24 * 60 * 60 * 1000 });
```

---

## 3. 푸시 알림 — 구조

푸시는 세 주체가 관여한다.

```
[앱 서버] --(Web Push 프로토콜)--> [푸시 서비스(FCM 등 브라우저 제공)] --> [서비스 워커] --> 알림 표시
```

1. 클라이언트가 푸시 서비스에 **구독(subscription)**하고 그 엔드포인트를 앱 서버에 저장.
2. 앱 서버가 그 엔드포인트로 **VAPID 키로 서명한** 암호화 메시지를 보냄.
3. 푸시 서비스가 사용자 기기로 전달 → SW의 `push` 이벤트 발화 → 알림 표시.

> 핵심: 앱 서버가 브라우저에 직접 못 보낸다. 브라우저 벤더의 **푸시 서비스를 경유**하며, **VAPID**로 발신자를 식별한다.

---

## 4. 푸시 구독과 권한

```js
// 권한 요청은 반드시 사용자 제스처(클릭) 안에서 — 무단 요청은 거부/차단됨
async function subscribe() {
  const reg = await navigator.serviceWorker.ready;
  const sub = await reg.pushManager.subscribe({
    userVisibleOnly: true,                          // 모든 푸시가 알림을 보여야 함(무음 푸시 금지)
    applicationServerKey: urlBase64ToUint8Array(VAPID_PUBLIC_KEY),
  });
  await fetch('/api/subscribe', { method: 'POST', body: JSON.stringify(sub) }); // 서버 저장
}
```

- 권한 상태: `default`(미정) / `granted` / `denied`. **denied는 코드로 되돌릴 수 없다**(사용자가 브라우저 설정에서 직접 해제해야).
- 베스트 프랙티스: 가치를 보여준 뒤(맥락 있는 시점에) 요청. 첫 방문 즉시 요청은 차단율↑.

---

## 5. 푸시 수신과 알림 표시

```js
// sw.js
self.addEventListener('push', (e) => {
  const data = e.data?.json() ?? {};
  e.waitUntil(
    self.registration.showNotification(data.title, {
      body: data.body,
      icon: '/icon-192.png',
      badge: '/badge.png',
      data: { url: data.url },          // 클릭 시 쓸 정보
      actions: [{ action: 'open', title: '열기' }],
    })
  );
});

self.addEventListener('notificationclick', (e) => {
  e.notification.close();
  e.waitUntil(clients.openWindow(e.notification.data.url));  // 해당 페이지 열기
});
```

> `userVisibleOnly: true` 때문에 푸시를 받으면 **반드시 알림을 표시**해야 한다(조용한 추적성 푸시 금지 정책).

---

## 6. 설치 UX (beforeinstallprompt)

브라우저 기본 설치 배너 대신 **자체 UI로 설치를 유도**할 수 있다.

```js
let deferredPrompt;
window.addEventListener('beforeinstallprompt', (e) => {
  e.preventDefault();              // 기본 미니 배너 막고
  deferredPrompt = e;             // 나중에 쓰려고 보관
  showInstallButton();            // 내 "앱 설치" 버튼 노출
});

installBtn.addEventListener('click', async () => {
  deferredPrompt.prompt();                    // 설치 프롬프트 표시(사용자 제스처 내)
  const { outcome } = await deferredPrompt.userChoice;
  console.log(outcome);                        // 'accepted' | 'dismissed'
  deferredPrompt = null;
});

window.addEventListener('appinstalled', () => hideInstallButton());
```

- `beforeinstallprompt`는 설치 가능 조건(매니페스트+SW+HTTPS) 충족 시 발화. iOS Safari는 미지원(수동 "홈 화면에 추가").
- `display-mode: standalone` 미디어쿼리로 설치 실행 여부 감지 가능.

---

## 7. 면접 포인트

**Q. Background Sync는 무엇을 해결하나요?**
> 오프라인에서 한 작업(전송·제출)을 IndexedDB 큐에 저장하고 `sync`를 등록하면, 온라인 복귀 시 서비스 워커가 깨어나 자동 재시도한다. 앱을 닫아도 동작하며, 미지원 브라우저는 `online` 이벤트로 폴백한다.

**Q. 웹 푸시의 동작 구조는?**
> 클라이언트가 브라우저의 푸시 서비스에 구독해 엔드포인트를 서버에 저장하고, 앱 서버가 VAPID로 서명·암호화한 메시지를 그 엔드포인트(푸시 서비스)로 보내면, 푸시 서비스가 기기로 전달해 SW의 `push` 이벤트로 알림을 표시한다. 앱 서버가 브라우저에 직접 보내지 못하고 푸시 서비스를 경유한다.

**Q. `userVisibleOnly: true`의 의미는?**
> 모든 푸시는 사용자에게 보이는 알림을 표시해야 한다는 제약이다. 알림 없이 백그라운드에서 사용자를 추적하는 무음 푸시를 막기 위한 정책이다.

**Q. 푸시 권한을 언제 요청해야 하나요?**
> 사용자 제스처(클릭) 안에서, 가치를 보여준 맥락 있는 시점에 요청한다. 첫 방문 즉시 요청하면 거부율이 높고, 한 번 `denied`되면 코드로 되돌릴 수 없다(사용자가 브라우저 설정에서 직접 풀어야).

**Q. `beforeinstallprompt`로 설치 UX를 어떻게 커스텀하나요?**
> 이벤트에서 `preventDefault()`로 기본 배너를 막고 이벤트 객체를 보관했다가, 사용자가 내 "설치" 버튼을 누르면 `prompt()`를 호출한다. `userChoice`로 수락/거절을 알 수 있고, `appinstalled`로 완료를 감지한다. iOS Safari는 미지원이라 수동 안내가 필요하다.
