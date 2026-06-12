# 4. Hono (경량 엣지 프레임워크)

## 목차

1. [Hono란?](#1-hono란)
2. [지원 런타임](#2-지원-런타임)
3. [기본 라우팅과 미들웨어](#3-기본-라우팅과-미들웨어)
4. [Zod로 타입 안전 요청 처리](#4-zod로-타입-안전-요청-처리)
5. [RPC 모드 (프론트엔드 타입 공유)](#5-rpc-모드-프론트엔드와-타입-공유)
6. [Cloudflare Workers 배포](#6-cloudflare-workers에-배포)
7. [Next.js App Router와 조합](#7-nextjs-app-router와-조합)
8. [면접 포인트](#8-면접-포인트)

---

## 1. Hono란?

**Hono(炎)** 는 2022년 등장한 초경량 웹 프레임워크입니다. 이름은 일본어로 "불꽃"을 뜻하며, **엣지 컴퓨팅 환경에 최적화**되어 있습니다.

**핵심 특징:**

- 번들 크기 14KB (Express: ~0.5MB)
- Web Standards API 기반 (`Request`, `Response`, `Headers`) — 런타임 독립적
- Express와 유사한 API — 마이그레이션 쉬움
- 빌트인 TypeScript 지원
- 빌트인 RPC 모드 — tRPC 없이 타입 공유 가능

```bash
# Node.js
npm create hono@latest my-bff
# → 런타임 선택: cloudflare-workers / bun / deno / nodejs
```

---

## 2. 지원 런타임

Hono가 지원하는 런타임과 각각의 특징입니다.

| 런타임 | 특징 | 주요 사용 사례 |
|--------|------|----------------|
| Cloudflare Workers | 전 세계 엣지 네트워크, 무료 티어 넉넉 | 글로벌 BFF, API 게이트웨이 |
| Bun | Node.js보다 빠른 런타임 | 로컬 개발, 서버 |
| Deno | 보안 기본, URL import | 서버 |
| Node.js | 가장 넓은 생태계 | 기존 프로젝트 마이그레이션 |
| Vercel Edge | Next.js와 통합 | Next.js 미들웨어 |
| AWS Lambda | 서버리스 | 이벤트 기반 처리 |

```typescript
// 같은 코드가 모든 런타임에서 동작
import { Hono } from 'hono';

const app = new Hono();

app.get('/', c => c.json({ message: 'Hello Hono!' }));

export default app; // Cloudflare Workers, Bun, Deno 동일
```

---

## 3. 기본 라우팅과 미들웨어

### 라우팅

```typescript
import { Hono } from 'hono';

const app = new Hono();

// 기본 라우트
app.get('/health', c => c.json({ status: 'ok' }));

// 경로 파라미터
app.get('/users/:id', c => {
  const id = c.req.param('id');
  return c.json({ id });
});

// 쿼리 스트링
app.get('/products', c => {
  const page = c.req.query('page') ?? '1';
  const limit = c.req.query('limit') ?? '20';
  return c.json({ page: Number(page), limit: Number(limit) });
});

// POST with JSON body
app.post('/orders', async c => {
  const body = await c.req.json();
  return c.json({ created: true, ...body }, 201);
});

// 라우트 그룹 (경로 prefix)
const api = new Hono().basePath('/api');
api.get('/users', c => c.json([]));

app.route('/api', api);
```

### 미들웨어

```typescript
import { Hono } from 'hono';
import { logger } from 'hono/logger';
import { cors } from 'hono/cors';
import { bearerAuth } from 'hono/bearer-auth';
import { rateLimiter } from 'hono-rate-limiter';

const app = new Hono();

// 빌트인 미들웨어
app.use('*', logger());   // 요청 로깅
app.use('*', cors({
  origin: ['https://myapp.com', 'http://localhost:3000'],
  credentials: true,
}));

// Bearer 토큰 인증 (단순 고정 토큰)
app.use('/admin/*', bearerAuth({ token: process.env.ADMIN_TOKEN! }));

// Rate limiting
app.use('*', rateLimiter({
  windowMs: 15 * 60 * 1000,
  limit: 100,
  keyGenerator: c => c.req.header('CF-Connecting-IP') ?? 'unknown',
}));

// 커스텀 미들웨어
app.use('*', async (c, next) => {
  console.log(`${c.req.method} ${c.req.path}`);
  await next(); // 다음 핸들러 실행
  console.log(`Response: ${c.res.status}`);
});
```

### 에러 핸들링

```typescript
// 전역 에러 핸들러
app.onError((err, c) => {
  if (err instanceof HTTPException) {
    return c.json({ error: err.message }, err.status);
  }
  console.error(err);
  return c.json({ error: 'Internal server error' }, 500);
});

// 404 핸들러
app.notFound(c => c.json({ error: 'Not found' }, 404));

// 라우트에서 에러 던지기
import { HTTPException } from 'hono/http-exception';

app.get('/users/:id', async c => {
  const user = await findUser(c.req.param('id'));
  if (!user) throw new HTTPException(404, { message: 'User not found' });
  return c.json(user);
});
```

---

## 4. Zod로 타입 안전 요청 처리

```bash
npm i zod @hono/zod-validator
```

```typescript
import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';

const app = new Hono();

// 요청 바디 스키마
const createOrderSchema = z.object({
  productId: z.string().uuid(),
  quantity: z.number().int().min(1).max(100),
  address: z.object({
    street: z.string(),
    city: z.string(),
    zipCode: z.string().regex(/^\d{5}$/),
  }),
});

// 쿼리 스트링 스키마
const listQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  status: z.enum(['pending', 'completed', 'cancelled']).optional(),
});

app.post(
  '/orders',
  zValidator('json', createOrderSchema), // 유효성 검사 미들웨어
  async c => {
    const body = c.req.valid('json'); // 타입이 자동으로 추론됨
    // body: { productId: string; quantity: number; address: {...} }

    const order = await createOrder(body);
    return c.json(order, 201);
  },
);

app.get(
  '/orders',
  zValidator('query', listQuerySchema),
  async c => {
    const { page, limit, status } = c.req.valid('query');
    // page: number, limit: number (coerce가 string → number 변환)

    const orders = await getOrders({ page, limit, status });
    return c.json(orders);
  },
);
```

유효성 검사 실패 시 자동으로 400 응답이 반환됩니다.

---

## 5. RPC 모드 (프론트엔드와 타입 공유)

Hono RPC는 tRPC 없이 서버의 라우트 타입을 클라이언트에서 그대로 사용할 수 있게 해줍니다.

```typescript
// server/routes/users.ts (BFF 서버)
import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';

const users = new Hono()
  .get('/', async c => {
    const users = await getAllUsers();
    return c.json({ users });
  })
  .get('/:id', async c => {
    const id = c.req.param('id');
    const user = await getUserById(id);
    if (!user) return c.json({ error: 'Not found' }, 404);
    return c.json({ user });
  })
  .post(
    '/',
    zValidator('json', z.object({
      name: z.string(),
      email: z.string().email(),
    })),
    async c => {
      const data = c.req.valid('json');
      const user = await createUser(data);
      return c.json({ user }, 201);
    },
  );

export default users;
export type UsersRoute = typeof users; // 타입 내보내기
```

```typescript
// server/index.ts
import { Hono } from 'hono';
import users from './routes/users';

const app = new Hono().route('/users', users);

export default app;
export type AppType = typeof app; // 전체 앱 타입
```

```typescript
// client/src/lib/hono.ts (프론트엔드)
import { hc } from 'hono/client';
import type { AppType } from '../../server'; // 서버 타입만 import

// RPC 클라이언트 생성 (타입 안전)
export const client = hc<AppType>('http://localhost:4000');
```

```typescript
// client/src/components/UserList.tsx
import { client } from '../lib/hono';

async function fetchUsers() {
  const res = await client.users.$get();
  //                     ^^^^^ 타입 자동 완성
  if (!res.ok) throw new Error('Failed');
  const data = await res.json();
  // data.users 타입이 서버에서 반환한 타입과 동일
  return data.users;
}

async function createUser() {
  const res = await client.users.$post({
    json: { name: 'Lee', email: 'lee@example.com' },
    //           ^^^^ 잘못된 필드면 컴파일 에러
  });
  return res.json();
}
```

---

## 6. Cloudflare Workers에 배포

```bash
npm create hono@latest my-worker
# 런타임 선택: cloudflare-workers

npm i wrangler -D
```

```typescript
// src/index.ts
import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { cache } from 'hono/cache';

// Cloudflare Workers 환경 타입 (KV, D1, R2 등)
type Bindings = {
  MY_KV: KVNamespace;
  DB: D1Database;
  JWT_SECRET: string; // wrangler.toml에 정의한 환경 변수
};

const app = new Hono<{ Bindings: Bindings }>();

app.use('*', cors({ origin: 'https://myapp.com' }));

// KV 캐싱 예제
app.get(
  '/categories',
  cache({ cacheName: 'categories', cacheControl: 'max-age=300' }),
  async c => {
    // Cloudflare KV에서 캐시 확인
    const cached = await c.env.MY_KV.get('categories', 'json');
    if (cached) return c.json(cached);

    const categories = await fetchCategories();
    await c.env.MY_KV.put('categories', JSON.stringify(categories), {
      expirationTtl: 300,
    });
    return c.json(categories);
  },
);

// D1 (SQLite) 쿼리
app.get('/users/:id', async c => {
  const id = c.req.param('id');
  const user = await c.env.DB.prepare('SELECT * FROM users WHERE id = ?')
    .bind(id)
    .first();

  if (!user) return c.json({ error: 'Not found' }, 404);
  return c.json(user);
});

export default app;
```

```toml
# wrangler.toml
name = "my-bff"
main = "src/index.ts"
compatibility_date = "2024-01-01"

[[kv_namespaces]]
binding = "MY_KV"
id = "your-kv-namespace-id"

[[d1_databases]]
binding = "DB"
database_name = "my-db"
database_id = "your-db-id"

[vars]
ENVIRONMENT = "production"
```

```bash
# 배포
npx wrangler deploy
```

---

## 7. Next.js App Router와 조합

Next.js에서 외부 Hono BFF를 Route Handler로 연동하는 패턴입니다.

```typescript
// next.js app/api/[[...route]]/route.ts
// Hono 앱을 Next.js Route Handler로 마운트
import { Hono } from 'hono';
import { handle } from 'hono/vercel';

const app = new Hono().basePath('/api');

app.get('/hello', c => c.json({ message: 'Hello from Hono in Next.js!' }));

app.get('/data', async c => {
  // 여러 외부 서비스 집계
  const [users, products] = await Promise.all([
    fetch(`${process.env.USER_SERVICE}/users`).then(r => r.json()),
    fetch(`${process.env.PRODUCT_SERVICE}/products`).then(r => r.json()),
  ]);
  return c.json({ users, products });
});

export const GET = handle(app);
export const POST = handle(app);
```

---

## 8. 면접 포인트

**Q. Hono가 Express보다 빠른 이유는?**

> Hono는 Web Standards API(`Request`/`Response`) 기반으로 설계되어 Node.js HTTP 모듈 추상화 레이어가 없습니다. 내부 라우터가 Trie 자료구조를 사용해 O(1)에 가까운 라우트 매칭을 합니다. 또한 번들 크기가 14KB로 매우 작아 엣지 환경의 콜드 스타트가 빠릅니다.

**Q. Hono RPC와 tRPC의 차이는?**

> Hono RPC는 Hono 프레임워크에 빌트인되어 별도 라이브러리 없이 사용합니다. REST 스타일 라우트(`GET /users`, `POST /users`)를 그대로 유지하면서 타입을 공유합니다. tRPC는 procedure 기반으로 REST URL 개념 없이 완전히 새로운 API 패러다임입니다. 기존 REST API와의 호환이 필요하면 Hono RPC, 완전 새 프로젝트에서 타입 안전성만 원하면 tRPC가 적합합니다.

**Q. Cloudflare Workers에서 DB는 어떻게 사용하나요?**

> Cloudflare D1(SQLite), Workers KV, R2(Object Storage)를 제공합니다. `wrangler.toml`에 바인딩을 선언하면 `c.env.DB`처럼 환경 객체에서 접근합니다. 외부 DB(PostgreSQL 등)는 Hyperdrive를 통해 연결 풀링을 지원합니다.

**Q. Hono를 BFF로 선택하는 기준은?**

> 엣지 환경(Cloudflare Workers, Vercel Edge)에 배포해야 하거나, 경량 서버가 필요한 경우 적합합니다. Express API와 유사해 마이그레이션 비용이 낮고, RPC 모드로 tRPC 없이 타입 공유가 가능한 점도 장점입니다. 반면 NestJS 수준의 구조화된 아키텍처, DI 컨테이너, 엔터프라이즈 기능이 필요하면 NestJS가 더 적합합니다.
