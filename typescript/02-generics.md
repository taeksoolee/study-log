# 2. 제네릭 (Generics)

## 목차
1. 제네릭 기본 개념
2. 제약 조건 (extends)
3. 제네릭 유틸리티 함수
4. 조건부 타입과의 조합
5. 면접 포인트

---

## 1. 제네릭 기본 개념

제네릭은 타입을 매개변수처럼 다루어, 다양한 타입에서 재사용 가능한 컴포넌트를 만드는 방법입니다.

```typescript
// 제네릭 없이 작성하면 타입별로 함수를 중복 작성해야 함
function identityString(arg: string): string { return arg; }
function identityNumber(arg: number): number { return arg; }

// 제네릭으로 하나로 통합
function identity<T>(arg: T): T {
  return arg;
}

// 사용 시 타입을 명시하거나 추론에 맡길 수 있음
const s = identity<string>("hello"); // 명시적
const n = identity(42);              // 추론: T = number

// 제네릭 인터페이스
interface Box<T> {
  value: T;
  getValue(): T;
}

const stringBox: Box<string> = {
  value: "hello",
  getValue() { return this.value; }
};

// 제네릭 클래스
class Stack<T> {
  private items: T[] = [];

  push(item: T): void {
    this.items.push(item);
  }

  pop(): T | undefined {
    return this.items.pop();
  }

  peek(): T | undefined {
    return this.items[this.items.length - 1];
  }

  isEmpty(): boolean {
    return this.items.length === 0;
  }
}

const numStack = new Stack<number>();
numStack.push(1);
numStack.push(2);
console.log(numStack.pop()); // 2

// 여러 타입 매개변수
function pair<A, B>(first: A, second: B): [A, B] {
  return [first, second];
}

const p = pair("age", 30); // [string, number]

// 제네릭 타입 별칭
type Nullable<T> = T | null;
type Maybe<T> = T | null | undefined;
type Pair<A, B> = { first: A; second: B };
```

---

## 2. 제약 조건 (extends)

`extends`를 사용해 타입 매개변수가 특정 타입의 구조를 갖도록 제한할 수 있습니다.

```typescript
// 제약 없이 쓰면 T가 어떤 타입인지 몰라 프로퍼티 접근 불가
// function getLength<T>(arg: T): number {
//   return arg.length; // 에러: T에 length가 없을 수 있음
// }

// extends로 length 프로퍼티를 가진 타입으로 제한
interface Lengthwise {
  length: number;
}

function getLength<T extends Lengthwise>(arg: T): number {
  return arg.length; // OK: T는 반드시 length를 가짐
}

getLength("hello");   // OK: string에 length 있음
getLength([1, 2, 3]); // OK: array에 length 있음
// getLength(123);    // 에러: number에 length 없음

// keyof와 조합: 객체의 키 타입으로 제한
function getProperty<T, K extends keyof T>(obj: T, key: K): T[K] {
  return obj[key];
}

const user = { name: "Alice", age: 30, active: true };
const name = getProperty(user, "name"); // string
const age  = getProperty(user, "age");  // number
// getProperty(user, "email"); // 에러: 'email'은 유효한 키가 아님

// 조건부 제약: 타입 매개변수끼리 제약
function copyProperties<T, U extends T>(target: T, source: U): T {
  return Object.assign({}, target, source);
}

// 기본값(Default Type Parameters)
interface ApiResponse<T = unknown> {
  data: T;
  status: number;
  message: string;
}

// T 지정 없으면 unknown
const res1: ApiResponse = { data: "anything", status: 200, message: "OK" };
// T 지정하면 해당 타입
const res2: ApiResponse<{ id: number }> = {
  data: { id: 1 },
  status: 200,
  message: "OK"
};

// extends와 조건부 타입 (기초)
type IsArray<T> = T extends any[] ? true : false;
type A = IsArray<number[]>; // true
type B = IsArray<string>;   // false
```

---

## 3. 제네릭 유틸리티 함수

실무에서 자주 쓰이는 제네릭 유틸리티 함수 패턴입니다.

```typescript
// 배열 유틸리티
function first<T>(arr: T[]): T | undefined {
  return arr[0];
}

function last<T>(arr: T[]): T | undefined {
  return arr[arr.length - 1];
}

function unique<T>(arr: T[]): T[] {
  return [...new Set(arr)];
}

// 객체 유틸리티
function pick<T extends object, K extends keyof T>(obj: T, keys: K[]): Pick<T, K> {
  const result = {} as Pick<T, K>;
  keys.forEach(key => {
    result[key] = obj[key];
  });
  return result;
}

const fullUser = { id: 1, name: "Alice", email: "alice@example.com", password: "secret" };
const safeUser = pick(fullUser, ["id", "name", "email"]);
// safeUser.password // 에러: password는 선택된 키가 아님

function omit<T extends object, K extends keyof T>(obj: T, keys: K[]): Omit<T, K> {
  const result = { ...obj };
  keys.forEach(key => delete result[key]);
  return result as Omit<T, K>;
}

// 비동기 유틸리티
async function fetchJson<T>(url: string): Promise<T> {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  return res.json() as Promise<T>;
}

// 사용 예시
interface Post { id: number; title: string; body: string; }
// const post = await fetchJson<Post>('/api/posts/1');
// post.title // string으로 타입 추론됨

// 캐시 유틸리티
function memoize<TArgs extends any[], TReturn>(
  fn: (...args: TArgs) => TReturn
): (...args: TArgs) => TReturn {
  const cache = new Map<string, TReturn>();
  return (...args: TArgs): TReturn => {
    const key = JSON.stringify(args);
    if (cache.has(key)) return cache.get(key)!;
    const result = fn(...args);
    cache.set(key, result);
    return result;
  };
}

const expensiveCalc = memoize((n: number) => n * n);
expensiveCalc(5); // 계산 후 캐시
expensiveCalc(5); // 캐시에서 반환

// 이벤트 에미터 (타입 안전)
type EventMap = {
  login: { userId: string; timestamp: Date };
  logout: { userId: string };
  error: { message: string; code: number };
};

class TypedEventEmitter<T extends Record<string, any>> {
  private listeners = new Map<keyof T, Function[]>();

  on<K extends keyof T>(event: K, listener: (data: T[K]) => void): void {
    const existing = this.listeners.get(event) ?? [];
    this.listeners.set(event, [...existing, listener]);
  }

  emit<K extends keyof T>(event: K, data: T[K]): void {
    this.listeners.get(event)?.forEach(fn => fn(data));
  }
}

const emitter = new TypedEventEmitter<EventMap>();
emitter.on("login", ({ userId }) => console.log(`User ${userId} logged in`));
emitter.emit("login", { userId: "123", timestamp: new Date() });
// emitter.emit("login", { userId: 123 }); // 에러: userId는 string
```

---

## 4. 조건부 타입과의 조합

조건부 타입은 `T extends U ? X : Y` 형식으로 타입 수준의 분기 처리를 가능하게 합니다.

```typescript
// 기본 조건부 타입
type NonNullable2<T> = T extends null | undefined ? never : T;
type SafeString = NonNullable2<string | null>; // string

// 분배 조건부 타입: Union 타입에 조건부 타입 적용 시 각 멤버에 분배됨
type ToArray<T> = T extends any ? T[] : never;
type StrOrNumArr = ToArray<string | number>; // string[] | number[]
// (분배 없이 하려면 튜플로 감쌈)
type ToArrayNoDist<T> = [T] extends [any] ? T[] : never;
type Wrapped = ToArrayNoDist<string | number>; // (string | number)[]

// infer: 조건부 타입 안에서 타입 추출
type ReturnType2<T> = T extends (...args: any[]) => infer R ? R : never;
type FnReturn = ReturnType2<() => string>; // string
type FnReturn2 = ReturnType2<(a: number) => boolean>; // boolean

type Awaited2<T> = T extends Promise<infer U> ? Awaited2<U> : T;
type Resolved = Awaited2<Promise<Promise<string>>>; // string

// 배열 요소 타입 추출
type ElementType<T> = T extends (infer E)[] ? E : never;
type Num = ElementType<number[]>; // number
type Str = ElementType<string[]>; // string

// 함수 첫 번째 인자 타입 추출
type FirstArg<T> = T extends (first: infer F, ...rest: any[]) => any ? F : never;
type FA = FirstArg<(a: string, b: number) => void>; // string

// 재귀 조건부 타입 (깊은 Readonly)
type DeepReadonly<T> = T extends object
  ? { readonly [K in keyof T]: DeepReadonly<T[K]> }
  : T;

interface Config {
  server: {
    host: string;
    port: number;
    options: {
      timeout: number;
    };
  };
}

type ReadonlyConfig = DeepReadonly<Config>;
// ReadonlyConfig.server.options.timeout = 5000; // 에러: 모든 중첩 프로퍼티가 readonly

// 조건부 타입으로 타입 필터링
type FilterString<T> = T extends string ? T : never;
type OnlyStrings = FilterString<"a" | 1 | "b" | true>; // "a" | "b"

// 함수 오버로드 없이 Union 반환 타입 매핑
type MapReturnType<T extends "string" | "number"> =
  T extends "string" ? string :
  T extends "number" ? number :
  never;

function createValue<T extends "string" | "number">(type: T): MapReturnType<T> {
  if (type === "string") return "" as MapReturnType<T>;
  return 0 as MapReturnType<T>;
}

const str = createValue("string"); // string
const num = createValue("number"); // number
```

---

## 5. 면접 포인트

### Q1. 제네릭을 왜 사용하나요?

코드의 **재사용성**과 **타입 안전성**을 동시에 확보하기 위해 사용합니다. `any`를 쓰면 재사용은 가능하지만 타입 안전성을 잃습니다. 제네릭은 "이 함수/클래스는 어떤 타입과도 동작하지만, 입력 타입과 출력 타입의 관계는 보장된다"는 것을 표현합니다.

### Q2. `T extends K`와 일반 상속의 차이는?

제네릭의 `extends`는 상속이 아니라 **제약(constraint)**입니다. `T extends K`는 "T는 K의 구조적 하위 타입이어야 한다"는 의미입니다. 덕 타이핑(structural typing)이므로 `K`의 프로퍼티를 가지는 모든 타입이 허용됩니다.

### Q3. 분배 조건부 타입(Distributive Conditional Types)이란?

`T extends U ? X : Y`에서 T가 Union 타입일 때, Union의 각 멤버에 조건부 타입이 각각 적용되어 결과가 Union으로 합쳐지는 동작입니다. 예: `(A | B) extends U ? X : Y` → `(A extends U ? X : Y) | (B extends U ? X : Y)`. 분배를 막으려면 `[T] extends [U]`처럼 튜플로 감쌉니다.

### Q4. `infer` 키워드의 용도는?

조건부 타입의 `extends` 절 안에서 패턴 매칭으로 타입을 추출할 때 사용합니다. 예를 들어 함수의 반환 타입, Promise의 결과 타입, 배열의 요소 타입 등을 타입 수준에서 추출할 수 있습니다. 표준 라이브러리의 `ReturnType`, `Parameters`, `Awaited` 등이 `infer`로 구현되어 있습니다.

### Q5. 제네릭 타입 매개변수의 기본값은 어떻게 설정하나요?

`interface Foo<T = string>`처럼 `=` 으로 기본값을 지정합니다. 기본값이 있는 타입 매개변수는 생략 가능하며, 기본값이 있는 매개변수는 없는 매개변수 뒤에 와야 합니다.
