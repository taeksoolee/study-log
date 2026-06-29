# 프론트엔드 관측성 (Observability)

> "사용자 브라우저에서 무슨 일이 일어나는지"를 본다. 백엔드 로그만으론 클라이언트 에러·성능·실제 사용자 경험을 알 수 없다.

배포 후 프론트엔드는 **개발자가 직접 볼 수 없는 수천 개의 브라우저**에서 돌아간다. 관측성은 그 블랙박스를 에러 추적·실사용자 모니터링(RUM)·로깅으로 열어, "되는데요?"가 아니라 데이터로 문제를 잡게 한다.

## 학습 목차

1. [에러 추적 · RUM · Web Vitals 수집](./01-error-tracking-rum.md)

---

## 참고 자료

### 공식 문서 & 학습 사이트
- **Sentry Docs**: https://docs.sentry.io/platforms/javascript/
- **web-vitals 라이브러리**: https://github.com/GoogleChrome/web-vitals
- **MDN: Performance API**: https://developer.mozilla.org/ko/docs/Web/API/Performance_API
- **OpenTelemetry JS**: https://opentelemetry.io/docs/languages/js/
- **web.dev: Core Web Vitals**: https://web.dev/articles/vitals

### 도구
- 에러 추적: **Sentry**, Datadog RUM, Rollbar
- 분석/RUM: Google Analytics 4, **Vercel Analytics**, Cloudflare Web Analytics
