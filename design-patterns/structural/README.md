# 구조 패턴 (Structural Patterns)

## 개요

구조 패턴은 **클래스와 객체를 더 큰 구조로 조합**하는 방법을 다룬다.
기존 코드를 변경하지 않으면서 인터페이스를 호환시키거나, 기능을 추가하거나, 복잡성을 감추는 데 초점을 맞춘다.

핵심 원칙: **상속보다 합성(Composition over Inheritance)**

---

## 패턴 목록

| # | 패턴 | 핵심 의도 | 키워드 | 상태 |
|---|------|-----------|--------|------|
| 01 | [Adapter (어댑터)](./01-adapter.md) | 호환되지 않는 인터페이스를 연결 | 래퍼, 변환 | ⬜ |
| 02 | [Bridge (브리지)](./02-bridge.md) | 추상화와 구현을 독립적으로 분리 | 추상화, 플랫폼 독립 | ⬜ |
| 03 | [Composite (컴포짓)](./03-composite.md) | 트리 구조로 전체-부분 표현 | 재귀, 트리, 컴포넌트 | ⬜ |
| 04 | [Decorator (데코레이터)](./04-decorator.md) | 동적으로 기능 추가 (상속 대안) | HOC, 미들웨어 | ⬜ |
| 05 | [Facade (파사드)](./05-facade.md) | 복잡한 서브시스템에 단순 인터페이스 | SDK, API 래퍼 | ⬜ |
| 06 | [Flyweight (플라이웨이트)](./06-flyweight.md) | 공유로 메모리 절약 | 캐시, 풀링 | ⬜ |
| 07 | [Proxy (프록시)](./07-proxy.md) | 객체 접근을 제어하는 대리자 | 지연 로딩, 캐싱, 가드 | ⬜ |

---

## 패턴 선택 가이드

```
구조를 개선해야 한다
      │
      ├─ 호환되지 않는 두 인터페이스를 연결해야 한다 → Adapter
      │
      ├─ 추상화(기능)와 구현(플랫폼)을 따로 확장하고 싶다 → Bridge
      │
      ├─ 단일 객체와 컬렉션을 같은 방식으로 다루고 싶다 → Composite
      │
      ├─ 기존 객체에 기능을 동적으로 추가하고 싶다 → Decorator
      │
      ├─ 복잡한 시스템에 단순한 진입점을 만들고 싶다 → Facade
      │
      ├─ 유사한 객체를 대량 생성할 때 메모리를 아끼고 싶다 → Flyweight
      │
      └─ 객체 접근을 제어하거나 지연시키고 싶다 → Proxy
```

---

## 프론트엔드 연관성

| 패턴 | 프론트엔드 활용 사례 |
|------|---------------------|
| Adapter | 구버전 API 래핑, 서드파티 라이브러리 통합 |
| Bridge | 렌더러 교체 (Canvas/SVG), 플랫폼별 구현 |
| Composite | React 컴포넌트 트리, DOM 트리, 파일 시스템 UI |
| Decorator | HOC (Higher Order Component), 미들웨어, TypeScript 데코레이터 |
| Facade | SDK 초기화, axios 인스턴스 래퍼 |
| Flyweight | 아이콘 시스템, 가상화 리스트, Canvas 스프라이트 |
| Proxy | ES6 Proxy, Vue 3 반응성 시스템, 캐싱 레이어 |

---

[← 전체 목차로](../README.md)

---

## 참고 자료

- **Refactoring Guru (한국어)**: https://refactoring.guru/ko/design-patterns
- **Head First 디자인 패턴**: https://search.kyobobook.co.kr/search?keyword=Head+First+디자인+패턴
