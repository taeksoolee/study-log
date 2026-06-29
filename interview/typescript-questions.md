# 6. TypeScript 면접 질문 20개

## 목차
1. [TypeScript를 쓰는 이유와 한계는?](#1-typescript를-쓰는-이유와-한계는)
2. [`any` vs `unknown` vs `never`의 차이는?](#2-any-vs-unknown-vs-never의-차이는)
3. [`type`과 `interface`의 차이는?](#3-type과-interface의-차이는)
4. [구조적 타이핑(structural typing)이란?](#4-구조적-타이핑structural-typing이란)
5. [제네릭은 왜 필요한가요?](#5-제네릭은-왜-필요한가요)
6. [`extends`의 두 가지 의미는?](#6-extends의-두-가지-의미는)
7. [유니온과 인터섹션의 차이는?](#7-유니온과-인터섹션의-차이는)
8. [타입 가드와 타입 좁히기(narrowing)란?](#8-타입-가드와-타입-좁히기narrowing란)
9. [`keyof`, `typeof`, 인덱스 접근 타입은?](#9-keyof-typeof-인덱스-접근-타입은)
10. [매핑된 타입(Mapped Type)이란?](#10-매핑된-타입mapped-type이란)
11. [조건부 타입과 `infer`는?](#11-조건부-타입과-infer는)
12. [자주 쓰는 유틸리티 타입은?](#12-자주-쓰는-유틸리티-타입은)
13. [`as const`와 리터럴 타입은?](#13-as-const와-리터럴-타입은)
14. [공변성/반공변성(variance)이란?](#14-공변성반공변성variance이란)
15. [선언 병합과 모듈 보강은?](#15-선언-병합과-모듈-보강은)
16. [`enum`의 문제와 대안은?](#16-enum의-문제와-대안은)
17. [타입과 런타임 검증을 어떻게 잇나요?](#17-타입과-런타임-검증을-어떻게-잇나요)
18. [`satisfies` 연산자는 언제 쓰나요?](#18-satisfies-연산자는-언제-쓰나요)
19. [`strict` 모드의 핵심 옵션은?](#19-strict-모드의-핵심-옵션은)
20. [제네릭 제약과 기본값은?](#20-제네릭-제약과-기본값은)

---

## 1. TypeScript를 쓰는 이유와 한계는?

**답변:**
정적 타입으로 **컴파일 타임에 오류를 잡고**, 자동완성·리팩터링·문서화 효과를 얻는다. 한계: 타입은 **트랜스파일 시 제거**되어 런타임 검증이 없다 → 외부 입력(API 응답, 폼)은 zod 같은 런타임 검증이 따로 필요하다. 또 타입이 복잡해지면 학습·빌드 비용이 늘고, 잘못된 단언(`as`)으로 타입 안전성을 스스로 깰 수 있다.

---

## 2. `any` vs `unknown` vs `never`의 차이는?

**답변:**
- `any`: 타입 검사를 끈다. 어디에나 할당·접근 가능 → 안전성 포기(전염성). 지양.
- `unknown`: "모르는 타입". 무엇이든 담을 수 있지만, **쓰기 전에 좁히기(narrowing)를 강제**한다. `any`의 안전한 버전.
- `never`: 값이 절대 없음. 도달 불가 코드·완전성 검사(exhaustiveness)에 쓴다.

```ts
function assertNever(x: never): never { throw new Error('unhandled: ' + x); }
```

---

## 3. `type`과 `interface`의 차이는?

**답변:**
대부분 호환되지만:
- `interface`는 **선언 병합**(같은 이름 재선언 시 합쳐짐)이 되고 객체/클래스 계약에 적합, `extends`가 직관적.
- `type`은 유니온·튜플·매핑·조건부 등 **모든 타입 표현**이 가능(별칭).
- 라이브러리 공개 API는 확장 가능한 `interface`, 복합 타입은 `type`을 쓰는 게 관습.

---

## 4. 구조적 타이핑(structural typing)이란?

**답변:**
TS는 이름이 아니라 **구조(형태)가 호환되면 같은 타입으로 본다**("duck typing"). 명목적(nominal) 타이핑인 Java와 대비된다.

```ts
interface Point { x: number; y: number; }
const p = { x: 1, y: 2, z: 3 };
const q: Point = p; // OK — Point의 형태를 포함하므로 (잉여 속성 z 허용)
```

> 단, 객체 리터럴을 직접 할당하면 "잉여 속성 검사"가 작동해 오타를 잡는다.

---

## 5. 제네릭은 왜 필요한가요?

**답변:**
타입을 **매개변수화**해 재사용성과 타입 안전성을 동시에 얻는다. `any`는 타입 정보를 잃지만 제네릭은 입력→출력 타입 관계를 보존한다.

```ts
function first<T>(arr: T[]): T | undefined { return arr[0]; }
first([1,2,3]);      // number | undefined (관계 보존)
```

---

## 6. `extends`의 두 가지 의미는?

**답변:**
① **제약(constraint)**: `<T extends object>` — T가 object의 부분형이어야 함.
② **조건부 타입**: `T extends U ? A : B` — T가 U에 할당 가능한지로 분기.
문맥에 따라 의미가 다르다.

---

## 7. 유니온과 인터섹션의 차이는?

**답변:**
- 유니온 `A | B`: A *또는* B. 값은 둘 중 하나 → 공통 멤버만 바로 접근, 나머지는 좁히기 필요.
- 인터섹션 `A & B`: A *그리고* B 모두. 두 타입의 속성을 합침(믹스인).

> 헷갈림 주의: 유니온은 "값의 집합"으로는 합집합이지만, "접근 가능한 속성"으로는 교집합이다.

---

## 8. 타입 가드와 타입 좁히기(narrowing)란?

**답변:**
런타임 검사로 넓은 타입을 좁히는 것. `typeof`, `instanceof`, `in`, 그리고 사용자 정의 타입 가드(`x is T`)를 쓴다.

```ts
function isString(x: unknown): x is string { return typeof x === 'string'; }
```

판별 유니온(discriminated union)은 공통 리터럴 필드(`kind`)로 `switch` 좁히기를 한다.

---

## 9. `keyof`, `typeof`, 인덱스 접근 타입은?

**답변:**
```ts
const user = { id: 1, name: 'a' };
type User = typeof user;          // { id: number; name: string }  (값→타입)
type Keys = keyof User;           // 'id' | 'name'
type IdType = User['id'];         // number  (인덱스 접근)
```

`typeof`(값→타입), `keyof`(타입의 키 유니온), 인덱스 접근(속성 타입)을 조합해 기존 값/타입에서 타입을 파생한다.

---

## 10. 매핑된 타입(Mapped Type)이란?

**답변:**
기존 타입의 키를 순회하며 새 타입을 만든다. 유틸리티 타입의 기반.

```ts
type MyPartial<T> = { [K in keyof T]?: T[K] };
type ReadonlyT<T> = { readonly [K in keyof T]: T[K] };
```

`as`로 키 리매핑, `-?`/`-readonly`로 수식어 제거도 가능.

---

## 11. 조건부 타입과 `infer`는?

**답변:**
`T extends U ? X : Y`로 타입 분기. `infer`는 조건부 타입 안에서 타입을 **추출**한다.

```ts
type ElementOf<T> = T extends (infer E)[] ? E : never;
type A = ElementOf<string[]>;            // string
type ReturnType2<T> = T extends (...a: any[]) => infer R ? R : never;
```

유니온에 조건부 타입을 적용하면 **분배(distributive)**되어 각 멤버에 개별 적용된다.

---

## 12. 자주 쓰는 유틸리티 타입은?

**답변:**
`Partial<T>`, `Required<T>`, `Readonly<T>`, `Pick<T,K>`, `Omit<T,K>`, `Record<K,V>`, `Exclude<T,U>`, `Extract<T,U>`, `ReturnType<F>`, `Parameters<F>`, `Awaited<T>`. 대부분 매핑된 타입+조건부 타입으로 구현돼 있다.

---

## 13. `as const`와 리터럴 타입은?

**답변:**
`as const`는 값을 **읽기 전용 리터럴 타입**으로 좁힌다. 넓혀지는 것을 막아 유니온·키 추출에 유용.

```ts
const dirs = ['up', 'down'] as const; // readonly ['up','down']
type Dir = typeof dirs[number];        // 'up' | 'down'
```

---

## 14. 공변성/반공변성(variance)이란?

**답변:**
서브타입 관계가 제네릭/함수에서 어떻게 전파되는지. 반환 타입은 **공변**(서브타입 허용), 함수 매개변수는 본래 **반공변**이다(`strictFunctionTypes`에서 엄격). 그래서 `(x: Dog)=>void`는 `(x: Animal)=>void` 자리에 안전하게 못 들어간다(Cat이 와도 처리해야 하므로). 반대로 더 일반적인 `(x: Animal)=>void`는 `(x: Dog)=>void` 자리에 안전하게 들어간다.

---

## 15. 선언 병합과 모듈 보강은?

**답변:**
같은 이름의 `interface`는 자동 병합된다. `declare module`로 외부 라이브러리 타입을 **확장**(예: `Window`에 전역 추가, 라이브러리 타입 보강)할 수 있다.

---

## 16. `enum`의 문제와 대안은?

**답변:**
`enum`은 런타임 코드를 생성하고(트리셰이킹 방해), `const enum`은 격리 모듈/번들러와 충돌할 수 있다. 대안으로 `as const` 객체 + `typeof obj[keyof typeof obj]` 유니온이 더 가볍고 안전하다.

---

## 17. 타입과 런타임 검증을 어떻게 잇나요?

**답변:**
타입은 런타임에 사라지므로 외부 데이터는 신뢰할 수 없다. **zod/valibot** 같은 스키마로 런타임 검증 후 `z.infer`로 타입을 도출하면 "검증 = 타입"이 일치한다.

```ts
const User = z.object({ id: z.number(), name: z.string() });
type User = z.infer<typeof User>;  // 스키마에서 타입 생성
```

---

## 18. `satisfies` 연산자는 언제 쓰나요?

**답변:**
값이 어떤 타입을 **만족하는지 검사하되, 더 좁은 추론은 유지**할 때. `as`(단언, 검사 약함)나 타입 주석(추론 손실)의 단점을 보완한다.

```ts
const config = { port: 3000, host: 'localhost' } satisfies Record<string, unknown>;
config.port.toFixed(); // port가 number로 그대로 추론됨 (주석이었다면 unknown)
```

---

## 19. `strict` 모드의 핵심 옵션은?

**답변:**
`strict: true`가 묶는 것들: `strictNullChecks`(null/undefined 구분), `noImplicitAny`, `strictFunctionTypes`, `strictPropertyInitialization` 등. 특히 `strictNullChecks`가 가장 큰 안전성 향상을 준다(NPE류 방지).

---

## 20. 제네릭 제약과 기본값은?

**답변:**
```ts
function prop<T, K extends keyof T>(obj: T, key: K): T[K] { return obj[key]; }
type Box<T = string> = { value: T };   // 기본 타입 매개변수
```
`extends`로 제네릭이 가질 수 있는 타입을 제약하고, `= 기본값`으로 생략 시 기본 타입을 준다. 제약은 타입 안전성과 자동완성을 동시에 살린다.
