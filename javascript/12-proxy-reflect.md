# 12. Proxy와 Reflect

## 목차
1. [Proxy란](#1-proxy란)
2. [기본 트랩 (get, set, has)](#2-기본-트랩-get-set-has)
3. [Reflect API](#3-reflect-api)
4. [메타 프로그래밍 활용 예시](#4-메타-프로그래밍-활용-예시)
5. [Proxy의 한계와 주의사항](#5-proxy의-한계와-주의사항)
6. [면접 포인트](#면접-포인트)

---

## 1. Proxy란

**Proxy**: 다른 객체에 대한 **중간자(프록시)** 역할을 하는 객체. 대상 객체에 대한 기본 동작(읽기, 쓰기, 함수 호출 등)을 **가로채(intercept)** 커스텀 로직을 실행할 수 있다.

```js
const proxy = new Proxy(target, handler);
```

- `target`: 감싸는 원본 객체 (배열, 함수, 다른 프록시도 가능)
- `handler`: 트랩(trap)을 정의하는 객체. 트랩이 없으면 원본에 그대로 전달

```js
const obj = { name: 'Alice' };

const proxy = new Proxy(obj, {});  // 핸들러 없음 = 투명한 래퍼
proxy.name = 'Bob';
console.log(obj.name); // 'Bob' - 원본 객체에 반영됨
```

### 사용 가능한 트랩 목록

| 트랩 | 가로채는 동작 |
|------|-------------|
| `get` | 프로퍼티 읽기 |
| `set` | 프로퍼티 쓰기 |
| `has` | `in` 연산자 |
| `deleteProperty` | `delete` 연산자 |
| `apply` | 함수 호출 |
| `construct` | `new` 연산자 |
| `getPrototypeOf` | `Object.getPrototypeOf()` |
| `ownKeys` | `Object.keys()`, `for...in` |
| `defineProperty` | `Object.defineProperty()` |
| `getOwnPropertyDescriptor` | `Object.getOwnPropertyDescriptor()` |

---

## 2. 기본 트랩 (get, set, has)

### `get` 트랩

프로퍼티 접근 시 호출된다.

```js
const handler = {
  get(target, prop, receiver) {
    // target: 원본 객체
    // prop: 접근하는 프로퍼티 이름 (문자열 또는 Symbol)
    // receiver: proxy 자신 (또는 프록시를 상속한 객체)

    console.log(`[get] ${String(prop)}`);

    if (prop in target) {
      return Reflect.get(target, prop, receiver);
    }
    // 존재하지 않는 프로퍼티 접근 시 에러 대신 기본값 반환
    return `${String(prop)} 프로퍼티가 없습니다.`;
  }
};

const user = new Proxy({ name: 'Alice', age: 30 }, handler);

console.log(user.name);    // '[get] name', 'Alice'
console.log(user.email);   // '[get] email', 'email 프로퍼티가 없습니다.'
```

### `set` 트랩

프로퍼티 쓰기 시 호출된다. 반드시 `true`(성공) 또는 `false`(실패) 반환.

```js
const handler = {
  set(target, prop, value, receiver) {
    console.log(`[set] ${String(prop)} = ${value}`);

    // 유효성 검사
    if (prop === 'age') {
      if (typeof value !== 'number') throw new TypeError('나이는 숫자여야 합니다.');
      if (value < 0 || value > 150) throw new RangeError('나이는 0~150 사이여야 합니다.');
    }

    return Reflect.set(target, prop, value, receiver); // true 반환
  }
};

const user = new Proxy({}, handler);

user.name = 'Alice'; // '[set] name = Alice'
user.age = 30;       // '[set] age = 30'
user.age = -1;       // RangeError: 나이는 0~150 사이여야 합니다.
user.age = 'old';    // TypeError: 나이는 숫자여야 합니다.
```

### `has` 트랩

`in` 연산자 사용 시 호출된다.

```js
// 범위 객체: in 연산자로 범위 확인
function makeRange(min, max) {
  return new Proxy({}, {
    has(target, prop) {
      const num = Number(prop);
      return num >= min && num <= max;
    }
  });
}

const range = makeRange(1, 100);
console.log(50 in range);  // true
console.log(150 in range); // false
console.log(1 in range);   // true

// 실용 예: 허용된 값 목록
const allowedRoles = new Proxy(
  { admin: true, editor: true, viewer: true },
  {
    has(target, prop) {
      return prop in target;
    }
  }
);

console.log('admin' in allowedRoles); // true
console.log('hacker' in allowedRoles); // false
```

### `deleteProperty` 트랩

```js
const protectedObj = new Proxy(
  { public: 'anyone', _private: 'secret' },
  {
    deleteProperty(target, prop) {
      if (prop.startsWith('_')) {
        throw new Error(`프라이빗 프로퍼티 "${prop}"는 삭제할 수 없습니다.`);
      }
      return Reflect.deleteProperty(target, prop);
    }
  }
);

delete protectedObj.public;  // 성공
delete protectedObj._private; // Error: 프라이빗 프로퍼티 "_private"는 삭제할 수 없습니다.
```

---

## 3. Reflect API

`Reflect`는 객체의 기본 동작을 수행하는 정적 메서드들의 모음이다. Proxy의 트랩과 1:1 대응한다.

### 왜 Reflect를 사용하는가?

```js
// 문제: 트랩 내에서 원본 동작을 수행할 때
const handler = {
  get(target, prop, receiver) {
    // 방법 1: 직접 접근 (this 바인딩 문제 발생 가능)
    return target[prop];

    // 방법 2: Reflect 사용 (receiver가 올바르게 전달됨)
    return Reflect.get(target, prop, receiver); // 권장
  }
};
```

```js
// receiver의 중요성: 상속 관계에서의 this
const parent = {
  get value() { return this.x; }
};

const child = { x: 42 };
Object.setPrototypeOf(child, parent);

const proxyChild = new Proxy(child, {
  get(target, prop, receiver) {
    // receiver = proxyChild
    return Reflect.get(target, prop, receiver); // this = proxyChild → x = 42
    // target[prop]을 쓰면 this = target(child)로 바인딩됨
  }
});

console.log(proxyChild.value); // 42
```

### Reflect 메서드 목록

```js
Reflect.get(target, prop, receiver)            // target[prop]
Reflect.set(target, prop, value, receiver)     // target[prop] = value
Reflect.has(target, prop)                      // prop in target
Reflect.deleteProperty(target, prop)           // delete target[prop]
Reflect.ownKeys(target)                        // Object.keys + symbols
Reflect.apply(target, thisArg, args)           // target.apply(thisArg, args)
Reflect.construct(target, args, newTarget)     // new target(...args)
Reflect.defineProperty(target, prop, desc)    // Object.defineProperty
Reflect.getOwnPropertyDescriptor(target, prop)
Reflect.getPrototypeOf(target)
Reflect.setPrototypeOf(target, proto)
Reflect.isExtensible(target)
Reflect.preventExtensions(target)
```

---

## 4. 메타 프로그래밍 활용 예시

### 4-1. 유효성 검사 (Validation)

```js
function createValidator(target, validators) {
  return new Proxy(target, {
    set(obj, prop, value) {
      if (prop in validators) {
        const { type, min, max, required } = validators[prop];

        if (required && (value === null || value === undefined)) {
          throw new Error(`${prop}은 필수 항목입니다.`);
        }
        if (type && typeof value !== type) {
          throw new TypeError(`${prop}은 ${type} 타입이어야 합니다.`);
        }
        if (min !== undefined && value < min) {
          throw new RangeError(`${prop}은 최솟값 ${min} 이상이어야 합니다.`);
        }
        if (max !== undefined && value > max) {
          throw new RangeError(`${prop}은 최댓값 ${max} 이하여야 합니다.`);
        }
      }
      return Reflect.set(obj, prop, value);
    }
  });
}

const user = createValidator({}, {
  name:   { type: 'string', required: true },
  age:    { type: 'number', min: 0, max: 150 },
  email:  { type: 'string' }
});

user.name = 'Alice';    // 성공
user.age = 30;          // 성공
user.age = -1;          // RangeError: age은 최솟값 0 이상이어야 합니다.
user.name = 123;        // TypeError: name은 string 타입이어야 합니다.
```

### 4-2. 반응형 시스템 원리 (Vue 3의 reactivity)

```js
// 간단한 반응형 시스템 구현
function reactive(obj) {
  const listeners = new Map(); // 프로퍼티 → 콜백 목록

  const proxy = new Proxy(obj, {
    get(target, prop, receiver) {
      // 현재 실행 중인 이펙트를 추적 (의존성 수집)
      if (currentEffect) {
        if (!listeners.has(prop)) listeners.set(prop, new Set());
        listeners.get(prop).add(currentEffect);
      }
      return Reflect.get(target, prop, receiver);
    },
    set(target, prop, value, receiver) {
      const result = Reflect.set(target, prop, value, receiver);
      // 값이 변경되면 해당 프로퍼티를 사용하는 이펙트 재실행
      if (listeners.has(prop)) {
        listeners.get(prop).forEach(effect => effect());
      }
      return result;
    }
  });

  return proxy;
}

let currentEffect = null;

function effect(fn) {
  currentEffect = fn;
  fn(); // 처음 실행: 의존성 수집
  currentEffect = null;
}

// 사용 예
const state = reactive({ count: 0, name: 'Alice' });

effect(() => {
  console.log(`카운트: ${state.count}`); // count에 의존성 등록
});
// '카운트: 0' (초기 실행)

state.count = 1; // '카운트: 1' (자동 재실행)
state.count = 2; // '카운트: 2' (자동 재실행)
state.name = 'Bob'; // 아무것도 출력 안 됨 (count 이펙트는 name에 의존 없음)
```

### 4-3. 읽기 전용 객체

```js
function readonly(obj) {
  return new Proxy(obj, {
    set(target, prop) {
      console.warn(`[readonly] "${String(prop)}" 수정 시도가 차단되었습니다.`);
      return false; // strict mode에서 TypeError 발생
    },
    deleteProperty(target, prop) {
      console.warn(`[readonly] "${String(prop)}" 삭제 시도가 차단되었습니다.`);
      return false;
    },
    get(target, prop, receiver) {
      const value = Reflect.get(target, prop, receiver);
      // 중첩 객체도 readonly로 감쌈
      if (typeof value === 'object' && value !== null) {
        return readonly(value);
      }
      return value;
    }
  });
}

const config = readonly({ host: 'localhost', db: { port: 5432 } });
config.host = 'remote';       // 경고 출력, 변경 안 됨
config.db.port = 9999;        // 중첩 객체도 보호
console.log(config.host);     // 'localhost'
```

### 4-4. 로깅 / 프로파일링

```js
function createLoggingProxy(obj, name = 'Object') {
  return new Proxy(obj, {
    get(target, prop, receiver) {
      const value = Reflect.get(target, prop, receiver);
      if (typeof value === 'function') {
        return function(...args) {
          console.log(`[${name}] ${String(prop)} 호출 (args: ${JSON.stringify(args)})`);
          const start = performance.now();
          const result = value.apply(this, args);
          const end = performance.now();
          console.log(`[${name}] ${String(prop)} 완료 (${(end - start).toFixed(2)}ms)`);
          return result;
        };
      }
      return value;
    }
  });
}

const api = createLoggingProxy({
  fetchUser(id) {
    // 실제 API 호출 시뮬레이션
    return { id, name: 'Alice' };
  }
}, 'API');

api.fetchUser(1);
// [API] fetchUser 호출 (args: [1])
// [API] fetchUser 완료 (0.05ms)
```

---

## 5. Proxy의 한계와 주의사항

```js
// 1. 내장 객체(Map, Set, Date)는 내부 슬롯(Internal Slot) 때문에 주의
const map = new Map();
const proxy = new Proxy(map, {});
proxy.set('key', 'value'); // TypeError: Method Map.prototype.set called on incompatible receiver

// 해결: get 트랩에서 this 바인딩
const mapProxy = new Proxy(map, {
  get(target, prop, receiver) {
    const value = Reflect.get(target, prop, receiver);
    return typeof value === 'function' ? value.bind(target) : value;
  }
});
mapProxy.set('key', 'value'); // 정상 동작

// 2. Proxy는 취소(revoke)할 수 있음
const { proxy: revocable, revoke } = Proxy.revocable({ name: 'Alice' }, {});
console.log(revocable.name); // 'Alice'
revoke();
console.log(revocable.name); // TypeError: Cannot perform 'get' on a proxy that has been revoked

// 3. 성능: 모든 접근이 트랩을 거치므로 Hot Path에는 주의
// 4. 디버깅: 트랩 내부를 추적하기 어려울 수 있음
```

---

## 면접 포인트

**Q. Proxy란 무엇이고 어떻게 사용하나요?**
> Proxy는 대상 객체의 기본 동작(읽기, 쓰기, 열거 등)을 가로채는 래퍼 객체다. `new Proxy(target, handler)`로 생성하며, handler에 트랩을 정의한다. 유효성 검사, 로깅, 반응형 시스템, 접근 제어 등에 활용한다.

**Q. Reflect API는 왜 필요한가요?**
> 트랩 내에서 원본 동작을 올바르게 수행하기 위해서다. `target[prop]` 직접 접근은 `receiver`(프록시 자신) 바인딩을 놓칠 수 있다. `Reflect.get(target, prop, receiver)`는 getter의 `this`를 receiver로 올바르게 바인딩한다. Proxy 트랩과 Reflect 메서드는 1:1 대응한다.

**Q. Vue 3의 반응형 시스템과 Proxy의 관계는?**
> Vue 2는 `Object.defineProperty`로 반응성을 구현했는데, 이는 초기화 시 알려진 프로퍼티만 감지하고 배열 변이를 완벽히 처리하지 못했다. Vue 3는 Proxy로 전환하여 동적 프로퍼티 추가/삭제, 배열 인덱스 변경, `Map/Set` 등도 감지할 수 있게 되었다.

**Q. Proxy의 `get` 트랩에서 `target[prop]` 대신 `Reflect.get(target, prop, receiver)`를 써야 하는 이유는?**
> 상속(프로토타입 체인)이 있을 때 getter 함수의 `this`가 올바르게 바인딩되어야 하기 때문이다. `target[prop]`은 항상 `target`을 `this`로 사용하지만, `Reflect.get(target, prop, receiver)`는 getter의 `this`를 receiver(프록시 또는 상속받은 객체)로 지정한다.

**Q. Proxy로 구현할 수 없는 것은?**
> `Map`, `Set`, `Date`, `Promise` 등 내부 슬롯(`[[MapData]]` 등)에 의존하는 내장 객체는 `this` 바인딩 문제가 발생한다. `.bind(target)` 패턴으로 우회할 수 있다. 또한 Proxy는 취소(revoke)하지 않는 이상 메모리에서 원본과 함께 유지되어 GC 최적화에 영향을 줄 수 있다.
