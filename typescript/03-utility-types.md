# 3. 유틸리티 타입 (Utility Types)

## 목차
1. Partial, Required, Readonly
2. Pick, Omit
3. Record
4. Exclude, Extract, NonNullable
5. ReturnType, Parameters, ConstructorParameters
6. 직접 구현 (내부 구조 이해)
7. 실전 조합 패턴
8. 면접 포인트

---

## 1. Partial, Required, Readonly

```typescript
interface User {
  id: number;
  name: string;
  email: string;
  age?: number; // 선택적 프로퍼티
}

// Partial<T>: 모든 프로퍼티를 선택적으로 만듦 (업데이트 DTO에 유용)
type UserUpdate = Partial<User>;
// { id?: number; name?: string; email?: string; age?: number }

function updateUser(id: number, updates: Partial<User>): User {
  // 기존 데이터와 병합
  const existing: User = { id, name: "Alice", email: "alice@ex.com" };
  return { ...existing, ...updates };
}

// Required<T>: 모든 프로퍼티를 필수로 만듦 (Partial의 반대)
type UserRequired = Required<User>;
// { id: number; name: string; email: string; age: number }

// Readonly<T>: 모든 프로퍼티를 읽기 전용으로 만듦
type FrozenUser = Readonly<User>;
const frozenUser: FrozenUser = { id: 1, name: "Alice", email: "a@ex.com" };
// frozenUser.name = "Bob"; // 에러: 읽기 전용 프로퍼티

// 배열도 Readonly 가능
const readonlyArr: Readonly<number[]> = [1, 2, 3];
// ReadonlyArray<number>와 동일
// readonlyArr.push(4); // 에러

// ReadonlyArray (배열 전용)
const arr: ReadonlyArray<string> = ["a", "b", "c"];
// arr[0] = "z"; // 에러
```

---

## 2. Pick, Omit

```typescript
interface Article {
  id: number;
  title: string;
  content: string;
  authorId: number;
  createdAt: Date;
  updatedAt: Date;
  tags: string[];
}

// Pick<T, K>: 지정한 키만 선택
type ArticlePreview = Pick<Article, "id" | "title" | "tags">;
// { id: number; title: string; tags: string[] }

// 목록 화면에 필요한 정보만 담은 타입
type ArticleListItem = Pick<Article, "id" | "title" | "createdAt">;

// Omit<T, K>: 지정한 키를 제외
type ArticleWithoutDates = Omit<Article, "createdAt" | "updatedAt">;
// { id: number; title: string; content: string; authorId: number; tags: string[] }

// 생성 DTO: 서버에서 생성하는 필드 제외
type CreateArticleDto = Omit<Article, "id" | "createdAt" | "updatedAt">;

// Pick vs Omit 선택 기준:
// 선택할 키가 적으면 Pick, 제외할 키가 적으면 Omit
```

---

## 3. Record

```typescript
// Record<K, V>: K를 키 타입, V를 값 타입으로 하는 객체 타입
type PageMap = Record<string, string>;
// { [key: string]: string }

// 열거형 키에 특히 유용
type Status = "todo" | "in-progress" | "done";
type StatusLabel = Record<Status, string>;

const labels: StatusLabel = {
  todo: "할 일",
  "in-progress": "진행 중",
  done: "완료",
  // extra: "..." // 에러: 'extra'는 Status에 없음
};

// 복잡한 값 타입
interface Config {
  enabled: boolean;
  timeout: number;
}
type FeatureFlags = Record<string, Config>;

// 집계/그룹핑에 유용
function groupBy<T>(items: T[], key: keyof T): Record<string, T[]> {
  return items.reduce((acc, item) => {
    const group = String(item[key]);
    return { ...acc, [group]: [...(acc[group] ?? []), item] };
  }, {} as Record<string, T[]>);
}

type Category = "fruit" | "vegetable";
type Product = { name: string; category: Category; price: number };
const products: Product[] = [
  { name: "Apple", category: "fruit", price: 1000 },
  { name: "Carrot", category: "vegetable", price: 500 },
  { name: "Banana", category: "fruit", price: 800 },
];

const grouped = groupBy(products, "category");
// { fruit: [...], vegetable: [...] }
```

---

## 4. Exclude, Extract, NonNullable

```typescript
// Exclude<T, U>: T에서 U에 해당하는 타입을 제거
type AllStatus = "active" | "inactive" | "pending" | "deleted";
type ActiveStatus = Exclude<AllStatus, "deleted" | "inactive">;
// "active" | "pending"

type NumberOrString = string | number | boolean;
type JustString = Exclude<NumberOrString, number | boolean>;
// string

// Extract<T, U>: T에서 U에 해당하는 타입만 추출 (Exclude의 반대)
type EventTypes = "click" | "keydown" | "scroll" | "focus" | "blur";
type MouseEvents = Extract<EventTypes, "click" | "scroll">;
// "click" | "scroll"

type OnlyStrings2 = Extract<string | number | boolean | null, string>;
// string

// NonNullable<T>: null과 undefined 제거
type MaybeString = string | null | undefined;
type DefinitelyString = NonNullable<MaybeString>;
// string

// 실용 예시: API 응답에서 null 제거
interface ApiUser {
  id: number;
  name: string | null;
  avatar: string | null | undefined;
}
type CleanUser = { [K in keyof ApiUser]: NonNullable<ApiUser[K]> };
// { id: number; name: string; avatar: string }
```

---

## 5. ReturnType, Parameters, ConstructorParameters

```typescript
// ReturnType<T>: 함수 타입의 반환 타입 추출
function createUser(name: string, age: number) {
  return { id: Math.random(), name, age, createdAt: new Date() };
}

type UserType = ReturnType<typeof createUser>;
// { id: number; name: string; age: number; createdAt: Date }

// API 응답 타입을 함수 반환 타입에서 자동으로 추론
async function fetchUser(id: number) {
  const data = await fetch(`/api/users/${id}`);
  return data.json() as Promise<{ id: number; name: string }>;
}
type FetchUserResult = Awaited<ReturnType<typeof fetchUser>>;
// { id: number; name: string }

// Parameters<T>: 함수 타입의 매개변수 타입을 튜플로 추출
function createPost(title: string, content: string, authorId: number): void {}
type PostParams = Parameters<typeof createPost>;
// [title: string, content: string, authorId: number]

// 함수 인자를 그대로 전달하는 래퍼 함수에 유용
function withLogging<T extends (...args: any[]) => any>(fn: T) {
  return (...args: Parameters<T>): ReturnType<T> => {
    console.log("Calling with:", args);
    const result = fn(...args);
    console.log("Result:", result);
    return result;
  };
}

const loggedCreateUser = withLogging(createUser);
// loggedCreateUser의 타입은 원본 함수와 동일하게 추론됨

// ConstructorParameters<T>: 생성자 매개변수 타입 추출
class Service {
  constructor(
    private baseUrl: string,
    private timeout: number,
    private apiKey: string
  ) {}
}

type ServiceParams = ConstructorParameters<typeof Service>;
// [baseUrl: string, timeout: number, apiKey: string]

// InstanceType<T>: 생성자 타입에서 인스턴스 타입 추출
type ServiceInstance = InstanceType<typeof Service>;
// Service

// ThisType<T>: 객체 리터럴 내 this 타입 지정 (noImplicitThis 필요)
type Methods = {
  getName(): string;
  setName(name: string): void;
};

const obj: { data: { name: string } } & ThisType<{ data: { name: string } } & Methods> = {
  data: { name: "Alice" },
};
```

---

## 6. 직접 구현 (내부 구조 이해)

```typescript
// Partial 직접 구현
type MyPartial<T> = {
  [K in keyof T]?: T[K];
};

// Required 직접 구현 (-? 로 선택성 제거)
type MyRequired<T> = {
  [K in keyof T]-?: T[K];
};

// Readonly 직접 구현
type MyReadonly<T> = {
  readonly [K in keyof T]: T[K];
};

// Mutable (Readonly 반대, -readonly로 제거)
type Mutable<T> = {
  -readonly [K in keyof T]: T[K];
};

// Pick 직접 구현
type MyPick<T, K extends keyof T> = {
  [P in K]: T[P];
};

// Omit 직접 구현
type MyOmit<T, K extends keyof T> = {
  [P in Exclude<keyof T, K>]: T[P];
};
// 또는: MyPick<T, Exclude<keyof T, K>>

// Record 직접 구현
type MyRecord<K extends keyof any, V> = {
  [P in K]: V;
};

// Exclude 직접 구현
type MyExclude<T, U> = T extends U ? never : T;
// 분배 조건부 타입으로 동작: Union의 각 멤버를 체크

// Extract 직접 구현
type MyExtract<T, U> = T extends U ? T : never;

// NonNullable 직접 구현
type MyNonNullable<T> = T extends null | undefined ? never : T;

// ReturnType 직접 구현
type MyReturnType<T extends (...args: any) => any> =
  T extends (...args: any) => infer R ? R : never;

// Parameters 직접 구현
type MyParameters<T extends (...args: any) => any> =
  T extends (...args: infer P) => any ? P : never;

// Awaited 직접 구현 (재귀)
type MyAwaited<T> =
  T extends null | undefined ? T :
  T extends object & { then(onfulfilled: infer F, ...args: infer _): any }
    ? F extends (value: infer V, ...args: infer _) => any
      ? MyAwaited<V>
      : never
    : T;
```

---

## 7. 실전 조합 패턴

```typescript
interface Todo {
  id: number;
  title: string;
  completed: boolean;
  dueDate: Date | null;
  tags: string[];
}

// 생성 DTO: id는 서버에서 부여, dueDate와 tags는 선택적
type CreateTodoDto = Omit<Todo, "id"> & Partial<Pick<Todo, "dueDate" | "tags">>;
// { title: string; completed: boolean; dueDate?: Date | null; tags?: string[] }

// 업데이트 DTO: id는 필수, 나머지는 선택적
type UpdateTodoDto = Pick<Todo, "id"> & Partial<Omit<Todo, "id">>;

// 응답 타입: null 제거 후 Readonly
type TodoResponse = Readonly<{
  [K in keyof Todo]: NonNullable<Todo[K]>
}>;

// 깊은 Partial (중첩 객체에도 적용)
type DeepPartial<T> = T extends object
  ? { [K in keyof T]?: DeepPartial<T[K]> }
  : T;

interface AppConfig {
  server: { host: string; port: number };
  db: { url: string; name: string };
}

type PartialConfig = DeepPartial<AppConfig>;
// 중첩 프로퍼티도 모두 선택적
const config: PartialConfig = { server: { host: "localhost" } }; // OK

// 특정 키를 필수로, 나머지를 선택적으로
type WithRequired<T, K extends keyof T> = Omit<T, K> & Required<Pick<T, K>>;

type UserWithRequiredEmail = WithRequired<Partial<User>, "email">;
// email은 필수, 나머지는 선택적
```

---

## 8. 면접 포인트

### Q1. `Partial`과 `Required`의 내부 구현 원리는?

Mapped Type(`[K in keyof T]`)을 활용합니다. `Partial`은 `?`를 추가하고, `Required`는 `-?`로 선택성 수식어를 제거합니다. 비슷하게 `Readonly`는 `readonly`를 추가하고, `Mutable`(비표준)은 `-readonly`로 제거합니다.

### Q2. `Omit`을 직접 구현한다면?

`Exclude<keyof T, K>`로 제외할 키를 뺀 나머지 키 집합을 구한 뒤, 그 키들로 `Pick`하면 됩니다. 내부적으로 `Exclude`는 분배 조건부 타입(`T extends U ? never : T`)으로 구현됩니다.

### Q3. `ReturnType`과 `typeof` 연산자를 같이 쓰는 이유는?

`ReturnType`은 함수 **타입**을 인자로 받습니다. 함수 **값**(변수나 선언)에서 타입을 얻으려면 `typeof`가 필요합니다. `ReturnType<typeof myFunction>` 패턴은 함수 구현을 변경해도 반환 타입이 자동으로 따라오기 때문에, 반환 타입을 별도로 정의하지 않아도 됩니다.

### Q4. `Record<string, unknown>`과 `object`의 차이는?

`object`는 원시 타입이 아닌 모든 값의 타입이며, 인덱스 접근이 불가합니다. `Record<string, unknown>`은 문자열 키로 인덱싱 가능한 객체를 명시적으로 표현하며, 타입이 `unknown`이어도 키 접근 자체는 허용됩니다. 타입 안전한 동적 객체가 필요할 때 `Record<string, unknown>`을 선호합니다.
