# 04. 실행 컨텍스트

## 목차
1. [실행 컨텍스트란](#1-실행-컨텍스트란)
2. [구성 요소](#2-구성-요소)
3. [생성과 실행 과정](#3-생성과-실행-과정)
4. [`this` 바인딩](#4-this-바인딩)
5. [면접 포인트](#면접-포인트)

---

## 1. 실행 컨텍스트란

**코드가 실행되는 환경(컨텍스트)**. JS 엔진이 코드를 실행하기 위해 필요한 정보를 담는 객체다.

3가지 종류:
- **전역 실행 컨텍스트(GEC)**: 파일 로드 시 생성, 1개만 존재
- **함수 실행 컨텍스트(FEC)**: 함수 호출마다 생성
- **eval 실행 컨텍스트**: `eval()` 함수 (사용 지양)

---

## 2. 구성 요소

```
실행 컨텍스트 (ES2015+)
├── LexicalEnvironment (렉시컬 환경)
│   ├── EnvironmentRecord (식별자 바인딩 기록)
│   │   ├── let, const, 함수 선언식
│   │   └── outer (외부 렉시컬 환경 참조 → 스코프 체인)
│   └── ThisBinding (현재 this 값)
└── VariableEnvironment (변수 환경)
    └── EnvironmentRecord: var 선언 기록
```

> LexicalEnvironment와 VariableEnvironment는 초기에 동일하지만, `let`/`const`는 LexicalEnvironment에, `var`는 VariableEnvironment에 기록된다.

---

## 3. 생성과 실행 과정

실행 컨텍스트는 **2단계**로 동작한다.

### 1단계: 생성(Creation) 단계
코드를 실행하기 전에 먼저 스캔.

```js
function foo(a) {
  var b = 2;
  function bar() {}
  let c = 3;
}

foo(1);
```

`foo` 호출 시 EC 생성:
```
foo EC {
  LexicalEnvironment: {
    EnvironmentRecord: {
      a: 1,          // 매개변수
      bar: function, // 함수 선언식 → 즉시 참조 저장
      c: <TDZ>       // let → TDZ 상태
    },
    outer: 전역 EC
  },
  VariableEnvironment: {
    EnvironmentRecord: {
      b: undefined   // var → undefined로 초기화 (호이스팅)
    }
  }
}
```

### 2단계: 실행(Execution) 단계
코드를 위에서부터 순서대로 실행, 값 할당.

```
b: undefined → b: 2
c: <TDZ>     → c: 3
```

### 콜스택에서의 동작

```js
const x = 1;

function outer() {
  const y = 2;
  function inner() {
    const z = 3;
    console.log(x, y, z);
  }
  inner();
}

outer();
```

```
실행 흐름:
1. 전역 EC 생성 → 콜스택에 push
2. outer() 호출 → outer EC 생성 → push
3. inner() 호출 → inner EC 생성 → push
4. inner 종료 → inner EC pop
5. outer 종료 → outer EC pop
6. 프로그램 종료 → 전역 EC pop

콜스택:
│ inner EC │
│ outer EC │
│ 전역 EC  │
└──────────┘
```

---

## 4. `this` 바인딩

`this`는 **어떻게 호출되었느냐**에 따라 결정된다 (화살표 함수 제외).

### 기본 규칙 (4가지)

**① 전역 / 일반 함수 호출**
```js
function foo() {
  console.log(this); // 브라우저: window, Node.js: global, strict mode: undefined
}
foo();
```

**② 메서드 호출 → 호출한 객체**
```js
const obj = {
  name: 'Alice',
  greet() {
    console.log(this.name); // 'Alice'
  }
};
obj.greet();

// 주의: 메서드를 변수에 담으면 this가 바뀜
const fn = obj.greet;
fn(); // undefined (또는 window.name)
```

**③ `new` 호출 → 새로 생성된 인스턴스**
```js
function Person(name) {
  this.name = name;
}
const p = new Person('Alice');
console.log(p.name); // 'Alice'
```

**④ `call` / `apply` / `bind` → 명시적 지정**
```js
function greet() {
  console.log(this.name);
}

const user = { name: 'Bob' };

greet.call(user);       // 'Bob' - 즉시 호출
greet.apply(user, []);  // 'Bob' - 즉시 호출 (인수를 배열로)
const bound = greet.bind(user);
bound(); // 'Bob' - 나중에 호출
```

### 화살표 함수의 `this`

화살표 함수는 **자신의 `this`가 없다**. 정의된 위치의 상위 스코프 `this`를 상속한다 (렉시컬 `this`).

```js
const obj = {
  name: 'Alice',
  regular() {
    setTimeout(function() {
      console.log(this.name); // undefined (일반 함수, this = window)
    }, 100);
  },
  arrow() {
    setTimeout(() => {
      console.log(this.name); // 'Alice' (화살표 함수, this = obj)
    }, 100);
  }
};
```

```js
// 화살표 함수는 call/bind/apply로 this를 바꿀 수 없음
const fn = () => console.log(this);
fn.call({ x: 1 }); // 여전히 상위 스코프의 this
```

### `this` 결정 우선순위

```
new 호출 > call/apply/bind > 메서드 호출(obj.fn()) > 기본(전역/undefined)
```

---

## 면접 포인트

**Q. 실행 컨텍스트란 무엇인가요?**
> 코드가 실행되는 환경을 추상화한 객체. 변수/함수 선언 정보, 스코프 체인(`outer` 참조), `this` 바인딩을 포함. 함수 호출마다 생성되어 콜스택에 push되고, 실행 완료 후 pop된다.

**Q. `this`는 어떻게 결정되나요?**
> 호출 방식에 따라 다름. 일반 함수는 전역(또는 undefined), 메서드는 호출 객체, `new`는 새 인스턴스, `call/apply/bind`는 명시적 지정. 화살표 함수는 자신만의 `this`가 없고 상위 스코프의 `this`를 사용.

**Q. 화살표 함수에서 `this`를 왜 사용하나요? (콜백에서)**
> 콜백 함수를 일반 함수로 쓰면 `this`가 전역/undefined로 바뀌는 문제가 있음. 화살표 함수는 렉시컬 `this`라 정의 시점의 `this`(보통 원하는 객체)를 유지하므로 이벤트 핸들러나 setTimeout 콜백에 자주 사용.
