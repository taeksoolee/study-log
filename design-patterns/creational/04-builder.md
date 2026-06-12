# Builder (빌더 패턴)

## 목차
1. [개념](#1-개념)
2. [문제 — 텔레스코핑 생성자 안티패턴](#2-문제--텔레스코핑-생성자-안티패턴)
3. [메서드 체이닝 구현](#3-메서드-체이닝-구현)
4. [Query Builder 예제](#4-query-builder-예제)
5. [불변 객체와 빌더](#5-불변-객체와-빌더)
6. [실제 라이브러리 사례](#6-실제-라이브러리-사례)
7. [면접 포인트](#7-면접-포인트)

---

## 1. 개념

> 복잡한 객체의 **생성 과정을 단계별로 분리**하여, 동일한 생성 프로세스로 서로 다른 표현의 객체를 생성할 수 있게 한다.

**언제 쓰는가?**
- 생성자 매개변수가 많을 때 (4개 이상이면 고려)
- 선택적 매개변수가 많을 때
- 객체를 여러 단계에 걸쳐 설정해야 할 때
- 읽기 쉬운 객체 생성 코드가 필요할 때

---

## 2. 문제 — 텔레스코핑 생성자 안티패턴

```typescript
// 나쁜 예 — 생성자 매개변수가 너무 많음
class HttpRequest {
  constructor(
    url: string,
    method: string,
    headers?: Record<string, string>,
    body?: string,
    timeout?: number,
    retries?: number,
    cache?: boolean,
    credentials?: string,
  ) {}
}

// 사용 시 가독성 최악 — 어떤 인자가 어떤 의미인지 불명확
const req = new HttpRequest(
  'https://api.example.com/users',
  'POST',
  { 'Content-Type': 'application/json' },
  JSON.stringify({ name: 'Alice' }),
  5000,
  3,
  false,
  'include',
);
```

---

## 3. 메서드 체이닝 구현

```typescript
class HttpRequest {
  private _url: string = '';
  private _method: string = 'GET';
  private _headers: Record<string, string> = {};
  private _body: string | undefined;
  private _timeout: number = 30000;
  private _retries: number = 0;

  private constructor() {}

  // 빌더 시작점 — 정적 팩토리 메서드
  static builder(): HttpRequestBuilder {
    return new HttpRequestBuilder();
  }

  // Getters
  get url() { return this._url; }
  get method() { return this._method; }
  get headers() { return this._headers; }
  get body() { return this._body; }
  get timeout() { return this._timeout; }
  get retries() { return this._retries; }
}

class HttpRequestBuilder {
  private request: HttpRequest;

  constructor() {
    this.request = new (HttpRequest as any)();
  }

  url(url: string): this {
    (this.request as any)._url = url;
    return this; // this 반환이 메서드 체이닝의 핵심
  }

  method(method: 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH'): this {
    (this.request as any)._method = method;
    return this;
  }

  header(key: string, value: string): this {
    (this.request as any)._headers[key] = value;
    return this;
  }

  body(body: string): this {
    (this.request as any)._body = body;
    return this;
  }

  timeout(ms: number): this {
    (this.request as any)._timeout = ms;
    return this;
  }

  retries(count: number): this {
    (this.request as any)._retries = count;
    return this;
  }

  json(): this {
    return this.header('Content-Type', 'application/json');
  }

  build(): HttpRequest {
    if (!this.request.url) throw new Error('URL은 필수입니다');
    return this.request;
  }
}

// 사용 — 읽기 좋고 선택적 설정이 명확함
const request = HttpRequest.builder()
  .url('https://api.example.com/users')
  .method('POST')
  .json()
  .header('Authorization', 'Bearer token123')
  .body(JSON.stringify({ name: 'Alice' }))
  .timeout(5000)
  .retries(3)
  .build();
```

---

## 4. Query Builder 예제

데이터베이스 쿼리 빌더는 빌더 패턴의 가장 대표적인 실용 사례다.

```typescript
class QueryBuilder {
  private table: string = '';
  private conditions: string[] = [];
  private columns: string[] = ['*'];
  private orderByClause: string = '';
  private limitClause: number | null = null;
  private joins: string[] = [];

  from(table: string): this {
    this.table = table;
    return this;
  }

  select(...columns: string[]): this {
    this.columns = columns;
    return this;
  }

  where(condition: string): this {
    this.conditions.push(condition);
    return this;
  }

  join(table: string, on: string): this {
    this.joins.push(`JOIN ${table} ON ${on}`);
    return this;
  }

  orderBy(column: string, direction: 'ASC' | 'DESC' = 'ASC'): this {
    this.orderByClause = `ORDER BY ${column} ${direction}`;
    return this;
  }

  limit(n: number): this {
    this.limitClause = n;
    return this;
  }

  build(): string {
    if (!this.table) throw new Error('테이블명이 필요합니다');

    const parts = [
      `SELECT ${this.columns.join(', ')}`,
      `FROM ${this.table}`,
      ...this.joins,
      this.conditions.length > 0
        ? `WHERE ${this.conditions.join(' AND ')}`
        : '',
      this.orderByClause,
      this.limitClause !== null ? `LIMIT ${this.limitClause}` : '',
    ].filter(Boolean);

    return parts.join(' ');
  }
}

// 사용
const query = new QueryBuilder()
  .from('users')
  .select('id', 'name', 'email')
  .join('orders', 'users.id = orders.user_id')
  .where('users.active = true')
  .where('orders.created_at > "2024-01-01"')
  .orderBy('users.name')
  .limit(20)
  .build();

console.log(query);
// SELECT id, name, email FROM users JOIN orders ON users.id = orders.user_id
// WHERE users.active = true AND orders.created_at > "2024-01-01"
// ORDER BY users.name ASC LIMIT 20
```

---

## 5. 불변 객체와 빌더

빌더 패턴은 불변(immutable) 객체 생성에도 효과적이다.

```typescript
// 불변 값 객체
class UserProfile {
  constructor(
    readonly name: string,
    readonly email: string,
    readonly age: number,
    readonly bio: string,
    readonly avatar: string,
  ) {
    Object.freeze(this);
  }

  // 빌더를 통해서만 생성
  static builder() {
    return new UserProfileBuilder();
  }
}

class UserProfileBuilder {
  private _name = '';
  private _email = '';
  private _age = 0;
  private _bio = '';
  private _avatar = '';

  name(name: string): this { this._name = name; return this; }
  email(email: string): this { this._email = email; return this; }
  age(age: number): this { this._age = age; return this; }
  bio(bio: string): this { this._bio = bio; return this; }
  avatar(url: string): this { this._avatar = url; return this; }

  build(): UserProfile {
    if (!this._name || !this._email) {
      throw new Error('이름과 이메일은 필수입니다');
    }
    return new UserProfile(
      this._name, this._email, this._age, this._bio, this._avatar
    );
  }
}

const profile = UserProfile.builder()
  .name('Alice')
  .email('alice@example.com')
  .age(30)
  .build();
```

---

## 6. 실제 라이브러리 사례

| 라이브러리 | 빌더 패턴 활용 |
|-----------|---------------|
| **Knex.js** | `knex('users').select('*').where({ active: true }).limit(10)` |
| **Axios** | `axios.create({ baseURL, timeout, headers })` |
| **Jest** | `expect(value).toBe(x)`, `jest.fn().mockReturnValue(y)` |
| **Zod** | `z.string().min(3).max(20).email()` |
| **Tailwind CSS** | 클래스 조합 방식이 빌더 개념과 유사 |

---

## 7. 면접 포인트

**Q1. 빌더 패턴이란 무엇이고 언제 사용하나요?**
> 복잡한 객체를 단계적으로 구성하는 패턴입니다. 생성자 매개변수가 많거나 선택적 매개변수가 많을 때, 가독성 있는 객체 생성 코드가 필요할 때 사용합니다.

**Q2. 메서드 체이닝은 어떻게 구현하나요?**
> 각 설정 메서드에서 `return this`를 반환합니다. 이를 통해 연속 호출이 가능합니다.

**Q3. Zod와 빌더 패턴의 관계를 설명해주세요.**
> Zod의 `z.string().min(3).email()`은 메서드 체이닝 기반 빌더 패턴입니다. 각 단계에서 새 스키마 객체를 반환하며 유효성 검사 규칙을 누적합니다.

**Q4. 빌더 패턴의 단점은?**
> 코드 양이 증가합니다. 단순한 객체에 적용하면 오히려 과설계(over-engineering)가 됩니다.

---

[← Abstract Factory](./03-abstract-factory.md) | [← 생성 패턴 목차](./README.md) | [다음: Prototype →](./05-prototype.md)
