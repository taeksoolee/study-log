# Observer (옵저버 패턴)

## 목차
1. [개념](#1-개념)
2. [EventEmitter 직접 구현](#2-eventemitter-직접-구현)
3. [React useState와의 연결](#3-react-usestate와의-연결)
4. [RxJS Observable과의 연결](#4-rxjs-observable과의-연결)
5. [실용 예시 — 실시간 데이터](#5-실용-예시--실시간-데이터)
6. [면접 포인트](#6-면접-포인트)

---

## 1. 개념

> 객체의 상태 변화를 **구독(subscribe)하고 자동으로 통지(notify)**받는 1:N 의존 관계를 정의한다.

"발행-구독(Pub/Sub)" 패턴이라고도 한다.

**핵심 구성 요소**
- **Subject (Observable)**: 상태를 가지며, 옵저버 목록을 관리
- **Observer**: 변경 통지를 받는 객체

**언제 쓰는가?**
- 어떤 객체의 변경이 다른 객체들에게 알려져야 할 때
- 의존하는 객체의 수를 미리 알 수 없을 때
- 이벤트 기반 시스템

---

## 2. EventEmitter 직접 구현

```typescript
type Listener<T = any> = (data: T) => void;

class EventEmitter<Events extends Record<string, any>> {
  private listeners = new Map<keyof Events, Set<Listener>>();

  on<K extends keyof Events>(event: K, listener: Listener<Events[K]>): this {
    if (!this.listeners.has(event)) {
      this.listeners.set(event, new Set());
    }
    this.listeners.get(event)!.add(listener as Listener);
    return this;
  }

  off<K extends keyof Events>(event: K, listener: Listener<Events[K]>): this {
    this.listeners.get(event)?.delete(listener as Listener);
    return this;
  }

  once<K extends keyof Events>(event: K, listener: Listener<Events[K]>): this {
    const wrapper: Listener<Events[K]> = (data) => {
      listener(data);
      this.off(event, wrapper);
    };
    return this.on(event, wrapper);
  }

  emit<K extends keyof Events>(event: K, data: Events[K]): void {
    this.listeners.get(event)?.forEach(listener => {
      try {
        listener(data);
      } catch (err) {
        console.error(`[EventEmitter] 리스너 에러:`, err);
      }
    });
  }

  listenerCount(event: keyof Events): number {
    return this.listeners.get(event)?.size ?? 0;
  }

  removeAllListeners(event?: keyof Events): void {
    if (event) {
      this.listeners.delete(event);
    } else {
      this.listeners.clear();
    }
  }
}

// 타입 안전한 사용
interface StoreEvents {
  'state:change': { key: string; value: any; prevValue: any };
  'error': Error;
  'ready': void;
}

const store = new EventEmitter<StoreEvents>();

store.on('state:change', ({ key, value }) => {
  console.log(`${key}: ${value}`);
});

store.once('ready', () => {
  console.log('Store 준비 완료');
});

store.emit('state:change', { key: 'count', value: 1, prevValue: 0 });
store.emit('ready', undefined);
```

---

## 3. React useState와의 연결

React의 상태 시스템은 옵저버 패턴을 기반으로 한다.

```typescript
// React useState의 내부 원리 (단순화)
function createSignal<T>(initialValue: T) {
  let value = initialValue;
  const observers = new Set<() => void>();

  const get = (): T => {
    // 현재 실행 중인 effect가 있으면 구독 등록
    if (currentEffect) {
      observers.add(currentEffect);
    }
    return value;
  };

  const set = (newValue: T | ((prev: T) => T)): void => {
    const nextValue =
      typeof newValue === 'function'
        ? (newValue as (prev: T) => T)(value)
        : newValue;

    if (nextValue !== value) {
      value = nextValue;
      // 모든 옵저버에게 변경 알림 → 리렌더링 트리거
      observers.forEach(observer => observer());
    }
  };

  return [get, set] as const;
}

let currentEffect: (() => void) | null = null;

function createEffect(fn: () => void): void {
  currentEffect = fn;
  fn(); // 최초 실행 시 의존성 수집
  currentEffect = null;
}

// 사용
const [count, setCount] = createSignal(0);
const [name, setName] = createSignal('Alice');

createEffect(() => {
  console.log(`count: ${count()}`); // count를 읽으면 자동으로 구독
});

setCount(1); // 옵저버 호출 → 콘솔 출력
setCount(2);
setName('Bob'); // count 옵저버는 영향 없음
```

---

## 4. RxJS Observable과의 연결

RxJS는 옵저버 패턴을 비동기/이벤트 스트림에 적용한 라이브러리다.

```typescript
import { Observable, Subject, BehaviorSubject, fromEvent } from 'rxjs';
import { map, filter, debounceTime, distinctUntilChanged } from 'rxjs/operators';

// Subject = 옵저버 패턴의 Subject (발행자 + 구독자 모두 가능)
const subject = new Subject<number>();

subject.subscribe(value => console.log(`옵저버 1: ${value}`));
subject.subscribe(value => console.log(`옵저버 2: ${value * 2}`));

subject.next(1);  // 옵저버 1: 1, 옵저버 2: 2
subject.next(2);  // 옵저버 1: 2, 옵저버 2: 4

// BehaviorSubject = 현재 값을 보관하는 Subject
const state$ = new BehaviorSubject({ count: 0, loading: false });
state$.subscribe(state => console.log('상태:', state));

// 새 구독자도 현재 값을 즉시 받음
state$.next({ count: 1, loading: false });

// DOM 이벤트를 Observable로
const searchInput = document.getElementById('search') as HTMLInputElement;
fromEvent(searchInput, 'input').pipe(
  map((e) => (e.target as HTMLInputElement).value),
  debounceTime(300),
  distinctUntilChanged(),
  filter(query => query.length > 2),
).subscribe(query => {
  console.log('검색:', query);
});
```

---

## 5. 실용 예시 — 실시간 데이터

```typescript
// WebSocket 기반 실시간 데이터 구독
interface Message {
  type: string;
  payload: any;
}

class RealtimeClient extends EventEmitter<{
  'message': Message;
  'connect': void;
  'disconnect': void;
  'error': Error;
}> {
  private ws: WebSocket | null = null;
  private reconnectTimer: ReturnType<typeof setTimeout> | null = null;

  connect(url: string): void {
    this.ws = new WebSocket(url);

    this.ws.onopen = () => {
      console.log('연결됨');
      this.emit('connect', undefined);
    };

    this.ws.onmessage = (event) => {
      const message: Message = JSON.parse(event.data);
      this.emit('message', message);
    };

    this.ws.onclose = () => {
      this.emit('disconnect', undefined);
      // 자동 재연결
      this.reconnectTimer = setTimeout(() => this.connect(url), 3000);
    };

    this.ws.onerror = () => {
      this.emit('error', new Error('WebSocket 에러'));
    };
  }

  send(message: Message): void {
    this.ws?.send(JSON.stringify(message));
  }
}

// 사용
const client = new RealtimeClient();

client.on('message', (msg) => {
  if (msg.type === 'price_update') {
    updatePriceDisplay(msg.payload);
  }
});

client.on('connect', () => {
  client.send({ type: 'subscribe', payload: { symbols: ['AAPL', 'GOOG'] } });
});

client.connect('wss://stream.example.com');

function updatePriceDisplay(data: any): void {
  console.log(`${data.symbol}: ${data.price}`);
}
```

---

## 6. 면접 포인트

**Q1. 옵저버 패턴이란 무엇인가요?**
> 객체(Subject)의 상태 변화를 여러 옵저버에게 자동으로 통지하는 1:N 의존 관계 패턴입니다. 발행-구독 패턴이라고도 합니다.

**Q2. React의 useState와 옵저버 패턴의 관계는?**
> `useState`의 setter를 호출하면 React가 해당 컴포넌트(옵저버)를 리렌더링(통지)합니다. React의 렌더링 시스템 자체가 옵저버 패턴 기반입니다.

**Q3. 이벤트 리스너에서 메모리 누수를 어떻게 방지하나요?**
> 컴포넌트 언마운트 시 `removeEventListener` 또는 구독 해제 함수를 호출합니다. React에서는 `useEffect`의 cleanup 함수에서 구독을 해제합니다.

**Q4. RxJS Observable과 EventEmitter의 차이는?**
> EventEmitter는 단순한 이벤트 방출/구독입니다. RxJS Observable은 비동기 데이터 스트림에 `map`, `filter`, `debounceTime` 같은 연산자를 파이프라인으로 적용할 수 있어 더 강력합니다.

---

[← Memento](./05-memento.md) | [← 행동 패턴 목차](./README.md) | [다음: State →](./07-state.md)
