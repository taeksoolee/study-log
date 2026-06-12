# 5. 데코레이터 (Decorators)

## 목차
1. 데코레이터 개념과 설정
2. 클래스 데코레이터
3. 메서드 데코레이터
4. 프로퍼티 데코레이터
5. 매개변수 데코레이터
6. 데코레이터 팩토리와 합성
7. 실용 예시
8. 면접 포인트

---

## 1. 데코레이터 개념과 설정

데코레이터는 클래스, 메서드, 프로퍼티, 매개변수에 메타데이터나 동작을 추가하는 선언적 문법입니다. AOP(관점 지향 프로그래밍)의 TypeScript 구현입니다.

```json
// tsconfig.json 설정 필요
{
  "compilerOptions": {
    "experimentalDecorators": true,   // 레거시 데코레이터 (현재 주류)
    "emitDecoratorMetadata": true     // 메타데이터 반사 (reflect-metadata 필요)
  }
}
```

```typescript
// 데코레이터의 실행 순서
// 1. 프로퍼티 데코레이터
// 2. 메서드 데코레이터 (매개변수 데코레이터 먼저)
// 3. 클래스 데코레이터
// 동일 대상에 여러 데코레이터: 아래에서 위로 실행 (수학의 합성 함수처럼)

@classDecorator       // 3번째 실행
class MyClass {
  @propDecorator      // 1번째 실행
  myProp: string = "";

  @methodDecorator    // 2번째 실행
  myMethod() {}
}
```

---

## 2. 클래스 데코레이터

클래스 생성자를 인자로 받습니다. 클래스 자체를 수정하거나 래핑합니다.

```typescript
// 기본 형식: 생성자를 인자로 받음
function sealed(constructor: Function): void {
  Object.seal(constructor);
  Object.seal(constructor.prototype);
}

@sealed
class BugReport {
  type = "report";
  title: string;
  constructor(t: string) {
    this.title = t;
  }
}

// 새 생성자 반환: 클래스를 완전히 교체
function reportable<T extends { new(...args: any[]): { reportingURL: string } }>(
  constructor: T
) {
  return class extends constructor {
    reportingURL = "http://www.example.com";
  };
}

@reportable
class BugReport2 {
  reportingURL = "";
  title: string;
  constructor(t: string) { this.title = t; }
}

const bug = new BugReport2("Some Bug");
console.log(bug.reportingURL); // "http://www.example.com"

// 실용 예시: 싱글톤 데코레이터
function Singleton<T extends { new(...args: any[]): any }>(constructor: T) {
  let instance: InstanceType<T>;
  return new Proxy(constructor, {
    construct(target, args) {
      if (!instance) {
        instance = new target(...args);
      }
      return instance;
    }
  });
}

@Singleton
class DatabaseConnection {
  private url: string;
  constructor(url: string) {
    this.url = url;
    console.log(`Connected to ${url}`);
  }
  query(sql: string) { return `Result of: ${sql}`; }
}

const db1 = new DatabaseConnection("postgres://localhost/mydb");
const db2 = new DatabaseConnection("postgres://localhost/other");
console.log(db1 === db2); // true: 같은 인스턴스
```

---

## 3. 메서드 데코레이터

메서드의 프로퍼티 디스크립터를 받아 동작을 변경합니다.

```typescript
// 형식: (target, propertyKey, descriptor)
// target: 정적 메서드면 생성자, 인스턴스 메서드면 프로토타입
// propertyKey: 메서드 이름
// descriptor: PropertyDescriptor (value, writable, enumerable, configurable)

// 로깅 데코레이터
function log(target: any, propertyKey: string, descriptor: PropertyDescriptor) {
  const originalMethod = descriptor.value;
  descriptor.value = function(...args: any[]) {
    console.log(`[${new Date().toISOString()}] ${propertyKey} called with:`, args);
    const result = originalMethod.apply(this, args);
    console.log(`[${new Date().toISOString()}] ${propertyKey} returned:`, result);
    return result;
  };
  return descriptor;
}

// 실행 시간 측정 데코레이터
function measure(target: any, propertyKey: string, descriptor: PropertyDescriptor) {
  const originalMethod = descriptor.value;
  descriptor.value = async function(...args: any[]) {
    const start = performance.now();
    const result = await originalMethod.apply(this, args);
    const duration = performance.now() - start;
    console.log(`${propertyKey} took ${duration.toFixed(2)}ms`);
    return result;
  };
  return descriptor;
}

// 재시도 데코레이터 (팩토리)
function retry(times: number, delay: number = 0) {
  return function(target: any, propertyKey: string, descriptor: PropertyDescriptor) {
    const originalMethod = descriptor.value;
    descriptor.value = async function(...args: any[]) {
      for (let attempt = 0; attempt <= times; attempt++) {
        try {
          return await originalMethod.apply(this, args);
        } catch (error) {
          if (attempt === times) throw error;
          console.log(`Attempt ${attempt + 1} failed, retrying in ${delay}ms...`);
          if (delay > 0) await new Promise(r => setTimeout(r, delay));
        }
      }
    };
    return descriptor;
  };
}

class ApiService {
  @log
  greet(name: string): string {
    return `Hello, ${name}!`;
  }

  @measure
  @retry(3, 1000)
  async fetchData(url: string): Promise<any> {
    const res = await fetch(url);
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return res.json();
  }
}

// enumerable 데코레이터
function enumerable(value: boolean) {
  return function(target: any, propertyKey: string, descriptor: PropertyDescriptor) {
    descriptor.enumerable = value;
    return descriptor;
  };
}

class Greeter {
  @enumerable(false)
  greet() {
    return "Hello!";
  }
}
```

---

## 4. 프로퍼티 데코레이터

프로퍼티에 대한 메타데이터를 기록하거나 게터/세터를 추가합니다.

```typescript
import "reflect-metadata";

// 유효성 검사 메타데이터 데코레이터
function Required2(target: any, propertyKey: string): void {
  const existing: string[] = Reflect.getMetadata("required", target) ?? [];
  Reflect.defineMetadata("required", [...existing, propertyKey], target);
}

function MinLength(min: number) {
  return function(target: any, propertyKey: string): void {
    Reflect.defineMetadata("minLength", min, target, propertyKey);
  };
}

function validate(obj: any): { valid: boolean; errors: string[] } {
  const errors: string[] = [];
  const required: string[] = Reflect.getMetadata("required", obj) ?? [];

  for (const key of required) {
    if (!obj[key]) errors.push(`${key} is required`);
  }

  for (const key of Object.keys(obj)) {
    const minLen = Reflect.getMetadata("minLength", obj, key);
    if (minLen && typeof obj[key] === "string" && obj[key].length < minLen) {
      errors.push(`${key} must be at least ${minLen} characters`);
    }
  }

  return { valid: errors.length === 0, errors };
}

class CreateUserDto {
  @Required2
  @MinLength(2)
  name: string = "";

  @Required2
  @MinLength(5)
  email: string = "";

  password: string = "";
}

const dto = new CreateUserDto();
dto.name = "A"; // 너무 짧음
const result = validate(dto);
// { valid: false, errors: ["email is required", "name must be at least 2 characters"] }

// 게터/세터 자동 생성 데코레이터
function observable(target: any, propertyKey: string): void {
  const storageKey = `_${propertyKey}`;

  Object.defineProperty(target, propertyKey, {
    get() { return this[storageKey]; },
    set(value: any) {
      const oldValue = this[storageKey];
      this[storageKey] = value;
      if (oldValue !== value) {
        console.log(`${propertyKey} changed: ${oldValue} → ${value}`);
      }
    },
    enumerable: true,
    configurable: true,
  });
}

class State {
  @observable
  count: number = 0;
}

const state = new State();
state.count = 1; // "count changed: undefined → 1"
state.count = 2; // "count changed: 1 → 2"
```

---

## 5. 매개변수 데코레이터

메서드의 특정 매개변수에 메타데이터를 주입합니다.

```typescript
import "reflect-metadata";

const INJECT_METADATA_KEY = Symbol("inject");

function Inject(token: string) {
  return function(target: any, propertyKey: string | undefined, parameterIndex: number): void {
    const existing: { index: number; token: string }[] =
      Reflect.getMetadata(INJECT_METADATA_KEY, target, propertyKey!) ?? [];
    Reflect.defineMetadata(
      INJECT_METADATA_KEY,
      [...existing, { index: parameterIndex, token }],
      target,
      propertyKey!
    );
  };
}

class UserController {
  getUser(
    @Inject("userId") id: number,
    @Inject("requestId") requestId: string
  ): string {
    return `User ${id} (request: ${requestId})`;
  }
}

// 의존성 주입 컨테이너에서 활용하는 패턴 (NestJS 등)
```

---

## 6. 데코레이터 팩토리와 합성

```typescript
// 데코레이터 팩토리: 데코레이터를 반환하는 함수
// 인자를 받아 동작을 커스터마이징
function throttle(milliseconds: number) {
  return function(target: any, propertyKey: string, descriptor: PropertyDescriptor) {
    const originalMethod = descriptor.value;
    let lastCall = 0;

    descriptor.value = function(...args: any[]) {
      const now = Date.now();
      if (now - lastCall >= milliseconds) {
        lastCall = now;
        return originalMethod.apply(this, args);
      }
    };

    return descriptor;
  };
}

function debounce(milliseconds: number) {
  return function(target: any, propertyKey: string, descriptor: PropertyDescriptor) {
    const originalMethod = descriptor.value;
    let timer: ReturnType<typeof setTimeout>;

    descriptor.value = function(...args: any[]) {
      clearTimeout(timer);
      timer = setTimeout(() => originalMethod.apply(this, args), milliseconds);
    };

    return descriptor;
  };
}

class SearchComponent {
  @debounce(300)
  onInput(value: string): void {
    console.log("Searching for:", value);
  }

  @throttle(1000)
  onScroll(): void {
    console.log("Scroll handler");
  }
}

// 데코레이터 합성 순서: 평가는 위→아래, 실행은 아래→위
function first() {
  console.log("first(): factory");
  return function(_: any, __: string, ___: PropertyDescriptor) {
    console.log("first(): decorator"); // 두 번째 실행
  };
}

function second() {
  console.log("second(): factory");
  return function(_: any, __: string, ___: PropertyDescriptor) {
    console.log("second(): decorator"); // 첫 번째 실행
  };
}

class Example {
  @first()   // factory 평가: 1번
  @second()  // factory 평가: 2번
  method() {} // second 데코레이터 먼저 실행, first 데코레이터 나중 실행
}
// 출력:
// "first(): factory"
// "second(): factory"
// "second(): decorator"
// "first(): decorator"
```

---

## 7. 실용 예시

```typescript
// NestJS 스타일 컨트롤러 데코레이터
const routes: { path: string; method: string; handler: string }[] = [];

function Controller(prefix: string) {
  return function(constructor: Function) {
    Reflect.defineMetadata("prefix", prefix, constructor);
  };
}

function Get(path: string) {
  return function(target: any, propertyKey: string) {
    routes.push({ path, method: "GET", handler: propertyKey });
  };
}

function Post(path: string) {
  return function(target: any, propertyKey: string) {
    routes.push({ path, method: "POST", handler: propertyKey });
  };
}

@Controller("/api/users")
class UserController2 {
  @Get("/")
  findAll() { return []; }

  @Get("/:id")
  findOne() { return {}; }

  @Post("/")
  create() { return {}; }
}

// 캐시 데코레이터
function Cache(ttl: number = 60) {
  const store = new Map<string, { value: any; expiresAt: number }>();

  return function(target: any, propertyKey: string, descriptor: PropertyDescriptor) {
    const originalMethod = descriptor.value;

    descriptor.value = async function(...args: any[]) {
      const key = `${propertyKey}:${JSON.stringify(args)}`;
      const cached = store.get(key);

      if (cached && cached.expiresAt > Date.now()) {
        console.log(`[Cache HIT] ${key}`);
        return cached.value;
      }

      console.log(`[Cache MISS] ${key}`);
      const value = await originalMethod.apply(this, args);
      store.set(key, { value, expiresAt: Date.now() + ttl * 1000 });
      return value;
    };

    return descriptor;
  };
}

class ProductService {
  @Cache(300) // 5분 캐시
  async getProduct(id: number) {
    // DB 조회 (느린 작업)
    return { id, name: `Product ${id}`, price: 1000 };
  }
}
```

---

## 8. 면접 포인트

### Q1. 데코레이터란 무엇이고 AOP와의 관계는?

데코레이터는 클래스/메서드/프로퍼티의 동작을 선언적으로 수정하는 함수입니다. AOP(관점 지향 프로그래밍)의 구현체로, 핵심 비즈니스 로직(관심사)과 로깅, 캐싱, 인증 등의 횡단 관심사(cross-cutting concerns)를 분리할 수 있습니다. NestJS, TypeORM 등 Node.js 프레임워크에서 핵심 기능으로 활용됩니다.

### Q2. 메서드 데코레이터에서 `descriptor.value`를 직접 교체하면 어떤 문제가 생길 수 있나요?

`this` 바인딩 문제가 발생할 수 있습니다. 원본 메서드를 호출할 때 반드시 `originalMethod.apply(this, args)`처럼 `this`를 명시적으로 전달해야 합니다. 화살표 함수로 교체하면 `this`가 고정되어 서브클래스에서 override가 불가능해집니다.

### Q3. 데코레이터 실행 순서는?

같은 클래스에서: 프로퍼티 → 메서드(매개변수 먼저) → 클래스 데코레이터 순서로 평가됩니다. 여러 데코레이터가 같은 대상에 쌓인 경우: 팩토리는 위→아래 평가, 실행은 아래→위 순서입니다 (수학 합성 함수와 동일).

### Q4. `experimentalDecorators`와 TC39 Stage 3 데코레이터의 차이는?

현재 주류인 `experimentalDecorators`는 TypeScript 고유 구현으로 ES 표준이 아닙니다. TC39 Stage 3 데코레이터(TypeScript 5.0+에서 지원)는 공식 표준을 따르며 API가 다릅니다. 인자 수, 반환 방식, 실행 시점이 일부 달라서 마이그레이션 시 코드 수정이 필요합니다.

### Q5. `reflect-metadata`는 왜 필요한가요?

`emitDecoratorMetadata` 옵션을 켜면 TypeScript가 런타임에 타입 정보를 메타데이터로 emit합니다. `reflect-metadata` 라이브러리는 이 메타데이터를 읽고 쓰는 `Reflect.defineMetadata`/`Reflect.getMetadata` API를 제공합니다. NestJS의 의존성 주입은 이 메커니즘으로 생성자 매개변수 타입을 런타임에 읽어 자동으로 주입합니다.
