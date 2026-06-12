# 1. 타입 시스템 기초

## 목차
1. 기본 타입
2. Union 타입
3. Intersection 타입
4. Type vs Interface 차이
5. Type Guards
6. 면접 포인트

---

## 1. 기본 타입

TypeScript의 기본 타입은 JavaScript의 런타임 값에 정적 타입을 부여합니다.

```typescript
// 원시 타입
const name: string = "Alice";
const age: number = 30;
const isActive: boolean = true;
const nothing: null = null;
const undef: undefined = undefined;
const sym: symbol = Symbol("id");
const big: bigint = 9007199254740991n;

// 배열
const nums: number[] = [1, 2, 3];
const strs: Array<string> = ["a", "b"];

// 튜플: 고정 길이, 각 위치의 타입이 정해진 배열
const tuple: [string, number] = ["Alice", 30];
// tuple[2]; // 에러: 튜플 길이를 초과

// any: 타입 검사를 완전히 비활성화 (사용 지양)
let anything: any = 42;
anything = "now a string"; // 에러 없음

// unknown: any와 비슷하지만 사용 전에 타입을 좁혀야 함 (any보다 안전)
let unknownVal: unknown = "hello";
// unknownVal.toUpperCase(); // 에러: 타입을 좁히지 않으면 사용 불가
if (typeof unknownVal === "string") {
  unknownVal.toUpperCase(); // OK
}

// never: 절대 발생하지 않는 값의 타입 (무한루프, 항상 throw하는 함수)
function throwError(msg: string): never {
  throw new Error(msg);
}

// void: 반환 값이 없는 함수의 반환 타입
function log(msg: string): void {
  console.log(msg);
}

// object: 원시 타입이 아닌 모든 값
const obj: object = { key: "value" };

// 리터럴 타입: 특정 값만 허용
type Direction = "left" | "right" | "up" | "down";
const move: Direction = "left";
```

### any vs unknown 핵심 차이

| 구분 | any | unknown |
|------|-----|---------|
| 타입 할당 | 모든 타입에 할당 가능 | 모든 타입에 할당 불가 (any 제외) |
| 프로퍼티 접근 | 자유롭게 접근 가능 | 타입 좁히기 필요 |
| 타입 안전성 | 없음 | 있음 |

---

## 2. Union 타입

Union 타입(`|`)은 여러 타입 중 하나가 될 수 있음을 나타냅니다.

```typescript
// 기본 Union
type StringOrNumber = string | number;

function printId(id: StringOrNumber): void {
  if (typeof id === "string") {
    console.log(id.toUpperCase()); // string 메서드 사용
  } else {
    console.log(id.toFixed(2));   // number 메서드 사용
  }
}

// 객체 Union (Discriminated Union 패턴)
type Circle = {
  kind: "circle";
  radius: number;
};

type Rectangle = {
  kind: "rectangle";
  width: number;
  height: number;
};

type Shape = Circle | Rectangle;

function getArea(shape: Shape): number {
  switch (shape.kind) {
    case "circle":
      return Math.PI * shape.radius ** 2;
    case "rectangle":
      return shape.width * shape.height;
    // default에서 never 체크로 모든 케이스를 처리했는지 확인
    default:
      const _exhaustive: never = shape;
      throw new Error(`Unknown shape: ${_exhaustive}`);
  }
}

// Union에서 공통 프로퍼티만 접근 가능 (타입 좁히기 전)
type Cat = { name: string; meow(): void };
type Dog = { name: string; bark(): void };
type Pet = Cat | Dog;

function greetPet(pet: Pet): void {
  console.log(pet.name); // OK: 공통 프로퍼티
  // pet.meow(); // 에러: Dog에는 meow가 없음
}
```

---

## 3. Intersection 타입

Intersection 타입(`&`)은 여러 타입을 모두 만족해야 함을 나타냅니다. "A이면서 B인 타입"입니다.

```typescript
type HasName = { name: string };
type HasAge = { age: number };

// Intersection: 두 타입의 모든 프로퍼티를 가짐
type Person = HasName & HasAge;

const alice: Person = { name: "Alice", age: 30 }; // 둘 다 필요

// 실용 예시: Mixin 패턴
type Serializable = {
  serialize(): string;
};

type Loggable = {
  log(): void;
};

type LoggableUser = Person & Serializable & Loggable;

// Union vs Intersection 비교
type A = { a: string };
type B = { b: number };

type UnionAB = A | B;   // a 또는 b 중 하나 (혹은 둘 다)
type IntersectAB = A & B; // a와 b 둘 다 필요

const u1: UnionAB = { a: "hello" };         // OK
const u2: UnionAB = { b: 42 };              // OK
const i1: IntersectAB = { a: "hi", b: 1 }; // OK
// const i2: IntersectAB = { a: "hi" };     // 에러: b 누락

// 프리미티브 Intersection은 never가 됨
type Impossible = string & number; // never
```

---

## 4. Type vs Interface 차이

`type`과 `interface`는 대부분의 상황에서 호환되지만 중요한 차이가 있습니다.

```typescript
// Interface: 객체 구조 정의에 특화
interface User {
  id: number;
  name: string;
}

// Type Alias: 더 넓은 표현 가능 (원시 타입, Union, Intersection 등)
type ID = string | number;
type Callback = () => void;

// --- 선언 병합 (Declaration Merging) ---
// Interface는 같은 이름으로 여러 번 선언하면 자동으로 합쳐짐
interface Window {
  myCustomProp: string;
}
// Window는 이제 기존 브라우저 Window + myCustomProp을 가짐

// Type은 같은 이름으로 재선언 불가 (에러 발생)
// type ID = number; // 에러: 중복 선언

// --- 상속 방식 ---
// Interface: extends 키워드 사용
interface Animal {
  name: string;
}
interface Dog extends Animal {
  breed: string;
}

// Type: & (Intersection) 사용
type AnimalType = { name: string };
type DogType = AnimalType & { breed: string };

// --- implements ---
// 클래스는 interface와 type 모두 implements 가능
interface Printable {
  print(): void;
}
type Loggable2 = {
  log(): void;
};

class Document implements Printable, Loggable2 {
  print() { console.log("printing..."); }
  log()   { console.log("logging..."); }
}

// --- 언제 무엇을 쓸까 ---
// Interface: 객체 모양 정의, 라이브러리 공개 API, 클래스 계약
// Type:      Union/Intersection, 튜플, 유틸리티 조합, 함수 타입
```

### Type vs Interface 요약 비교

| 기능 | interface | type |
|------|-----------|------|
| 객체 타입 정의 | O | O |
| 선언 병합 | O | X |
| Union/Intersection 표현 | 제한적 | O |
| 원시 타입 alias | X | O |
| 클래스 implements | O | O |
| 튜플 타입 | X | O |
| 조건부 타입 | X | O |

---

## 5. Type Guards

타입 가드는 런타임에 특정 스코프 안에서 타입을 좁혀주는 표현식입니다.

```typescript
// 1. typeof 가드 (원시 타입용)
function process(val: string | number): string {
  if (typeof val === "string") {
    return val.toUpperCase(); // 여기서 val은 string
  }
  return val.toFixed(2); // 여기서 val은 number
}

// 2. instanceof 가드 (클래스 인스턴스용)
class Bird {
  fly() { console.log("flying"); }
}
class Fish {
  swim() { console.log("swimming"); }
}

function move(animal: Bird | Fish): void {
  if (animal instanceof Bird) {
    animal.fly();  // Bird로 좁혀짐
  } else {
    animal.swim(); // Fish로 좁혀짐
  }
}

// 3. in 연산자 가드 (프로퍼티 존재 확인)
type Admin = { role: "admin"; permissions: string[] };
type Guest = { role: "guest"; sessionId: string };
type UserRole = Admin | Guest;

function handleUser(user: UserRole): void {
  if ("permissions" in user) {
    console.log("Admin:", user.permissions); // Admin으로 좁혀짐
  } else {
    console.log("Guest:", user.sessionId);   // Guest로 좁혀짐
  }
}

// 4. 사용자 정의 타입 가드 (is 키워드)
interface Cat2 { meow(): void; species: "cat" }
interface Dog2 { bark(): void; species: "dog" }

// 반환 타입이 'pet is Cat2'이면 true일 때 해당 스코프에서 Cat2로 좁혀짐
function isCat(pet: Cat2 | Dog2): pet is Cat2 {
  return pet.species === "cat";
}

function makeSound(pet: Cat2 | Dog2): void {
  if (isCat(pet)) {
    pet.meow(); // Cat2로 좁혀짐
  } else {
    pet.bark(); // Dog2로 좁혀짐
  }
}

// 5. Assertion Functions (asserts 키워드, TS 3.7+)
function assertIsString(val: unknown): asserts val is string {
  if (typeof val !== "string") {
    throw new Error("Not a string!");
  }
}

function processValue(val: unknown): void {
  assertIsString(val);
  // 이 아래에서 val은 string으로 확정됨
  console.log(val.toUpperCase());
}

// 6. Discriminated Union을 이용한 타입 가드
type Result<T> =
  | { success: true; data: T }
  | { success: false; error: string };

function handleResult(result: Result<number>): void {
  if (result.success) {
    console.log("Data:", result.data);   // { success: true; data: number }
  } else {
    console.log("Error:", result.error); // { success: false; error: string }
  }
}
```

---

## 6. 면접 포인트

### Q1. `any`와 `unknown`의 차이점은?

`any`는 타입 검사를 완전히 포기하는 탈출구입니다. `unknown`은 "어떤 값이든 될 수 있지만, 사용하려면 타입을 먼저 좁혀야 한다"는 타입 안전한 대안입니다. 외부 API 응답이나 JSON.parse 결과처럼 타입을 모를 때는 `any` 대신 `unknown`을 쓰고 타입 가드로 좁혀서 사용하는 것이 좋습니다.

### Q2. `type`과 `interface` 중 언제 무엇을 쓰나요?

팀 컨벤션에 따라 다르지만, 일반적으로:
- **interface**: 객체의 형태(shape) 정의, 클래스 구현 계약, 라이브러리 공개 API (선언 병합 활용)
- **type**: Union/Intersection 조합, 원시 타입 alias, 유틸리티 타입 조합, 함수 시그니처

### Q3. Discriminated Union이란?

공통 리터럴 타입 프로퍼티(discriminant/tag)를 가진 Union 타입입니다. `switch`나 `if`로 해당 프로퍼티를 체크하면 TypeScript가 각 분기에서 정확한 타입으로 좁혀줍니다. Redux action 패턴, 상태 머신, API 응답 타입 모델링에 유용합니다.

### Q4. `never` 타입은 어디에 사용하나요?

1. **exhaustiveness check**: switch 문의 default 케이스에서 `never`에 대입해 모든 케이스를 처리했는지 컴파일 타임에 검증
2. **불가능한 타입**: `string & number`처럼 동시에 만족 불가능한 Intersection
3. **무한 루프/항상 throw**: 반환되지 않는 함수의 반환 타입

### Q5. 사용자 정의 타입 가드(`is`)의 한계는?

TypeScript는 `is` 반환 타입의 내용을 검증하지 않습니다. 즉, 구현 로직이 잘못되어도 컴파일러는 믿어버립니다. 따라서 타입 가드 함수 내부 로직이 실제로 올바른지 개발자가 책임져야 합니다.
