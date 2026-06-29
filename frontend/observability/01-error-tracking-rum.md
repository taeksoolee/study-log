# 1. 에러 추적 · RUM · Web Vitals 수집

## 목차
1. [관측성의 세 기둥과 프론트엔드 특수성](#1-관측성의-세-기둥과-프론트엔드-특수성)
2. [전역 에러 캐치](#2-전역-에러-캐치)
3. [소스맵 — 압축된 스택을 원본으로](#3-소스맵--압축된-스택을-원본으로)
4. [Sentry로 보는 에러 추적의 구성요소](#4-sentry로-보는-에러-추적의-구성요소)
5. [RUM과 Core Web Vitals 수집](#5-rum과-core-web-vitals-수집)
6. [샘플링·PII·노이즈 관리](#6-샘플링pii노이즈-관리)
7. [면접 포인트](#7-면접-포인트)

---

## 1. 관측성의 세 기둥과 프론트엔드 특수성

관측성의 고전적 세 기둥은 **로그(Logs) · 메트릭(Metrics) · 추적(Traces)**이다. 프론트엔드는 여기에 고유한 어려움이 더해진다.

- **환경 파편화**: 수천 종의 브라우저·기기·네트워크. 내 PC에선 재현 안 됨.
- **클라이언트 측 발생**: 에러가 서버에 안 남는다 → 따로 수집해 보내야 함.
- **사용자 경험이 곧 지표**: 응답 200 OK여도 화면이 3초간 비어 있으면 실패.

그래서 프론트엔드 관측성은 ① **에러 추적**(무엇이 깨졌나) ② **RUM**(실사용자 성능·행동) ③ **로깅/세션 리플레이**(맥락)로 구성된다.

---

## 2. 전역 에러 캐치

`try/catch`로 못 잡는 것: 비동기 콜백, 이벤트 핸들러, 리소스 로드 실패, 거부된 Promise. 전역 핸들러로 빠짐없이 포착한다.

```js
// 동기 에러 + 리소스 로드 에러
// 리소스 로드 에러(<img>/<script> 실패)는 버블링되지 않아 capture(3번째 인자 true) 필수
window.addEventListener('error', (e) => {
  if (e.target && e.target !== window) {   // 리소스 로드 실패
    report({ type: 'resource', tag: e.target.tagName, src: e.target.src || e.target.href });
  } else {                                  // JS 런타임 에러
    report({ type: 'error', message: e.message, stack: e.error?.stack,
             file: e.filename, line: e.lineno, col: e.colno });
  }
}, true);

// 처리되지 않은 Promise 거부 (await/catch 누락)
window.addEventListener('unhandledrejection', (e) => {
  report({ type: 'promise', reason: String(e.reason), stack: e.reason?.stack });
});
```

프레임워크 경계도 잡는다:

```jsx
// React: 렌더 중 에러는 Error Boundary로 (이벤트 핸들러 에러는 위 전역으로)
class ErrorBoundary extends React.Component {
  componentDidCatch(error, info) {
    report({ type: 'react', error: error.message, component: info.componentStack });
  }
  // ...
}
```

> 전송 팁: 페이지 이탈 중에도 유실 없이 보내려면 `navigator.sendBeacon()`이나 `fetch(url, { keepalive: true })`를 쓴다. 일반 `fetch`는 언로드 시 취소될 수 있다.

---

## 3. 소스맵 — 압축된 스택을 원본으로

프로덕션 번들은 minify되어 스택이 `a.b.c is not a function (main.js:1:24683)`처럼 읽을 수 없다. **소스맵**(`.map` 파일)은 압축된 위치 ↔ 원본 위치 대응표라, 추적 도구가 이를 적용해 원본 파일·줄·함수명을 복원한다.

```js
// 빌드 시 생성 (예: vite)
build: { sourcemap: true }   // 또는 'hidden' (파일은 만들되 주석 링크 제외)
```

운영 원칙:
- 소스맵을 **공개 배포하지 말 것** — 원본 코드가 노출된다. `hidden` 모드로 만들어 **에러 추적 서비스에만 업로드**한다.
- 릴리스 버전과 소스맵을 짝지어 업로드해야 정확한 매핑이 된다(릴리스 태깅).

---

## 4. Sentry로 보는 에러 추적의 구성요소

특정 제품에 종속되지 않는, 에러 추적 도구의 공통 개념:

- **그룹핑(fingerprinting)**: 같은 원인의 에러 수천 건을 하나의 *이슈*로 묶는다(스택·메시지 기반). 노이즈 폭발 방지.
- **컨텍스트**: 에러 시점의 URL·브라우저·사용자 ID·앱 상태(release, 환경).
- **브레드크럼(breadcrumbs)**: 에러 직전의 사용자 행동 로그(클릭→네비게이션→API 호출)로 재현 경로 확보.
- **릴리스 추적**: 어느 배포부터 에러가 급증했는지 → 회귀 원인 배포 특정, 롤백 판단.
- **알림/이슈 상태**: 임계치 초과 시 Slack 알림, resolve/ignore 워크플로.

```js
// 개념 예시 (벤더 무관한 형태)
tracker.init({ dsn, release: 'app@1.4.2', environment: 'production',
               tracesSampleRate: 0.1 });
tracker.setUser({ id: 'u_123' });
tracker.addBreadcrumb({ category: 'ui', message: '결제 버튼 클릭' });
```

---

## 5. RUM과 Core Web Vitals 수집

**RUM**(Real User Monitoring)은 합성 테스트(Lighthouse)와 달리 *실제 사용자*의 성능을 측정한다. 핵심은 Google의 **Core Web Vitals**.

| 지표 | 의미 | Good 기준 |
|------|------|----------|
| **LCP** (Largest Contentful Paint) | 가장 큰 콘텐츠가 그려지는 시각 = 로딩 체감 | ≤ 2.5s |
| **INP** (Interaction to Next Paint) | 입력 후 다음 페인트까지 = 반응성 (2024년 FID 대체) | ≤ 200ms |
| **CLS** (Cumulative Layout Shift) | 예기치 않은 레이아웃 이동량 = 시각 안정성 | ≤ 0.1 |

```js
// 공식 web-vitals 라이브러리로 실측치 수집 후 전송
import { onLCP, onINP, onCLS } from 'web-vitals';

function send(metric) {
  navigator.sendBeacon('/rum',
    JSON.stringify({ name: metric.name, value: metric.value, id: metric.id }));
}
onLCP(send); onINP(send); onCLS(send);
```

- 이 값들은 **분포(p75)**로 봐야 한다. 평균은 느린 꼬리 사용자를 가린다. Google도 75 백분위로 평가한다.
- 합성(랩) 측정은 회귀 게이트(CI)용, RUM(필드)은 실제 사용자 평가용 — 둘 다 필요하다.

---

## 6. 샘플링·PII·노이즈 관리

수집은 공짜가 아니다(비용·성능·프라이버시).

- **샘플링**: 트래픽이 크면 트레이스/세션을 일부만(`tracesSampleRate: 0.1`) 수집. 에러는 대개 전량, 성능 트레이스는 샘플링.
- **PII 스크러빙**: 이메일·토큰·카드번호가 URL/상태에 섞여 전송되지 않게 마스킹. 법적(GDPR/개인정보보호법) 의무.
- **노이즈 필터**: 브라우저 확장 에러, `ResizeObserver loop limit exceeded`, 봇, 안 쓰는 구버전 등은 무시 목록으로.
- **성능 영향 최소화**: SDK는 비동기 로드, 전송은 `sendBeacon`/배치로 메인 스레드를 막지 않게.

---

## 7. 면접 포인트

**Q. `try/catch`로 못 잡는 에러는 어떻게 수집하나요?**
> 전역 핸들러로 보완한다. 동기/리소스 에러는 `window.addEventListener('error')`, 처리 안 된 Promise 거부는 `'unhandledrejection'`, React 렌더 에러는 Error Boundary의 `componentDidCatch`로 잡아 한곳으로 전송한다.

**Q. 소스맵이 왜 필요하고, 운영 시 주의점은?**
> minify된 프로덕션 스택은 읽을 수 없어, 소스맵으로 압축 위치를 원본 파일·줄·함수로 복원한다. 단 원본 코드 노출을 막기 위해 공개 배포하지 말고 `hidden` 모드로 생성해 에러 추적 서비스에만 릴리스와 짝지어 업로드한다.

**Q. Core Web Vitals 3가지는?**
> LCP(최대 콘텐츠 페인트, 로딩 체감, ≤2.5s), INP(상호작용→다음 페인트, 반응성, ≤200ms, 2024년 FID 대체), CLS(누적 레이아웃 이동, 시각 안정성, ≤0.1). p75 분포로 평가한다.

**Q. 합성 모니터링과 RUM의 차이는?**
> 합성(Lighthouse)은 통제된 환경에서 일관되게 측정해 CI 회귀 게이트에 좋고, RUM은 실제 사용자의 다양한 기기·네트워크에서 측정해 진짜 경험을 반영한다. 평균이 아니라 p75 같은 분포로 봐야 느린 사용자를 놓치지 않는다.

**Q. 에러 추적에서 그룹핑(fingerprinting)이 왜 중요한가요?**
> 동일 원인의 에러 수천 건을 하나의 이슈로 묶지 않으면 알림이 폭발해 신호가 노이즈에 묻힌다. 스택·메시지 기반으로 묶어 "새로운/급증한 이슈"에 집중하고, 릴리스 추적과 결합해 회귀를 일으킨 배포를 특정한다.

**Q. 클라이언트 데이터 수집 시 프라이버시·성능은 어떻게 챙기나요?**
> PII(이메일·토큰)를 전송 전 스크러빙하고(GDPR/개인정보보호법), 트래픽이 크면 성능 트레이스를 샘플링하며, SDK는 비동기 로드·`sendBeacon` 배치 전송으로 메인 스레드를 막지 않게 한다.
