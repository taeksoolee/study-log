# Chain of Responsibility (책임 연쇄 패턴)

## 목차
1. [개념](#1-개념)
2. [클래스 기반 구현](#2-클래스-기반-구현)
3. [함수형 체인 구현](#3-함수형-체인-구현)
4. [Express.js 미들웨어 체인과의 연결](#4-expressjs-미들웨어-체인과의-연결)
5. [DOM 이벤트 버블링과의 연결](#5-dom-이벤트-버블링과의-연결)
6. [면접 포인트](#6-면접-포인트)

---

## 1. 개념

> 요청을 처리할 수 있는 객체를 찾을 때까지 **체인을 따라 요청을 전달**한다.
> 발신자와 수신자를 분리한다.

**언제 쓰는가?**
- 요청을 처리할 객체가 런타임에 결정될 때
- 여러 객체가 요청을 처리할 기회를 가져야 할 때
- 처리 순서를 동적으로 변경하거나 확장해야 할 때

**구조**
```
Client → Handler1 → Handler2 → Handler3 → null
           │           │           │
         처리함      처리함       처리함
           │         (또는       (또는
        (중단)       next())     next())
```

---

## 2. 클래스 기반 구현

```typescript
// 추상 핸들러
abstract class Handler<T> {
  private next: Handler<T> | null = null;

  setNext(handler: Handler<T>): Handler<T> {
    this.next = handler;
    return handler; // 체이닝 가능: h1.setNext(h2).setNext(h3)
  }

  handle(request: T): void {
    if (this.next) {
      this.next.handle(request);
    }
  }
}

// HTTP 요청 처리 체인 예제
interface HttpRequest {
  method: string;
  path: string;
  headers: Record<string, string>;
  body?: string;
  user?: { id: number; role: string };
}

interface HttpResponse {
  status: number;
  body: string;
}

// 로깅 핸들러
class LoggingHandler extends Handler<HttpRequest> {
  handle(request: HttpRequest): void {
    console.log(`[LOG] ${request.method} ${request.path}`);
    super.handle(request); // 다음으로 전달
  }
}

// 인증 핸들러
class AuthHandler extends Handler<HttpRequest> {
  handle(request: HttpRequest): void {
    const token = request.headers['authorization'];
    if (!token) {
      console.log('[AUTH] 401 Unauthorized — 체인 중단');
      return; // 체인 중단
    }
    request.user = { id: 1, role: 'admin' }; // 토큰 파싱 결과
    console.log('[AUTH] 인증 성공');
    super.handle(request); // 다음으로 전달
  }
}

// 속도 제한 핸들러
class RateLimitHandler extends Handler<HttpRequest> {
  private requestCounts = new Map<string, number>();

  handle(request: HttpRequest): void {
    const ip = request.headers['x-forwarded-for'] || 'unknown';
    const count = (this.requestCounts.get(ip) || 0) + 1;
    this.requestCounts.set(ip, count);

    if (count > 100) {
      console.log('[RATE] 429 Too Many Requests — 체인 중단');
      return;
    }
    super.handle(request);
  }
}

// 비즈니스 로직 핸들러
class BusinessHandler extends Handler<HttpRequest> {
  handle(request: HttpRequest): void {
    console.log(`[HANDLER] 요청 처리: user=${request.user?.id}`);
    // 실제 처리 로직
  }
}

// 체인 구성
const logging = new LoggingHandler();
const auth = new AuthHandler();
const rateLimit = new RateLimitHandler();
const business = new BusinessHandler();

logging.setNext(auth).setNext(rateLimit).setNext(business);

// 테스트
logging.handle({
  method: 'GET',
  path: '/api/users',
  headers: { authorization: 'Bearer token123' },
});
// [LOG] GET /api/users
// [AUTH] 인증 성공
// [HANDLER] 요청 처리: user=1
```

---

## 3. 함수형 체인 구현

```typescript
type Middleware<T> = (ctx: T, next: () => void) => void;

function createChain<T>(middlewares: Middleware<T>[]) {
  return (ctx: T) => {
    let index = 0;
    function next() {
      if (index < middlewares.length) {
        middlewares[index++](ctx, next);
      }
    }
    next();
  };
}

// 사용
interface Context {
  user?: string;
  method: string;
  path: string;
}

const chain = createChain<Context>([
  (ctx, next) => {
    console.log(`요청: ${ctx.method} ${ctx.path}`);
    next();
    console.log('응답 완료');
  },
  (ctx, next) => {
    ctx.user = 'Alice';
    next();
  },
  (ctx) => {
    console.log(`처리: user=${ctx.user}`);
  },
]);

chain({ method: 'GET', path: '/home' });
```

---

## 4. Express.js 미들웨어 체인과의 연결

```typescript
// Express 미들웨어 = 책임 연쇄 패턴의 함수형 구현
const app = express();

// 각 미들웨어가 핸들러
app.use((req, res, next) => {
  console.log(`[LOG] ${req.method} ${req.url}`);
  next(); // 다음 핸들러로 전달
});

app.use((req, res, next) => {
  const token = req.headers.authorization;
  if (!token) {
    return res.status(401).json({ error: 'Unauthorized' }); // 체인 중단
  }
  (req as any).user = decodeToken(token);
  next();
});

app.get('/api/data', (req, res) => {
  res.json({ data: 'success' }); // 최종 처리
});

// next(error)로 에러 핸들러로 전달
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  res.status(500).json({ error: err.message });
});
```

---

## 5. DOM 이벤트 버블링과의 연결

```typescript
// DOM 이벤트 버블링 = 자식 → 부모로의 책임 연쇄
document.querySelector('.child')?.addEventListener('click', (e) => {
  console.log('자식 처리');
  // e.stopPropagation() 으로 체인 중단
  // 없으면 부모로 전달 (bubbling)
});

document.querySelector('.parent')?.addEventListener('click', (e) => {
  console.log('부모 처리');
});

document.addEventListener('click', (e) => {
  console.log('document 처리'); // 최상위 핸들러
});

// 클릭 시: 자식 처리 → 부모 처리 → document 처리
```

---

## 6. 면접 포인트

**Q1. 책임 연쇄 패턴이란 무엇인가요?**
> 요청을 체인으로 연결된 핸들러들이 순서대로 처리할 기회를 갖는 패턴입니다. 각 핸들러는 요청을 처리하고 체인을 중단하거나, 다음 핸들러로 전달합니다.

**Q2. Express.js 미들웨어와 책임 연쇄 패턴의 관계는?**
> Express 미들웨어 체인이 책임 연쇄 패턴의 전형적인 구현입니다. `next()`가 다음 핸들러로 전달하는 역할을 하며, `next()`를 호출하지 않으면 체인이 중단됩니다.

**Q3. DOM 이벤트 버블링과의 관계는?**
> 이벤트 버블링은 자식에서 부모로 요청이 전달되는 책임 연쇄입니다. `stopPropagation()`이 체인 중단 역할을 합니다.

**Q4. 책임 연쇄 패턴의 단점은?**
> 요청이 처리되지 않을 수 있습니다. 디버깅 시 어느 핸들러에서 처리되었는지 추적이 어려울 수 있습니다. 체인이 너무 길면 성능에 영향을 줍니다.

---

[← 행동 패턴 목차](./README.md) | [다음: Command →](./02-command.md)
