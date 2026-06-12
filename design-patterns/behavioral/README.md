# 행동 패턴 (Behavioral Patterns)

## 개요

행동 패턴은 **객체 간의 통신과 책임 분배**를 다루는 패턴이다.
알고리즘, 요청의 흐름, 객체 간 협력 방식에 초점을 맞춘다.

핵심 목표: 결합도를 낮추면서 유연하고 재사용 가능한 객체 간 상호작용을 설계한다.

---

## 패턴 목록

| # | 패턴 | 핵심 의도 | 키워드 | 상태 |
|---|------|-----------|--------|------|
| 01 | [Chain of Responsibility (책임 연쇄)](./01-chain-of-responsibility.md) | 요청을 처리할 수 있는 객체를 찾을 때까지 전달 | 미들웨어, 파이프라인 | ⬜ |
| 02 | [Command (커맨드)](./02-command.md) | 요청을 객체로 캡슐화 | Undo/Redo, 큐 | ⬜ |
| 03 | [Iterator (이터레이터)](./03-iterator.md) | 컬렉션 순회 방법 표준화 | Symbol.iterator, 제너레이터 | ⬜ |
| 04 | [Mediator (미디에이터)](./04-mediator.md) | 객체 간 직접 참조 없이 통신 | 이벤트 버스, 중재자 | ⬜ |
| 05 | [Memento (메멘토)](./05-memento.md) | 객체 상태를 저장하고 복원 | Undo, 스냅샷 | ⬜ |
| 06 | [Observer (옵저버)](./06-observer.md) | 상태 변화를 구독자에게 알림 | EventEmitter, 반응형 | ⬜ |
| 07 | [State (상태)](./07-state.md) | 상태에 따라 행동이 달라짐 | FSM, XState | ⬜ |
| 08 | [Strategy (전략)](./08-strategy.md) | 알고리즘을 교체 가능하게 캡슐화 | 정책 패턴, 함수형 | ⬜ |
| 09 | [Template Method (템플릿 메서드)](./09-template-method.md) | 알고리즘 골격 정의, 세부 구현 위임 | 훅, 추상 클래스 | ⬜ |
| 10 | [Visitor (비지터)](./10-visitor.md) | 구조를 바꾸지 않고 연산 추가 | AST, 더블 디스패치 | ⬜ |

---

## 패턴 선택 가이드

```
객체 간 통신을 개선해야 한다
      │
      ├─ 요청이 여러 핸들러를 순서대로 거쳐야 한다 → Chain of Responsibility
      │
      ├─ 요청을 나중에 실행하거나 되돌려야 한다 → Command
      │
      ├─ 다양한 컬렉션을 일관되게 순회해야 한다 → Iterator
      │
      ├─ 많은 객체 간의 복잡한 통신을 단순화해야 한다 → Mediator
      │
      ├─ 객체 상태를 저장하고 복원해야 한다 → Memento
      │
      ├─ 여러 객체에 이벤트를 전파해야 한다 → Observer
      │
      ├─ 상태에 따라 객체 행동이 달라져야 한다 → State
      │
      ├─ 알고리즘을 런타임에 교체해야 한다 → Strategy
      │
      ├─ 알고리즘 구조는 고정, 세부 구현만 변경해야 한다 → Template Method
      │
      └─ 객체 구조 변경 없이 새 연산을 추가해야 한다 → Visitor
```

---

## 프론트엔드 연관성

| 패턴 | 프론트엔드 활용 사례 |
|------|---------------------|
| Chain of Responsibility | Express.js 미들웨어, 이벤트 버블링 |
| Command | Redux Action, Undo/Redo, Command Palette |
| Iterator | `for...of`, 제너레이터, 무한 스크롤 |
| Mediator | 이벤트 버스, Redux, React Context |
| Memento | 브라우저 히스토리, 폼 Undo, Immer |
| Observer | addEventListener, RxJS, React useState |
| State | 유한 상태 머신, XState, UI 상태 관리 |
| Strategy | 정렬, 유효성 검사, 결제 방법 선택 |
| Template Method | React lifecycle, 추상 컴포넌트 |
| Visitor | Babel AST, ESLint 규칙, 렌더러 |

---

[← 전체 목차로](../README.md)
