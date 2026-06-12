# 9. CI/CD (지속적 통합 / 지속적 배포)

## 목차
1. CI/CD 개요
2. CI vs CD vs CD (통합 vs 전달 vs 배포)
3. CI/CD 파이프라인 구성
4. GitHub Actions 실전
5. GitLab CI/CD
6. Docker 기반 컨테이너 배포
7. 배포 전략 (Blue-Green, Canary)
8. 롤백 전략
9. 프론트엔드 CI/CD
10. 면접 포인트

---

## 1. CI/CD 개요

```
전통적 배포의 문제:
  "2주에 한 번 배포" → 변경사항 누적 → 버그 원인 특정 어려움
  "수동 배포" → 사람 실수 → 배포 공포(deploy fear)

CI/CD의 목표:
  - 코드 변경을 안전하게 자동으로 프로덕션까지 전달
  - 빠른 피드백으로 문제를 조기에 발견
  - 배포를 두렵지 않은 일상적 행위로 만들기
```

### 핵심 지표 (DORA Metrics)

```
구글의 DevOps Research and Assessment 4가지 지표:

1. Deployment Frequency (배포 빈도)
   엘리트: 하루 여러 번 | 낮음: 월 1회 이하

2. Lead Time for Changes (변경 리드 타임)
   엘리트: 1시간 미만 | 낮음: 6개월 이상

3. Change Failure Rate (변경 실패율)
   엘리트: 0~15% | 낮음: 46~60%

4. Time to Restore Service (복구 시간)
   엘리트: 1시간 미만 | 낮음: 1주 이상
```

---

## 2. CI vs CD vs CD

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  CI (Continuous Integration, 지속적 통합)                       │
│  코드 변경 시 자동으로 빌드 + 테스트 실행                       │
│  목표: 통합 문제 조기 발견                                      │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  CD (Continuous Delivery, 지속적 전달)                          │
│  CI 이후 스테이징 환경까지 자동 배포                            │
│  프로덕션 배포는 수동 승인 (버튼 클릭)                          │
│  목표: 언제든 배포 가능한 상태 유지                             │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  CD (Continuous Deployment, 지속적 배포)                        │
│  CI 이후 프로덕션까지 완전 자동화                               │
│  사람의 개입 없음                                               │
│  목표: 빠른 고객 가치 전달                                      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

코드 커밋
    ↓
[빌드] → [테스트] → [코드 분석]  ← CI 영역
    ↓
[스테이징 배포] → [통합 테스트]   ← Continuous Delivery
    ↓
[수동 승인?] → [프로덕션 배포]   ← Delivery(승인) or Deployment(자동)
```

---

## 3. CI/CD 파이프라인 구성

### 표준 파이프라인 단계

```
커밋
 │
 ▼
빌드 (Build)
  - 소스 코드 컴파일/번들링
  - 의존성 설치
  - 도커 이미지 빌드
 │
 ▼
단위 테스트 (Unit Test)
  - Jest, Vitest 등
  - 빠른 피드백 (수 분 내)
 │
 ▼
정적 분석 (Static Analysis)
  - ESLint, TypeScript 타입 체크
  - 보안 취약점 스캔 (npm audit)
  - 코드 커버리지 측정
 │
 ▼
통합/E2E 테스트 (Integration/E2E Test)
  - Playwright, Cypress
  - API 통합 테스트
 │
 ▼
스테이징 배포 (Staging Deploy)
  - 프로덕션과 동일한 환경
  - QA 검증
 │
 ▼
프로덕션 배포 (Production Deploy)
  - 수동 승인 (CD) 또는 자동 (CD)
  - 배포 후 헬스체크
```

---

## 4. GitHub Actions 실전

### PR 체크 워크플로우

```yaml
# .github/workflows/pr-check.yml
name: PR Check

on:
  pull_request:
    branches: [main, develop]

jobs:
  lint-and-type-check:
    name: Lint & Type Check
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: TypeScript type check
        run: npm run type-check

      - name: ESLint
        run: npm run lint

  test:
    name: Unit Tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run tests with coverage
        run: npm run test:coverage

      - name: Upload coverage report
        uses: codecov/codecov-action@v4
        with:
          token: ${{ secrets.CODECOV_TOKEN }}

  build:
    name: Build Check
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Build
        run: npm run build
        env:
          NEXT_PUBLIC_API_URL: ${{ secrets.STAGING_API_URL }}
```

### 자동 배포 워크플로우

```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  push:
    branches: [main]

concurrency:
  group: production-deploy
  cancel-in-progress: false  # 배포 중복 방지

jobs:
  deploy:
    name: Deploy
    runs-on: ubuntu-latest
    environment: production  # GitHub Environment 승인 연동

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run tests
        run: npm test

      - name: Build
        run: npm run build
        env:
          NEXT_PUBLIC_API_URL: ${{ secrets.PROD_API_URL }}

      - name: Deploy to server
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.PROD_HOST }}
          username: ${{ secrets.PROD_USER }}
          key: ${{ secrets.PROD_SSH_KEY }}
          script: |
            cd /app
            git pull origin main
            npm ci --production
            npm run build
            pm2 reload app

      - name: Notify Slack on success
        if: success()
        uses: slackapi/slack-github-action@v1
        with:
          payload: |
            {
              "text": "✅ 배포 성공: ${{ github.sha }} by ${{ github.actor }}"
            }
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}

      - name: Notify Slack on failure
        if: failure()
        uses: slackapi/slack-github-action@v1
        with:
          payload: |
            {
              "text": "❌ 배포 실패: ${{ github.sha }} 확인 필요"
            }
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
```

---

## 5. GitLab CI/CD

```yaml
# .gitlab-ci.yml
stages:
  - install
  - test
  - build
  - deploy

variables:
  NODE_VERSION: "20"
  CACHE_KEY: "$CI_COMMIT_REF_SLUG"

# 공통 템플릿
.node-setup: &node-setup
  image: node:${NODE_VERSION}-alpine
  cache:
    key: ${CACHE_KEY}
    paths:
      - node_modules/
  before_script:
    - npm ci

install:
  <<: *node-setup
  stage: install
  script:
    - echo "Dependencies installed"

lint:
  <<: *node-setup
  stage: test
  script:
    - npm run lint
    - npm run type-check

test:
  <<: *node-setup
  stage: test
  script:
    - npm run test:coverage
  coverage: '/Lines\s*:\s*(\d+\.?\d*)%/'
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage/cobertura-coverage.xml

build:
  <<: *node-setup
  stage: build
  script:
    - npm run build
  artifacts:
    paths:
      - dist/
    expire_in: 1 hour

deploy-staging:
  stage: deploy
  script:
    - echo "Deploy to staging"
  environment:
    name: staging
    url: https://staging.example.com
  only:
    - develop

deploy-production:
  stage: deploy
  script:
    - echo "Deploy to production"
  environment:
    name: production
    url: https://example.com
  when: manual  # 수동 승인
  only:
    - main
```

---

## 6. Docker 기반 컨테이너 배포

### 멀티 스테이지 빌드 (프론트엔드)

```dockerfile
# Dockerfile
# Stage 1: 빌드
FROM node:20-alpine AS builder
WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

# Stage 2: 프로덕션 이미지 (경량화)
FROM nginx:alpine AS production

# nginx 설정
COPY nginx.conf /etc/nginx/conf.d/default.conf
# 빌드 결과만 복사
COPY --from=builder /app/dist /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

```nginx
# nginx.conf (SPA 설정)
server {
    listen 80;
    root /usr/share/nginx/html;
    index index.html;

    # SPA 라우팅: 모든 경로를 index.html로
    location / {
        try_files $uri $uri/ /index.html;
    }

    # 정적 자산 캐싱
    location ~* \.(js|css|png|jpg|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

### Docker Compose로 로컬 환경 통일

```yaml
# docker-compose.yml
version: '3.8'

services:
  frontend:
    build:
      context: ./frontend
      target: builder  # 개발 스테이지
    ports:
      - "3000:3000"
    volumes:
      - ./frontend:/app
      - /app/node_modules  # node_modules 바인드 제외
    environment:
      - VITE_API_URL=http://backend:4000
    command: npm run dev

  backend:
    build: ./backend
    ports:
      - "4000:4000"
    environment:
      - DATABASE_URL=postgresql://postgres:password@db:5432/mydb
    depends_on:
      - db

  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_PASSWORD: password
      POSTGRES_DB: mydb
    volumes:
      - pgdata:/var/lib/postgresql/data

volumes:
  pgdata:
```

---

## 7. 배포 전략

### Blue-Green 배포

```
Blue 환경 (현재 프로덕션):
  [Load Balancer] → [Blue: v1.0] (100% 트래픽)
  [Green: v1.1]   (대기 중)

배포 과정:
  1. Green 환경에 새 버전 배포
  2. Green 환경 테스트 및 검증
  3. 로드 밸런서 트래픽을 Green으로 전환 (순간 전환)
  4. Blue 환경 대기 (롤백용)
  5. 안정 확인 후 Blue 환경 종료

장점: 다운타임 없음, 즉각적 롤백 가능
단점: 인프라 비용 2배, DB 스키마 변경 복잡
```

### Canary 배포

```
점진적 트래픽 이동:

초기:   [LB] → 95% v1.0 / 5% v2.0 (카나리아)
1시간:  [LB] → 80% v1.0 / 20% v2.0 (지표 모니터링)
4시간:  [LB] → 50% v1.0 / 50% v2.0 (안정 확인)
완료:   [LB] → 0% v1.0 / 100% v2.0

장점: 위험 최소화, 실제 트래픽으로 검증
단점: 두 버전이 동시 운영되어 API 호환성 필요
```

```yaml
# GitHub Actions Canary 배포 예시
- name: Canary Deploy (5%)
  run: |
    kubectl set image deployment/app app=myapp:${{ github.sha }}
    kubectl scale deployment/app-canary --replicas=1
    kubectl scale deployment/app-stable --replicas=19

- name: Monitor error rate
  run: |
    # 30분간 에러율 모니터링
    ERROR_RATE=$(curl -s "$METRICS_URL/error_rate")
    if (( $(echo "$ERROR_RATE > 1" | bc -l) )); then
      echo "Error rate too high, rolling back"
      kubectl rollout undo deployment/app-canary
      exit 1
    fi
```

---

## 8. 롤백 전략

### Git 기반 롤백

```bash
# 방법 1: 이전 태그로 재배포
git tag v1.0.0  # 배포 전 태그
git checkout v1.0.0
# CI/CD 파이프라인 재실행

# 방법 2: Revert 커밋
git revert HEAD  # 새 커밋으로 변경 취소 (히스토리 보존)
git push origin main  # CI/CD 자동 재배포

# 방법 3: 긴급 reset (주의: 히스토리 파괴)
# 비추천 - 위의 방법 우선 사용
```

### 쿠버네티스 롤백

```bash
# 롤아웃 히스토리 확인
kubectl rollout history deployment/my-app

# 이전 버전으로 즉시 롤백
kubectl rollout undo deployment/my-app

# 특정 리비전으로 롤백
kubectl rollout undo deployment/my-app --to-revision=3

# 롤백 상태 확인
kubectl rollout status deployment/my-app
```

### 롤백 자동화

```typescript
// 헬스체크 기반 자동 롤백 로직
async function deployWithAutoRollback(version: string) {
  const previousVersion = await getCurrentVersion();

  try {
    await deploy(version);

    // 5분간 에러율 모니터링
    const isHealthy = await monitorHealth({
      duration: 5 * 60 * 1000,
      maxErrorRate: 0.01,  // 1% 초과 시 롤백
    });

    if (!isHealthy) {
      throw new Error('Health check failed');
    }

    console.log(`✅ Deploy ${version} successful`);
  } catch (error) {
    console.log(`❌ Deploy failed, rolling back to ${previousVersion}`);
    await deploy(previousVersion);
    await notifySlack(`Rollback to ${previousVersion} completed`);
    throw error;
  }
}
```

---

## 9. 프론트엔드 CI/CD

### Vercel 자동 배포

```json
// vercel.json
{
  "buildCommand": "npm run build",
  "outputDirectory": "dist",
  "framework": "vite",
  "routes": [
    {
      "src": "/api/(.*)",
      "dest": "https://api.example.com/$1"
    },
    {
      "src": "/(.*)",
      "dest": "/index.html"
    }
  ],
  "env": {
    "VITE_API_URL": "@api-url"
  }
}
```

```
Vercel 자동 배포 흐름:
  PR 생성 → Preview URL 자동 생성 (PR별 독립 환경)
  main 머지 → Production 자동 배포

Preview 배포의 장점:
  - 리뷰어가 코드 없이 결과물 확인 가능
  - PR마다 독립 URL로 QA 가능
  - 스테이징 환경 별도 관리 불필요
```

### Netlify CI/CD

```toml
# netlify.toml
[build]
  command = "npm run build"
  publish = "dist"

[build.environment]
  NODE_VERSION = "20"

# PR Preview 설정
[context.deploy-preview]
  command = "npm run build:preview"

# 브랜치별 배포 설정
[context.staging]
  command = "npm run build:staging"

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
```

### 프론트엔드 특화 CI 체크

```yaml
# .github/workflows/frontend-ci.yml
name: Frontend CI

on: [pull_request]

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - run: npm ci

      # 번들 크기 체크
      - name: Bundle size check
        uses: andresz1/size-limit-action@v1
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}

      # Lighthouse CI
      - name: Lighthouse CI
        uses: treosh/lighthouse-ci-action@v11
        with:
          urls: |
            http://localhost:3000
          budgetPath: ./lighthouse-budget.json
          uploadArtifacts: true

      # E2E 테스트
      - name: Playwright E2E
        run: npx playwright test
        env:
          BASE_URL: ${{ env.PREVIEW_URL }}
```

---

## 10. 면접 포인트

**Q. CI와 CD의 차이를 설명해주세요.**

CI(지속적 통합)는 코드 변경 시 자동으로 빌드와 테스트를 실행해 통합 문제를 조기에 발견하는 것입니다. CD는 두 가지 의미가 있는데, 지속적 전달(Continuous Delivery)은 스테이징까지 자동 배포하되 프로덕션은 수동 승인하는 것이고, 지속적 배포(Continuous Deployment)는 테스트를 통과하면 프로덕션까지 완전 자동화하는 것입니다.

**Q. Blue-Green 배포와 Canary 배포의 차이는?**

Blue-Green은 두 환경을 동시에 운영하다 트래픽을 한 번에 전환하는 방식으로, 다운타임 없이 즉각적 롤백이 가능하지만 인프라 비용이 2배입니다. Canary는 일부 트래픽(예: 5%)만 새 버전으로 보내 위험을 최소화하며 점진적으로 확대하는 방식입니다. 실제 트래픽으로 검증할 수 있지만 두 버전이 동시에 운영되므로 API 하위 호환성이 필요합니다.

**Q. 프론트엔드 개발에서 CI/CD를 어떻게 활용하나요?**

PR 생성 시 TypeScript 타입 체크, ESLint, 단위 테스트, 빌드 성공 여부를 자동으로 검증합니다. Vercel이나 Netlify를 이용하면 PR마다 Preview URL이 자동 생성돼 QA나 리뷰어가 코드 없이 결과물을 확인할 수 있습니다. main 브랜치 머지 시 자동으로 프로덕션 배포가 이루어지고, bundle size 측정이나 Lighthouse CI를 파이프라인에 포함시켜 성능 회귀를 방지합니다.

**Q. 배포 파이프라인에서 테스트 단계를 어떻게 구성하시나요?**

속도와 신뢰성의 균형을 맞추는 것이 핵심입니다. 단위 테스트는 가장 빠르게 실행해 즉각적 피드백을 제공하고, 통합 테스트는 그 다음에 배치합니다. E2E 테스트는 느리므로 핵심 사용자 흐름(결제, 로그인 등)만 선별해 스테이징 배포 후 실행합니다. 테스트가 너무 많아 파이프라인이 느려지면 PR 체크와 배포 체크를 분리하는 것도 방법입니다.
