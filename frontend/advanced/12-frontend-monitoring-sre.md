# 프론트엔드 모니터링 & SRE

> 배포는 끝이 아니라 시작이다. 장애를 얼마나 빨리 감지하고 복구하는가가 서비스 품질을 결정한다.

---

## 개요

### 프론트엔드 SRE (Site Reliability Engineering)

SRE는 Google이 만든 운영 철학. 핵심:
- **측정 가능한 신뢰성 목표** 설정 (SLI/SLO)
- **자동화**로 운영 부담 감소
- **Error Budget**으로 속도와 안정성 균형

프론트엔드에 적용하면 "체감 성능"을 숫자로 관리하고, 성능 회귀를 자동 감지하며, 장애 대응이 체계화된다.

### Observability의 3가지 축

| 축 | 설명 | 프론트엔드 예시 |
|---|------|---------------|
| **Metrics** | 시계열 수치 데이터 | LCP, INP, CLS, 에러율 |
| **Logs** | 이벤트 기반 상세 기록 | console.error, Sentry 이벤트 |
| **Traces** | 요청 여정 추적 | 클릭 → API 호출 → 렌더링 완료 |

---

## 핵심 개념

### 1. Real User Monitoring (RUM) vs Synthetic Monitoring

| 구분 | RUM | Synthetic |
|------|-----|-----------|
| 데이터 소스 | 실제 사용자 브라우저 | 인조 요청 (봇) |
| 환경 | 다양 (디바이스·네트워크·지역) | 통제된 동일 환경 |
| 장점 | 실제 체감 반영 | 일관된 비교, 즉시 검증 |
| 단점 | 노이즈 많음, 트래픽 의존 | 실제 환경 미반영 |
| 도구 | Datadog RUM, Sentry | Lighthouse CI, WebPageTest |

**왜 둘 다 필요한가:**
- Synthetic → CI/CD 게이트로 회귀 방지 ("코드가 빨라졌는가?")
- RUM → 실제 영향도 파악 ("사용자가 빠르다고 느끼는가?")

---

### 2. Core Web Vitals 수집 파이프라인

#### web-vitals + Beacon API로 RUM 전송

```typescript
import { onLCP, onINP, onCLS, onFCP, onTTFB, type Metric } from 'web-vitals';

type MetricsQueue = Metric[];
let queue: MetricsQueue = [];
let timer: ReturnType<typeof setTimeout> | null = null;

function enqueue(metric: Metric) {
  queue.push(metric);
  if (queue.length >= 5) flush();
  else if (!timer) timer = setTimeout(flush, 5000);
}

function flush() {
  if (queue.length === 0) return;
  if (timer) { clearTimeout(timer); timer = null; }

  const payload = JSON.stringify({
    metrics: queue.map(m => ({
      name: m.name,
      value: m.value,
      rating: m.rating,
      page: window.location.pathname,
      connection: (navigator as any).connection?.effectiveType,
      timestamp: Date.now(),
    })),
  });

  queue = [];

  if (navigator.sendBeacon) {
    navigator.sendBeacon('/api/vitals', new Blob([payload], { type: 'application/json' }));
  } else {
    fetch('/api/vitals', { method: 'POST', body: payload, keepalive: true });
  }
}

export function initRUM() {
  onLCP(enqueue);
  onINP(enqueue);
  onCLS(enqueue);
  onFCP(enqueue);
  onTTFB(enqueue);
  window.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'hidden') flush();
  });
}
```

#### 데이터 해석 기준

| 백분위 | 용도 |
|--------|------|
| **p75** | Google CWV 공식 평가 기준 |
| p95 | 소수지만 심각한 문제 발견 |

**세분화:** 페이지별 / 디바이스별 / 지역별 / 네트워크별로 나눠야 원인 파악 가능.

---

### 3. Error Budget & SLI/SLO

#### SLI (Service Level Indicator) — 측정 지표

| SLI | 측정 방법 |
|-----|----------|
| LCP 성공률 | LCP < 2.5s인 페이지뷰 / 전체 PV |
| 에러 없는 세션 비율 | 에러 미발생 세션 / 전체 세션 |
| API 성공률 | 2xx 응답 / 전체 요청 |

#### SLO (Service Level Objective) — 목표

```
p75 LCP < 2.5s → 99.5% (28일 rolling window)
JS 미처리 에러율 < 0.1%
API 성공률 > 99.9%
```

#### Error Budget 계산

```typescript
function calculateErrorBudget(slo: number, totalEvents: number, goodEvents: number) {
  const allowedBad = Math.floor(totalEvents * (1 - slo));
  const actualBad = totalEvents - goodEvents;
  const remaining = allowedBad - actualBad;
  const percentRemaining = (remaining / allowedBad) * 100;

  return {
    currentSLI: ((goodEvents / totalEvents) * 100).toFixed(2) + '%',
    allowedBad,
    actualBad,
    remaining,
    percentRemaining: percentRemaining.toFixed(1) + '%',
    exhausted: remaining <= 0,
  };
}

// 예시: SLO 99.5%, 100만 PV 중 994,500이 양호
const budget = calculateErrorBudget(0.995, 1_000_000, 994_500);
// allowedBad: 5000, actualBad: 5500, remaining: -500 → 예산 초과!
```

#### Error Budget 정책

| Budget 잔여 | 상태 | 액션 |
|-------------|------|------|
| > 50% | 🟢 정상 | 새 기능 개발 진행 |
| 20~50% | 🟡 경고 | 성능 리뷰 병행 |
| < 20% | 🔴 위험 | 배포 시 성능 영향 분석 필수 |
| 소진 | 🚨 동결 | 성능/안정성 개선만 허용 |

---

### 4. 알림 설계

#### 심각도 분류

| 심각도 | 기준 | 채널 | 대응 시간 |
|--------|------|------|----------|
| **P1** | 전체 서비스 다운 | PagerDuty + 전화 | 15분 |
| **P2** | 핵심 기능 불가 | Slack #incident | 1시간 |
| **P3** | 성능 회귀, 일부 저하 | Slack #alerts | 다음 스프린트 |

#### 알림 피로 방지 원칙

1. 임계치는 SLO 기반 (절대값 아닌 비율)
2. 같은 원인 에러 그룹화
3. 5분 이상 지속 시에만 발화
4. 복구 시 자동 해소

#### Sentry 설정 예시

```typescript
import * as Sentry from '@sentry/nextjs';

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  tracesSampleRate: 0.1,
  replaysOnErrorSampleRate: 1.0,
  beforeSend(event) {
    // ChunkLoadError는 새 배포 시 자연 발생 → 경고 레벨로 낮춤
    if (event.exception?.values?.[0]?.type === 'ChunkLoadError') {
      event.level = 'warning';
    }
    return event;
  },
});
```

#### 성능 회귀 알림 (Grafana)

```yaml
alert:
  name: "LCP p75 회귀"
  condition: avg(lcp_p75) over 1h > avg(lcp_p75) over previous 24h * 1.3
  for: 15m
  severity: P3
  annotation: "LCP p75가 30% 이상 증가"
```

---

### 5. 프론트엔드 On-Call

#### 프론트엔드 장애 유형

| 유형 | 원인 | 대응 |
|------|------|------|
| ChunkLoadError | 새 배포 후 구 캐시 | 자동 리로드 로직 |
| API 5xx | 백엔드 장애 | 에러 바운더리 + 재시도 |
| CDN 장애 | CDN 프로바이더 이슈 | 멀티 CDN fallback |
| 메모리 릭 | 이벤트 리스너 미정리 | 프로파일링 → 수정 |

#### 장애 대응 Runbook 템플릿

```markdown
## 1단계: 감지 & 확인 (5분 이내)
- [ ] 알림 확인 (Sentry / Grafana)
- [ ] 영향 범위 파악 (어떤 페이지? 몇 % 사용자?)
- [ ] 최근 배포 이력 확인

## 2단계: 분류 (10분 이내)
- 배포 기인 → 롤백 진행
- 외부 의존성 → 우회/대기

## 3단계: 대응
- 롤백 필요: 이전 버전 즉시 복원 → 증상 해소 확인
- 핫픽스: 수정 → 테스트 → 긴급 배포

## 4단계: 사후 처리
- 타임라인 기록
- Blameless 포스트몰템 작성
- 재발 방지 액션 등록
```

#### 롤백 판단 기준

```
즉시 롤백:
✓ 에러율 배포 전 대비 10배 이상 증가
✓ CWV p75가 "poor" 진입
✓ 핵심 전환(결제, 가입) 완전 차단
✓ 원인 파악에 30분 이상 소요 예상

롤백 불필요:
✗ 특정 브라우저에서만 발생 (비율 < 1%)
✗ 원인 파악 완료, 핫픽스 진행 중
```

#### 포스트몰템 템플릿

```markdown
## 포스트몰템: [장애 제목]
날짜: YYYY-MM-DD | 심각도: P2 | 영향: 45분, 약 3,200명

### 타임라인
- 14:25 배포 → 14:30 에러 급증 → 14:50 롤백 → 15:15 정상 복귀

### 근본 원인
결제 SDK 메이저 업데이트 시 breaking change 미확인

### 재발 방지
| 액션 | 담당 | 기한 |
|------|------|------|
| SDK 업데이트 E2E 추가 | @frontend | 1 sprint |
| 결제 페이지 Synthetic 추가 | @sre | 1주 |
```

---

## 실전 코드 예제: Error Budget 주간 리포트

```typescript
// scripts/error-budget-report.ts (크론 실행)
async function generateReport() {
  const stats = await fetchSentryProjectStats(); // 28일 데이터

  const slo = 0.999;
  const currentRate = stats.crashFreeSessions / stats.totalSessions;
  const allowedCrashes = Math.floor(stats.totalSessions * (1 - slo));
  const actualCrashes = stats.totalSessions - stats.crashFreeSessions;
  const budgetRemaining = ((allowedCrashes - actualCrashes) / allowedCrashes) * 100;

  const status = budgetRemaining > 50 ? '🟢' :
                 budgetRemaining > 20 ? '🟡' :
                 budgetRemaining > 0  ? '🔴' : '🚨';

  await postToSlack(`
${status} Error Budget Report (${stats.period})
SLO: ${(slo * 100).toFixed(1)}% | Current: ${(currentRate * 100).toFixed(3)}%
Budget: ${budgetRemaining.toFixed(1)}% remaining (${actualCrashes}/${allowedCrashes})
${budgetRemaining <= 0 ? '⚠️ BUDGET EXHAUSTED - Feature freeze' : ''}
  `);
}
```

### Grafana PromQL 예시

```promql
# LCP p75 (페이지별)
histogram_quantile(0.75, sum(rate(web_vitals_lcp_bucket[5m])) by (le, page))

# 에러율 (분당)
sum(rate(frontend_errors_total[1m])) / sum(rate(frontend_pageviews_total[1m])) * 100

# SLO 달성률 (28일)
sum(web_vitals_lcp_good_total) / sum(web_vitals_lcp_total) * 100
```

---

## 도구 비교

| 도구 | 장점 | 단점 | 비용 |
|------|------|------|------|
| **Datadog RUM** | 통합 관측, 세션 리플레이 | 비쌈 | $$$ |
| **New Relic Browser** | APM 연동 우수 | UI 복잡 | $$ |
| **Sentry Performance** | 에러+성능, 무료 플랜 | RUM 기능 제한 | $ |
| **Vercel Analytics** | 설정 간편, Next.js 최적화 | Vercel 종속 | $ |
| **자체 구축** | 완전한 제어, 비용 효율 | 개발 부담 | 인건비 |

### 자체 구축 추천 스택

```
web-vitals → Beacon API → ClickHouse → Grafana → Slack/PagerDuty
에러 추적: Sentry (셀프호스트 가능)
```

---

## 면접 포인트

### Q1. RUM과 Synthetic Monitoring의 차이?

> RUM은 실제 사용자 브라우저에서 수집하여 다양한 환경의 체감을 반영. Synthetic은 통제된 환경에서 일관된 비교 기준 제공. 실무에서는 Synthetic으로 CI 게이트, RUM으로 실제 영향도를 판단한다.

### Q2. SLI/SLO를 프론트엔드에 어떻게 적용?

> SLI로 "LCP < 2.5s 비율"을 정의하고, SLO로 "28일간 99.5% 이상"을 설정. web-vitals로 수집 → 대시보드 시각화 → SLO 위반 시 알림. "얼마나 빨라야 하는가"를 데이터로 관리.

### Q3. Error Budget이란?

> SLO를 만족하면서 허용되는 실패 여유. 99.5% SLO + 100만 PV → 5000건까지 허용. Budget 남으면 적극 배포, 소진되면 안정화 집중. 속도와 안정성 갈등을 객관적으로 해결.

### Q4. 프론트엔드 장애 감지 & 대응?

> Sentry로 에러 급증 감지, Grafana로 CWV 회귀 모니터링. P1은 PagerDuty, P2는 Slack. Runbook 기반 대응 → 배포 기인이면 즉시 롤백. 사후 blameless 포스트몰템.

### Q5. CWV 성능 회귀 방지?

> 3단계: (1) CI에서 Lighthouse CI 게이트, (2) 배포 직후 Synthetic 검증, (3) RUM에서 p75 변화 모니터링 + 30% 악화 시 알림. 번들 크기도 Performance Budget으로 감시.

---

## 참고 자료

- [web-vitals](https://github.com/GoogleChrome/web-vitals) — Google 공식 CWV 수집
- [Google SRE Book](https://sre.google/sre-book/table-of-contents/) — SRE 바이블 (무료)
- [The Art of SLOs](https://sre.google/resources/practices-and-processes/art-of-slos/) — SLO 설정 워크숍
- [Sentry Performance Docs](https://docs.sentry.io/product/performance/) — 프론트엔드 성능 추적
- [Grafana Best Practices](https://grafana.com/docs/grafana/latest/best-practices/) — 대시보드 설계
- [Web Almanac - Performance](https://almanac.httparchive.org/en/2022/performance) — 웹 성능 현황
