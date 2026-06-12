# 2. 유틸리티 라이브러리

## 목차

1. [lodash-es: 자주 쓰는 함수들](#1-lodash-es-자주-쓰는-함수들)
2. [Tree-shaking: 개별 import vs 전체 import](#2-tree-shaking-개별-import-vs-전체-import)
3. [네이티브 JS로 대체 가능한 것들](#3-네이티브-js로-대체-가능한-것들)
4. [Ramda: 함수형 프로그래밍](#4-ramda-함수형-프로그래밍)
5. [유틸 함수 직접 구현 vs 라이브러리 판단 기준](#5-유틸-함수-직접-구현-vs-라이브러리-판단-기준)
6. [면접 포인트](#6-면접-포인트)

---

## 1. lodash-es: 자주 쓰는 함수들

ES Module 버전 lodash. Tree-shaking 지원.

```bash
npm install lodash-es
npm install --save-dev @types/lodash-es
```

### 함수 & 성능

```js
import { debounce, throttle } from 'lodash-es';

// debounce: 마지막 호출 후 N ms 뒤에 실행 (검색 입력)
const handleSearch = debounce((query) => {
  fetch(`/api/search?q=${query}`);
}, 300);

// throttle: N ms에 한 번만 실행 (스크롤, 리사이즈)
const handleScroll = throttle(() => {
  console.log('scroll position:', window.scrollY);
}, 100);

// React에서 사용 시 useMemo/useCallback으로 래핑
import { useMemo } from 'react';
const debouncedSearch = useMemo(
  () => debounce(handleSearch, 300),
  []
);
```

### 객체 복사 & 변환

```js
import { cloneDeep, pick, omit, merge } from 'lodash-es';

// cloneDeep: 중첩 객체 깊은 복사
const original = { a: { b: { c: 1 } } };
const copy = cloneDeep(original);
copy.a.b.c = 999;
console.log(original.a.b.c); // 1 (영향 없음)

// pick: 특정 키만 선택
const user = { id: 1, name: '홍길동', password: 'secret', role: 'admin' };
const safeUser = pick(user, ['id', 'name']); // { id: 1, name: '홍길동' }

// omit: 특정 키 제외
const withoutPw = omit(user, ['password']); // password 제외

// merge: 깊은 병합 (Object.assign은 얕은 복사)
const defaults = { theme: { color: 'blue', size: 'md' }, lang: 'ko' };
const userPrefs = { theme: { color: 'red' } };
const merged = merge({}, defaults, userPrefs);
// { theme: { color: 'red', size: 'md' }, lang: 'ko' }
```

### 배열 & 컬렉션

```js
import { groupBy, keyBy, uniqBy, sortBy, chunk, flatten, flatMap } from 'lodash-es';

const users = [
  { id: 1, name: '홍길동', dept: '개발', age: 30 },
  { id: 2, name: '김철수', dept: '디자인', age: 25 },
  { id: 3, name: '이영희', dept: '개발', age: 28 },
];

// groupBy: 키 기준 그룹핑
groupBy(users, 'dept');
// { 개발: [...], 디자인: [...] }

// keyBy: id → 객체 맵 변환 (O(1) 조회)
const userMap = keyBy(users, 'id');
// { 1: { id:1, ... }, 2: { id:2, ... } }

// uniqBy: 특정 키 기준 중복 제거
const unique = uniqBy([...users, users[0]], 'id');

// sortBy: 정렬 (여러 기준 가능)
sortBy(users, ['dept', 'age']);

// chunk: 배열 분할 (페이지네이션 등)
chunk([1, 2, 3, 4, 5], 2); // [[1,2],[3,4],[5]]
```

---

## 2. Tree-shaking: 개별 import vs 전체 import

```js
// BAD: 전체 import — 번들에 lodash 전체 포함 (~70KB)
import _ from 'lodash';
_.debounce(fn, 300);

// BAD: lodash (CJS 버전) — tree-shaking 안 됨
import { debounce } from 'lodash';

// GOOD: lodash-es — ES Module, tree-shaking 지원
import { debounce } from 'lodash-es';

// GOOD: 개별 패키지 (CJS 환경에서도 최적화)
import debounce from 'lodash/debounce';
```

### 번들 크기 비교 (예시)

| import 방식 | 번들 크기 |
|------------|---------|
| `import _ from 'lodash'` | ~70KB (전체) |
| `import { debounce } from 'lodash'` | ~70KB (tree-shaking 안 됨) |
| `import { debounce } from 'lodash-es'` | ~2KB (debounce만) |
| `import debounce from 'lodash/debounce'` | ~2KB |

---

## 3. 네이티브 JS로 대체 가능한 것들

모던 JS(ES2019+)로 lodash 없이 처리 가능한 케이스.

```js
// flatten → Array.prototype.flat()
[1, [2, [3]]].flat();      // [1, 2, [3]]
[1, [2, [3]]].flat(Infinity); // [1, 2, 3]

// uniq → Set
const unique = [...new Set([1, 2, 2, 3])]; // [1, 2, 3]

// compact (falsy 제거) → filter
[0, 1, false, 2, null, 3].filter(Boolean); // [1, 2, 3]

// last
const arr = [1, 2, 3];
arr.at(-1); // 3 (ES2022)

// isEmpty
Object.keys(obj).length === 0;
arr.length === 0;

// range
Array.from({ length: 5 }, (_, i) => i); // [0,1,2,3,4]

// pick (네이티브)
const pick = (obj, keys) =>
  Object.fromEntries(keys.map(k => [k, obj[k]]));

// omit (네이티브)
const omit = (obj, keys) => {
  const { [keys[0]]: _, ...rest } = obj;
  return rest;
};
// 또는
const omit = (obj, keys) =>
  Object.fromEntries(Object.entries(obj).filter(([k]) => !keys.includes(k)));

// cloneDeep 대안 (단순 구조)
const clone = JSON.parse(JSON.stringify(obj)); // 함수, Date, undefined 불가
const clone2 = structuredClone(obj); // ES2022, 대부분 타입 지원
```

---

## 4. Ramda: 함수형 프로그래밍

커링(currying)과 합성(composition)에 특화된 함수형 라이브러리.

```bash
npm install ramda
npm install --save-dev @types/ramda
```

### 커링과 합성

```js
import * as R from 'ramda';

// 모든 Ramda 함수는 자동 커링
const add = R.add;
const add5 = add(5);   // 부분 적용
add5(3);               // 8

// pipe: 왼쪽 → 오른쪽 합성
const process = R.pipe(
  R.filter(x => x > 0),
  R.map(x => x * 2),
  R.sum
);
process([-1, 1, 2, 3]); // (1+2+3)*2 = 12

// compose: 오른쪽 → 왼쪽 합성
const process2 = R.compose(R.sum, R.map(x => x * 2), R.filter(x => x > 0));

// 데이터는 항상 마지막 인자
const getAdults = R.filter(R.propSatisfies(age => age >= 18, 'age'));
getAdults(users);
```

### 실용 예제

```js
import * as R from 'ramda';

const users = [
  { id: 1, name: '홍길동', score: 85, active: true },
  { id: 2, name: '김철수', score: 92, active: false },
  { id: 3, name: '이영희', score: 78, active: true },
];

// 활성 유저의 이름만 추출 (점수 높은 순)
const getActiveNames = R.pipe(
  R.filter(R.prop('active')),
  R.sortBy(R.prop('score')),
  R.reverse,
  R.map(R.prop('name'))
);
getActiveNames(users); // ['홍길동', '이영희']

// lens: 불변 객체 업데이트
const nameLens = R.lensProp('name');
const updated = R.set(nameLens, '새이름', users[0]);
// users[0]은 변경되지 않음
```

---

## 5. 유틸 함수 직접 구현 vs 라이브러리 판단 기준

### 라이브러리 사용이 유리한 경우

- 복잡한 엣지 케이스 처리가 필요할 때 (debounce의 leading/trailing 옵션 등)
- 팀원 모두 이미 알고 있는 API일 때
- 성능 최적화가 이미 되어 있을 때 (lodash의 각종 최적화)

### 직접 구현이 유리한 경우

```js
// 간단한 한 줄 코드는 직접 구현
// 라이브러리 import 비용(번들 크기) > 직접 구현 비용

// PREFER: 직접 구현
const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

const clamp = (val, min, max) => Math.min(Math.max(val, min), max);

const capitalize = (str) => str.charAt(0).toUpperCase() + str.slice(1);

// 특수한 비즈니스 로직에는 직접 구현
const formatKoreanPhone = (phone) =>
  phone.replace(/(\d{3})(\d{4})(\d{4})/, '$1-$2-$3');
```

### 판단 체크리스트

| 기준 | 라이브러리 | 직접 구현 |
|------|-----------|---------|
| 코드 복잡도 | 높음 | 낮음 (5줄 이하) |
| 엣지 케이스 | 많음 | 단순함 |
| 번들 크기 영향 | 감수 가능 | 최소화 필요 |
| 팀 친숙도 | 높음 | 낮음 |
| 유지보수 주체 | 오픈소스 커뮤니티 | 팀 |

---

## 6. 면접 포인트

**Q. lodash vs lodash-es의 차이는?**
> `lodash`는 CommonJS 형식이라 Webpack/Rollup의 tree-shaking이 제한적입니다. `lodash-es`는 ES Module 형식이라 번들러가 실제로 사용하는 함수만 포함할 수 있습니다. Vite, Rollup 같은 현대 번들러를 사용한다면 `lodash-es`를 권장합니다.

**Q. debounce와 throttle의 차이는?**
> `debounce`는 마지막 호출 이후 N ms가 지나야 실행됩니다(검색 입력처럼 "입력이 멈추면 실행"). `throttle`은 N ms에 최대 1번만 실행됩니다(스크롤 이벤트처럼 "주기적으로 한 번씩"). React에서 두 함수 모두 `useMemo`나 `useCallback`으로 감싸야 리렌더링 시 재생성을 막을 수 있습니다.

**Q. cloneDeep 대신 structuredClone을 쓸 수 있는가?**
> `structuredClone`(ES2022)은 브라우저 내장 API로 lodash 없이 깊은 복사가 가능합니다. Map, Set, Date, ArrayBuffer도 지원합니다. 단, 함수, Symbol, DOM 노드는 복사할 수 없습니다. 모던 브라우저와 Node.js 17+에서 지원됩니다.

**Q. 함수형 라이브러리(Ramda)를 쓰는 장점은?**
> 자동 커링으로 부분 적용이 쉽고, `pipe`/`compose`로 선언적 데이터 변환 파이프라인을 구성할 수 있습니다. 부수 효과(side effect)가 없는 순수 함수 위주라 테스트하기 쉽습니다. 다만 팀 전체가 함수형 패러다임에 익숙해야 코드 가독성이 높아집니다.
