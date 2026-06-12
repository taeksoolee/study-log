# TypeScript 학습 로그

TypeScript의 핵심 개념을 체계적으로 정리한 학습 문서입니다.

---

## 목차

| # | 주제 | 파일 | 상태 |
|---|------|------|------|
| 1 | 타입 시스템 기초 (기본 타입, Union, Intersection, Type vs Interface, Type Guards) | [01-type-system.md](./01-type-system.md) | ⬜ |
| 2 | 제네릭 (기본, 제약 조건, 유틸리티 함수, 조건부 타입) | [02-generics.md](./02-generics.md) | ⬜ |
| 3 | 유틸리티 타입 (Partial, Required, Pick, Omit, Record 등 직접 구현) | [03-utility-types.md](./03-utility-types.md) | ⬜ |
| 4 | 고급 타입 (Conditional, Mapped, Template Literal, Infer) | [04-advanced-types.md](./04-advanced-types.md) | ⬜ |
| 5 | 데코레이터 (클래스/메서드/프로퍼티 데코레이터, 실용 예시) | [05-decorators.md](./05-decorators.md) | ⬜ |

---

## 학습 순서 가이드

```
01 타입 시스템
   ↓
02 제네릭
   ↓
03 유틸리티 타입  ←  02의 제네릭 지식 필요
   ↓
04 고급 타입      ←  02, 03의 이해 필요
   ↓
05 데코레이터     ←  독립적으로 학습 가능
```

---

## 참고 자료

- [TypeScript 공식 문서](https://www.typescriptlang.org/docs/)
- [TypeScript Playground](https://www.typescriptlang.org/play)
- [타입스크립트 딥다이브 (한국어)](https://radlohead.gitbook.io/typescript-deep-dive/)

---

## 참고 자료

### 공식 문서 & 학습 사이트
- **TypeScript 공식 핸드북**: https://www.typescriptlang.org/docs/handbook/intro.html
- **TypeScript Playground**: https://www.typescriptlang.org/play
- **TypeScript Deep Dive**: https://basarat.gitbook.io/typescript/

### 추천 도서
| 책 제목 | 교보문고 |
|---------|---------|
| 이펙티브 타입스크립트 | [검색](https://search.kyobobook.co.kr/search?keyword=이펙티브+타입스크립트) |
| 타입스크립트 프로그래밍 | [검색](https://search.kyobobook.co.kr/search?keyword=타입스크립트+프로그래밍) |
