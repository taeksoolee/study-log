# 3. 모던 번들러 비교

## 목차
1. [번들러 생태계 개요](#1-번들러-생태계-개요)
2. [esbuild - Go 기반 초고속 번들러](#2-esbuild---go-기반-초고속-번들러)
3. [SWC - Rust 기반 Babel 대체재](#3-swc---rust-기반-babel-대체재)
4. [Rollup - 라이브러리 번들링 특화](#4-rollup---라이브러리-번들링-특화)
5. [Turbopack - Webpack의 후계자](#5-turbopack---webpack의-후계자)
6. [성능 벤치마크](#6-성능-벤치마크)
7. [번들러 선택 가이드](#7-번들러-선택-가이드)
8. [면접 포인트](#8-면접-포인트)

---

## 1. 번들러 생태계 개요

2020년대에 접어들며 번들러 생태계는 **"JavaScript로 만든 도구를 네이티브 언어(Go, Rust)로 재작성"** 하는 흐름이 대세가 되었다.
JavaScript 런타임의 태생적 한계(단일 스레드, JIT 오버헤드)를 극복하기 위한 시도다.

```
[세대별 분류]
1세대: Browserify (2011), Grunt/Gulp (태스크 러너)
2세대: Webpack (2012), Rollup (2015) - JS 기반
3세대: esbuild (2020, Go), SWC (2020, Rust), Vite (2020)
4세대: Turbopack (2022, Rust), Rolldown (2024, Rust) - 진행 중
```

---

## 2. esbuild - Go 기반 초고속 번들러

### 특징과 설계 철학

[esbuild](https://esbuild.github.io/)는 Evan Wallace(Figma 공동창업자)가 2020년 Go 언어로 작성한 번들러다.
기존 JS 기반 번들러 대비 **10~100배 빠른 속도**를 목표로 설계되었다.

**속도의 비결**
- Go의 네이티브 멀티스레딩 활용 (Goroutine)
- 파싱부터 코드 생성까지 단일 패스 처리
- 불필요한 데이터 변환(직렬화/역직렬화) 최소화
- 메모리 사용량 최적화

### 기본 사용법

```bash
npm install --save-dev esbuild
```

```js
// build.mjs
import * as esbuild from 'esbuild';

// 기본 번들링
await esbuild.build({
  entryPoints: ['src/index.ts'],
  bundle: true,
  outfile: 'dist/out.js',
  minify: true,
  sourcemap: true,
  target: ['chrome90', 'firefox88', 'safari14'],
  format: 'esm', // 'iife' | 'cjs' | 'esm'
});

// Watch 모드
const ctx = await esbuild.context({
  entryPoints: ['src/index.ts'],
  bundle: true,
  outfile: 'dist/out.js',
});

await ctx.watch();
console.log('Watching...');
```

```bash
# CLI로 직접 실행
npx esbuild src/index.ts --bundle --outfile=dist/out.js --minify
```

### esbuild의 한계

esbuild는 속도에 집중하느라 일부 기능을 의도적으로 미지원한다.

| 기능 | 지원 여부 | 비고 |
|------|-----------|------|
| TypeScript 트랜스파일 | O | 타입 검사는 미수행 |
| JSX 변환 | O | |
| Tree Shaking | O | |
| Code Splitting | 부분 지원 | ESM만 |
| CSS Modules | X | 별도 플러그인 필요 |
| Babel 플러그인 호환 | X | 자체 플러그인 API 사용 |
| Rollup 플러그인 호환 | X | |

### Vite가 esbuild를 사용하는 이유

Vite는 개발 서버에서 **의존성 사전 번들링(Pre-bundling)** 에 esbuild를 사용한다.

```
[Vite 개발 서버 내부]
                         ┌─── esbuild ──→ node_modules 사전 번들링 (빠름)
브라우저 요청 → Vite ─┤
                         └─── Rollup 플러그인 ──→ 소스 코드 변환 (유연함)

[Vite 프로덕션 빌드]
소스 코드 ──→ Rollup (성숙한 Tree Shaking, 다양한 output 형식)
```

node_modules 패키지는 내용이 자주 바뀌지 않으므로 esbuild로 한 번만 고속 번들링하고 캐시한다.

---

## 3. SWC - Rust 기반 Babel 대체재

### 특징과 설계 철학

[SWC(Speedy Web Compiler)](https://swc.rs/)는 강동윤 개발자가 Rust로 작성한 트랜스파일러/번들러다.
**Babel의 기능을 Rust로 재구현**하여 20~70배의 성능 향상을 달성했다.

```
[벤치마크: 파일 변환 속도]
Babel: ~500ms (단일 스레드 JS)
SWC:   ~15ms  (Rust + 멀티스레딩)
```

### 기본 사용법

```bash
npm install --save-dev @swc/core @swc/cli
```

```json
// .swcrc
{
  "jsc": {
    "parser": {
      "syntax": "typescript",
      "tsx": true,
      "decorators": true
    },
    "transform": {
      "react": {
        "runtime": "automatic"
      }
    },
    "target": "es2017",
    "loose": false,
    "externalHelpers": false
  },
  "module": {
    "type": "es6"
  },
  "minify": false,
  "sourceMaps": true
}
```

```bash
# CLI 변환
npx swc src/index.ts -o dist/index.js

# 디렉토리 전체 변환
npx swc src -d dist
```

### Webpack에서 SWC 사용 (swc-loader)

```bash
npm install --save-dev swc-loader @swc/core
```

```js
// webpack.config.js
module.exports = {
  module: {
    rules: [
      {
        test: /\.(js|jsx|ts|tsx)$/,
        exclude: /node_modules/,
        use: {
          loader: 'swc-loader',
          options: {
            // .swcrc 파일의 설정을 사용하거나 여기서 직접 설정
            jsc: {
              parser: { syntax: 'typescript', tsx: true },
              transform: { react: { runtime: 'automatic' } },
            },
          },
        },
      },
    ],
  },
};
```

### Next.js가 SWC를 기본 채택한 이유

Next.js 12(2021)부터 Babel 대신 SWC를 기본 컴파일러로 사용한다.

```
[Next.js의 SWC 도입 효과]
로컬 컴파일 속도: 3배 향상
Fast Refresh: 5배 향상
프로덕션 빌드: 1.7배 향상
```

- **성능**: Rust의 병렬 처리로 대규모 앱도 빠른 컴파일
- **공식 지원**: styled-components, emotion 등 Next.js 전용 변환 내장
- **호환성**: Babel 설정(`babel.config.js`)이 있으면 자동으로 Babel로 폴백

```js
// next.config.js - SWC 관련 설정
module.exports = {
  compiler: {
    // styled-components SSR 지원
    styledComponents: true,
    // emotion 지원
    emotion: true,
    // console.log 제거 (프로덕션)
    removeConsole: {
      exclude: ['error'],
    },
  },
};
```

---

## 4. Rollup - 라이브러리 번들링 특화

### 특징과 설계 철학

[Rollup](https://rollupjs.org/)은 2015년 Rich Harris가 만든 번들러로, **라이브러리 배포**에 최적화되어 있다.
ES Module을 네이티브로 지원하는 최초의 번들러 중 하나로, Vite의 프로덕션 빌드 엔진으로 사용된다.

### 핵심 강점: Output Formats

Rollup의 가장 큰 장점은 **다양한 모듈 형식으로 동시 출력**이 가능하다는 점이다.
라이브러리를 배포할 때 CJS(Node.js), ESM(트리쉐이킹 가능), UMD(CDN) 형식을 모두 제공해야 하는 경우에 특히 유용하다.

```js
// rollup.config.js
import resolve from '@rollup/plugin-node-resolve';
import commonjs from '@rollup/plugin-commonjs';
import typescript from '@rollup/plugin-typescript';
import terser from '@rollup/plugin-terser';

export default {
  input: 'src/index.ts',

  output: [
    // CommonJS (require)
    {
      file: 'dist/index.cjs.js',
      format: 'cjs',
      exports: 'named',
      sourcemap: true,
    },
    // ES Module (import - Tree Shaking 가능)
    {
      file: 'dist/index.esm.js',
      format: 'esm',
      sourcemap: true,
    },
    // UMD (CDN, 전역 변수 방식)
    {
      file: 'dist/index.umd.js',
      format: 'umd',
      name: 'MyLibrary',       // 전역 변수명 (window.MyLibrary)
      globals: {
        react: 'React',        // 외부 의존성의 전역 변수 매핑
      },
      plugins: [terser()],     // UMD만 압축
    },
  ],

  // 번들에 포함하지 않을 외부 의존성
  external: ['react', 'react-dom'],

  plugins: [
    resolve(),
    commonjs(),
    typescript({ tsconfig: './tsconfig.json' }),
  ],
};
```

```json
// package.json - 각 형식을 진입점으로 지정
{
  "main": "dist/index.cjs.js",
  "module": "dist/index.esm.js",
  "exports": {
    ".": {
      "import": "./dist/index.esm.js",
      "require": "./dist/index.cjs.js"
    }
  }
}
```

### Rollup의 Tree Shaking

Rollup은 Tree Shaking의 원조에 가까운 번들러로, 정교한 정적 분석이 강점이다.

```js
// math.js
export const add = (a, b) => a + b;
export const subtract = (a, b) => a - b;
export const multiply = (a, b) => a * b;

// main.js
import { add } from './math';
console.log(add(1, 2));
// subtract, multiply는 번들에서 제거됨
```

---

## 5. Turbopack - Webpack의 후계자

### 특징과 배경

[Turbopack](https://turbo.build/pack)은 Webpack 창시자 Tobias Koppers가 Vercel에 합류해 Rust로 재작성한 차세대 번들러다.
**증분 빌드(Incremental Build)** 를 핵심 설계 원칙으로 삼고 있다.

```
[증분 빌드 개념]
첫 번째 빌드: 모든 파일 처리
이후 변경:    변경된 파일과 의존하는 파일만 재처리

→ 계산 결과를 함수 단위로 캐시
→ 입력이 같으면 캐시된 결과 재사용 (메모이제이션)
```

### 성능 목표

Vercel의 공식 벤치마크(2022):

| 번들러 | 콜드 스타트 | HMR (파일 변경) |
|--------|------------|-----------------|
| Webpack | 기준 (1x) | 기준 (1x) |
| Vite | 약 5x 빠름 | 약 3x 빠름 |
| Turbopack | 약 10x 빠름 | 약 700x 빠름 |

> 주의: 위 수치는 대규모 앱 기준이며, 실제 환경에서는 차이가 다를 수 있다.

### Next.js에서 Turbopack 사용

```bash
# Next.js 13.1+에서 개발 서버에 Turbopack 활성화
next dev --turbo

# 또는 package.json
{
  "scripts": {
    "dev": "next dev --turbo"
  }
}
```

```js
// next.config.js
module.exports = {
  experimental: {
    turbo: {
      // webpack loader를 Turbopack에서 사용
      rules: {
        '*.svg': {
          loaders: ['@svgr/webpack'],
          as: '*.js',
        },
      },
      // path alias
      resolveAlias: {
        '@': './src',
      },
    },
  },
};
```

### 현재 상태 (2024 기준)

- Next.js 14+에서 개발 서버(--turbo) 안정화 진행 중
- 프로덕션 빌드는 아직 베타 단계
- Webpack 플러그인 생태계와의 호환성은 부분적으로만 지원

---

## 6. 성능 벤치마크

아래 표는 대규모 React 앱(~1000개 모듈) 기준 상대적 성능 비교다.
실제 환경, 하드웨어, 앱 규모에 따라 결과는 달라질 수 있다.

| 번들러 | 콜드 빌드 | 증분 빌드(HMR) | 주 언어 | 멀티코어 |
|--------|----------|--------------|---------|---------|
| Webpack 5 | 기준 (1x) | 기준 (1x) | JavaScript | 제한적 |
| Rollup | 0.8x | 0.9x | JavaScript | X |
| esbuild | 10~100x | 10x | Go | O |
| SWC (트랜스파일만) | 20~70x | - | Rust | O |
| Vite (esbuild 사용) | 5~10x 빠른 시작 | 5~10x | JS+Go | 부분 |
| Turbopack | 10x | 수백x | Rust | O |

---

## 7. 번들러 선택 가이드

### 앱(Application) 개발

```
신규 프로젝트, 빠른 개발 환경 우선
  → Vite (React/Vue/Svelte 공식 지원, 풍부한 에코시스템)

Next.js 기반 프로젝트
  → 내장 번들러 사용 (SWC + Webpack / Turbopack)

레거시 유지보수, 복잡한 커스텀 빌드
  → Webpack 5 (가장 풍부한 플러그인 생태계)

최대 빌드 속도만 필요 (단순한 앱)
  → esbuild 직접 사용
```

### 라이브러리(Library) 개발

```
npm 배포용 라이브러리
  → Rollup (다양한 output format, 정교한 Tree Shaking)
  → 또는 Vite Library Mode (내부적으로 Rollup 사용)

TypeScript 라이브러리, 타입 선언 파일(.d.ts) 필요
  → Rollup + @rollup/plugin-typescript
  → 또는 tsup (esbuild 기반 라이브러리 번들러)
```

### 판단 기준 요약

| 상황 | 추천 |
|------|------|
| SPA 신규 개발 | Vite |
| Next.js 앱 | 기본 내장 (SWC) |
| 레거시 Webpack 마이그레이션 | 단계적 Vite 전환 |
| npm 라이브러리 배포 | Rollup / tsup |
| 최고 속도의 CI 빌드 | esbuild |
| 대규모 모노레포 | Turbopack (Next.js) 또는 Turborepo |

---

## 8. 면접 포인트

### Q1. esbuild가 기존 번들러보다 빠른 이유는 무엇인가요?

esbuild는 **Go 언어**로 작성되어 네이티브 코드로 실행됩니다. 세 가지 핵심 이유가 있습니다.

1. **멀티스레딩**: Go의 Goroutine을 활용해 파싱, 링킹, 코드 생성을 병렬 처리합니다. JavaScript는 단일 스레드 기반이라 Worker를 써도 오버헤드가 있습니다.
2. **단일 패스 처리**: 가능한 한 파싱부터 코드 생성까지 한 번의 순회로 처리합니다.
3. **메모리 효율**: 데이터 구조를 콤팩트하게 유지하고 불필요한 직렬화를 피합니다.

---

### Q2. Rollup이 라이브러리 번들링에 적합한 이유는?

Rollup은 **다양한 output format(CJS, ESM, UMD, IIFE)을 동시에 생성**할 수 있고, **정교한 Tree Shaking**이 강점입니다.

라이브러리를 npm에 배포할 때는 CJS(Node.js require), ESM(번들러 import, 트리쉐이킹 가능), UMD(CDN script 태그)를 모두 제공해야 사용자가 환경에 따라 선택할 수 있습니다. Rollup은 하나의 설정으로 이 세 가지를 동시에 출력할 수 있습니다.

또한 `external` 옵션으로 react 같은 peer dependency를 번들에서 제외해 불필요한 중복을 피할 수 있습니다.

---

### Q3. SWC와 Babel의 차이를 설명해주세요.

| 항목 | Babel | SWC |
|------|-------|-----|
| 구현 언어 | JavaScript | Rust |
| 속도 | 기준 | 20~70배 빠름 |
| 플러그인 | JS로 직접 작성 가능, 생태계 방대 | Rust로 작성해야 하며 생태계 제한 |
| 타입 검사 | 미수행 | 미수행 |
| 채택 사례 | CRA, 구형 설정 | Next.js 12+, Parcel 2 |

**공통점**: 둘 다 TypeScript 타입 검사를 수행하지 않고 구문 변환만 합니다. 타입 검사는 `tsc --noEmit`을 별도로 실행해야 합니다.

---

### Q4. Turbopack의 증분 빌드가 빠른 이유는?

Turbopack은 **함수 수준의 메모이제이션(캐싱)** 을 사용합니다. 빌드 과정을 수많은 작은 함수 단위로 쪼개고, 각 함수의 입력값이 바뀌지 않았으면 이전 결과를 그대로 재사용합니다.

파일 하나가 바뀌면 해당 파일을 처리하는 함수와 그에 의존하는 함수만 재실행됩니다. Webpack처럼 변경된 청크 전체를 재번들링하지 않기 때문에 HMR이 파일 수와 무관하게 빠릅니다.

이는 [Turborepo의 캐싱 전략](./05-monorepo.md)과 동일한 원리입니다.
