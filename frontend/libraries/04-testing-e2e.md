# 4. E2E 테스트 (Playwright & Cypress)

## 목차

1. [Playwright 소개 및 설치](#1-playwright-소개-및-설치)
2. [기본 테스트 작성](#2-기본-테스트-작성)
3. [페이지 객체 모델 (POM) 패턴](#3-페이지-객체-모델-pom-패턴)
4. [네트워크 모킹 & 스크린샷/비디오](#4-네트워크-모킹--스크린샷비디오)
5. [CI/CD에서 Playwright 실행](#5-cicd에서-playwright-실행)
6. [Cypress](#6-cypress)
7. [Playwright vs Cypress 비교](#7-playwright-vs-cypress-비교)
8. [E2E 테스트 전략](#8-e2e-테스트-전략)
9. [면접 포인트](#9-면접-포인트)

---

## 1. Playwright 소개 및 설치

Playwright는 Microsoft가 만든 E2E 테스트 프레임워크. Chromium, Firefox, WebKit 지원.

### 주요 특징

- **멀티 브라우저**: Chromium, Firefox, WebKit(Safari) 동시 테스트
- **Auto-wait**: 요소가 나타날 때까지 자동 대기 (flaky 테스트 감소)
- **네트워크 모킹**: API 응답 인터셉트 및 변조
- **병렬 실행**: 기본적으로 테스트 파일 단위 병렬
- **Trace Viewer**: 실패한 테스트의 스크린샷, 네트워크 로그 분석

### 설치

```bash
npm init playwright@latest
# 또는
npm install --save-dev @playwright/test
npx playwright install  # 브라우저 바이너리 설치
```

### playwright.config.ts

```ts
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  retries: process.env.CI ? 2 : 0,  // CI에서 재시도
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',  // 실패 시 trace 저장
    screenshot: 'only-on-failure',
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
    { name: 'webkit', use: { ...devices['Desktop Safari'] } },
    { name: 'Mobile Chrome', use: { ...devices['Pixel 5'] } },
  ],
  // 테스트 전 개발 서버 실행
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
  },
});
```

---

## 2. 기본 테스트 작성

```ts
// e2e/login.spec.ts
import { test, expect } from '@playwright/test';

test.describe('로그인 페이지', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/login');
  });

  test('유효한 자격 증명으로 로그인 성공', async ({ page }) => {
    // 입력
    await page.getByLabel('이메일').fill('user@example.com');
    await page.getByLabel('비밀번호').fill('password123');

    // 클릭
    await page.getByRole('button', { name: '로그인' }).click();

    // URL 변경 확인
    await expect(page).toHaveURL('/dashboard');
    await expect(page.getByText('안녕하세요')).toBeVisible();
  });

  test('잘못된 비밀번호로 로그인 실패', async ({ page }) => {
    await page.getByLabel('이메일').fill('user@example.com');
    await page.getByLabel('비밀번호').fill('wrongpassword');
    await page.getByRole('button', { name: '로그인' }).click();

    await expect(page.getByRole('alert')).toContainText('이메일 또는 비밀번호가 틀렸습니다');
  });
});
```

### 로케이터 우선순위

```ts
// 권장: 접근성 기반 (사용자 관점)
page.getByRole('button', { name: '제출' })
page.getByLabel('이메일')
page.getByText('완료')
page.getByPlaceholder('검색어를 입력하세요')

// 차선: test-id 속성 (구현 세부사항에 덜 의존)
page.getByTestId('submit-button')  // data-testid="submit-button"

// 최후: CSS 선택자 (변경에 취약)
page.locator('.submit-btn')
page.locator('#email-input')
```

---

## 3. 페이지 객체 모델 (POM) 패턴

페이지별 클래스를 만들어 로케이터와 동작을 캡슐화. 유지보수성 향상.

```ts
// e2e/pages/LoginPage.ts
import { type Page, type Locator } from '@playwright/test';

export class LoginPage {
  readonly page: Page;
  readonly emailInput: Locator;
  readonly passwordInput: Locator;
  readonly submitButton: Locator;
  readonly errorMessage: Locator;

  constructor(page: Page) {
    this.page = page;
    this.emailInput = page.getByLabel('이메일');
    this.passwordInput = page.getByLabel('비밀번호');
    this.submitButton = page.getByRole('button', { name: '로그인' });
    this.errorMessage = page.getByRole('alert');
  }

  async goto() {
    await this.page.goto('/login');
  }

  async login(email: string, password: string) {
    await this.emailInput.fill(email);
    await this.passwordInput.fill(password);
    await this.submitButton.click();
  }
}

// e2e/login.spec.ts — POM 적용
import { test, expect } from '@playwright/test';
import { LoginPage } from './pages/LoginPage';

test('로그인 성공', async ({ page }) => {
  const loginPage = new LoginPage(page);
  await loginPage.goto();
  await loginPage.login('user@example.com', 'password123');

  await expect(page).toHaveURL('/dashboard');
});
```

---

## 4. 네트워크 모킹 & 스크린샷/비디오

### API 응답 모킹

```ts
test('API 오류 시 에러 메시지 표시', async ({ page }) => {
  // 특정 API 요청 인터셉트
  await page.route('/api/users', (route) => {
    route.fulfill({
      status: 500,
      contentType: 'application/json',
      body: JSON.stringify({ error: '서버 오류' }),
    });
  });

  await page.goto('/users');
  await expect(page.getByRole('alert')).toContainText('오류가 발생했습니다');
});

// 특정 패턴 모킹
await page.route('**/api/products/**', async (route) => {
  const response = await route.fetch(); // 실제 요청
  const json = await response.json();
  json.price = 9999;  // 응답 수정
  await route.fulfill({ response, json });
});
```

### 스크린샷 & 비디오

```ts
// 수동 스크린샷
await page.screenshot({ path: 'screenshot.png', fullPage: true });

// 특정 요소만
await page.locator('.chart').screenshot({ path: 'chart.png' });

// 시각적 회귀 테스트
await expect(page).toHaveScreenshot('homepage.png');

// playwright.config.ts에서 비디오 설정
use: {
  video: 'on-first-retry',  // 'off' | 'on' | 'on-first-retry'
}
```

---

## 5. CI/CD에서 Playwright 실행

### GitHub Actions

```yaml
# .github/workflows/e2e.yml
name: Playwright Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20

      - name: Install dependencies
        run: npm ci

      - name: Install Playwright browsers
        run: npx playwright install --with-deps

      - name: Run Playwright tests
        run: npx playwright test

      - name: Upload test report
        uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: playwright-report
          path: playwright-report/
```

---

## 6. Cypress

Electron 기반 E2E 프레임워크. 컴포넌트 테스트도 지원.

```bash
npm install --save-dev cypress
npx cypress open  # GUI 실행
```

### 기본 테스트

```ts
// cypress/e2e/login.cy.ts
describe('로그인', () => {
  beforeEach(() => {
    cy.visit('/login');
  });

  it('로그인 성공', () => {
    cy.get('[data-cy=email]').type('user@example.com');
    cy.get('[data-cy=password]').type('password123');
    cy.get('[data-cy=submit]').click();

    cy.url().should('include', '/dashboard');
    cy.contains('안녕하세요').should('be.visible');
  });

  it('API 모킹', () => {
    cy.intercept('POST', '/api/login', {
      statusCode: 200,
      body: { token: 'mock-token', user: { name: '홍길동' } },
    }).as('loginRequest');

    cy.get('[data-cy=email]').type('user@example.com');
    cy.get('[data-cy=submit]').click();

    cy.wait('@loginRequest');
    cy.contains('홍길동').should('be.visible');
  });
});
```

### 컴포넌트 테스트 (Cypress 독자 기능)

```tsx
// Button.cy.tsx
import { mount } from 'cypress/react';
import Button from './Button';

it('버튼 클릭 시 onClick 호출', () => {
  const onClick = cy.stub();
  mount(<Button onClick={onClick} label="클릭" />);

  cy.get('button').click();
  expect(onClick).to.have.been.calledOnce;
});
```

---

## 7. Playwright vs Cypress 비교

| 항목 | Playwright | Cypress |
|------|-----------|---------|
| 지원 브라우저 | Chromium, Firefox, WebKit | Chrome, Edge, Firefox (Safari 제한적) |
| 병렬 실행 | 기본 지원 | 유료 플랜(Cypress Cloud) |
| 실행 속도 | 빠름 | 보통 |
| Auto-wait | 내장 | 내장 |
| API 모킹 | `page.route()` | `cy.intercept()` |
| 컴포넌트 테스트 | 미지원 | 지원 |
| 시각적 디버깅 | Trace Viewer | Time-travel 디버깅 |
| 언어 지원 | JS, TS, Python, Java, C# | JS, TS |
| 학습 곡선 | 중간 | 낮음 |
| iframe 테스트 | 쉬움 | 어려움 |

---

## 8. E2E 테스트 전략

### 테스트 피라미드

```
        /\
       /E2E\        ← 적게 (핵심 사용자 흐름만)
      /------\
     /통합 테스트\    ← 보통
    /----------\
   /  유닛 테스트  \  ← 많이 (빠르고 저렴)
  /--------------\
```

### 무엇을 E2E로 테스트할지

```
테스트해야 하는 것:
- 핵심 사용자 흐름 (회원가입 → 로그인 → 구매)
- 인증/인가 흐름
- 중요한 폼 제출 & 유효성 검사
- 결제 플로우

테스트하지 않아도 되는 것:
- 모든 UI 상태 (유닛/컴포넌트 테스트로)
- 단순 텍스트 변경
- 에러 핸들링 세부 사항 (유닛 테스트로)
```

### 안정적인 테스트를 위한 팁

```ts
// 1. 시간 의존성 제거
await page.clock.setFixedTime(new Date('2024-01-01'));

// 2. 테스트 격리 — 각 테스트가 독립적으로 실행
test.beforeEach(async ({ page }) => {
  // DB 초기화 또는 API 모킹으로 상태 초기화
});

// 3. 재시도 설정 (flaky 테스트 대응)
test('불안정한 테스트', async ({ page }) => {
  test.setTimeout(60000);
  // ...
});
```

---

## 9. 면접 포인트

**Q. E2E 테스트와 유닛 테스트의 차이는?**
> 유닛 테스트는 개별 함수/컴포넌트를 격리해서 빠르게 테스트합니다. E2E 테스트는 실제 브라우저에서 사용자 흐름 전체(UI 렌더링, API 통신, 라우팅)를 검증합니다. 유닛 테스트가 빠르고 저렴한 반면, E2E는 느리고 유지비용이 높습니다. 테스트 피라미드에 따라 유닛 테스트를 많이, E2E를 적게 작성합니다.

**Q. Playwright의 auto-wait가 무엇인가?**
> Playwright는 `click()`, `fill()` 등의 액션 전에 요소가 가시적이고(visible), 활성화(enabled)되고, 안정적인(stable) 상태가 될 때까지 자동으로 대기합니다. 덕분에 `setTimeout`이나 명시적 대기 코드 없이도 비동기 UI 변화에 대응할 수 있어 flaky 테스트가 줄어듭니다.

**Q. 페이지 객체 모델(POM) 패턴을 사용하는 이유는?**
> UI가 변경될 때 테스트 코드를 한 곳(Page 클래스)만 수정하면 됩니다. 로케이터와 동작을 재사용하고, 테스트 코드 자체는 비즈니스 흐름에 집중할 수 있어 가독성이 높아집니다.

**Q. Playwright와 Cypress를 어떻게 선택하는가?**
> Safari(WebKit) 테스트가 필요하거나 병렬 실행이 중요하면 Playwright를 선택합니다. 팀이 Cypress에 익숙하거나 컴포넌트 테스트가 필요하면 Cypress가 유리합니다. 최근 신규 프로젝트에서는 Playwright가 더 많이 선택되는 추세입니다.
