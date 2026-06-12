# 7. BroadcastChannel

## 목차
1. 개요
2. 탭 간 통신 기본
3. 실시간 동기화 구현
4. postMessage vs BroadcastChannel
5. 면접 포인트

---

## 1. 개요

`BroadcastChannel`은 같은 origin의 여러 브라우징 컨텍스트(탭, iframe, 워커)끼리 간단하게 메시지를 브로드캐스트할 수 있는 API다.

```js
// 발신
const channel = new BroadcastChannel('app-channel');
channel.postMessage({ type: 'UPDATE', data: payload });

// 수신 (같은 채널명 구독 중인 모든 컨텍스트)
channel.onmessage = (event) => {
  console.log(event.data);
};

// 에러 처리
channel.onmessageerror = (event) => {
  console.error('역직렬화 실패:', event);
};

// 채널 닫기
channel.close();
```

- 같은 origin 내 동일 채널명 구독자 전체에 전송 (발신자 자신은 수신 안 함)
- structured clone algorithm으로 직렬화 (JSON보다 다양한 타입 지원: Map, Set, Date, ArrayBuffer 등)
- 채널 이름으로 격리 가능 (네임스페이스 역할)

---

## 2. 탭 간 통신 기본

### 로그인/로그아웃 상태 동기화

```js
// auth.js (모든 탭에서 import)
const authChannel = new BroadcastChannel('auth');

export function broadcastLogin(user) {
  authChannel.postMessage({ type: 'LOGIN', user });
}

export function broadcastLogout() {
  authChannel.postMessage({ type: 'LOGOUT' });
}

export function listenAuthChanges(onLogin, onLogout) {
  authChannel.onmessage = ({ data }) => {
    if (data.type === 'LOGIN') onLogin(data.user);
    if (data.type === 'LOGOUT') onLogout();
  };

  // 정리 함수 반환
  return () => authChannel.close();
}
```

```js
// React Hook
function useAuthSync() {
  const { setUser, clearUser } = useAuthStore();

  useEffect(() => {
    const cleanup = listenAuthChanges(setUser, clearUser);
    return cleanup;
  }, []);
}
```

### 장바구니 실시간 동기화

```js
const cartChannel = new BroadcastChannel('cart');

// 장바구니 변경 시 브로드캐스트
function updateCart(items) {
  localStorage.setItem('cart', JSON.stringify(items));
  cartChannel.postMessage({ type: 'CART_UPDATED', items });
}

// 다른 탭에서 수신
cartChannel.onmessage = ({ data }) => {
  if (data.type === 'CART_UPDATED') {
    renderCart(data.items);
  }
};
```

---

## 3. 실시간 동기화 구현

### 탭 간 상태 미러링 (Primary/Replica 패턴)

```js
class TabStateSyncer {
  #channel;
  #state;
  #listeners = new Set();

  constructor(channelName, initialState) {
    this.#state = initialState;
    this.#channel = new BroadcastChannel(channelName);

    this.#channel.onmessage = ({ data }) => {
      if (data.type === 'STATE_UPDATE') {
        this.#state = { ...this.#state, ...data.patch };
        this.#notify();
      }
      if (data.type === 'REQUEST_STATE') {
        // 현재 상태를 새로 열린 탭에 전송
        this.#channel.postMessage({ type: 'STATE_SYNC', state: this.#state });
      }
      if (data.type === 'STATE_SYNC' && !this.#initialized) {
        this.#state = data.state;
        this.#initialized = true;
        this.#notify();
      }
    };

    // 다른 탭에 현재 상태 요청
    this.#channel.postMessage({ type: 'REQUEST_STATE' });
  }

  #initialized = false;

  update(patch) {
    this.#state = { ...this.#state, ...patch };
    this.#channel.postMessage({ type: 'STATE_UPDATE', patch });
    this.#notify();
  }

  subscribe(listener) {
    this.#listeners.add(listener);
    return () => this.#listeners.delete(listener);
  }

  #notify() {
    this.#listeners.forEach(fn => fn(this.#state));
  }

  getState() { return this.#state; }

  destroy() { this.#channel.close(); }
}

// 사용
const syncer = new TabStateSyncer('app-state', { theme: 'light', lang: 'ko' });

const unsub = syncer.subscribe(state => {
  document.documentElement.dataset.theme = state.theme;
});

// 테마 변경 → 모든 탭에 즉시 반영
syncer.update({ theme: 'dark' });
```

### 단일 탭 보장 (Singleton Tab)

```js
const leaderChannel = new BroadcastChannel('leader-election');
let isLeader = false;

function electLeader() {
  leaderChannel.postMessage({ type: 'PING' });

  setTimeout(() => {
    isLeader = true;
    startLeaderTasks(); // 리더만 수행할 작업 (예: 폴링)
  }, 200);
}

leaderChannel.onmessage = ({ data }) => {
  if (data.type === 'PING') {
    // 다른 탭이 리더 선출 시도 중 → 내가 이미 있으면 응답
    if (isLeader) {
      leaderChannel.postMessage({ type: 'LEADER_EXISTS' });
    }
  }
  if (data.type === 'LEADER_EXISTS') {
    isLeader = false; // 리더가 이미 있음
  }
};

electLeader();
```

---

## 4. postMessage vs BroadcastChannel

| 항목 | window.postMessage | BroadcastChannel |
|------|-------------------|-----------------|
| 대상 | 특정 window 객체 필요 | 채널명만으로 통신 |
| 참조 필요 | opener, parent 참조 필요 | 불필요 |
| 보안 | targetOrigin 지정 필수 | same-origin 자동 보장 |
| 수신자 수 | 1:1 | 1:N (브로드캐스트) |
| Worker 지원 | 제한적 | 가능 |
| 사용 사례 | iframe 통신, 팝업 통신 | 탭 간 이벤트 브로드캐스트 |

```js
// postMessage: 부모-자식 관계 필요
window.opener.postMessage({ type: 'AUTH_DONE' }, 'https://example.com');

// BroadcastChannel: 관계 불필요
const ch = new BroadcastChannel('auth');
ch.postMessage({ type: 'AUTH_DONE' });
```

### SharedWorker와의 비교

```js
// BroadcastChannel: 발신자는 수신 안 함, 단순 이벤트 전파에 적합
// SharedWorker: 상태 보관 가능, 복잡한 로직 처리 가능

// 간단한 이벤트 전파 → BroadcastChannel
// 공유 상태 + 복잡 로직 → SharedWorker
```

---

## 5. 면접 포인트

**Q. BroadcastChannel의 메시지를 발신자가 수신하지 못하는 이유는?**

스펙상 발신자 자신에게는 메시지가 전달되지 않는다. 탭 자체에 상태를 반영하려면 `postMessage` 후 직접 핸들러를 호출하거나, 전역 상태 관리를 별도로 처리해야 한다.

**Q. BroadcastChannel은 Service Worker에서도 사용 가능한가?**

가능하다. Service Worker에서 BroadcastChannel을 통해 클라이언트(탭)에 이벤트를 전달할 수 있다. 단, `clients.matchAll()`로 특정 탭에 직접 postMessage하는 방법도 있다.

**Q. 탭이 닫힐 때 채널을 닫지 않으면 어떻게 되나?**

탭이 닫히면 자동으로 연결이 해제된다. 하지만 SPA에서 컴포넌트 수준의 채널이라면 반드시 `close()`를 명시적으로 호출해야 메모리 누수를 방지할 수 있다.

**Q. localStorage와 storage 이벤트로도 탭 간 통신이 되는데, BroadcastChannel을 쓰는 이유는?**

`storage` 이벤트는 localStorage를 변경한 탭을 제외한 다른 탭에서만 발생하고, 문자열만 전달 가능하다. BroadcastChannel은 structured clone으로 Map, Set, ArrayBuffer 등 다양한 타입을 전달할 수 있고, API가 더 직관적이며 Worker에서도 사용 가능하다.
