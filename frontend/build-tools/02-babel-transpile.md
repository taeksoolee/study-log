# 2. Babel & Transpile

## 목차
1. [트랜스파일링이 필요한 이유](#1-트랜스파일링이-필요한-이유)
2. [Babel 동작 과정](#2-babel-동작-과정)
3. [AST(Abstract Syntax Tree)](#3-astabstract-syntax-tree)
4. [Babel 플러그인과 프리셋](#4-babel-플러그인과-프리셋)
5. [.babelrc 설정 예시](#5-babelrc-설정-예시)
6. [Transpile vs Polyfill](#6-transpile-vs-polyfill)
7. [core-js와 useBuiltIns 설정](#7-core-js와-usebuiltins-설정)
8. [TypeScript 트랜스파일](#8-typescript-트랜스파일)
9. [면접 포인트](#9-면접-포인트)

---

## 1. 트랜스파일링이 필요한 이유

### 브라우저 호환성 문제

JavaScript는 매년 새로운 문법과 기능이 추가된다(ES2015, ES2016, ...).
그러나 모든 브라우저(특히 구형 IE, 오래된 Safari)가 최신 문법을 지원하지는 않는다.

```js
// 최신 문법 (ES2015+)
const greet = (name) => `Hello, ${name}!`;
const { x, y, ...rest } = obj;
const result = await fetchData();

// IE11은 위 코드를 이해하지 못함
// → 트랜스파일러가 구형 브라우저가 이해할 수 있는 코드로 변환해야 함
```

### 트랜스파일러의 역할
트랜스파일러(Transpiler)는 한 언어 또는 버전으로 작성된 코드를 다른 언어 또는 버전으로 변환하는 도구다.

- **소스-투-소스(source-to-source) 컴파일러**라고도 부른다
- JavaScript → JavaScript (ES6+ → ES5)
- TypeScript → JavaScript
- JSX → JavaScript

대표적인 트랜스파일러로 **Babel**이 있으며, 현재 프론트엔드 생태계의 표준으로 자리잡고 있다.

---

## 2. Babel 동작 과정

Babel은 코드를 변환할 때 **3단계 파이프라인**을 거친다.

```
원본 소스 코드
      ↓
  [1단계: 파싱(Parsing)]
  소스 코드 → AST (Abstract Syntax Tree)
      ↓
  [2단계: 변환(Transformation)]
  AST → 변환된 AST (플러그인이 이 단계에서 동작)
      ↓
  [3단계: 코드 생성(Code Generation)]
  변환된 AST → 출력 코드
      ↓
출력 소스 코드
```

### 단계별 설명

**1단계: 파싱(Parsing)**
- `@babel/parser`(구 Babylon)가 소스 코드를 읽어 AST로 변환
- 어휘 분석(Lexical Analysis): 코드를 토큰(token) 단위로 분리
- 구문 분석(Syntactic Analysis): 토큰을 AST 노드로 구성

**2단계: 변환(Transformation)**
- `@babel/traverse`가 AST를 순회(traverse)하며 각 노드를 방문
- 플러그인들이 특정 노드 타입을 감지하여 변환 작업 수행
- 화살표 함수 노드 → 일반 함수 노드로 교체 등

**3단계: 코드 생성(Code Generation)**
- `@babel/generator`가 변환된 AST를 다시 코드 문자열로 변환
- 소스맵(Source Map) 생성 가능

---

## 3. AST(Abstract Syntax Tree)

### AST란?

AST는 프로그램의 구조를 트리 형태로 표현한 추상 자료구조다.
소스 코드의 각 문법 요소가 트리의 노드(node)가 된다.

```js
// 원본 코드
const add = (a, b) => a + b;
```

위 코드는 대략 다음과 같은 AST 구조로 파싱된다.

```json
{
  "type": "Program",
  "body": [
    {
      "type": "VariableDeclaration",
      "kind": "const",
      "declarations": [
        {
          "type": "VariableDeclarator",
          "id": {
            "type": "Identifier",
            "name": "add"
          },
          "init": {
            "type": "ArrowFunctionExpression",
            "params": [
              { "type": "Identifier", "name": "a" },
              { "type": "Identifier", "name": "b" }
            ],
            "body": {
              "type": "BinaryExpression",
              "operator": "+",
              "left": { "type": "Identifier", "name": "a" },
              "right": { "type": "Identifier", "name": "b" }
            }
          }
        }
      ]
    }
  ]
}
```

> AST Explorer(astexplorer.net)에서 직접 코드를 입력하고 AST 구조를 확인할 수 있다.

### AST의 활용
- **Babel**: 코드 변환
- **ESLint**: 코드 린팅 (규칙 위반 감지)
- **Prettier**: 코드 포매팅
- **TypeScript**: 타입 검사
- **webpack**: 의존성 분석

---

## 4. Babel 플러그인과 프리셋

### 플러그인(Plugin)
개별 문법 변환을 담당하는 가장 작은 단위다.

```bash
npm install --save-dev @babel/plugin-transform-arrow-functions
```

```js
// 화살표 함수를 일반 함수로 변환
// Before
const fn = () => {};

// After (플러그인 적용)
const fn = function() {};
```

```json
// .babelrc
{
  "plugins": [
    "@babel/plugin-transform-arrow-functions",
    "@babel/plugin-transform-template-literals"
  ]
}
```

### 프리셋(Preset)
관련된 플러그인들을 묶어놓은 패키지다. 플러그인을 하나씩 설정하는 번거로움을 줄여준다.

#### @babel/preset-env
타겟 환경(브라우저, Node.js 버전)에 맞게 필요한 변환만 자동으로 적용한다.
browserslist 설정과 함께 사용하면 실제로 지원해야 하는 브라우저에 맞는 최소한의 변환만 수행한다.

```bash
npm install --save-dev @babel/preset-env
```

```js
// .babelrc
{
  "presets": [
    ["@babel/preset-env", {
      "targets": {
        "browsers": ["> 1%", "last 2 versions", "not ie <= 8"]
      }
    }]
  ]
}
```

#### @babel/preset-react
JSX 문법을 `React.createElement()` 호출로 변환한다.
React 17+부터는 자동 런타임(`runtime: 'automatic'`)을 사용하면 `import React` 불필요.

```bash
npm install --save-dev @babel/preset-react
```

```js
// Before (JSX)
const element = <h1 className="title">Hello</h1>;

// After (변환 결과 - classic 런타임)
const element = React.createElement("h1", { className: "title" }, "Hello");

// After (변환 결과 - automatic 런타임, React 17+)
import { jsx as _jsx } from "react/jsx-runtime";
const element = _jsx("h1", { className: "title", children: "Hello" });
```

#### @babel/preset-typescript
TypeScript 타입 구문을 제거하여 순수 JavaScript로 변환한다.
(타입 검사는 수행하지 않음 - 타입 검사는 `tsc`의 역할)

---

## 5. .babelrc 설정 예시

### 기본 설정 (.babelrc 또는 babel.config.json)

```json
{
  "presets": [
    [
      "@babel/preset-env",
      {
        "targets": {
          "chrome": "80",
          "ie": "11"
        },
        "useBuiltIns": "usage",
        "corejs": 3,
        "modules": false
      }
    ],
    [
      "@babel/preset-react",
      {
        "runtime": "automatic"
      }
    ],
    "@babel/preset-typescript"
  ],
  "plugins": [
    "@babel/plugin-transform-class-properties",
    "@babel/plugin-syntax-dynamic-import"
  ],
  "env": {
    "test": {
      "presets": [
        ["@babel/preset-env", { "targets": { "node": "current" } }]
      ]
    }
  }
}
```

### .babelrc vs babel.config.json 차이

| 항목 | .babelrc | babel.config.json |
|------|----------|-------------------|
| **적용 범위** | 해당 파일이 위치한 패키지 내부만 | 프로젝트 전체 (모노레포 포함) |
| **node_modules** | 적용 안 됨 | 적용 가능 |
| **권장 사용** | 특정 패키지 전용 설정 | 프로젝트 전체 공통 설정 |

---

## 6. Transpile vs Polyfill

트랜스파일과 폴리필은 브라우저 호환성을 해결하는 서로 다른 방법이다.

### Transpile (트랜스파일)
**문법(syntax)** 을 변환한다. 새로운 문법을 구형 브라우저가 이해할 수 있는 동등한 코드로 바꾼다.

```js
// [Transpile 예시] 화살표 함수 → 일반 함수
// Before
const multiply = (a, b) => a * b;

// After (Babel 변환)
var multiply = function(a, b) { return a * b; };
```

```js
// [Transpile 예시] 클래스 → 프로토타입
// Before
class Animal {
  constructor(name) { this.name = name; }
  speak() { console.log(`${this.name} makes a sound.`); }
}

// After (Babel 변환)
function Animal(name) { this.name = name; }
Animal.prototype.speak = function() {
  console.log(this.name + " makes a sound.");
};
```

```js
// [Transpile 예시] 구조 분해 할당
// Before
const { a, b, ...rest } = obj;

// After
var _obj = obj,
    a = _obj.a,
    b = _obj.b,
    rest = _objectWithoutProperties(_obj, ["a", "b"]);
```

### Polyfill (폴리필)
**기능(feature)** 을 구현한다. 구형 브라우저에 존재하지 않는 빌트인 객체나 메서드를 코드로 구현하여 추가한다.

```js
// [Polyfill 예시] Array.prototype.includes가 없는 브라우저에 구현 추가
if (!Array.prototype.includes) {
  Array.prototype.includes = function(searchElement) {
    for (var i = 0; i < this.length; i++) {
      if (this[i] === searchElement) return true;
    }
    return false;
  };
}
```

```js
// [Polyfill이 필요한 기능들]
Promise           // IE 미지원
fetch             // IE 미지원
Array.from()      // IE 미지원
Object.assign()   // IE 미지원
Symbol            // IE 미지원
Map, Set          // IE 부분 지원
```

### 핵심 차이 요약

| 구분 | Transpile | Polyfill |
|------|-----------|----------|
| **대상** | 문법(Syntax) | 기능(Built-in API) |
| **방식** | 코드 변환 | 기능 구현 추가 |
| **예시** | 화살표 함수, 클래스, 템플릿 리터럴 | Promise, fetch, Array.from |
| **도구** | Babel, TypeScript | core-js, whatwg-fetch |
| **적용 시점** | 빌드 타임 | 런타임 (코드 상단에 import) |

---

## 7. core-js와 useBuiltIns 설정

### core-js
JavaScript 표준 빌트인의 폴리필 모음 라이브러리다.
`@babel/preset-env`와 함께 사용하면 타겟 환경에 맞는 폴리필만 자동으로 포함시킬 수 있다.

```bash
npm install --save core-js@3
```

### useBuiltIns 옵션

#### `"entry"` - 수동 진입점 방식
```js
// 설정
{
  "presets": [["@babel/preset-env", {
    "useBuiltIns": "entry",
    "corejs": 3
  }]]
}

// 코드 최상단에 직접 import 추가 (빌드 시 타겟에 맞게 확장됨)
import "core-js/stable";
import "regenerator-runtime/runtime";

// 빌드 후 결과 (타겟에 따라 필요한 폴리필만 개별 import로 확장)
import "core-js/modules/es.array.flat.js";
import "core-js/modules/es.promise.js";
// ...
```

#### `"usage"` - 자동 감지 방식 (권장)
```js
// 설정
{
  "presets": [["@babel/preset-env", {
    "useBuiltIns": "usage",
    "corejs": 3
  }]]
}

// 코드에서 사용된 기능을 자동으로 감지하여 필요한 폴리필만 주입
// 명시적 import 불필요

// 코드
const arr = [1, [2, 3]].flat();      // Array.flat 폴리필 자동 추가
const p = Promise.resolve(1);        // Promise 폴리필 자동 추가
```

#### `false` (기본값)
폴리필을 자동으로 주입하지 않는다. 직접 필요한 폴리필을 import해야 한다.

### browserslist 설정
```json
// package.json
{
  "browserslist": [
    "> 0.5%",
    "last 2 versions",
    "Firefox ESR",
    "not dead",
    "not IE 11"
  ]
}
```

```
# .browserslistrc
> 0.5%
last 2 versions
not dead
not IE 11
```

---

## 8. TypeScript 트랜스파일

TypeScript를 JavaScript로 변환하는 방법은 두 가지다.

### tsc (TypeScript Compiler)

Microsoft가 공식 제공하는 TypeScript 컴파일러다.

**특징**
- **타입 검사 수행**: 타입 오류를 빌드 단계에서 감지
- 느림: 전체 타입 시스템을 처리해야 함
- `tsconfig.json`으로 세밀한 설정 가능

```json
// tsconfig.json
{
  "compilerOptions": {
    "target": "ES2017",          // 출력 JavaScript 버전
    "module": "ESNext",          // 모듈 시스템
    "lib": ["ES2017", "DOM"],    // 사용 가능한 타입 라이브러리
    "strict": true,              // 엄격 모드 활성화
    "outDir": "./dist",
    "rootDir": "./src",
    "declaration": true,         // .d.ts 타입 선언 파일 생성
    "sourceMap": true,
    "moduleResolution": "node",
    "esModuleInterop": true,
    "skipLibCheck": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

### @babel/preset-typescript

Babel로 TypeScript를 처리하는 방식이다.

**특징**
- **타입 검사 미수행**: 타입 구문을 그냥 제거(strip)만 함
- 빠름: 타입 시스템 처리 없이 구문만 제거
- Babel의 기존 파이프라인에 통합 가능

```bash
npm install --save-dev @babel/preset-typescript
```

```json
// .babelrc
{
  "presets": [
    "@babel/preset-env",
    "@babel/preset-typescript"
  ]
}
```

### tsc vs @babel/preset-typescript 비교

| 항목 | tsc | @babel/preset-typescript |
|------|-----|--------------------------|
| **타입 검사** | O (빌드 시 타입 오류 감지) | X (타입 구문만 제거) |
| **변환 속도** | 느림 | 빠름 |
| **폴리필** | 별도 설정 필요 | @babel/preset-env와 통합 |
| **데코레이터** | 네이티브 지원 | 플러그인 필요 |
| **사용 추천** | 타입 안전성 중요 시 | 빌드 속도 중요, Webpack/Vite와 통합 시 |

### 실무 권장 패턴
빌드 속도와 타입 안전성 두 가지를 모두 얻으려면 다음을 함께 사용한다.

```json
// package.json
{
  "scripts": {
    "build": "webpack --config webpack.config.js",
    "type-check": "tsc --noEmit",           // 타입 검사만 수행 (파일 출력 없음)
    "type-check:watch": "tsc --noEmit --watch"
  }
}
```

- **Babel**: 빠른 트랜스파일 (빌드 파이프라인)
- **tsc --noEmit**: 타입 검사만 수행 (CI 또는 별도 스크립트)

---

## 9. 면접 포인트

### Q1. Babel의 동작 과정을 설명해주세요.

Babel은 **파싱(Parsing) → 변환(Transformation) → 코드 생성(Code Generation)** 3단계로 동작합니다.

1. **파싱**: `@babel/parser`가 소스 코드를 읽어 **AST(추상 구문 트리)** 로 변환합니다. 코드를 토큰으로 쪼개는 어휘 분석과, 토큰을 트리 구조로 만드는 구문 분석을 거칩니다.

2. **변환**: `@babel/traverse`가 AST를 순회하며 플러그인들이 각 노드를 방문하여 필요한 변환을 수행합니다. 예를 들어 `ArrowFunctionExpression` 노드를 `FunctionExpression` 노드로 교체합니다.

3. **코드 생성**: `@babel/generator`가 변환된 AST를 다시 JavaScript 코드 문자열로 변환하며, 소스맵도 이 단계에서 생성됩니다.

---

### Q2. Transpile과 Polyfill의 차이를 설명해주세요.

**Transpile**은 새로운 **문법(Syntax)** 을 구형 브라우저가 이해하는 동등한 문법으로 변환하는 것입니다. 빌드 타임에 소스 코드가 변환되며, 화살표 함수 → 일반 함수, 클래스 → 프로토타입, 템플릿 리터럴 → 문자열 연결 등이 해당됩니다.

**Polyfill**은 구형 브라우저에 존재하지 않는 **빌트인 객체나 메서드를 런타임에 구현하여 추가**하는 것입니다. `Promise`, `fetch`, `Array.from`, `Object.assign` 등 기능이 아예 없는 경우에 해당 기능을 JavaScript 코드로 직접 구현합니다.

핵심 차이: Transpile은 코드 형태를 바꾸고, Polyfill은 없는 기능을 만들어냅니다.

---

### Q3. @babel/preset-env에서 useBuiltIns: "usage"와 "entry"의 차이점은?

**"entry"**: 코드 최상단에 `import "core-js/stable"`을 직접 작성하면, Babel이 타겟 환경에서 필요한 모든 폴리필 import 구문으로 확장합니다. 실제 코드에서 사용 여부와 관계없이 타겟 환경에 필요한 전체 폴리필이 포함됩니다.

**"usage"**: 코드를 분석하여 실제로 사용된 기능에 대한 폴리필만 자동으로 주입합니다. 명시적 import가 필요 없고, 번들 크기를 더 작게 유지할 수 있어 일반적으로 권장됩니다.

---

### Q4. TypeScript를 tsc 대신 Babel로 변환하는 경우의 장단점은?

**장점**
- 빌드 속도가 빠릅니다. Babel은 타입을 무시하고 구문만 제거하기 때문입니다.
- 기존 Babel 파이프라인(`@babel/preset-env`, 폴리필 등)에 통합하기 쉽습니다.
- Webpack/Vite 등 번들러와의 통합이 자연스럽습니다.

**단점**
- **타입 검사를 하지 않습니다.** 타입 오류가 있어도 빌드가 통과됩니다.
- `const enum`, 일부 데코레이터 문법 등 tsc 전용 기능을 지원하지 않습니다.

**실무 패턴**: Babel로 빌드하고, `tsc --noEmit`을 CI 파이프라인이나 별도 스크립트로 실행하여 타입 검사와 빌드 속도를 모두 챙기는 방식을 많이 사용합니다.
