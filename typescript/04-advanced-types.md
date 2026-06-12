# 4. 고급 타입 (Advanced Types)

## 목차
1. 조건부 타입 (Conditional Types)
2. Mapped Types (매핑된 타입)
3. Template Literal Types (템플릿 리터럴 타입)
4. infer 키워드 심화
5. 면접 포인트

---

## 1. 조건부 타입 (Conditional Types)

`T extends U ? X : Y` 형식으로 타입 수준의 조건 분기를 표현합니다.

```typescript
// 기본 형식
type IsString<T> = T extends string ? "yes" : "no";
type A = IsString<string>;  // "yes"
type B = IsString<number>;  // "no"

// 분배 조건부 타입 (Distributive Conditional Types)
// Union 타입에 적용하면 각 멤버에 분배됨
type ToArray<T> = T extends any ? T[] : never;
type C = ToArray<string | number>;
// string[] | number[] (각각 분배됨)

// 분배를 막으려면 튜플로 감쌈
type ToArrayFixed<T> = [T] extends [any] ? T[] : never;
type D = ToArrayFixed<string | number>;
// (string | number)[]

// 실용 조건부 타입
type Flatten<T> = T extends Array<infer Item> ? Item : T;
type Num = Flatten<number[]>;   // number
type Str = Flatten<string>;     // string (배열이 아니면 그대로)

// 중첩 조건부 타입
type TypeName<T> =
  T extends string   ? "string"   :
  T extends number   ? "number"   :
  T extends boolean  ? "boolean"  :
  T extends null     ? "null"     :
  T extends undefined ? "undefined" :
  T extends Function ? "function" :
  "object";

type T1 = TypeName<string>;    // "string"
type T2 = TypeName<() => void>; // "function"
type T3 = TypeName<{}>; // "object"

// 조건부 타입으로 필터링
type NonNullableKeys<T> = {
  [K in keyof T]: null extends T[K] ? never : K
}[keyof T];

interface FormData {
  name: string;
  email: string;
  phone: string | null;
  bio: string | null;
}

type RequiredKeys = NonNullableKeys<FormData>; // "name" | "email"

// 재귀 조건부 타입 (TS 4.1+, tail recursion 최적화)
type DeepReadonly<T> = {
  readonly [K in keyof T]: T[K] extends object ? DeepReadonly<T[K]> : T[K];
};

type Join<T extends string[], Sep extends string = ","> =
  T extends []                ? "" :
  T extends [infer F extends string] ? F :
  T extends [infer F extends string, ...infer R extends string[]]
    ? `${F}${Sep}${Join<R, Sep>}`
    : never;

type Joined = Join<["a", "b", "c"], "-">; // "a-b-c"
```

---

## 2. Mapped Types (매핑된 타입)

기존 타입의 각 프로퍼티를 변환해 새 타입을 만듭니다.

```typescript
// 기본 형식: [K in keyof T]
type Copy<T> = {
  [K in keyof T]: T[K];
};

// 수식어 추가/제거
// +?: 선택적으로, -?: 필수로, +readonly: 읽기전용으로, -readonly: 가변으로
type Partial2<T>  = { [K in keyof T]?:  T[K] };
type Required2<T> = { [K in keyof T]-?: T[K] };
type Readonly2<T> = { readonly [K in keyof T]: T[K] };
type Mutable<T>   = { -readonly [K in keyof T]: T[K] };

// 키 재매핑 (as 절, TS 4.1+)
// 키 이름을 변환할 수 있음
type Getters<T> = {
  [K in keyof T as `get${Capitalize<string & K>}`]: () => T[K];
};

interface User {
  id: number;
  name: string;
  email: string;
}

type UserGetters = Getters<User>;
// {
//   getId: () => number;
//   getName: () => string;
//   getEmail: () => string;
// }

// 키 필터링: never를 반환하면 해당 키가 제거됨
type OnlyReadonlyProps<T> = {
  [K in keyof T as T[K] extends Function ? never : K]: T[K];
};

interface Service {
  id: number;
  name: string;
  start(): void;
  stop(): void;
}

type ServiceData = OnlyReadonlyProps<Service>;
// { id: number; name: string } (메서드 제거됨)

// 값 변환: 모든 값을 변환
type Stringify<T> = {
  [K in keyof T]: string;
};

// 조건부 변환
type NullableProps<T> = {
  [K in keyof T]: T[K] | null;
};

// 중첩 타입 변환
type DeepPartial<T> = T extends object
  ? { [K in keyof T]?: DeepPartial<T[K]> }
  : T;

// 이벤트 핸들러 타입 자동 생성
type EventHandlers<T extends Record<string, any>> = {
  [K in keyof T as `on${Capitalize<string & K>}`]?: (event: T[K]) => void;
};

type AppEvents = {
  click: { x: number; y: number };
  resize: { width: number; height: number };
  keydown: { key: string; code: string };
};

type AppEventHandlers = EventHandlers<AppEvents>;
// {
//   onClick?: (event: { x: number; y: number }) => void;
//   onResize?: (event: { width: number; height: number }) => void;
//   onKeydown?: (event: { key: string; code: string }) => void;
// }
```

---

## 3. Template Literal Types (템플릿 리터럴 타입)

TypeScript 4.1에서 도입된 기능으로, 문자열 리터럴 타입을 조합해 새로운 타입을 생성합니다.

```typescript
// 기본 형식
type Greeting = `Hello, ${string}!`;
const g1: Greeting = "Hello, World!"; // OK
// const g2: Greeting = "Hi, World!"; // 에러

// Union과 조합 → 카르테시안 곱으로 모든 조합 생성
type Color = "red" | "green" | "blue";
type Variant = "light" | "dark";
type ColorVariant = `${Variant}-${Color}`;
// "light-red" | "light-green" | "light-blue" | "dark-red" | "dark-green" | "dark-blue"

// CSS 관련 타입
type CSSUnit = "px" | "rem" | "em" | "%" | "vh" | "vw";
type CSSValue = `${number}${CSSUnit}`;
// const size: CSSValue = "16px"; // OK
// const size2: CSSValue = "16"; // 에러: 단위 없음

// 내장 문자열 조작 타입
type Upper = Uppercase<"hello world">;    // "HELLO WORLD"
type Lower = Lowercase<"HELLO WORLD">;    // "hello world"
type Cap   = Capitalize<"hello world">;   // "Hello world"
type Uncap = Uncapitalize<"Hello World">; // "hELLO wORLD"

// 이벤트 이름 패턴
type EventName = `on${Capitalize<string>}`;
// onClick, onSubmit, onKeydown 등

// API 경로 타입
type ApiVersion = "v1" | "v2";
type Resource = "users" | "posts" | "comments";
type ApiPath = `/api/${ApiVersion}/${Resource}`;
// "/api/v1/users" | "/api/v1/posts" | ... (6개 조합)

// 타입에서 문자열 파싱 (infer와 조합)
type ExtractRouteParams<T extends string> =
  T extends `${string}:${infer Param}/${infer Rest}`
    ? Param | ExtractRouteParams<`/${Rest}`>
    : T extends `${string}:${infer Param}`
    ? Param
    : never;

type Params = ExtractRouteParams<"/users/:userId/posts/:postId">;
// "userId" | "postId"

// 객체 키를 camelCase로 변환
type CamelCase<S extends string> =
  S extends `${infer Head}_${infer Tail}`
    ? `${Head}${Capitalize<CamelCase<Tail>>}`
    : S;

type SnakeToCamel<T extends Record<string, any>> = {
  [K in keyof T as CamelCase<string & K>]: T[K]
};

interface SnakeCaseUser {
  user_id: number;
  first_name: string;
  last_name: string;
  created_at: Date;
}

type CamelCaseUser = SnakeToCamel<SnakeCaseUser>;
// { userId: number; firstName: string; lastName: string; createdAt: Date }

// 타입 안전한 CSS-in-JS 스타일 키
type CSSPropertyMap = {
  [K in keyof CSSStyleDeclaration as K extends string ? K : never]: string;
};
```

---

## 4. infer 키워드 심화

`infer`는 조건부 타입의 `extends` 절에서 패턴 매칭으로 타입을 추출합니다.

```typescript
// 기본 사용: 함수 반환 타입 추출
type ReturnType2<T> = T extends (...args: any[]) => infer R ? R : never;

// Promise 언래핑
type UnwrapPromise<T> = T extends Promise<infer U> ? UnwrapPromise<U> : T;
type Resolved = UnwrapPromise<Promise<Promise<string>>>; // string

// 배열 요소 타입
type ElementOf<T> = T extends (infer E)[] ? E : never;
type NumEl = ElementOf<number[]>; // number

// 첫 번째 / 마지막 요소
type Head<T extends any[]> = T extends [infer H, ...any[]] ? H : never;
type Tail<T extends any[]> = T extends [any, ...infer T] ? T : never;
type Last<T extends any[]> = T extends [...any[], infer L] ? L : never;

type H = Head<[1, 2, 3]>; // 1
type Ta = Tail<[1, 2, 3]>; // [2, 3]
type L = Last<[1, 2, 3]>;  // 3

// 함수 파라미터 타입
type Parameters2<T extends (...args: any[]) => any> =
  T extends (...args: infer P) => any ? P : never;

// 생성자 파라미터
type ConstructorParams<T extends new (...args: any[]) => any> =
  T extends new (...args: infer P) => any ? P : never;

// 객체의 특정 메서드 반환 타입
type MethodReturn<T, K extends keyof T> =
  T[K] extends (...args: any[]) => infer R ? R : never;

interface Repository {
  findById(id: number): Promise<User>;
  findAll(): Promise<User[]>;
  save(user: User): Promise<User>;
}

type FindByIdReturn = MethodReturn<Repository, "findById">;
// Promise<User>

// 재귀 infer: 중첩 배열 평탄화
type Flatten2<T> = T extends Array<infer Item>
  ? Flatten2<Item>
  : T;

type NestedArray = Flatten2<number[][][]>; // number

// 문자열에서 타입 추출
type ParseInt<T extends string> =
  T extends `${infer N extends number}` ? N : never;

type MyNum = ParseInt<"42">; // 42 (숫자 리터럴 타입)

// 여러 위치에서 동시 infer
type ZipTypes<T, U> =
  T extends [infer TH, ...infer TT]
    ? U extends [infer UH, ...infer UT]
      ? [[TH, UH], ...ZipTypes<TT, UT>]
      : []
    : [];

type Zipped = ZipTypes<[1, 2, 3], ["a", "b", "c"]>;
// [[1, "a"], [2, "b"], [3, "c"]]
```

---

## 5. 면접 포인트

### Q1. 분배 조건부 타입이 항상 일어나는 것은 아닌데, 언제 분배가 일어나지 않나요?

분배는 타입 매개변수가 **naked type** (튜플, 배열, 객체 등으로 감싸지 않은 형태)으로 쓰일 때만 일어납니다. `[T] extends [U]`처럼 튜플로 감싸면 분배가 억제됩니다. 또한 `T = any`인 경우 항상 조건의 `true` 분기로 분기됩니다.

### Q2. Mapped Type의 키 재매핑(`as`)은 어떻게 활용하나요?

`as` 절에서 키 이름을 변환할 수 있습니다. `never`를 반환하면 해당 키가 결과 타입에서 제거됩니다. 이를 활용해 특정 타입의 키만 남기거나, camelCase 변환, getter/setter 이름 자동 생성 등이 가능합니다.

### Q3. Template Literal Type의 실무 활용 사례는?

1. **이벤트 이름 패턴 강제**: `on${Capitalize<string>}`
2. **API 경로 타입**: 버전과 리소스 조합으로 가능한 경로 집합 표현
3. **CSS-in-JS**: 유효한 CSS 값 형식 강제
4. **스네이크케이스 ↔ 카멜케이스 변환**: 백엔드-프론트엔드 타입 브릿지
5. **경로 매개변수 추출**: Express 스타일의 라우트에서 `:param` 추출

### Q4. `infer`를 여러 개 사용할 수 있나요?

네. `T extends { a: infer A; b: infer B }`처럼 같은 조건부 타입 안에서 여러 `infer`를 사용할 수 있습니다. 같은 이름의 `infer`를 공변(covariant) 위치에서 여러 번 쓰면 Union이 되고, 반변(contravariant) 위치(함수 매개변수 등)에서는 Intersection이 됩니다.

### Q5. 조건부 타입을 남용하면 생기는 문제는?

1. **컴파일 성능 저하**: 복잡한 재귀 조건부 타입은 타입 체커를 느리게 만듦
2. **가독성 저하**: 깊이 중첩된 조건부 타입은 이해하기 어려움
3. **타입 인스턴스화 한도 초과**: TypeScript는 타입 인스턴스화 깊이를 제한하며, 초과 시 에러 발생
4. **디버깅 어려움**: 타입 추론 결과가 예상과 다를 때 원인 파악이 어려움

실무에서는 지나치게 복잡한 타입 체조보다 명확하고 단순한 타입 설계가 팀 생산성에 유리합니다.
