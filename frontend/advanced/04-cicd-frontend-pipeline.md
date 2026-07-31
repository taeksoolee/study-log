# CI/CD & 프론트엔드 배포 파이프라인

## 개요

현대 프론트엔드 개발에서 CI/CD는 선택이 아닌 필수다. 빌드 결과물이 정적 파일이라 "FTP로 올리면 끝"이던 시대는 지났다. TypeScript 타입 체크, 린트, 테스트, 번들 최적화, 다양한 환경 배포까지—수동으로 관리하면 반드시 실수가 발생한다.

### CI/CD가 프론트엔드에 필수인 이유

| 문제 | CI/CD 없이 | CI/CD 있으면 |
|------|-----------|-------------|
| 타입 에러 | 배포 후 런타임에서 발견 | PR 단계에서 차단 |
| 번들 크기 증가 | 누구도 모르게 2MB → 5MB | size-limit이 PR에 경고 |
| 스타일 깨짐 | QA가 수동으로 발견 | Visual Regression이 스크린샷 비교 |
| 배포 실수 | 잘못된 환경변수로 장애 | 환경별 자동 주입 + 승인 게이트 |
| 롤백 | "어제 빌드 파일 어딨지?" | 버튼 하나로 즉시 복귀 |

### 빠른 피드백 루프의 가치

```
코드 작성 → 커밋 → 5분 이내 결과 확인 → 수정
```

- 피드백이 빠를수록 버그 수정 비용이 낮다
- PR에서 문제를 잡으면 코드 리뷰 품질도 올라간다
- Preview Deploy로 디자이너/PM이 직접 확인 가능 → 커뮤니케이션 비용 절감

---

## CI (Continuous Integration)

### 파이프라인 설계

```
PR 생성 → lint → type-check → unit test → build → bundle size check → preview deploy
```

각 단계는 이전 단계가 실패하면 중단(fail-fast)하되, 독립적인 체크는 병렬로 실행해 전체 시간을 줄인다.

```
┌─────────────────────────────────────────────┐
│  PR 생성 (트리거)                            │
├─────────┬─────────────┬─────────────────────┤
│  lint   │ type-check  │  unit test          │  ← 병렬
├─────────┴─────────────┴─────────────────────┤
│  build                                       │  ← 위 3개 모두 통과 후
├─────────────────────────────────────────────┤
│  bundle size check + Lighthouse CI           │
├─────────────────────────────────────────────┤
│  preview deploy + PR 코멘트                  │
└─────────────────────────────────────────────┘
```

### GitHub Actions 실전 구성

#### 트리거 설정

```yaml
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]
    paths:
      - 'apps/web/**'
      - 'packages/ui/**'
      - 'package.json'
      - 'pnpm-lock.yaml'
```

`paths` 필터로 프론트엔드 코드가 변경된 경우에만 CI를 실행한다. 백엔드만 수정했는데 프론트엔드 CI가 돌아갈 필요 없다.

#### 캐시 전략

```yaml
- name: Setup pnpm
  uses: pnpm/action-setup@v4
  with:
    version: 9

- name: Setup Node.js
  uses: actions/setup-node@v4
  with:
    node-version: 20
    cache: 'pnpm'

- name: Turbo Cache
  uses: actions/cache@v4
  with:
    path: .turbo
    key: turbo-${{ runner.os }}-${{ hashFiles('**/pnpm-lock.yaml') }}-${{ github.sha }}
    restore-keys: |
      turbo-${{ runner.os }}-${{ hashFiles('**/pnpm-lock.yaml') }}-
      turbo-${{ runner.os }}-
```

캐시 효과:
- `pnpm store`: 의존성 재설치 시간 70% 단축
- `.turbo`: 변경되지 않은 패키지 빌드 스킵
- `.next/cache`: Next.js 증분 빌드 활용

#### 병렬 실행 (Matrix Strategy)

```yaml
jobs:
  quality:
    strategy:
      fail-fast: false
      matrix:
        check: [lint, typecheck, test]
    steps:
      - run: pnpm turbo run ${{ matrix.check }}
```

`fail-fast: false`로 설정하면 하나가 실패해도 나머지 결과를 볼 수 있다.

### 핵심 체크 항목

#### 1. ESLint + Prettier (코드 품질)

```json
// package.json scripts
{
  "lint": "eslint . --max-warnings 0",
  "format:check": "prettier --check ."
}
```

- `--max-warnings 0`: warning도 CI에서 실패 처리
- Prettier는 `--check` 모드로 포맷 확인만 (수정은 로컬에서)
- eslint-config-next, @typescript-eslint 조합 권장

#### 2. TypeScript strict 타입 체크

```json
// tsconfig.json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true
  }
}
```

```bash
tsc --noEmit --pretty
```

빌드 없이 타입만 체크하므로 빠르다 (보통 10~30초).

#### 3. Unit/Integration Test (Vitest)

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    environment: 'jsdom',
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json-summary'],
      thresholds: {
        statements: 80,
        branches: 75,
        functions: 80,
        lines: 80,
      },
    },
  },
});
```

- 커버리지 임계값 설정으로 품질 하한선 유지
- `json-summary` 리포터로 PR 코멘트에 커버리지 표시 가능

#### 4. 번들 사이즈 모니터링

```json
// package.json
{
  "size-limit": [
    {
      "path": ".next/static/**/*.js",
      "limit": "250 kB",
      "gzip": true
    },
    {
      "path": ".next/static/chunks/pages/index-*.js",
      "limit": "80 kB"
    }
  ]
}
```

```yaml
# CI에서 size-limit 실행
- name: Check bundle size
  uses: andresz1/size-limit-action@v1
  with:
    github_token: ${{ secrets.GITHUB_TOKEN }}
```

PR에 자동으로 번들 크기 변화를 코멘트로 남겨준다:

```
📦 Size Changes
  .next/static/**/*.js: 245 kB (+3.2 kB, +1.3%)
```

#### 5. Lighthouse CI (성능 점수 회귀 방지)

```yaml
- name: Lighthouse CI
  uses: treosh/lighthouse-ci-action@v11
  with:
    configPath: ./lighthouserc.json
    urls: |
      ${{ steps.deploy.outputs.preview_url }}
    budgetPath: ./budget.json
```

```json
// lighthouserc.json
{
  "ci": {
    "assert": {
      "assertions": {
        "categories:performance": ["error", { "minScore": 0.9 }],
        "categories:accessibility": ["error", { "minScore": 0.95 }],
        "first-contentful-paint": ["warn", { "maxNumericValue": 1800 }],
        "largest-contentful-paint": ["error", { "maxNumericValue": 2500 }]
      }
    }
  }
}
```

#### 6. Visual Regression (Chromatic)

```yaml
- name: Visual Regression
  uses: chromaui/action@latest
  with:
    projectToken: ${{ secrets.CHROMATIC_PROJECT_TOKEN }}
    exitZeroOnChanges: true  # 변경 감지 시 실패하지 않고 리뷰 요청
```

- Storybook 기반으로 컴포넌트 스크린샷 비교
- 의도된 변경은 승인, 의도치 않은 변경은 차단
- Percy도 유사한 기능 제공 (Storybook 없이도 가능)

---

## CD (Continuous Deployment)

### 배포 전략

#### Preview Deploy: PR별 독립 환경

```
feature/login → https://login-branch-abc123.vercel.app
feature/cart  → https://cart-branch-def456.vercel.app
```

- **Vercel**: Git 연동만 하면 PR마다 자동 Preview URL 생성
- **Cloudflare Pages**: 동일 기능 + Edge에서 동작
- **Netlify**: Deploy Preview 기능

장점:
- 코드 리뷰 시 실제 동작 확인 가능
- 디자이너/PM이 별도 환경 구축 없이 검증
- PR 닫히면 자동 삭제 → 리소스 낭비 없음

#### Staging 환경

```yaml
# main 브랜치 머지 시 자동 배포
on:
  push:
    branches: [main]

jobs:
  deploy-staging:
    runs-on: ubuntu-latest
    environment: staging  # GitHub Environment로 보호
    steps:
      - run: pnpm build
        env:
          NEXT_PUBLIC_API_URL: ${{ vars.STAGING_API_URL }}
      - run: vercel deploy --prod --scope=my-team --token=${{ secrets.VERCEL_TOKEN }}
```

#### Production 배포

```yaml
# 태그 생성 시 + 수동 승인 후 배포
on:
  push:
    tags: ['v*']

jobs:
  deploy-production:
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://myapp.com
    steps:
      - run: pnpm build
      - run: vercel deploy --prod --token=${{ secrets.VERCEL_TOKEN }}
```

GitHub Environment의 `required_reviewers` 설정으로 수동 승인 게이트를 추가한다.

### 캐나리 배포

전체 사용자에게 한 번에 배포하는 것은 위험하다. 캐나리 배포는 일부 트래픽에만 새 버전을 노출해 안전성을 검증한다.

```
[사용자 100%] ──┬── 95% ──→ v1.2.0 (현재 안정 버전)
                └──  5% ──→ v1.3.0 (새 버전)
```

#### Cloudflare Workers로 캐나리 구현

```typescript
// worker.ts - 엣지에서 트래픽 분배
export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const canaryPercentage = parseInt(env.CANARY_PERCENTAGE || '5');
    const isCanary = Math.random() * 100 < canaryPercentage;

    // 쿠키로 세션 고정 (같은 사용자는 같은 버전 유지)
    const cookie = request.headers.get('cookie');
    const versionCookie = parseCookie(cookie, 'app-version');

    const targetVersion = versionCookie || (isCanary ? 'canary' : 'stable');
    const origin = targetVersion === 'canary' ? env.CANARY_ORIGIN : env.STABLE_ORIGIN;

    const response = await fetch(origin + new URL(request.url).pathname, request);
    const newResponse = new Response(response.body, response);

    if (!versionCookie) {
      newResponse.headers.set('Set-Cookie', `app-version=${targetVersion}; Path=/; Max-Age=3600`);
    }

    return newResponse;
  },
};
```

모니터링 기준:
- 에러율이 기존 대비 2배 이상 → 자동 롤백
- Core Web Vitals(LCP, CLS, INP) 악화 → 경고
- 이상 없으면 10% → 25% → 50% → 100% 점진 확대

### Feature Flag

코드 배포와 기능 릴리스를 분리하는 핵심 전략이다.

```typescript
// Feature Flag 사용 예시
import { useFeatureFlag } from '@/lib/feature-flags';

function CheckoutPage() {
  const showNewPayment = useFeatureFlag('new-payment-flow');

  return (
    <div>
      {showNewPayment ? <NewPaymentFlow /> : <LegacyPaymentFlow />}
    </div>
  );
}
```

#### 자체 구현 (간단한 경우)

```typescript
// lib/feature-flags.ts
type FeatureFlags = {
  'new-payment-flow': boolean;
  'dark-mode': boolean;
  'ai-search': boolean;
};

const FLAGS: Record<string, Partial<FeatureFlags>> = {
  production: { 'new-payment-flow': false, 'dark-mode': true },
  staging: { 'new-payment-flow': true, 'dark-mode': true, 'ai-search': true },
};

export function getFlag(key: keyof FeatureFlags): boolean {
  const env = process.env.NEXT_PUBLIC_ENV || 'production';
  return FLAGS[env]?.[key] ?? false;
}
```

#### 서비스 비교

| 서비스 | 장점 | 단점 |
|--------|------|------|
| LaunchDarkly | 풍부한 타겟팅, SDK 성숙 | 비용 높음 |
| Unleash | 오픈소스, 셀프호스팅 가능 | 셋업 필요 |
| Flagsmith | 무료 티어, 원격 설정 | 규모 확장 시 성능 |
| 자체 구현 | 완전한 제어 | 유지보수 부담 |

활용 패턴:
- **점진적 롤아웃**: 내부 → 베타 → 5% → 50% → 100%
- **A/B 테스트**: 두 버전 비교 후 데이터 기반 결정
- **킬 스위치**: 장애 시 즉시 기능 비활성화

### 롤백 전략

#### Immutable Deploy

```
v1.2.0 빌드 → /deployments/abc123/ (유지)
v1.3.0 빌드 → /deployments/def456/ (유지)
v1.3.1 빌드 → /deployments/ghi789/ (현재 활성)

롤백: 활성 포인터를 abc123으로 변경 → 즉시 복귀
```

- 이전 빌드 아티팩트가 그대로 보존되어 있으므로 재빌드 불필요
- Vercel: 대시보드에서 "Instant Rollback" 클릭 한 번
- S3 + CloudFront: 이전 버전 디렉토리로 origin 변경

#### CDN 캐시 무효화

```bash
# CloudFront 무효화
aws cloudfront create-invalidation \
  --distribution-id E1234567890 \
  --paths "/*"

# Vercel은 배포 시 자동으로 엣지 캐시 갱신
```

롤백 시 CDN 캐시에 새 버전이 남아있으면 안 되므로, 무효화는 필수다.

---

## 실전 코드: GitHub Actions 워크플로

```yaml
# .github/workflows/ci.yml
name: Frontend CI/CD

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
    paths:
      - 'apps/web/**'
      - 'packages/**'
      - 'pnpm-lock.yaml'

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

env:
  TURBO_TOKEN: ${{ secrets.TURBO_TOKEN }}
  TURBO_TEAM: ${{ vars.TURBO_TEAM }}

jobs:
  install:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
        with:
          version: 9
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'pnpm'
      - run: pnpm install --frozen-lockfile
      - uses: actions/cache/save@v4
        with:
          path: |
            node_modules
            apps/*/node_modules
            packages/*/node_modules
          key: modules-${{ hashFiles('pnpm-lock.yaml') }}

  quality:
    needs: install
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        check: [lint, typecheck, test]
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
        with:
          version: 9
      - uses: actions/setup-node@v4
        with:
          node-version: 20
      - uses: actions/cache/restore@v4
        with:
          path: |
            node_modules
            apps/*/node_modules
            packages/*/node_modules
          key: modules-${{ hashFiles('pnpm-lock.yaml') }}
      - name: Turbo Cache
        uses: actions/cache@v4
        with:
          path: .turbo
          key: turbo-${{ matrix.check }}-${{ github.sha }}
          restore-keys: turbo-${{ matrix.check }}-
      - run: pnpm turbo run ${{ matrix.check }}

  build:
    needs: quality
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
        with:
          version: 9
      - uses: actions/setup-node@v4
        with:
          node-version: 20
      - uses: actions/cache/restore@v4
        with:
          path: |
            node_modules
            apps/*/node_modules
            packages/*/node_modules
          key: modules-${{ hashFiles('pnpm-lock.yaml') }}
      - run: pnpm turbo run build
      - name: Check bundle size
        run: pnpm size-limit
      - name: Upload build artifacts
        uses: actions/upload-artifact@v4
        with:
          name: build-output
          path: apps/web/.next

  size-report:
    needs: build
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: andresz1/size-limit-action@v1
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          build_script: turbo run build
          skip_step: install

  preview:
    needs: build
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Deploy Preview
        id: deploy
        uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
      - name: Comment Preview URL
        uses: actions/github-script@v7
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `🚀 **Preview 배포 완료**\n\n${process.env.PREVIEW_URL}\n\n빌드 시간: ${process.env.BUILD_TIME}`
            })
        env:
          PREVIEW_URL: ${{ steps.deploy.outputs.preview-url }}
```

---

## 모노레포에서의 CI/CD

### Turborepo: affected packages만 빌드

```json
// turbo.json
{
  "$schema": "https://turbo.build/schema.json",
  "pipeline": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": [".next/**", "dist/**"]
    },
    "lint": { "dependsOn": [] },
    "typecheck": { "dependsOn": ["^build"] },
    "test": { "dependsOn": ["^build"] }
  }
}
```

핵심 원리:
- 의존 그래프를 분석해 변경된 패키지와 영향받는 패키지만 빌드
- Remote Cache(Vercel)로 다른 개발자/CI가 이미 빌드한 결과 재사용
- `turbo run build --filter=...@HEAD~1` : 최근 커밋에서 변경된 것만

```bash
# 변경된 패키지만 빌드
pnpm turbo run build --filter='...[origin/main]'

# 특정 앱과 그 의존성만
pnpm turbo run build --filter=web...
```

### Changesets: 버전 관리 & Changelog 자동화

```bash
# 변경사항 기록
pnpm changeset

# 버전 범프 + changelog 생성
pnpm changeset version

# npm publish
pnpm changeset publish
```

```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    branches: [main]

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: changesets/action@v1
        with:
          publish: pnpm changeset publish
          version: pnpm changeset version
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

### 패키지별 독립 배포

```
monorepo/
├── apps/
│   ├── web/          → Vercel (자동 배포)
│   ├── admin/        → Cloudflare Pages
│   └── docs/         → GitHub Pages
├── packages/
│   ├── ui/           → npm publish
│   ├── utils/        → npm publish
│   └── config/       → 내부 전용 (배포 안 함)
```

각 앱은 독립적인 배포 타겟을 가진다. Turborepo가 의존성을 추적하므로, `packages/ui` 변경 시 이를 사용하는 `apps/web`과 `apps/admin`만 재빌드된다.

---

## 환경 변수 관리

### 환경별 파일 구조

```
.env                    # 기본값 (Git에 커밋 가능, 비밀 X)
.env.local              # 로컬 오버라이드 (Git 무시)
.env.development        # 개발 환경
.env.production         # 프로덕션 환경 (빌드 시 참조)
.env.staging            # 스테이징 환경
```

### 빌드 시점 vs 런타임 환경변수

```typescript
// Next.js 기준
// NEXT_PUBLIC_ 접두사 → 빌드 시 번들에 인라인 (클라이언트 노출)
const apiUrl = process.env.NEXT_PUBLIC_API_URL;  // 빌드 시 치환됨

// 접두사 없음 → 서버에서만 접근 가능 (비밀 보호)
const dbUrl = process.env.DATABASE_URL;  // 클라이언트 번들에 포함 안 됨
```

**주의**: `NEXT_PUBLIC_` 변수는 빌드 시점에 결정되므로, 같은 빌드를 여러 환경에 배포할 수 없다. 환경별로 별도 빌드가 필요하다.

런타임 환경변수가 필요한 경우:

```typescript
// app/api/config/route.ts (서버에서 제공)
export function GET() {
  return Response.json({
    apiUrl: process.env.API_URL,
    featureFlags: process.env.FEATURE_FLAGS,
  });
}
```

### GitHub Actions에서 주입

```yaml
jobs:
  build:
    environment: production  # GitHub Environment 선택
    env:
      NEXT_PUBLIC_API_URL: ${{ vars.API_URL }}          # 비밀 아닌 값
      NEXT_PUBLIC_GA_ID: ${{ vars.GA_ID }}
      SENTRY_AUTH_TOKEN: ${{ secrets.SENTRY_TOKEN }}    # 비밀 값
    steps:
      - run: pnpm build
```

- `vars.*`: 환경 변수 (로그에 노출 가능)
- `secrets.*`: 암호화 저장, 로그에 마스킹됨

### Vault / SSM 연동 (대규모 프로젝트)

```yaml
- name: Get secrets from AWS SSM
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::123456789:role/github-actions
    aws-region: ap-northeast-2

- name: Fetch parameters
  run: |
    export DB_URL=$(aws ssm get-parameter --name /prod/db-url --with-decryption --query Parameter.Value --output text)
    export API_KEY=$(aws ssm get-parameter --name /prod/api-key --with-decryption --query Parameter.Value --output text)
```

장점:
- 시크릿 로테이션 자동화
- 감사 로그(누가 언제 접근했는지)
- 여러 서비스에서 동일한 시크릿 공유

---

## 면접 포인트

### Q: CI/CD 파이프라인을 어떻게 구성했는가?

> "PR 단계에서 lint, type-check, test를 병렬로 실행하고, 빌드 후 번들 사이즈 체크와 Preview Deploy를 수행합니다. main 머지 시 staging 자동 배포, 태그 시 production 배포(수동 승인)로 3단계 환경을 운영합니다. Turborepo 캐시로 CI 시간을 8분에서 3분으로 줄였습니다."

### Q: Preview Deploy의 장점은?

> "PR마다 독립 URL이 생성되어 코드 리뷰 시 실제 동작을 확인할 수 있습니다. 디자이너/PM이 직접 검증하므로 커뮤니케이션 비용이 줄고, Lighthouse CI를 연결해 성능 회귀도 PR 단계에서 잡습니다."

### Q: 번들 사이즈 회귀를 어떻게 방지하는가?

> "size-limit으로 총 번들과 주요 청크별 임계값을 설정하고, PR마다 변화량을 코멘트로 남깁니다. 임계값 초과 시 CI가 실패하므로, 대형 라이브러리 추가 시 반드시 리뷰어가 인지하게 됩니다. 추가로 webpack-bundle-analyzer로 주기적으로 청크 구성을 시각화합니다."

### Q: Feature Flag를 사용한 경험이 있는가?

> "대규모 리팩터링 시 feature flag로 새 코드를 감싸고, 내부 사용자 → 베타 → 전체 순으로 롤아웃했습니다. 문제 발생 시 코드 롤백 없이 플래그만 끄면 되므로 장애 대응이 빠릅니다. 배포와 릴리스를 분리해 '금요일에도 배포 가능한' 문화를 만들었습니다."

### Q: 롤백은 어떻게 처리하는가?

> "Immutable Deploy로 이전 빌드 아티팩트를 보존합니다. Vercel은 instant rollback으로 30초 내 복귀가 가능하고, 자체 인프라에서는 S3에 버전별 디렉토리를 유지해 CloudFront origin만 변경합니다. CDN 캐시 무효화도 자동화되어 있습니다."

### Q: 모노레포에서 CI를 어떻게 최적화하는가?

> "Turborepo의 의존성 그래프 분석으로 변경된 패키지와 영향받는 패키지만 빌드합니다. Remote Cache로 동일 입력의 빌드를 스킵하고, GitHub Actions의 path filter로 관련 없는 변경에는 CI 자체를 실행하지 않습니다. 결과적으로 평균 CI 시간을 60% 단축했습니다."

---

## 참고 자료

- [GitHub Actions 공식 문서](https://docs.github.com/en/actions)
- [Vercel 배포 문서](https://vercel.com/docs/deployments/overview)
- [Turborepo 공식 문서](https://turbo.build/repo/docs)
- [size-limit](https://github.com/ai/size-limit) - 번들 사이즈 모니터링
- [Lighthouse CI](https://github.com/GoogleChrome/lighthouse-ci) - 성능 회귀 방지
- [Changesets](https://github.com/changesets/changesets) - 모노레포 버전 관리
- [Chromatic](https://www.chromatic.com/) - Visual Regression Testing
- [LaunchDarkly 문서](https://docs.launchdarkly.com/) - Feature Flag 서비스
- [Unleash](https://www.getunleash.io/) - 오픈소스 Feature Flag
- [Martin Fowler - Feature Toggles](https://martinfowler.com/articles/feature-toggles.html)
