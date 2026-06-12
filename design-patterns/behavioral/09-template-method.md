# Template Method (템플릿 메서드 패턴)

## 목차
1. [개념](#1-개념)
2. [추상 클래스 기반 구현](#2-추상-클래스-기반-구현)
3. [훅 메서드 (선택적 오버라이드)](#3-훅-메서드-선택적-오버라이드)
4. [데이터 파서 예제](#4-데이터-파서-예제)
5. [React 라이프사이클과의 연결](#5-react-라이프사이클과의-연결)
6. [함수형 방식으로 구현](#6-함수형-방식으로-구현)
7. [면접 포인트](#7-면접-포인트)

---

## 1. 개념

> 상위 클래스에서 **알고리즘의 골격(템플릿)을 정의**하고,
> 일부 단계를 서브클래스가 구현하도록 위임한다.

**언제 쓰는가?**
- 여러 클래스가 같은 알고리즘 구조를 공유하지만 세부 구현이 다를 때
- 중복된 코드를 상위 클래스로 끌어올리고 싶을 때
- 서브클래스의 확장 포인트를 명확히 정의하고 싶을 때

**전략 패턴 vs 템플릿 메서드**
- 전략: 합성(composition) 사용, 런타임에 교체 가능
- 템플릿 메서드: 상속(inheritance) 사용, 컴파일 타임에 결정

---

## 2. 추상 클래스 기반 구현

```typescript
// 음료 제조 알고리즘 — 클래식 예제
abstract class BeverageTemplate {
  // 템플릿 메서드 — 알고리즘 골격 (final로 선언하면 이상적이지만 TS에선 관례)
  prepare(): void {
    this.boilWater();
    this.brew();
    this.pourInCup();
    if (this.customerWantsCondiments()) {
      this.addCondiments();
    }
  }

  // 공통 단계 — 변하지 않는 부분
  private boilWater(): void {
    console.log('물 끓이기');
  }

  private pourInCup(): void {
    console.log('컵에 따르기');
  }

  // 추상 메서드 — 서브클래스가 반드시 구현
  protected abstract brew(): void;
  protected abstract addCondiments(): void;

  // 훅 메서드 — 기본 구현 제공, 오버라이드 선택적
  protected customerWantsCondiments(): boolean {
    return true;
  }
}

class Tea extends BeverageTemplate {
  protected brew(): void {
    console.log('찻잎 우리기');
  }

  protected addCondiments(): void {
    console.log('레몬 추가');
  }
}

class Coffee extends BeverageTemplate {
  protected brew(): void {
    console.log('커피 필터에 드리기');
  }

  protected addCondiments(): void {
    console.log('설탕과 우유 추가');
  }

  // 훅 메서드 오버라이드
  protected customerWantsCondiments(): boolean {
    const answer = prompt('설탕/우유를 넣을까요? (y/n)') || 'n';
    return answer.toLowerCase() === 'y';
  }
}

// 사용
const tea = new Tea();
tea.prepare();
// 물 끓이기 → 찻잎 우리기 → 컵에 따르기 → 레몬 추가

const coffee = new Coffee();
coffee.prepare();
// 물 끓이기 → 커피 필터에 드리기 → 컵에 따르기 → (선택적) 설탕과 우유 추가
```

---

## 3. 훅 메서드 (선택적 오버라이드)

```typescript
// API 요청 템플릿
abstract class ApiRequestTemplate<TRequest, TResponse> {
  // 템플릿 메서드
  async execute(request: TRequest): Promise<TResponse> {
    this.logRequest(request);

    // 전처리 훅 (선택적)
    const processedRequest = await this.preProcess(request);

    let response: TResponse;
    try {
      response = await this.fetchData(processedRequest);
    } catch (err) {
      return this.handleError(err as Error);
    }

    // 후처리 훅 (선택적)
    const processedResponse = await this.postProcess(response);
    this.logResponse(processedResponse);

    return processedResponse;
  }

  // 서브클래스가 반드시 구현
  protected abstract fetchData(request: TRequest): Promise<TResponse>;

  // 훅 메서드 — 기본 구현 있음, 오버라이드 선택적
  protected async preProcess(request: TRequest): Promise<TRequest> {
    return request;
  }

  protected async postProcess(response: TResponse): Promise<TResponse> {
    return response;
  }

  protected handleError(error: Error): never {
    throw error;
  }

  protected logRequest(request: TRequest): void {
    console.log('[Request]', request);
  }

  protected logResponse(response: TResponse): void {
    console.log('[Response]', response);
  }
}

// 구체 구현
class UserApiRequest extends ApiRequestTemplate<{ userId: number }, User> {
  protected async fetchData({ userId }: { userId: number }): Promise<User> {
    const res = await fetch(`/api/users/${userId}`);
    return res.json();
  }

  // 응답 후처리 오버라이드
  protected async postProcess(user: User): Promise<User> {
    return { ...user, fullName: `${user.firstName} ${user.lastName}` };
  }
}
```

---

## 4. 데이터 파서 예제

```typescript
// CSV, JSON, XML 파싱의 공통 알고리즘 구조
abstract class DataParser<T> {
  // 템플릿 메서드
  parse(raw: string): T[] {
    const validated = this.validate(raw);
    const rows = this.extractRows(validated);
    const items = rows.map(row => this.parseRow(row));
    return this.postProcess(items);
  }

  // 공통 단계
  private validate(raw: string): string {
    if (!raw || raw.trim().length === 0) {
      throw new Error('빈 입력');
    }
    return raw.trim();
  }

  // 추상 메서드
  protected abstract extractRows(data: string): string[];
  protected abstract parseRow(row: string): T;

  // 훅
  protected postProcess(items: T[]): T[] {
    return items;
  }
}

class CsvParser extends DataParser<Record<string, string>> {
  constructor(private delimiter = ',') { super(); }

  protected extractRows(data: string): string[] {
    const lines = data.split('\n').filter(Boolean);
    return lines.slice(1); // 헤더 제거
  }

  protected parseRow(row: string): Record<string, string> {
    const headers = ['id', 'name', 'email']; // 실제로는 첫 줄에서 파싱
    const values = row.split(this.delimiter);
    return Object.fromEntries(headers.map((h, i) => [h, values[i]?.trim() || '']));
  }
}

class JsonlParser<T> extends DataParser<T> {
  protected extractRows(data: string): string[] {
    return data.split('\n').filter(Boolean);
  }

  protected parseRow(row: string): T {
    return JSON.parse(row);
  }
}

// 사용
const csvParser = new CsvParser();
const users = csvParser.parse(`id,name,email
1,Alice,alice@example.com
2,Bob,bob@example.com`);
```

---

## 5. React 라이프사이클과의 연결

React 클래스 컴포넌트의 라이프사이클은 템플릿 메서드 패턴이다.

```typescript
// React의 Component 클래스가 템플릿을 정의
class Component<P, S> {
  // 템플릿 메서드 — React가 호출하는 렌더링 파이프라인
  _mount(): void {
    this.componentDidMount?.();    // 훅 (선택적)
  }

  _update(prevProps: P, prevState: S): void {
    if (this.shouldComponentUpdate?.(prevProps, prevState) !== false) {
      // 실제 업데이트 수행
      this.componentDidUpdate?.(prevProps, prevState); // 훅
    }
  }

  _unmount(): void {
    this.componentWillUnmount?.(); // 훅
  }

  // 서브클래스가 반드시 구현 (추상 메서드)
  abstract render(): JSX.Element;

  // 훅 메서드들 (선택적 오버라이드)
  componentDidMount?(): void;
  shouldComponentUpdate?(nextProps: P, nextState: S): boolean;
  componentDidUpdate?(prevProps: P, prevState: S): void;
  componentWillUnmount?(): void;
}

// 서브클래스가 세부 구현
class MyComponent extends React.Component {
  componentDidMount() {
    console.log('마운트됨');
  }

  render() {
    return <div>Hello</div>;
  }
}
```

---

## 6. 함수형 방식으로 구현

```typescript
// 상속 없이 함수로 템플릿 메서드 구현
interface RequestOptions<TReq, TRes> {
  fetch: (req: TReq) => Promise<TRes>;
  preProcess?: (req: TReq) => TReq | Promise<TReq>;
  postProcess?: (res: TRes) => TRes | Promise<TRes>;
  onError?: (err: Error) => never;
}

function createApiRequest<TReq, TRes>(options: RequestOptions<TReq, TRes>) {
  return async (request: TReq): Promise<TRes> => {
    const processedReq = options.preProcess
      ? await options.preProcess(request)
      : request;

    let response: TRes;
    try {
      response = await options.fetch(processedReq);
    } catch (err) {
      if (options.onError) return options.onError(err as Error);
      throw err;
    }

    return options.postProcess ? options.postProcess(response) : response;
  };
}

// 사용 — 훅만 주입
const fetchUser = createApiRequest({
  fetch: async (id: number) => {
    const res = await fetch(`/api/users/${id}`);
    return res.json();
  },
  postProcess: (user) => ({ ...user, displayName: user.name.toUpperCase() }),
});
```

---

## 7. 면접 포인트

**Q1. 템플릿 메서드 패턴이란 무엇인가요?**
> 상위 클래스에서 알고리즘의 골격을 정의하고, 구체적인 단계 구현을 서브클래스에 위임하는 패턴입니다. "알고리즘 구조는 고정, 세부 구현은 유연"이 핵심입니다.

**Q2. 전략 패턴과의 차이를 설명해주세요.**
> 템플릿 메서드는 상속을 사용하고 알고리즘의 구조 자체를 재사용합니다. 전략 패턴은 합성을 사용하고 알고리즘 전체를 교체합니다.

**Q3. 훅 메서드(Hook Method)란 무엇인가요?**
> 선택적으로 오버라이드할 수 있는 메서드입니다. 기본 구현이 있지만(빈 구현 또는 기본 동작), 서브클래스가 원하면 재정의할 수 있습니다.

**Q4. React 클래스 컴포넌트와 템플릿 메서드의 관계는?**
> React.Component가 렌더링 파이프라인(템플릿)을 정의합니다. `componentDidMount`, `render`, `componentWillUnmount` 등이 서브클래스가 구현/오버라이드할 수 있는 훅 메서드입니다.

---

[← Strategy](./08-strategy.md) | [← 행동 패턴 목차](./README.md) | [다음: Visitor →](./10-visitor.md)
