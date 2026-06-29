# PWA (Progressive Web App)

> 웹 기술로 **설치 가능하고, 오프라인에서 동작하며, 네이티브 앱 같은** 경험을 제공하는 웹 앱. 핵심 기술은 **서비스 워커**(네트워크 프록시)와 **웹 앱 매니페스트**(설치 메타데이터).

PWA는 "설치 배너 띄우기"가 아니라, 서비스 워커로 네트워크를 제어해 **신뢰성(오프라인)·속도(캐싱)·재참여(푸시)**를 얻는 일련의 능력이다. HTTPS가 전제다.

## 학습 목차

1. [PWA 개념 · 매니페스트 · 서비스 워커 생명주기](./01-service-worker.md)
2. [캐싱 전략 · 오프라인 · 업데이트](./02-caching-offline.md)
3. [백그라운드 동기화 · 푸시 알림 · 설치 UX](./03-background-push-install.md)

---

## 참고 자료

### 공식 문서 & 학습 사이트
- **web.dev — Learn PWA**: https://web.dev/learn/pwa/
- **MDN — Progressive web apps**: https://developer.mozilla.org/ko/docs/Web/Progressive_web_apps
- **Workbox (SW 라이브러리)**: https://developer.chrome.com/docs/workbox
- **MDN — Service Worker API**: https://developer.mozilla.org/ko/docs/Web/API/Service_Worker_API

### 도구
- Lighthouse PWA 감사, Chrome DevTools → Application(서비스 워커·캐시·매니페스트), Workbox
