# 생성 패턴 (Creational Patterns)

## 개요

생성 패턴은 **객체 생성 메커니즘**을 다루는 패턴이다.
`new` 키워드로 직접 객체를 만드는 방식 대신, 상황에 따라 적합한 객체를 유연하게 생성하는 방법을 제공한다.

핵심 목표: **어떤 객체를 생성할지, 누가 생성할지, 어떻게 생성할지**를 캡슐화한다.

---

## 패턴 목록

| # | 패턴 | 핵심 의도 | 키워드 | 상태 |
|---|------|-----------|--------|------|
| 01 | [Singleton (싱글톤)](./01-singleton.md) | 인스턴스를 단 하나만 유지 | 전역 상태, 공유 자원 | ⬜ |
| 02 | [Factory Method (팩토리 메서드)](./02-factory-method.md) | 서브클래스가 생성할 객체 타입을 결정 | 확장성, 다형성 | ⬜ |
| 03 | [Abstract Factory (추상 팩토리)](./03-abstract-factory.md) | 관련 객체들의 군(群)을 묶어서 생성 | 테마, 플랫폼 독립성 | ⬜ |
| 04 | [Builder (빌더)](./04-builder.md) | 복잡한 객체를 단계적으로 구성 | 메서드 체이닝, 불변 객체 | ⬜ |
| 05 | [Prototype (프로토타입)](./05-prototype.md) | 기존 객체를 복제하여 새 객체 생성 | 깊은 복사, Object.create | ⬜ |

---

## 패턴 선택 가이드

```
객체를 생성해야 한다
      │
      ├─ 인스턴스가 딱 하나여야 한다 → Singleton
      │
      ├─ 어떤 클래스를 만들지 런타임에 결정해야 한다 → Factory Method
      │
      ├─ 서로 관련된 여러 객체를 함께 생성해야 한다 → Abstract Factory
      │
      ├─ 복잡한 객체를 단계별로 만들어야 한다 → Builder
      │
      └─ 기존 객체를 기반으로 새 객체를 만들어야 한다 → Prototype
```

---

## 프론트엔드 연관성

| 패턴 | 프론트엔드 활용 사례 |
|------|---------------------|
| Singleton | Redux store, Logger, WebSocket 연결 관리 |
| Factory Method | `React.createElement`, 컴포넌트 팩토리 |
| Abstract Factory | UI 테마 시스템, 플랫폼별 컴포넌트 |
| Builder | Query builder, Config 객체 생성, Test Fixture |
| Prototype | 상태 복사, 불변 업데이트 패턴 |

---

[← 전체 목차로](../README.md)
