# State (상태 패턴)

## 목차
1. [개념](#1-개념)
2. [조건문 지옥 문제](#2-조건문-지옥-문제)
3. [상태 패턴으로 리팩토링](#3-상태-패턴으로-리팩토링)
4. [유한 상태 머신(FSM) 구현](#4-유한-상태-머신fsm-구현)
5. [XState와의 연결](#5-xstate와의-연결)
6. [면접 포인트](#6-면접-포인트)

---

## 1. 개념

> 객체의 **내부 상태가 변경될 때 객체의 행동이 달라지도록** 한다.
> 마치 객체의 클래스가 바뀐 것처럼 보인다.

**핵심 아이디어**: 상태별 로직을 별도 클래스로 추출하고, 상태 전환을 명시적으로 관리한다.

**언제 쓰는가?**
- 상태에 따라 동작이 크게 달라질 때
- 상태 전환 로직이 복잡할 때
- 상태 전환 규칙을 명시적으로 관리해야 할 때
- 조건문이 너무 많아질 때

---

## 2. 조건문 지옥 문제

```typescript
// 나쁜 예 — 상태 조건문이 도처에 분산
type OrderStatus = 'pending' | 'confirmed' | 'shipped' | 'delivered' | 'cancelled';

class Order {
  status: OrderStatus = 'pending';

  confirm(): void {
    if (this.status === 'pending') {
      this.status = 'confirmed';
    } else if (this.status === 'cancelled') {
      throw new Error('취소된 주문은 확인할 수 없습니다');
    } else {
      throw new Error('이미 처리된 주문입니다');
    }
  }

  ship(): void {
    if (this.status === 'confirmed') {
      this.status = 'shipped';
    } else {
      throw new Error(`현재 상태(${this.status})에서 배송 불가`);
    }
  }

  // 상태가 추가될 때마다 모든 메서드를 수정해야 함 (OCP 위반)
}
```

---

## 3. 상태 패턴으로 리팩토링

```typescript
// 상태 인터페이스
interface OrderState {
  confirm(order: Order): void;
  ship(order: Order): void;
  deliver(order: Order): void;
  cancel(order: Order): void;
  getStatus(): string;
}

// 구체 상태 클래스들
class PendingState implements OrderState {
  confirm(order: Order): void {
    console.log('주문 확인 완료');
    order.setState(new ConfirmedState());
  }
  ship(): void { throw new Error('확인 전에는 배송 불가'); }
  deliver(): void { throw new Error('확인 전에는 배달 불가'); }
  cancel(order: Order): void {
    console.log('주문 취소');
    order.setState(new CancelledState());
  }
  getStatus() { return 'pending'; }
}

class ConfirmedState implements OrderState {
  confirm(): void { throw new Error('이미 확인된 주문'); }
  ship(order: Order): void {
    console.log('배송 시작');
    order.setState(new ShippedState());
  }
  deliver(): void { throw new Error('배송 전에는 배달 완료 불가'); }
  cancel(order: Order): void {
    console.log('주문 취소');
    order.setState(new CancelledState());
  }
  getStatus() { return 'confirmed'; }
}

class ShippedState implements OrderState {
  confirm(): void { throw new Error('이미 배송 중'); }
  ship(): void { throw new Error('이미 배송 중'); }
  deliver(order: Order): void {
    console.log('배달 완료');
    order.setState(new DeliveredState());
  }
  cancel(): void { throw new Error('배송 중에는 취소 불가'); }
  getStatus() { return 'shipped'; }
}

class DeliveredState implements OrderState {
  confirm(): void { throw new Error('이미 완료된 주문'); }
  ship(): void { throw new Error('이미 완료된 주문'); }
  deliver(): void { throw new Error('이미 배달 완료'); }
  cancel(): void { throw new Error('배달 완료 후 취소 불가'); }
  getStatus() { return 'delivered'; }
}

class CancelledState implements OrderState {
  confirm(): void { throw new Error('취소된 주문 처리 불가'); }
  ship(): void { throw new Error('취소된 주문 처리 불가'); }
  deliver(): void { throw new Error('취소된 주문 처리 불가'); }
  cancel(): void { throw new Error('이미 취소됨'); }
  getStatus() { return 'cancelled'; }
}

// 컨텍스트 (Context)
class Order {
  private state: OrderState;

  constructor(public id: string) {
    this.state = new PendingState();
  }

  setState(state: OrderState): void {
    console.log(`상태 전환: ${this.state.getStatus()} → ${state.getStatus()}`);
    this.state = state;
  }

  getStatus(): string { return this.state.getStatus(); }

  confirm(): void { this.state.confirm(this); }
  ship(): void { this.state.ship(this); }
  deliver(): void { this.state.deliver(this); }
  cancel(): void { this.state.cancel(this); }
}

// 사용
const order = new Order('ORD-001');
order.confirm();  // 상태 전환: pending → confirmed
order.ship();     // 상태 전환: confirmed → shipped
order.deliver();  // 상태 전환: shipped → delivered
// order.cancel(); // Error: 배달 완료 후 취소 불가
```

---

## 4. 유한 상태 머신(FSM) 구현

```typescript
// 선언적 FSM — 전환 테이블 방식
interface Transition<State extends string, Event extends string> {
  from: State;
  event: Event;
  to: State;
  action?: () => void;
}

class StateMachine<State extends string, Event extends string> {
  private currentState: State;

  constructor(
    initialState: State,
    private transitions: Transition<State, Event>[],
  ) {
    this.currentState = initialState;
  }

  dispatch(event: Event): boolean {
    const transition = this.transitions.find(
      t => t.from === this.currentState && t.event === event,
    );

    if (!transition) {
      console.warn(`전환 없음: ${this.currentState} + ${event}`);
      return false;
    }

    console.log(`${this.currentState} --[${event}]--> ${transition.to}`);
    this.currentState = transition.to;
    transition.action?.();
    return true;
  }

  getState(): State { return this.currentState; }
  is(state: State): boolean { return this.currentState === state; }
}

// 신호등 FSM
type TrafficState = 'red' | 'green' | 'yellow';
type TrafficEvent = 'next';

const trafficLight = new StateMachine<TrafficState, TrafficEvent>(
  'red',
  [
    { from: 'red', event: 'next', to: 'green', action: () => console.log('🟢 출발') },
    { from: 'green', event: 'next', to: 'yellow', action: () => console.log('🟡 준비') },
    { from: 'yellow', event: 'next', to: 'red', action: () => console.log('🔴 정지') },
  ],
);

trafficLight.dispatch('next'); // red → green
trafficLight.dispatch('next'); // green → yellow
trafficLight.dispatch('next'); // yellow → red
```

---

## 5. XState와의 연결

XState는 JavaScript용 유한 상태 머신 라이브러리다.

```typescript
import { createMachine, interpret } from 'xstate';

// 주문 상태 머신 선언 (시각화 가능!)
const orderMachine = createMachine({
  id: 'order',
  initial: 'pending',
  states: {
    pending: {
      on: {
        CONFIRM: 'confirmed',
        CANCEL: 'cancelled',
      },
    },
    confirmed: {
      on: {
        SHIP: 'shipped',
        CANCEL: 'cancelled',
      },
    },
    shipped: {
      on: {
        DELIVER: 'delivered',
      },
    },
    delivered: { type: 'final' },
    cancelled: { type: 'final' },
  },
});

// React에서 사용
import { useMachine } from '@xstate/react';

function OrderComponent() {
  const [state, send] = useMachine(orderMachine);

  return (
    <div>
      <p>현재 상태: {state.value}</p>
      {state.matches('pending') && (
        <button onClick={() => send('CONFIRM')}>확인</button>
      )}
      {state.matches('confirmed') && (
        <button onClick={() => send('SHIP')}>배송</button>
      )}
    </div>
  );
}
```

---

## 6. 면접 포인트

**Q1. 상태 패턴이란 무엇인가요?**
> 객체의 내부 상태에 따라 행동이 달라지게 하는 패턴입니다. 상태별 로직을 별도 클래스로 추출하여 조건문 범람을 없애고 상태 전환을 명확하게 합니다.

**Q2. 조건문 방식과 상태 패턴의 차이는?**
> 조건문 방식은 상태 로직이 분산되어 새 상태 추가 시 모든 메서드를 수정해야 합니다(OCP 위반). 상태 패턴은 새 상태 추가 시 새 클래스만 추가하면 됩니다.

**Q3. 유한 상태 머신(FSM)이란 무엇인가요?**
> 유한한 수의 상태와 상태 전환 규칙으로 시스템을 모델링하는 방법입니다. 상태 패턴의 형식화된 버전으로, XState 같은 라이브러리로 구현합니다.

**Q4. UI 개발에서 상태 패턴이 유용한 이유는?**
> 버튼(normal/hover/active/disabled), 폼(idle/loading/success/error), 모달(closed/opening/open/closing) 등 UI 컴포넌트가 명확한 상태를 갖기 때문입니다. 상태 패턴으로 각 상태의 렌더링과 이벤트 처리를 명확하게 분리할 수 있습니다.

---

[← Observer](./06-observer.md) | [← 행동 패턴 목차](./README.md) | [다음: Strategy →](./08-strategy.md)
