# 6. Vite 심화

## 목차
1. [Vite 플러그인 시스템](#1-vite-플러그인-시스템)
2. [커스텀 플러그인 제작](#2-커스텀-플러그인-제작)
3. [환경 변수 관리 (import.meta.env)](#3-환경-변수-관리-importmetaenv)
4. [SSR 모드 설정](#4-ssr-모드-설정)
5. [Library Mode - 라이브러리 배포](#5-library-mode---라이브러리-배포)
6. [Vite + Vitest 테스트 환경](#6-vite--vitest-테스트-환경)
7. [성능 최적화 설정](#7-성능-최적화-설정)
8. [면접 포인트](#8-면접-포인트)

---

## 1. Vite 플러그인 시스템

### Rollup 플러그인 호환성

Vite의 플러그인 시스템은 **Rollup 플러그인 API의 슈퍼셋**이다.
대부분의 Rollup 플러그인을 Vite에서 그대로 사용할 수 있으며, Vite 전용 훅이 추가되어 있다.

```
[플러그인 실행 순서]
Vite 전용 훅 (config, configResolved, configureServer, ...)
    ↓
Rollup 호환 훅 (resolveId, load, transform, ...)
    ↓
빌드/개발 서버 처리
```

### 플러그인 적용 순서 제어

```js
// vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import myPlugin from './plugins/my-plugin';

export default defineConfig({
  plugins: [
    // enforce: 'pre' → 다른 플러그인보다 먼저 실행
    { ...myPlugin(), enforce: 'pre' },

    react(),

    // enforce: 'post' → 다른 플러그인보다 나중에 실행
    { ...myPlugin(), enforce: 'post' },
  ],
});
```

### 자주 사용하는 공식/커뮤니티 플러그인

```bash
# React (JSX 변환 + Fast Refresh)
npm install --save-dev @vitejs/plugin-react

# Vue 3
npm install --save-dev @vitejs/plugin-vue

# SVG를 React 컴포넌트로 import
npm install --save-dev vite-plugin-svgr

# 번들 분석
npm install --save-dev rollup-plugin-visualizer

# PWA (Service Worker)
npm install --save-dev vite-plugin-pwa

# 이미지 최적화
npm install --save-dev vite-plugin-imagemin
```

---

## 2. 커스텀 플러그인 제작

### 플러그인 기본 구조

Vite 플러그인은 **객체를 반환하는 팩토리 함수** 형태로 작성한다.

```ts
// plugins/my-plugin.ts
import type { Plugin } from 'vite';

export function myPlugin(options = {}): Plugin {
  return {
    // 플러그인 이름 (필수 - 디버깅 시 사용)
    name: 'vite-plugin-my-plugin',

    // 적용 시점: 'build' | 'serve' | 기본값은 항상 적용
    apply: 'build',

    // vite.config 처리 전 호출 - config 수정 가능
    config(config, { command }) {
      if (command === 'build') {
        return {
          build: { sourcemap: true },
        };
      }
    },

    // config 처리 완료 후 호출 - 최종 config 읽기 전용
    configResolved(resolvedConfig) {
      console.log('Final config:', resolvedConfig.mode);
    },

    // 개발 서버 설정 (serve 모드만)
    configureServer(server) {
      server.middlewares.use('/custom-api', (req, res) => {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ message: 'hello from plugin' }));
      });
    },

    // 모듈 경로 해결
    resolveId(source, importer) {
      if (source === 'virtual:my-module') {
        return source; // 가상 모듈 ID 반환
      }
    },

    // 모듈 코드 로드
    load(id) {
      if (id === 'virtual:my-module') {
        return 'export const message = "from virtual module"';
      }
    },

    // 코드 변환 (Babel 변환과 유사한 역할)
    transform(code, id) {
      if (id.endsWith('.special')) {
        return {
          code: code.replace(/MY_PLACEHOLDER/g, 'replaced'),
          map: null, // 소스맵 (없으면 null)
        };
      }
    },

    // 빌드 완료 후 훅
    closeBundle() {
      console.log('Build complete!');
    },
  };
}
```

### 실전 예제: 환경 변수 주입 플러그인

```ts
// plugins/inject-build-info.ts
import type { Plugin } from 'vite';
import { execSync } from 'child_process';

export function injectBuildInfo(): Plugin {
  let buildInfo: Record<string, string>;

  return {
    name: 'vite-plugin-inject-build-info',
    apply: 'build',

    buildStart() {
      buildInfo = {
        BUILD_TIME: new Date().toISOString(),
        GIT_HASH: execSync('git rev-parse --short HEAD').toString().trim(),
        GIT_BRANCH: execSync('git branch --show-current').toString().trim(),
      };
    },

    transform(code, id) {
      if (id.includes('src/') && (id.endsWith('.ts') || id.endsWith('.tsx'))) {
        let result = code;
        for (const [key, value] of Object.entries(buildInfo)) {
          result = result.replace(
            new RegExp(`__${key}__`, 'g'),
            JSON.stringify(value),
          );
        }
        return { code: result, map: null };
      }
    },
  };
}
```

```tsx
// 사용 예시
console.log('Built at:', __BUILD_TIME__);  // 빌드 시 실제 값으로 교체
```

---

## 3. 환경 변수 관리 (import.meta.env)

### 기본 환경 변수 규칙

```
[파일 우선순위 (낮음 → 높음)]
.env                  ← 공통 (git 커밋)
.env.local            ← 공통 로컬 전용 (git 무시)
.env.[mode]           ← 특정 모드 (예: .env.production)
.env.[mode].local     ← 특정 모드 로컬 전용
```

```bash
# .env (git 커밋)
VITE_API_URL=https://api.production.com
VITE_APP_NAME=My App

# .env.development (git 커밋)
VITE_API_URL=http://localhost:8080

# .env.local (git 무시 - 개인 설정)
VITE_DEV_AUTH_TOKEN=my-personal-token
```

```ts
// 클라이언트 코드에서 접근
// VITE_ 접두사가 있는 변수만 브라우저에 노출됨!
console.log(import.meta.env.VITE_API_URL);     // 환경 변수
console.log(import.meta.env.MODE);             // 'development' | 'production'
console.log(import.meta.env.DEV);              // true (개발 환경)
console.log(import.meta.env.PROD);             // true (프로덕션)
console.log(import.meta.env.SSR);              // true (SSR 환경)

// VITE_ 없는 변수는 브라우저에서 접근 불가 (보안)
console.log(import.meta.env.DB_PASSWORD);      // undefined!
```

### TypeScript 타입 정의

```ts
// src/vite-env.d.ts
/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_API_URL: string;
  readonly VITE_APP_NAME: string;
  readonly VITE_FEATURE_FLAG_DARK_MODE: 'true' | 'false';
  // 더 많은 환경 변수...
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
```

### 서버 사이드에서 환경 변수 접근

```ts
// vite.config.ts - 빌드 설정에서 환경 변수 사용
import { defineConfig, loadEnv } from 'vite';

export default defineConfig(({ mode }) => {
  // 현재 작업 디렉토리의 .env 파일 로드
  const env = loadEnv(mode, process.cwd(), '');

  return {
    // VITE_ 없는 변수도 접근 가능 (빌드 설정에서만)
    define: {
      'process.env.NODE_ENV': JSON.stringify(mode),
      __APP_VERSION__: JSON.stringify(process.env.npm_package_version),
    },
    server: {
      proxy: {
        '/api': env.BACKEND_URL, // VITE_ 없는 서버 변수 사용
      },
    },
  };
});
```

---

## 4. SSR 모드 설정

### Vite SSR 개요

Vite는 SSR(Server-Side Rendering)을 내장 지원한다.
개발 서버에서 SSR 번들을 빠르게 처리하고, 프로덕션에서는 별도 SSR 번들을 생성한다.

```
[Vite SSR 처리 흐름]
1. 서버: vite.ssrLoadModule()로 컴포넌트 로드
2. 서버: React/Vue의 renderToString()으로 HTML 생성
3. 클라이언트: 생성된 HTML로 초기 렌더링 (빠름)
4. 클라이언트: hydrateRoot()로 이벤트 연결
```

```ts
// server.ts (Express SSR 서버 예시)
import express from 'express';
import { createServer as createViteServer } from 'vite';

async function createServer() {
  const app = express();

  // Vite 개발 서버를 미들웨어로 사용
  const vite = await createViteServer({
    server: { middlewareMode: true },
    appType: 'custom',
  });

  app.use(vite.middlewares);

  app.use('*', async (req, res, next) => {
    const url = req.originalUrl;

    try {
      // 1. index.html 읽기
      let template = fs.readFileSync('index.html', 'utf-8');

      // 2. Vite가 HTML 변환 (HMR 클라이언트 주입 등)
      template = await vite.transformIndexHtml(url, template);

      // 3. SSR entry 모듈 로드
      const { render } = await vite.ssrLoadModule('/src/entry-server.tsx');

      // 4. 서버에서 HTML 렌더링
      const appHtml = await render(url);

      // 5. 렌더링 결과를 HTML 템플릿에 삽입
      const html = template.replace('<!--ssr-outlet-->', appHtml);

      res.status(200).set({ 'Content-Type': 'text/html' }).end(html);
    } catch (e) {
      vite.ssrFixStacktrace(e as Error);
      next(e);
    }
  });

  app.listen(5173);
}
```

```tsx
// src/entry-server.tsx
import { renderToString } from 'react-dom/server';
import { StaticRouter } from 'react-router-dom/server';
import App from './App';

export async function render(url: string) {
  return renderToString(
    <StaticRouter location={url}>
      <App />
    </StaticRouter>
  );
}
```

```tsx
// src/entry-client.tsx
import { hydrateRoot } from 'react-dom/client';
import { BrowserRouter } from 'react-router-dom';
import App from './App';

hydrateRoot(
  document.getElementById('root')!,
  <BrowserRouter>
    <App />
  </BrowserRouter>
);
```

---

## 5. Library Mode - 라이브러리 배포

### Library Mode 설정

Vite는 라이브러리 배포용 번들을 만들 수 있다. 내부적으로 Rollup을 사용한다.

```ts
// vite.config.ts (라이브러리 모드)
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { resolve } from 'path';
import dts from 'vite-plugin-dts';

export default defineConfig({
  plugins: [
    react(),
    // TypeScript 타입 선언 파일(.d.ts) 자동 생성
    dts({
      insertTypesEntry: true,
      rollupTypes: true,
    }),
  ],

  build: {
    lib: {
      entry: resolve(__dirname, 'src/index.ts'),  // 진입점
      name: 'MyLibrary',                          // UMD 전역 변수명
      formats: ['es', 'cjs'],                     // 출력 형식
      fileName: (format) => `my-library.${format}.js`,
    },
    rollupOptions: {
      // 번들에 포함하지 않을 외부 의존성
      external: ['react', 'react-dom'],
      output: {
        // UMD/IIFE에서 외부 의존성의 전역 변수 매핑
        globals: {
          react: 'React',
          'react-dom': 'ReactDOM',
        },
      },
    },
    // 소스맵 생성 (라이브러리 디버깅 지원)
    sourcemap: true,
    // minify 여부 (라이브러리는 보통 false - 소비자가 minify)
    minify: false,
  },
});
```

### package.json 배포 설정

```json
{
  "name": "@myorg/my-library",
  "version": "1.0.0",
  "type": "module",
  "files": ["dist"],
  "main": "./dist/my-library.cjs.js",
  "module": "./dist/my-library.es.js",
  "types": "./dist/index.d.ts",
  "exports": {
    ".": {
      "import": "./dist/my-library.es.js",
      "require": "./dist/my-library.cjs.js",
      "types": "./dist/index.d.ts"
    }
  },
  "scripts": {
    "build": "vite build",
    "build:watch": "vite build --watch"
  },
  "peerDependencies": {
    "react": "^18.0.0",
    "react-dom": "^18.0.0"
  },
  "devDependencies": {
    "react": "^18.2.0",
    "vite": "^5.0.0",
    "vite-plugin-dts": "^3.0.0"
  }
}
```

---

## 6. Vite + Vitest 테스트 환경

### Vitest 소개

[Vitest](https://vitest.dev/)는 Vite 기반의 테스트 프레임워크다.
Jest와 호환되는 API를 제공하면서 Vite 설정을 공유해 별도 설정 없이 바로 사용 가능하다.

```bash
npm install --save-dev vitest @testing-library/react jsdom
```

### vite.config.ts에 테스트 설정 통합

```ts
// vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],

  test: {
    // 테스트 환경: 'jsdom' | 'happy-dom' | 'node'
    environment: 'jsdom',

    // Jest 스타일 전역 API (describe, it, expect) 자동 import
    globals: true,

    // 각 테스트 전 실행할 설정 파일
    setupFiles: ['./src/test/setup.ts'],

    // 커버리지 설정
    coverage: {
      provider: 'v8',  // 'v8' | 'istanbul'
      reporter: ['text', 'json', 'html'],
      exclude: ['node_modules/', 'src/test/'],
    },

    // 테스트 파일 패턴
    include: ['src/**/*.{test,spec}.{js,ts,jsx,tsx}'],
  },
});
```

```ts
// src/test/setup.ts
import '@testing-library/jest-dom';

// fetch 모킹 (jsdom에는 fetch가 없음)
import { beforeAll, afterAll, afterEach } from 'vitest';
import { setupServer } from 'msw/node';
import { handlers } from './mocks/handlers';

const server = setupServer(...handlers);

beforeAll(() => server.listen({ onUnhandledRequest: 'error' }));
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
```

### 테스트 작성 예시

```tsx
// src/components/Button.test.tsx
import { render, screen, fireEvent } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import { Button } from './Button';

describe('Button', () => {
  it('renders correctly', () => {
    render(<Button>Click me</Button>);
    expect(screen.getByRole('button', { name: 'Click me' })).toBeInTheDocument();
  });

  it('calls onClick handler when clicked', () => {
    const handleClick = vi.fn();
    render(<Button onClick={handleClick}>Click me</Button>);

    fireEvent.click(screen.getByRole('button'));

    expect(handleClick).toHaveBeenCalledTimes(1);
  });

  it('is disabled when disabled prop is passed', () => {
    render(<Button disabled>Click me</Button>);
    expect(screen.getByRole('button')).toBeDisabled();
  });
});
```

```ts
// src/utils/format.test.ts (단순 유틸 테스트)
import { describe, it, expect } from 'vitest';
import { formatPrice } from './format';

describe('formatPrice', () => {
  it('formats price with currency symbol', () => {
    expect(formatPrice(1000, 'KRW')).toBe('₩1,000');
    expect(formatPrice(9.99, 'USD')).toBe('$9.99');
  });

  it('handles zero', () => {
    expect(formatPrice(0, 'USD')).toBe('$0.00');
  });
});
```

### package.json 스크립트

```json
{
  "scripts": {
    "test": "vitest",
    "test:run": "vitest run",
    "test:ui": "vitest --ui",           // 브라우저 UI로 테스트 결과 확인
    "test:coverage": "vitest run --coverage"
  }
}
```

---

## 7. 성능 최적화 설정

### 수동 청크 분리 (manualChunks)

```ts
// vite.config.ts
export default defineConfig({
  build: {
    rollupOptions: {
      output: {
        manualChunks: {
          // React 관련을 별도 청크로 (변경이 적어 캐시 히트율 높음)
          'react-vendor': ['react', 'react-dom', 'react-router-dom'],
          // UI 라이브러리 별도 청크
          'ui-vendor': ['@radix-ui/react-dialog', '@radix-ui/react-dropdown-menu'],
        },

        // 또는 함수 형태로 동적 분리
        manualChunks(id) {
          if (id.includes('node_modules')) {
            // lodash를 별도 청크로
            if (id.includes('lodash')) return 'lodash';
            // 나머지 node_modules는 vendor 청크
            return 'vendor';
          }
        },
      },
    },
    // 청크 크기 경고 임계값 (기본 500kb)
    chunkSizeWarningLimit: 1000,
  },
});
```

### 의존성 최적화 설정

```ts
export default defineConfig({
  optimizeDeps: {
    // 사전 번들링에 포함할 패키지 (자동 감지 안 되는 경우)
    include: ['lodash-es', '@myorg/ui'],
    // 사전 번들링에서 제외 (이미 ESM인 경우)
    exclude: ['some-esm-package'],
    // esbuild 설정 (사전 번들링용)
    esbuildOptions: {
      target: 'es2020',
    },
  },
});
```

---

## 8. 면접 포인트

### Q1. Vite 플러그인에서 enforce 옵션은 무엇인가요?

`enforce: 'pre'`는 Vite 코어 플러그인보다 먼저 실행되고, `enforce: 'post'`는 빌드 플러그인 이후에 실행됩니다.

기본적으로 Vite 플러그인은 다음 순서로 실행됩니다: `pre` → Vite 내부 → 일반 플러그인 → `post`.

예를 들어 소스 코드를 변환하기 전에 파일을 가공해야 한다면 `enforce: 'pre'`를, 번들링 후 최종 결과물에 작업해야 한다면 `enforce: 'post'`를 사용합니다.

---

### Q2. Vite에서 VITE_ 접두사가 없는 환경 변수는 왜 브라우저에서 접근이 안 되나요?

보안 때문입니다. `.env` 파일에는 데이터베이스 비밀번호, API 시크릿 키 등 클라이언트에 노출되면 안 되는 값도 포함될 수 있습니다.

Vite는 **`VITE_` 접두사가 있는 변수만** 번들에 포함하여 `import.meta.env`로 접근 가능하게 합니다. 나머지 변수는 `vite.config.ts` 같은 Node.js 환경에서만 접근 가능하여 실수로 민감한 정보를 노출하는 것을 방지합니다.

---

### Q3. Vite Library Mode와 일반 앱 빌드의 차이점은?

**일반 앱 빌드**: HTML을 진입점으로 사용하고, 모든 의존성을 번들에 포함. CSS가 HTML에 주입되는 형태. 코드 스플리팅, 에셋 최적화 등이 활성화.

**Library Mode**: TypeScript/JavaScript 파일을 진입점으로 사용. react 같은 peer dependency는 `external`로 제외하여 번들에 미포함. CJS/ESM 등 여러 형식으로 동시 출력. 타입 선언 파일(`.d.ts`) 생성. CSS Injection 대신 소비자가 직접 import하도록 분리.

라이브러리는 소비자의 앱에 통합되므로, 번들에 react를 포함하면 소비자의 앱과 react가 중복되어 문제가 생길 수 있습니다.

---

### Q4. Vitest를 Jest 대신 사용하는 장점은 무엇인가요?

1. **설정 공유**: `vite.config.ts`에 테스트 설정을 통합할 수 있어 별도 Jest 설정 파일이 필요 없습니다.

2. **ESM 지원**: Jest는 기본적으로 CommonJS 기반이라 ESM 처리 시 추가 설정이 필요합니다. Vitest는 Vite와 동일한 ESM 환경으로 처리합니다.

3. **빠른 속도**: esbuild 기반으로 변환하여 TypeScript/JSX 처리가 빠릅니다.

4. **HMR(Watch 모드)**: 변경된 파일과 관련된 테스트만 재실행합니다.

5. **jest 호환 API**: `describe`, `it`, `expect`, `vi.fn()` 등 jest와 동일한 API를 사용해 마이그레이션이 쉽습니다.
