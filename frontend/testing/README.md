# 프론트엔드 테스트 전략

> 도구 사용법([단위 테스트](../libraries/03-testing-unit.md)·[E2E](../libraries/04-testing-e2e.md)·[React 테스트](../react/08-testing.md))과 별개로, **무엇을·왜·어느 수준에서** 테스트할지의 전략을 다룬다.

테스트의 목적은 "커버리지 100%"가 아니라 **변경에 대한 확신**이다. 잘못 짠 테스트는 리팩터링을 막고(구현 결합), 느려서 안 돌리게 되며, 거짓 신호로 신뢰를 잃는다. 좋은 테스트는 사용자 관점에서 동작을 검증한다.

## 학습 목차

1. [테스트 전략 · 피라미드/트로피 · 무엇을 테스트할까](./01-strategy.md)
2. [테스트 더블 · 모킹 · MSW](./02-mocking-msw.md)
3. [E2E · 시각 회귀 · CI 통합](./03-e2e-ci.md)

---

## 참고 자료

### 공식 문서 & 학습 사이트
- **Testing Library**: https://testing-library.com/
- **Vitest**: https://vitest.dev/
- **Playwright**: https://playwright.dev/
- **MSW (Mock Service Worker)**: https://mswjs.io/
- **Kent C. Dodds — Testing Trophy**: https://kentcdodds.com/blog/the-testing-trophy-and-testing-classifications

### 추천 도서
| 책 제목 | 교보문고 |
|---------|---------|
| 자바스크립트 테스팅 | [검색](https://search.kyobobook.co.kr/search?keyword=자바스크립트+테스팅) |
| 단위 테스트 (블라디미르 코리코프) | [검색](https://search.kyobobook.co.kr/search?keyword=단위+테스트) |
