# Decorator (데코레이터 패턴)

## 목차
1. [개념](#1-개념)
2. [함수 데코레이터 (JS 방식)](#2-함수-데코레이터-js-방식)
3. [클래스 기반 데코레이터](#3-클래스-기반-데코레이터)
4. [TypeScript 데코레이터](#4-typescript-데코레이터)
5. [미들웨어 패턴과의 관계](#5-미들웨어-패턴과의-관계)
6. [React HOC와 데코레이터](#6-react-hoc와-데코레이터)
7. [면접 포인트](#7-면접-포인트)

---

## 1. 개념

> 객체에 **동적으로 책임을 추가**한다. 서브클래싱보다 유연한 기능 확장 방법을 제공한다.

기존 객체를 새 객체로 감싸서(wrap) 기능을 추가한다.
원본 객체의 인터페이스를 유지하므로 클라이언트는 차이를 모른다.

**언제 쓰는가?**
- 상속 없이 객체에 기능을 추가하고 싶을 때
- 런타임에 동적으로 기능을 추가/제거해야 할 때
- 여러 기능의 다양한 조합이 필요할 때 (N가지 기능 = 2^N 서브클래스 문제 해결)

**구조**
```
Component (interface)
└─ operation()

ConcreteComponent      BaseDecorator
└─ operation()         ├─ wrappee: Component
                       └─ operation() → wrappee.operation()

ConcreteDecoratorA     ConcreteDecoratorB
└─ operation()         └─ operation()
   super() + 추가 기능    super() + 추가 기능
```

---

## 2. 함수 데코레이터 (JS 방식)

JavaScript에서는 함수를 래핑하는 것이 가장 자연스러운 데코레이터 방식이다.

```typescript
// 기본 함수
function fetchUser(id: number): Promise<{ id: number; name: string }> {
  return fetch(`/api/users/${id}`).then(r => r.json());
}

// 데코레이터 팩토리 — 로깅 추가
function withLogging<T extends (...args: any[]) => Promise<any>>(fn: T): T {
  return (async (...args: any[]) => {
    console.log(`[LOG] 호출: ${fn.name}(${JSON.stringify(args)})`);
    const start = Date.now();
    try {
      const result = await fn(...args);
      console.log(`[LOG] 성공: ${fn.name} (${Date.now() - start}ms)`);
      return result;
    } catch (err) {
      console.error(`[LOG] 실패: ${fn.name}`, err);
      throw err;
    }
  }) as T;
}

// 데코레이터 팩토리 — 캐싱 추가
function withCache<T extends (...args: any[]) => Promise<any>>(fn: T, ttl = 60000): T {
  const cache = new Map<string, { value: any; expires: number }>();
  return (async (...args: any[]) => {
    const key = JSON.stringify(args);
    const cached = cache.get(key);
    if (cached && cached.expires > Date.now()) {
      console.log(`[CACHE] Hit: ${fn.name}`);
      return cached.value;
    }
    const result = await fn(...args);
    cache.set(key, { value: result, expires: Date.now() + ttl });
    return result;
  }) as T;
}

// 데코레이터 조합 — 함수를 겹겹이 감쌈
const enhancedFetchUser = withLogging(withCache(fetchUser));
// 호출 시: 로깅 → 캐시 확인 → (미스 시) API 호출 → 캐시 저장 → 로깅
```

---

## 3. 클래스 기반 데코레이터

```typescript
interface TextProcessor {
  process(text: string): string;
}

// 기본 구현
class PlainTextProcessor implements TextProcessor {
  process(text: string): string {
    return text;
  }
}

// 기본 데코레이터
abstract class TextDecorator implements TextProcessor {
  constructor(protected wrapped: TextProcessor) {}
  process(text: string): string {
    return this.wrapped.process(text);
  }
}

// 구체 데코레이터들
class TrimDecorator extends TextDecorator {
  process(text: string): string {
    return super.process(text).trim();
  }
}

class UpperCaseDecorator extends TextDecorator {
  process(text: string): string {
    return super.process(text).toUpperCase();
  }
}

class XssFilterDecorator extends TextDecorator {
  process(text: string): string {
    return super.process(text)
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }
}

class EllipsisDecorator extends TextDecorator {
  constructor(wrapped: TextProcessor, private maxLength: number) {
    super(wrapped);
  }
  process(text: string): string {
    const processed = super.process(text);
    return processed.length > this.maxLength
      ? processed.slice(0, this.maxLength) + '...'
      : processed;
  }
}

// 데코레이터 조합 — 순서가 중요
const processor = new EllipsisDecorator(
  new XssFilterDecorator(
    new TrimDecorator(
      new PlainTextProcessor()
    )
  ),
  50
);

const result = processor.process('  <script>alert("xss")</script> 안녕하세요  ');
console.log(result); // '&lt;script&gt;alert(&quot;xss&quot;)&lt;/script&gt; 안녕하세요'
```

---

## 4. TypeScript 데코레이터

TypeScript의 실험적 데코레이터 기능(Stage 3 TC39 제안)이다.

```typescript
// tsconfig.json: "experimentalDecorators": true

// 메서드 데코레이터 — 실행 시간 측정
function Measure(
  target: any,
  key: string,
  descriptor: PropertyDescriptor
) {
  const original = descriptor.value;
  descriptor.value = async function (...args: any[]) {
    const start = performance.now();
    const result = await original.apply(this, args);
    const elapsed = (performance.now() - start).toFixed(2);
    console.log(`${key} 실행 시간: ${elapsed}ms`);
    return result;
  };
  return descriptor;
}

// 메서드 데코레이터 — 에러 재시도
function Retry(times: number) {
  return function(target: any, key: string, descriptor: PropertyDescriptor) {
    const original = descriptor.value;
    descriptor.value = async function (...args: any[]) {
      for (let attempt = 1; attempt <= times; attempt++) {
        try {
          return await original.apply(this, args);
        } catch (err) {
          if (attempt === times) throw err;
          console.warn(`${key} 재시도 ${attempt}/${times}`);
        }
      }
    };
    return descriptor;
  };
}

class ApiService {
  @Measure
  @Retry(3)
  async fetchData(url: string) {
    const response = await fetch(url);
    return response.json();
  }
}
```

---

## 5. 미들웨어 패턴과의 관계

Express.js의 미들웨어는 데코레이터 패턴의 함수형 변형이다.

```typescript
// Express 미들웨어 = 함수를 체인으로 연결하는 데코레이터
app.use(cors());           // 데코레이터: CORS 헤더 추가
app.use(express.json());   // 데코레이터: JSON 파싱
app.use(authMiddleware);   // 데코레이터: 인증 검사
app.use(rateLimiter);      // 데코레이터: 요청 제한

// 각 미들웨어가 req/res를 감싸서 기능을 추가하고 다음으로 전달

// 커스텀 미들웨어 데코레이터 패턴
function compose(...middlewares: Middleware[]) {
  return function(req: Request, res: Response) {
    let index = 0;
    function next() {
      if (index < middlewares.length) {
        middlewares[index++](req, res, next);
      }
    }
    next();
  };
}
```

---

## 6. React HOC와 데코레이터

React의 Higher Order Component(HOC)는 컴포넌트 데코레이터다.

```tsx
// HOC = 컴포넌트를 받아 기능이 추가된 컴포넌트를 반환
function withAuth<P extends object>(
  WrappedComponent: React.ComponentType<P>
): React.FC<P> {
  return function AuthGuard(props: P) {
    const { isAuthenticated } = useAuth();
    if (!isAuthenticated) return <Navigate to="/login" />;
    return <WrappedComponent {...props} />;
  };
}

function withLoading<P extends object>(
  WrappedComponent: React.ComponentType<P>
): React.FC<P & { isLoading?: boolean }> {
  return function WithLoading({ isLoading, ...props }) {
    if (isLoading) return <Spinner />;
    return <WrappedComponent {...(props as P)} />;
  };
}

// 데코레이터 조합
const EnhancedDashboard = withAuth(withLoading(Dashboard));

// 현대 React에서는 HOC 대신 커스텀 훅 권장
// 하지만 패턴 이해를 위해 HOC도 중요
```

---

## 7. 면접 포인트

**Q1. 데코레이터 패턴이란 무엇인가요?**
> 객체를 다른 객체로 감싸서 기존 동작을 유지하면서 새로운 기능을 동적으로 추가하는 패턴입니다. 상속 없이 기능을 확장할 수 있습니다.

**Q2. 상속 vs 데코레이터의 트레이드오프는?**
> 상속은 컴파일 타임에 기능이 고정됩니다. 데코레이터는 런타임에 동적으로 기능을 추가/제거할 수 있고, 조합이 자유롭습니다. 단, 데코레이터가 많이 쌓이면 디버깅이 어려울 수 있습니다.

**Q3. React HOC와 데코레이터 패턴의 관계를 설명해주세요.**
> HOC는 컴포넌트(함수)를 감싸서 기능을 추가하는 컴포넌트 수준의 데코레이터 패턴입니다. `withAuth(Dashboard)`는 대시보드 컴포넌트에 인증 기능을 동적으로 추가합니다.

**Q4. Express 미들웨어와 데코레이터의 관계는?**
> Express 미들웨어 체인은 함수형 데코레이터 패턴입니다. 각 미들웨어가 req/res를 가로채어 처리하고 다음으로 전달(next)하는 구조입니다.

---

[← Composite](./03-composite.md) | [← 구조 패턴 목차](./README.md) | [다음: Facade →](./05-facade.md)
