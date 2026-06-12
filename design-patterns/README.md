# GOF 디자인 패턴 (Gang of Four Design Patterns)

## 목차
1. [디자인 패턴이란](#1-디자인-패턴이란)
2. [학습 필요성](#2-학습-필요성)
3. [카테고리 설명](#3-카테고리-설명)
4. [전체 패턴 목록](#4-전체-패턴-목록)

---

## 1. 디자인 패턴이란

디자인 패턴은 소프트웨어 설계에서 반복적으로 나타나는 문제에 대한 **재사용 가능한 해결책**이다.
1994년 Erich Gamma, Richard Helm, Ralph Johnson, John Vlissides (Gang of Four, GoF) 가 저서
*Design Patterns: Elements of Reusable Object-Oriented Software* 에서 23가지 패턴을 정리했다.

디자인 패턴은 코드 그 자체가 아니라 **설계 지식의 언어**다. 팀원 간 "여기에 옵저버 패턴 쓰자"라고 말하면
구체적인 구현 세부사항 없이 의도를 공유할 수 있다.

---

## 2. 학습 필요성

| 관점 | 설명 |
|------|------|
| 코드 품질 | 검증된 구조를 활용해 유지보수성, 확장성 향상 |
| 협업 | 공통 어휘 → 커뮤니케이션 비용 감소 |
| 면접 | 시니어/대기업 면접의 단골 질문 |
| 프레임워크 이해 | React, Vue, Express 등 주요 프레임워크가 패턴 기반으로 설계됨 |
| 리팩토링 | 스파게티 코드를 체계적으로 개선하는 가이드라인 |

---

## 3. 카테고리 설명

### 생성 패턴 (Creational Patterns)
**"어떻게 객체를 만들 것인가?"**

객체 생성 메커니즘을 다루며, 상황에 맞는 유연한 객체 생성 방법을 제공한다.
직접 `new` 키워드로 생성하는 것보다 더 나은 대안을 제시한다.

### 구조 패턴 (Structural Patterns)
**"어떻게 객체를 조합할 것인가?"**

클래스와 객체를 더 큰 구조로 조합하는 방법을 다룬다.
상속보다 합성을 활용하여 유연한 구조를 만든다.

### 행동 패턴 (Behavioral Patterns)
**"어떻게 객체가 상호작용할 것인가?"**

객체 간의 통신과 책임 분배를 다룬다.
알고리즘과 객체 간 책임 할당에 관한 패턴이다.

---

## 4. 전체 패턴 목록

### 생성 패턴 (Creational) — 5가지

| # | 패턴 | 핵심 의도 | 상태 |
|---|------|-----------|------|
| 01 | [Singleton (싱글톤)](./creational/01-singleton.md) | 인스턴스를 하나만 생성 | ⬜ |
| 02 | [Factory Method (팩토리 메서드)](./creational/02-factory-method.md) | 서브클래스가 생성할 객체 결정 | ⬜ |
| 03 | [Abstract Factory (추상 팩토리)](./creational/03-abstract-factory.md) | 관련 객체 군(群) 생성 | ⬜ |
| 04 | [Builder (빌더)](./creational/04-builder.md) | 복잡한 객체를 단계적으로 생성 | ⬜ |
| 05 | [Prototype (프로토타입)](./creational/05-prototype.md) | 기존 객체를 복사하여 생성 | ⬜ |

### 구조 패턴 (Structural) — 7가지

| # | 패턴 | 핵심 의도 | 상태 |
|---|------|-----------|------|
| 01 | [Adapter (어댑터)](./structural/01-adapter.md) | 호환되지 않는 인터페이스 연결 | ⬜ |
| 02 | [Bridge (브리지)](./structural/02-bridge.md) | 추상화와 구현을 분리 | ⬜ |
| 03 | [Composite (컴포짓)](./structural/03-composite.md) | 트리 구조로 전체-부분 표현 | ⬜ |
| 04 | [Decorator (데코레이터)](./structural/04-decorator.md) | 동적으로 기능 추가 | ⬜ |
| 05 | [Facade (파사드)](./structural/05-facade.md) | 복잡한 서브시스템에 단순 인터페이스 제공 | ⬜ |
| 06 | [Flyweight (플라이웨이트)](./structural/06-flyweight.md) | 공유로 메모리 절약 | ⬜ |
| 07 | [Proxy (프록시)](./structural/07-proxy.md) | 객체 접근 제어 대리자 | ⬜ |

### 행동 패턴 (Behavioral) — 11가지

| # | 패턴 | 핵심 의도 | 상태 |
|---|------|-----------|------|
| 01 | [Chain of Responsibility (책임 연쇄)](./behavioral/01-chain-of-responsibility.md) | 요청을 체인으로 전달 | ⬜ |
| 02 | [Command (커맨드)](./behavioral/02-command.md) | 요청을 객체로 캡슐화 | ⬜ |
| 03 | [Iterator (이터레이터)](./behavioral/03-iterator.md) | 순차 접근 방법 표준화 | ⬜ |
| 04 | [Mediator (미디에이터)](./behavioral/04-mediator.md) | 객체 간 중재자 | ⬜ |
| 05 | [Memento (메멘토)](./behavioral/05-memento.md) | 상태 저장 및 복원 | ⬜ |
| 06 | [Observer (옵저버)](./behavioral/06-observer.md) | 변화 통지 구독 | ⬜ |
| 07 | [State (상태)](./behavioral/07-state.md) | 상태에 따른 행동 변경 | ⬜ |
| 08 | [Strategy (전략)](./behavioral/08-strategy.md) | 알고리즘을 교체 가능하게 | ⬜ |
| 09 | [Template Method (템플릿 메서드)](./behavioral/09-template-method.md) | 알고리즘 골격 정의 | ⬜ |
| 10 | [Visitor (비지터)](./behavioral/10-visitor.md) | 구조를 바꾸지 않고 연산 추가 | ⬜ |

> GoF 원서에는 Interpreter 패턴도 포함되어 총 23가지이나, 프론트엔드 실무에서 활용 빈도가 낮아 이 학습서에서는 제외한다.

---

## 참고 자료

- [Refactoring.Guru - Design Patterns](https://refactoring.guru/design-patterns)
- [MDN Web Docs - JavaScript](https://developer.mozilla.org/ko/docs/Web/JavaScript)
- GoF 원서: *Design Patterns: Elements of Reusable Object-Oriented Software*
