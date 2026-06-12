# 브라우저 동작 원리 학습 로그

브라우저 내부 동작과 렌더링 최적화에 대한 학습 문서입니다.

---

## 목차

| # | 주제 | 파일 | 상태 |
|---|------|------|------|
| 1 | 브라우저 동작 원리 (URL → 화면 전체 흐름) | [01-how-browser-works.md](./01-how-browser-works.md) | ⬜ |
| 2 | 렌더링 파이프라인 (DOM → CSSOM → Layout → Paint → Composite) | [02-rendering-pipeline.md](./02-rendering-pipeline.md) | ⬜ |
| 3 | V8 엔진 (파싱, AST, Ignition, TurboFan, JIT) | [03-v8-engine.md](./03-v8-engine.md) | ⬜ |
| 4 | DOM & CSSOM (API, MutationObserver, IntersectionObserver) | [04-dom-cssom.md](./04-dom-cssom.md) | ⬜ |
| 5 | Reflow & Repaint (차이, 원인, 최적화) | [05-reflow-repaint.md](./05-reflow-repaint.md) | ⬜ |

---

## 학습 순서 가이드

```
01 브라우저 동작 원리 (전체 맥락 파악)
   ↓
02 렌더링 파이프라인 (01의 렌더링 부분 상세)
   ↓
04 DOM & CSSOM (02의 구성 요소 상세)
   ↓
05 Reflow & Repaint (02, 04 기반의 최적화)
   
03 V8 엔진 (독립적으로 학습 가능, JS 실행 성능 관련)
```

---

## 참고 자료

- [How Browsers Work (html5rocks)](https://www.html5rocks.com/en/tutorials/internals/howbrowserswork/)
- [Web.dev - Rendering Performance](https://web.dev/rendering-performance/)
- [V8 Blog](https://v8.dev/blog)
- [Chrome DevTools - Performance](https://developer.chrome.com/docs/devtools/performance/)

---

## 참고 자료

### 공식 문서 & 학습 사이트
- **web.dev (Google)**: https://web.dev/
- **web.dev Learn Performance**: https://web.dev/learn/performance/
- **Chrome Developers**: https://developer.chrome.com/
- **MDN Web API**: https://developer.mozilla.org/ko/docs/Web/API
- **V8 블로그**: https://v8.dev/blog

### 추천 도서
| 책 제목 | 교보문고 |
|---------|---------|
| 웹 성능 최적화 기법 | [검색](https://search.kyobobook.co.kr/search?keyword=웹+성능+최적화) |
| 고성능 자바스크립트 | [검색](https://search.kyobobook.co.kr/search?keyword=고성능+자바스크립트) |
