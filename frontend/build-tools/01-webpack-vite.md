# 1. Webpack & Vite

## 목차
1. [모듈 번들러의 필요성](#1-모듈-번들러의-필요성)
2. [Webpack 핵심 개념](#2-webpack-핵심-개념)
3. [webpack.config.js 기본 예시](#3-webpackconfigjs-기본-예시)
4. [Tree Shaking](#4-tree-shaking)
5. [Code Splitting](#5-code-splitting)
6. [Vite 등장 배경과 특징](#6-vite-등장-배경과-특징)
7. [Vite HMR 동작 방식](#7-vite-hmr-동작-방식)
8. [Webpack vs Vite 비교](#8-webpack-vs-vite-비교)
9. [면접 포인트](#9-면접-포인트)

---

## 1. 모듈 번들러의 필요성

### 브라우저 모듈 시스템의 한계

초기 웹 개발에서는 JavaScript 파일을 `<script>` 태그로 하나씩 불러왔다.
파일 수가 늘어날수록 다음과 같은 문제가 발생했다.

- **전역 스코프 오염**: 모든 파일이 전역 변수를 공유하여 충돌 발생
- **의존성 순서 문제**: 파일 로드 순서에 따라 동작이 달라짐
- **HTTP 요청 과다**: 파일 수만큼 네트워크 요청이 발생해 성능 저하
- **CommonJS/ESM 혼재**: Node.js 생태계(require/module.exports)와 브라우저 간 호환성 부재

```html
<!-- 문제: 순서가 중요하고, 전역 충돌 발생 -->
<script src="jquery.js"></script>
<script src="utils.js"></script>   <!-- window.utils 전역 오염 -->
<script src="app.js"></script>
```

모듈 번들러는 이러한 문제를 해결하기 위해 등장했다.
여러 모듈을 분석하여 의존성 그래프를 만들고, 하나(또는 여러)의 번들 파일로 합쳐준다.

---

## 2. Webpack 핵심 개념

Webpack은 현재 가장 널리 사용되는 모듈 번들러로, 5가지 핵심 개념으로 구성된다.

### Entry (진입점)
의존성 그래프를 만들기 시작하는 시작 파일을 지정한다.

```js
// 단일 엔트리
module.exports = {
  entry: './src/index.js',
};

// 다중 엔트리 (MPA)
module.exports = {
  entry: {
    home: './src/home.js',
    about: './src/about.js',
  },
};
```

### Output (출력)
번들링 결과물을 어디에, 어떤 이름으로 저장할지 설정한다.

```js
const path = require('path');

module.exports = {
  output: {
    path: path.resolve(__dirname, 'dist'),
    filename: '[name].[contenthash].js', // 캐시 버스팅을 위한 해시
    clean: true, // 빌드 전 dist 폴더 정리
  },
};
```

### Loader (로더)
JavaScript와 JSON 외의 파일(CSS, 이미지, TypeScript 등)을 모듈로 변환한다.
Webpack 자체는 JS/JSON만 이해하므로, 다른 파일 형식은 로더가 변환을 담당한다.

```js
module.exports = {
  module: {
    rules: [
      {
        test: /\.tsx?$/,        // 대상 파일 패턴
        use: 'ts-loader',       // 사용할 로더
        exclude: /node_modules/,
      },
      {
        test: /\.css$/,
        use: ['style-loader', 'css-loader'], // 오른쪽부터 순서대로 실행
      },
      {
        test: /\.(png|svg|jpg)$/,
        type: 'asset/resource',  // Webpack 5 내장 asset 처리
      },
    ],
  },
};
```

### Plugin (플러그인)
번들링 과정 전반에 걸쳐 추가적인 작업을 수행한다.
로더가 파일 단위 변환이라면, 플러그인은 번들 전체에 영향을 미친다.

```js
const HtmlWebpackPlugin = require('html-webpack-plugin');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');

module.exports = {
  plugins: [
    new HtmlWebpackPlugin({
      template: './public/index.html', // HTML에 번들 파일 자동 삽입
    }),
    new MiniCssExtractPlugin({
      filename: '[name].[contenthash].css', // CSS를 별도 파일로 추출
    }),
  ],
};
```

### Mode (모드)
`development` 또는 `production`으로 설정하며, 각각에 최적화된 기본값이 적용된다.

| 모드 | 특징 |
|------|------|
| `development` | 소스맵 포함, 빠른 빌드, 디버깅 용이 |
| `production` | 코드 압축(Minification), Tree Shaking, 최적화 |

---

## 3. webpack.config.js 기본 예시

```js
const path = require('path');
const HtmlWebpackPlugin = require('html-webpack-plugin');

module.exports = {
  mode: 'production',

  entry: './src/index.js',

  output: {
    path: path.resolve(__dirname, 'dist'),
    filename: '[name].[contenthash].js',
    clean: true,
  },

  module: {
    rules: [
      {
        test: /\.(js|jsx)$/,
        exclude: /node_modules/,
        use: {
          loader: 'babel-loader',
          options: {
            presets: ['@babel/preset-env', '@babel/preset-react'],
          },
        },
      },
      {
        test: /\.css$/,
        use: ['style-loader', 'css-loader'],
      },
    ],
  },

  resolve: {
    extensions: ['.js', '.jsx', '.ts', '.tsx'], // 확장자 생략 가능
    alias: {
      '@': path.resolve(__dirname, 'src'), // import 경로 단축
    },
  },

  plugins: [
    new HtmlWebpackPlugin({ template: './public/index.html' }),
  ],

  devServer: {
    port: 3000,
    hot: true,       // HMR 활성화
    open: true,
    historyApiFallback: true, // SPA 라우팅 지원
  },
};
```

---

## 4. Tree Shaking

Tree Shaking은 사용되지 않는 코드(dead code)를 빌드 결과물에서 제거하는 최적화 기법이다.
나무를 흔들어 죽은 잎을 떨어뜨리는 것에서 유래했다.

### 동작 조건
- **ES Module(import/export) 사용 필수**: CommonJS(require)는 정적 분석이 불가능하여 Tree Shaking 불가
- `mode: 'production'` 설정 시 자동 활성화
- `sideEffects` 설정으로 부작용 있는 파일 명시 가능

```js
// utils.js
export function add(a, b) { return a + b; }      // 사용됨 → 포함
export function subtract(a, b) { return a - b; } // 미사용 → 제거됨

// index.js
import { add } from './utils';
console.log(add(1, 2));
```

```json
// package.json - 사이드 이펙트 없는 파일 명시
{
  "sideEffects": false,

  // 또는 특정 파일만 사이드 이펙트 있음을 표시
  "sideEffects": ["./src/polyfills.js", "*.css"]
}
```

---

## 5. Code Splitting

Code Splitting은 번들을 여러 청크(chunk)로 분리하여 초기 로딩 성능을 개선하는 기법이다.

### Dynamic Import (동적 임포트)
```js
// 버튼 클릭 시 해당 모듈을 지연 로딩
const button = document.getElementById('loadChart');
button.addEventListener('click', async () => {
  const { Chart } = await import('./Chart.js'); // 별도 청크로 분리
  new Chart('#canvas', data);
});

// React에서의 Lazy Loading
import React, { lazy, Suspense } from 'react';

const HeavyComponent = lazy(() => import('./HeavyComponent'));

function App() {
  return (
    <Suspense fallback={<div>로딩 중...</div>}>
      <HeavyComponent />
    </Suspense>
  );
}
```

### SplitChunksPlugin
공통 모듈을 별도 청크로 분리하여 캐싱 효율을 높인다.

```js
module.exports = {
  optimization: {
    splitChunks: {
      chunks: 'all',          // 모든 청크에 대해 분리 적용
      cacheGroups: {
        vendor: {
          test: /[\\/]node_modules[\\/]/,
          name: 'vendors',    // node_modules를 vendors.js로 분리
          chunks: 'all',
        },
      },
    },
    runtimeChunk: 'single',   // 런타임 코드 별도 분리
  },
};
```

---

## 6. Vite 등장 배경과 특징

### 왜 Vite가 필요했나?

Webpack은 강력하지만, 프로젝트 규모가 커질수록 **개발 서버 시작 시간이 급격히 증가**하는 문제가 있었다.
수천 개의 모듈을 매번 번들링하여 서버를 시작하기 때문이다.

Vite는 이 문제를 해결하기 위해 두 가지 접근법을 사용한다.

### 1. 의존성 사전 번들링 (Pre-bundling)
`node_modules`의 패키지는 시작 시 `esbuild`로 한 번만 번들링한다.
esbuild는 Go 언어로 작성되어 기존 JS 번들러보다 10~100배 빠르다.

### 2. 소스 코드는 ESM으로 직접 서빙
개발 서버에서 소스 코드를 번들링하지 않고, 브라우저가 직접 ESM으로 요청할 때 변환해서 응답한다.
변환이 필요한 파일만 그때그때 처리하므로 서버 시작이 즉시 완료된다.

```
[Webpack 개발 서버]
모든 모듈 번들링 → 서버 시작 (파일 수에 비례해 느림)

[Vite 개발 서버]
서버 즉시 시작 → 브라우저 요청 시 해당 파일만 변환
```

### vite.config.js 기본 예시
```js
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],

  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },

  server: {
    port: 3000,
    open: true,
    proxy: {
      '/api': 'http://localhost:8080', // API 프록시
    },
  },

  build: {
    outDir: 'dist',
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom'], // 수동 청크 분리
        },
      },
    },
  },
});
```

---

## 7. Vite HMR 동작 방식

HMR(Hot Module Replacement)은 페이지를 새로고침하지 않고 변경된 모듈만 교체하는 기능이다.

### Webpack HMR vs Vite HMR

**Webpack HMR**: 변경된 파일을 포함하는 청크 전체를 재번들링 후 전송

**Vite HMR**: ESM 기반으로 변경된 파일만 즉시 무효화(invalidate)하고 새 모듈을 전송

```
[파일 변경 발생]
    ↓
[Vite 개발 서버가 변경 감지]
    ↓
[해당 모듈의 의존성 체인만 무효화]
    ↓
[WebSocket으로 브라우저에 업데이트 알림]
    ↓
[브라우저가 변경된 모듈만 새로 요청 및 교체]
    ↓
[상태(state) 유지한 채 UI 갱신]
```

```js
// Vite HMR API 직접 사용 (고급 사용 사례)
if (import.meta.hot) {
  import.meta.hot.accept('./dep.js', (newModule) => {
    // 모듈 업데이트 시 처리 로직
    newModule.render();
  });

  import.meta.hot.dispose(() => {
    // 이전 모듈 정리 (이벤트 리스너 제거 등)
    cleanup();
  });
}
```

---

## 8. Webpack vs Vite 비교

| 항목 | Webpack | Vite |
|------|---------|------|
| **등장 연도** | 2012 | 2020 |
| **개발 서버 시작** | 느림 (전체 번들링 필요) | 빠름 (ESM 직접 서빙) |
| **HMR 속도** | 느림 (청크 재번들링) | 빠름 (모듈 단위 교체) |
| **빌드 도구** | Webpack (JS 기반) | Rollup (프로덕션) + esbuild (개발) |
| **설정 복잡도** | 높음 (세밀한 제어 가능) | 낮음 (합리적인 기본값) |
| **생태계** | 매우 풍부 (오랜 역사) | 빠르게 성장 중 |
| **SSR 지원** | 플러그인 필요 | 내장 지원 |
| **레거시 브라우저** | 강력한 지원 | 별도 플러그인 필요 |
| **적합한 상황** | 복잡한 커스텀 빌드, 레거시 환경 | 신규 프로젝트, 빠른 개발 환경 |

### 선택 기준
- **Vite 선택**: 신규 프로젝트, 빠른 개발 속도가 우선, React/Vue/Svelte SPA
- **Webpack 선택**: 레거시 코드베이스, 세밀한 번들 제어가 필요, 특수한 로더/플러그인 의존

---

## 9. 면접 포인트

### Q1. Webpack의 Loader와 Plugin의 차이점은 무엇인가요?

**Loader**는 파일 단위로 동작하며, Webpack이 이해하지 못하는 파일 형식(CSS, TypeScript, 이미지 등)을 JavaScript 모듈로 **변환**하는 역할을 합니다. `module.rules`에 정의하며, 체이닝 시 오른쪽에서 왼쪽 순서로 실행됩니다.

**Plugin**은 번들링 과정 전체에 걸쳐 동작하며, HTML 파일 생성, CSS 파일 추출, 번들 분석 등 **번들링 파이프라인을 확장**하는 역할을 합니다. Webpack의 lifecycle hook에 접근하여 더 강력한 작업을 수행할 수 있습니다.

---

### Q2. Tree Shaking이 동작하지 않는 경우는 어떤 경우인가요?

Tree Shaking은 ES Module의 **정적 분석**을 기반으로 동작합니다. 따라서 다음 경우에는 동작하지 않습니다.

1. **CommonJS 사용**: `require()`는 동적으로 실행되어 정적 분석 불가
2. **동적 import 표현식**: `import(variable)` 형태는 어떤 모듈이 사용될지 예측 불가
3. **sideEffects 미설정**: 번들러가 안전하게 제거하지 못함
4. **Babel 설정 오류**: `@babel/preset-env`가 ES Module을 CommonJS로 변환하는 경우 (modules: false 설정 필요)

---

### Q3. Vite가 개발 환경에서 빠른 이유를 설명해주세요.

Vite는 개발 서버에서 소스 코드를 **번들링하지 않습니다**. 대신 브라우저의 네이티브 ESM을 활용하여 요청받은 파일만 그때그때 변환합니다. 또한 `node_modules`의 의존성은 `esbuild`(Go 기반)로 한 번만 사전 번들링하여 캐시합니다.

반면 Webpack은 개발 서버 시작 시 Entry부터 모든 의존성을 추적하고 번들링을 완료해야 서버가 준비됩니다. 프로젝트 규모가 커질수록 이 시간이 수십 초에서 수 분까지 늘어날 수 있습니다.

---

### Q4. Code Splitting은 왜 필요하고, 어떤 방식으로 구현하나요?

사용자가 처음 페이지에 접속할 때 애플리케이션의 모든 코드를 다운로드하면 **초기 로딩 시간(TTI)**이 길어집니다. Code Splitting으로 현재 필요한 코드만 먼저 로드하고, 나머지는 필요할 때 로드하면 초기 성능을 크게 개선할 수 있습니다.

구현 방식은 크게 세 가지입니다.
1. **동적 import**: `import()` 문법으로 특정 시점에 모듈 로드
2. **React.lazy + Suspense**: 컴포넌트 단위 지연 로딩
3. **SplitChunksPlugin**: 공통 모듈(vendor 등)을 자동으로 별도 청크로 분리

---

## Vite 최신 동향 (Vite 5.x / 6.x)
- Rolldown (Rust 기반 Rollup 대체) 통합 계획
- Environment API
- CSS Layers 지원
- Lightning CSS 통합
