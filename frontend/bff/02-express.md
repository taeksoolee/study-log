# 2. Express.js (BFF 관점)

## 목차

1. [Express 기초](#1-express-기초)
2. [BFF 서버 구성 예제](#2-bff-서버-구성-예제)
3. [JWT 검증 미들웨어](#3-jwt-검증-미들웨어)
4. [Rate Limiting](#4-rate-limiting)
5. [CORS 설정](#5-cors-설정)
6. [TypeScript + Express 설정](#6-typescript--express-설정)
7. [프로젝트 구조](#7-프로젝트-구조)
8. [면접 포인트](#8-면접-포인트)

---

## 1. Express 기초

Express는 Node.js 기반의 최소한의 웹 프레임워크입니다. BFF를 직접 구성할 때 가장 많이 쓰이는 기반입니다.

### 라우팅

```typescript
import express, { Request, Response } from 'express';

const app = express();
app.use(express.json()); // JSON 바디 파싱

// 기본 라우트
app.get('/health', (req: Request, res: Response) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// 경로 파라미터
app.get('/users/:id', (req: Request, res: Response) => {
  const { id } = req.params;
  res.json({ id });
});

// 쿼리 스트링
app.get('/products', (req: Request, res: Response) => {
  const { page = '1', limit = '20', category } = req.query;
  res.json({ page: Number(page), limit: Number(limit), category });
});

// POST with body
app.post('/orders', (req: Request, res: Response) => {
  const { productId, quantity } = req.body;
  res.status(201).json({ message: 'Order created', productId, quantity });
});
```

### 미들웨어

미들웨어는 `(req, res, next)` 시그니처를 가진 함수입니다. `next()`를 호출해야 다음 미들웨어로 넘어갑니다.

```typescript
// 로깅 미들웨어
const logger = (req: Request, res: Response, next: NextFunction) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
  next(); // 반드시 호출
};

app.use(logger); // 전역 적용
app.get('/users', logger, handler); // 특정 라우트에만 적용
```

### 에러 핸들링

Express에서 에러 핸들러는 파라미터가 4개 `(err, req, res, next)`인 미들웨어입니다. 반드시 마지막에 등록해야 합니다.

```typescript
// 커스텀 에러 클래스
class AppError extends Error {
  constructor(
    public statusCode: number,
    message: string,
  ) {
    super(message);
    this.name = 'AppError';
  }
}

// 에러 핸들러 미들웨어 (4번째 파라미터 err 필수)
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  if (err instanceof AppError) {
    return res.status(err.statusCode).json({ error: err.message });
  }

  console.error('Unexpected error:', err);
  res.status(500).json({ error: 'Internal server error' });
});

// 라우트에서 에러 발생 (async 함수에서는 try/catch 필요)
app.get('/users/:id', async (req, res, next) => {
  try {
    const user = await getUserById(req.params.id);
    if (!user) throw new AppError(404, 'User not found');
    res.json(user);
  } catch (err) {
    next(err); // 에러 핸들러로 전달
  }
});
```

---

## 2. BFF 서버 구성 예제

### 여러 API 집계 엔드포인트

실제 BFF에서 가장 중요한 기능인 데이터 집계 예제입니다.

```typescript
// src/routes/dashboard.ts
import { Router } from 'express';
import axios from 'axios';

const router = Router();

// 환경 변수로 내부 서비스 URL 관리
const USER_SERVICE = process.env.USER_SERVICE_URL!;
const ORDER_SERVICE = process.env.ORDER_SERVICE_URL!;
const NOTIFICATION_SERVICE = process.env.NOTIFICATION_SERVICE_URL!;

router.get('/dashboard', async (req, res, next) => {
  try {
    const userId = req.user!.id; // authMiddleware에서 세팅됨
    const internalHeaders = {
      'X-Internal-Token': process.env.INTERNAL_TOKEN,
      'X-User-Id': userId,
    };

    // 병렬 호출로 지연 시간 최소화
    const [userRes, ordersRes, notificationsRes] = await Promise.allSettled([
      axios.get(`${USER_SERVICE}/users/${userId}`, { headers: internalHeaders }),
      axios.get(`${ORDER_SERVICE}/orders?userId=${userId}&limit=5`, { headers: internalHeaders }),
      axios.get(`${NOTIFICATION_SERVICE}/notifications?userId=${userId}&unread=true`, { headers: internalHeaders }),
    ]);

    // 실패한 서비스는 기본값으로 폴백 (전체 실패 방지)
    const user = userRes.status === 'fulfilled' ? userRes.value.data : null;
    const orders = ordersRes.status === 'fulfilled' ? ordersRes.value.data.items : [];
    const notifications = notificationsRes.status === 'fulfilled' ? notificationsRes.value.data.items : [];

    res.json({
      user: user ? { id: user.id, name: user.name, avatar: user.avatarUrl } : null,
      recentOrders: orders.map((o: any) => ({
        id: o.orderId,
        status: o.status,
        total: o.totalPrice,
        createdAt: o.createdAt,
      })),
      unreadNotifications: notifications.length,
    });
  } catch (err) {
    next(err);
  }
});

export default router;
```

---

## 3. JWT 검증 미들웨어

```typescript
// src/middleware/auth.ts
import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';

export interface AuthPayload {
  id: string;
  email: string;
  roles: string[];
}

// Express Request 타입 확장
declare global {
  namespace Express {
    interface Request {
      user?: AuthPayload;
    }
  }
}

export const authMiddleware = (req: Request, res: Response, next: NextFunction) => {
  const authHeader = req.headers.authorization;

  if (!authHeader?.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing or invalid Authorization header' });
  }

  const token = authHeader.split(' ')[1];

  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET!) as AuthPayload;
    req.user = payload;
    next();
  } catch (err) {
    if (err instanceof jwt.TokenExpiredError) {
      return res.status(401).json({ error: 'Token expired' });
    }
    return res.status(401).json({ error: 'Invalid token' });
  }
};

// 역할 기반 권한 체크 미들웨어
export const requireRole = (...roles: string[]) => {
  return (req: Request, res: Response, next: NextFunction) => {
    if (!req.user) return res.status(401).json({ error: 'Unauthorized' });

    const hasRole = roles.some(role => req.user!.roles.includes(role));
    if (!hasRole) return res.status(403).json({ error: 'Forbidden' });

    next();
  };
};
```

```typescript
// 라우트에 적용
import { authMiddleware, requireRole } from './middleware/auth';

app.use('/api', authMiddleware); // /api 하위 모두 인증 필요
app.delete('/api/users/:id', requireRole('admin'), deleteUser); // admin만 가능
```

---

## 4. Rate Limiting

```typescript
// src/middleware/rateLimiter.ts
import rateLimit from 'express-rate-limit';
import RedisStore from 'rate-limit-redis';
import { createClient } from 'redis';

const redisClient = createClient({ url: process.env.REDIS_URL });
redisClient.connect();

// 기본 Rate Limiter
export const defaultLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15분
  max: 100,                   // 최대 100회
  standardHeaders: true,      // RateLimit-* 헤더 포함
  legacyHeaders: false,
  message: { error: 'Too many requests, please try again later.' },
  store: new RedisStore({
    sendCommand: (...args: string[]) => redisClient.sendCommand(args),
  }),
});

// 로그인 엔드포인트용 엄격한 제한
export const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5, // 15분에 5회만 허용
  message: { error: 'Too many login attempts.' },
});

// 검색 API용 제한
export const searchLimiter = rateLimit({
  windowMs: 60 * 1000, // 1분
  max: 30,
});
```

```typescript
// 적용
app.use('/api', defaultLimiter);
app.post('/auth/login', authLimiter, loginHandler);
app.get('/api/search', searchLimiter, searchHandler);
```

---

## 5. CORS 설정

```typescript
// src/middleware/cors.ts
import cors from 'cors';

const ALLOWED_ORIGINS = [
  'https://myapp.com',
  'https://admin.myapp.com',
  process.env.NODE_ENV === 'development' ? 'http://localhost:3000' : '',
].filter(Boolean);

export const corsMiddleware = cors({
  origin: (origin, callback) => {
    // 서버-서버 요청(origin 없음)이나 허용된 오리진 통과
    if (!origin || ALLOWED_ORIGINS.includes(origin)) {
      callback(null, true);
    } else {
      callback(new Error(`Origin ${origin} not allowed by CORS`));
    }
  },
  credentials: true,          // 쿠키 포함 허용
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  exposedHeaders: ['X-Total-Count'], // 커스텀 응답 헤더 노출
  maxAge: 86400,              // preflight 캐시 1일
});
```

---

## 6. TypeScript + Express 설정

```json
// tsconfig.json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "commonjs",
    "lib": ["ES2022"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "resolveJsonModule": true,
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

```json
// package.json (주요 스크립트)
{
  "scripts": {
    "dev": "tsx watch src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "jsonwebtoken": "^9.0.0",
    "axios": "^1.6.0",
    "cors": "^2.8.5",
    "express-rate-limit": "^7.1.5",
    "redis": "^4.6.0"
  },
  "devDependencies": {
    "@types/express": "^4.17.21",
    "@types/jsonwebtoken": "^9.0.5",
    "@types/cors": "^2.8.17",
    "typescript": "^5.3.0",
    "tsx": "^4.6.0"
  }
}
```

---

## 7. 프로젝트 구조

```
src/
├── index.ts              # 앱 진입점, 서버 시작
├── app.ts                # Express 앱 설정 (미들웨어, 라우트 등록)
├── config/
│   └── env.ts            # 환경 변수 검증 및 타입화
├── middleware/
│   ├── auth.ts           # JWT 인증
│   ├── rateLimiter.ts    # Rate limiting
│   ├── cors.ts           # CORS
│   └── errorHandler.ts   # 전역 에러 핸들러
├── routes/
│   ├── index.ts          # 라우터 통합
│   ├── dashboard.ts      # /api/dashboard
│   ├── products.ts       # /api/products
│   └── orders.ts         # /api/orders
├── controllers/
│   ├── dashboardController.ts
│   ├── productsController.ts
│   └── ordersController.ts
├── services/
│   ├── userService.ts    # User 마이크로서비스 HTTP 클라이언트
│   ├── orderService.ts
│   └── productService.ts
└── types/
    └── index.ts          # 공통 타입 정의
```

```typescript
// src/app.ts
import express from 'express';
import { corsMiddleware } from './middleware/cors';
import { defaultLimiter } from './middleware/rateLimiter';
import { errorHandler } from './middleware/errorHandler';
import routes from './routes';

const app = express();

app.use(corsMiddleware);
app.use(express.json({ limit: '10mb' }));
app.use(defaultLimiter);

app.use('/api', routes);

// 에러 핸들러는 항상 마지막에
app.use(errorHandler);

export default app;
```

```typescript
// src/index.ts
import app from './app';

const PORT = process.env.PORT || 4000;

app.listen(PORT, () => {
  console.log(`BFF server running on port ${PORT}`);
});
```

---

## 8. 면접 포인트

**Q. Express 미들웨어 실행 순서를 설명해주세요.**

> 미들웨어는 등록된 순서대로 실행됩니다. `app.use()`로 전역 등록된 미들웨어가 먼저 실행되고, 라우트 핸들러가 실행됩니다. `next()`를 호출하면 다음 미들웨어로 넘어가고, `next(err)`를 호출하면 에러 핸들러로 바로 이동합니다. 에러 핸들러는 4개의 파라미터를 가지며 항상 마지막에 등록해야 합니다.

**Q. Express에서 async 함수를 쓸 때 주의할 점은?**

> async 함수 내에서 발생한 에러는 Express가 자동으로 잡지 못합니다. try/catch로 감싸고 `next(err)`를 호출하거나, `express-async-errors` 라이브러리를 사용해 전역 처리해야 합니다. Express 5에서는 이 문제가 기본 해결됩니다.

**Q. BFF에서 여러 서비스를 호출할 때 하나가 실패하면 어떻게 처리하나요?**

> `Promise.allSettled()`를 사용하면 일부 서비스가 실패해도 전체를 중단시키지 않습니다. 실패한 서비스는 기본값이나 빈 배열로 폴백 처리하고, 핵심 데이터(예: 사용자 정보)가 실패했을 경우에는 전체 에러로 처리하는 등 비즈니스 중요도에 따라 분기합니다.

**Q. Rate Limiting은 왜 Redis에 저장하나요?**

> 서버 인스턴스가 여러 개로 수평 확장(scale-out)되면, 인메모리에 저장된 요청 카운트는 인스턴스마다 따로 관리됩니다. 같은 사용자가 서버 A에 99번, 서버 B에 99번 요청해도 각각 제한을 넘지 않습니다. Redis를 공유 스토어로 사용하면 모든 인스턴스가 같은 카운트를 공유해 정확히 제한할 수 있습니다.
