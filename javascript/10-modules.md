# 10. 모듈 시스템 (Modules)

## 목차
1. [모듈이란](#1-모듈이란)
2. [ESM (ES Modules)](#2-esm-es-modules)
3. [CJS (CommonJS)](#3-cjs-commonjs)
4. [ESM vs CJS 차이](#4-esm-vs-cjs-차이)
5. [동적 import()](#5-동적-import)
6. [Tree Shaking](#6-tree-shaking)
7. [번들러와의 관계](#7-번들러와의-관계)
8. [면접 포인트](#면접-포인트)

---

## 1. 모듈이란

**모듈**: 독립적인 파일 단위로 코드를 분리하여, 필요한 것만 내보내고(export) 필요한 것만 가져오는(import) 메커니즘.

**모듈이 없으면:**
- 전역 스코프 오염 (변수 충돌)
- 의존성 순서를 수동으로 관리
- 코드 재사용성 저하

---

## 2. ESM (ES Modules)

ES2015(ES6)에서 표준화된 공식 모듈 시스템.

### `export`

```js
// math.js

// 이름 있는 내보내기 (Named Export)
export const PI = 3.14159;

export function add(a, b) {
  return a + b;
}

export class Vector {
  constructor(x, y) {
    this.x = x;
    this.y = y;
  }
}

// 한 번에 내보내기
const subtract = (a, b) => a - b;
const multiply = (a, b) => a * b;
export { subtract, multiply };

// 이름 바꿔서 내보내기
export { subtract as minus, multiply as times };
```

```js
// config.js

// 기본 내보내기 (Default Export): 모듈당 하나만 가능
export default {
  apiUrl: 'https://api.example.com',
  timeout: 5000
};
```

### `import`

```js
// app.js

// Named Import
import { PI, add, Vector } from './math.js';

// 이름 바꿔서 가져오기
import { add as sum } from './math.js';

// 전체 가져오기 (네임스페이스)
import * as Math from './math.js';
console.log(Math.PI);   // 3.14159
console.log(Math.add(1, 2)); // 3

// Default Import (이름은 자유롭게)
import config from './config.js';
console.log(config.apiUrl);

// Default + Named 동시
import config, { PI, add } from './combined.js';
```

### ESM의 특성

```js
// ESM은 항상 strict mode
// 'use strict' 선언 불필요

// 최상위 await 지원 (Top-level await, ES2022)
const data = await fetch('/api/data').then(r => r.json());
export { data };

// import는 호이스팅됨 (선언 전에 사용 불가하지만 파일 상단으로 끌어올려짐)
// import 구문은 조건문/함수 안에 넣을 수 없음 (정적)
if (condition) {
  import { foo } from './foo.js'; // SyntaxError!
}
```

---

## 3. CJS (CommonJS)

Node.js의 기본 모듈 시스템. `require()`와 `module.exports`를 사용.

```js
// math.cjs

const PI = 3.14159;

function add(a, b) {
  return a + b;
}

function subtract(a, b) {
  return a - b;
}

// 내보내기
module.exports = { PI, add, subtract };

// 또는 개별 할당
exports.PI = PI;
exports.add = add;
// 주의: exports = { ... } 형태로 재할당하면 module.exports와 연결이 끊김!
```

```js
// app.cjs

// 가져오기 (동기)
const { PI, add } = require('./math.cjs');
const path = require('path'); // Node.js 내장 모듈

console.log(PI);        // 3.14159
console.log(add(1, 2)); // 3

// require는 함수 내 어디서든 호출 가능 (동적)
function loadPlugin(name) {
  const plugin = require(`./plugins/${name}`);
  return plugin;
}
```

### CJS의 캐싱

```js
// counter.cjs
let count = 0;
module.exports = {
  increment: () => ++count,
  getCount: () => count
};

// a.cjs
const counter = require('./counter');
counter.increment();
counter.increment();

// b.cjs
const counter = require('./counter'); // 캐시에서 같은 객체 반환
console.log(counter.getCount()); // 2 (a에서 수정한 상태 유지)
```

---

## 4. ESM vs CJS 차이

| 구분 | ESM | CJS |
|------|-----|-----|
| 문법 | `import` / `export` | `require()` / `module.exports` |
| 로딩 방식 | **정적** (빌드 타임에 분석) | **동적** (런타임에 실행) |
| 실행 | 비동기 파싱 | 동기 실행 |
| `this` (최상위) | `undefined` | `module.exports` |
| 파일 확장자 | `.mjs` 또는 `"type": "module"` | `.cjs` 또는 기본 `.js` |
| 순환 참조 | 라이브 바인딩 (Live Binding) | 값의 복사본 |
| Tree Shaking | 가능 (정적 분석) | 어려움 |
| 브라우저 지원 | 네이티브 지원 | 번들러 필요 |

### 순환 참조 차이

```js
// ESM 순환 참조: 라이브 바인딩
// a.mjs
import { b } from './b.mjs';
export const a = 'A';
console.log(b); // 'B' - 초기화 후 실행되므로 정상

// b.mjs
import { a } from './a.mjs';
export const b = 'B';
console.log(a); // 'A'
```

```js
// CJS 순환 참조: 부분적으로 초기화된 객체를 받을 수 있음
// a.cjs
const { b } = require('./b.cjs');
console.log(b); // undefined - b가 아직 초기화 안 됨
module.exports.a = 'A';

// b.cjs
const { a } = require('./a.cjs');
module.exports.b = 'B';
console.log(a); // undefined
```

---

## 5. 동적 import()

ESM에서 **런타임에** 모듈을 불러오는 방법. Promise를 반환한다.

```js
// 조건부 로드
async function loadFeature(featureName) {
  if (featureName === 'chart') {
    // 해당 기능이 필요할 때만 로드
    const { Chart } = await import('./Chart.js');
    return new Chart();
  }
}

// 라우트 기반 코드 분할 (React Router 예시)
const routes = [
  {
    path: '/dashboard',
    component: () => import('./pages/Dashboard.js')
  },
  {
    path: '/settings',
    component: () => import('./pages/Settings.js')
  }
];

// 사용자 액션에 따른 지연 로드
button.addEventListener('click', async () => {
  const { default: HeavyModule } = await import('./HeavyModule.js');
  HeavyModule.doSomething();
});
```

### 동적 import()의 반환 구조

```js
// Named Export
const { foo, bar } = await import('./module.js');

// Default Export
const { default: MyClass } = await import('./MyClass.js');
// 또는
const module = await import('./MyClass.js');
const MyClass = module.default;

// 에러 처리
try {
  const module = await import('./optional.js');
  module.init();
} catch (err) {
  console.warn('모듈 로드 실패, 기본 동작으로 진행');
}
```

---

## 6. Tree Shaking

**Tree Shaking**: 번들링 시 사용하지 않는 코드(dead code)를 제거하는 최적화.

ESM의 정적 구조 덕분에 가능하다.

```js
// utils.js (ESM)
export function add(a, b) { return a + b; }
export function subtract(a, b) { return a - b; }
export function multiply(a, b) { return a * b; }
export function heavyFunction() {
  // 1만 줄의 복잡한 로직
}

// app.js
import { add } from './utils.js'; // add만 사용
console.log(add(1, 2));

// 번들 결과: subtract, multiply, heavyFunction은 제외됨
```

### Tree Shaking이 제대로 동작하려면

```js
// 1. ESM을 사용해야 함 (CJS는 동적이라 분석 불가)
// Bad: CJS
const utils = require('./utils'); // 전체 모듈이 포함됨

// Good: ESM
import { add } from './utils.js'; // 사용한 것만 포함

// 2. 사이드 이펙트가 없어야 함
// package.json
{
  "sideEffects": false  // 모든 파일이 사이드 이펙트 없음을 선언
  // 또는 특정 파일만 제외
  "sideEffects": ["./src/polyfills.js", "*.css"]
}

// 3. 배럴 파일(barrel file) 주의
// index.js (배럴 파일)
export { foo } from './foo.js';
export { bar } from './bar.js';
export { baz } from './baz.js'; // 대형 라이브러리

// app.js
import { foo } from './index.js'; // baz 전체가 번들에 포함될 수 있음
// 직접 import가 더 안전
import { foo } from './foo.js';
```

---

## 7. 번들러와의 관계

번들러(Webpack, Rollup, Vite, esbuild 등)는 여러 모듈 파일을 하나(또는 여러)의 파일로 합친다.

```
소스 파일                번들러                  번들 결과
app.js      ─┐
utils.js    ─┤  Webpack   →   bundle.js (최적화된 단일 파일)
api.js      ─┤  Rollup
styles.css  ─┘  Vite
```

### Vite의 모듈 처리

```js
// vite.config.js
export default {
  build: {
    rollupOptions: {
      output: {
        // 코드 분할 설정
        manualChunks: {
          vendor: ['react', 'react-dom'],    // 외부 라이브러리 분리
          utils: ['./src/utils/index.js']    // 유틸 분리
        }
      }
    }
  }
};
```

### 모듈 시스템 상호운용

```js
// Node.js에서 ESM과 CJS 혼용
// package.json에서 type 설정
{
  "type": "module"  // .js 파일을 ESM으로 처리
}

// ESM에서 CJS 모듈 가져오기
import cjsModule from './legacy.cjs'; // default import로만 가능

// CJS에서 ESM 모듈 가져오기 (require 불가!)
// 반드시 동적 import 사용
const esmModule = await import('./modern.mjs');
```

---

## 면접 포인트

**Q. ESM과 CJS의 가장 큰 차이는?**
> ESM은 **정적** 구조로, 빌드 타임에 의존성 그래프를 분석할 수 있어 Tree Shaking이 가능하다. CJS는 `require()`가 런타임에 실행되는 **동적** 방식으로 조건부/동적 로딩이 가능하지만 Tree Shaking이 어렵다. ESM은 비동기 파싱, CJS는 동기 실행이다.

**Q. Tree Shaking이란 무엇이고 어떻게 가능한가요?**
> 사용하지 않는 코드를 번들에서 제거하는 최적화 기법이다. ESM의 `import/export`가 정적으로 분석 가능하기 때문에 가능하다. 번들러가 어떤 export가 실제로 사용되는지 파악해 나머지를 제거한다. CJS의 `require()`는 런타임에 실행되어 정적 분석이 불가하다.

**Q. 동적 `import()`는 언제 사용하나요?**
> (1) 조건에 따라 다른 모듈을 로드할 때, (2) 초기 번들 크기를 줄이기 위한 코드 분할(lazy loading), (3) React Router의 라우트 기반 분할, (4) 사용자 액션에 의해 필요해진 무거운 기능 로드. Promise를 반환하므로 `await`와 함께 사용한다.

**Q. `export default` vs `export`의 차이는?**
> `export default`는 모듈당 하나만 가능하고 가져올 때 이름을 자유롭게 지정할 수 있다. Named export(`export`)는 여러 개 가능하고 `{ }` 문법으로 이름을 맞춰 가져와야 한다. 라이브러리 작성 시 Named export가 Tree Shaking에 유리하다.

**Q. `package.json`의 `"sideEffects": false`는 무슨 의미인가요?**
> 해당 패키지의 모든 파일이 import 시 부수 효과(전역 변수 수정, 폴리필 적용 등)가 없음을 번들러에게 알린다. 이 정보를 바탕으로 번들러가 더 적극적으로 Tree Shaking을 수행할 수 있다. 전역 CSS나 폴리필 파일은 배열로 예외 처리해야 한다.
