# 1. BFF (Backend for Frontend) 개념

## 목차

1. [BFF란?](#1-bff란)
2. [탄생 배경](#2-탄생-배경)
3. [BFF의 역할](#3-bff의-역할)
4. [BFF vs API Gateway](#4-bff-vs-api-gateway)
5. [프론트엔드 개발자가 BFF를 구현하는 이유](#5-프론트엔드-개발자가-bff를-구현하는-이유)
6. [Next.js Route Handlers와 BFF](#6-nextjs-route-handlers와-bff)
7. [tRPC로 타입 안전 BFF 구현](#7-trpc로-타입-안전-bff-구현)
8. [면접 포인트](#8-면접-포인트)

---

## 1. BFF란?

**BFF(Backend for Frontend)**는 특정 프론트엔드 클라이언트(웹, 모바일 앱 등)에 최적화된 전용 백엔드 레이어입니다. Sam Newman이 2015년에 처음 소개한 패턴으로, "각 클라이언트가 자신만의 백엔드를 갖는다"는 아이디어입니다.

```
기존 구조 (BFF 없음)
  [Web App]  ──────────────┐
  [iOS App]  ────────────── → [단일 API] → [DB / 마이크로서비스들]
  [Android] ──────────────┘

BFF 패턴 적용 후
  [Web App]   → [Web BFF]     ─┐
  [iOS App]   → [Mobile BFF]  ─┤ → [마이크로서비스들]
  [Android]   → [Mobile BFF]  ─┘
```

핵심: **클라이언트마다 다른 데이터 형태가 필요하다** — BFF가 그 변환을 담당합니다.

---

## 2. 탄생 배경

### 모놀리식 → 마이크로서비스 → BFF 필요성

**1단계: 모놀리식 API**

초기에는 하나의 백엔드가 모든 것을 처리했습니다.

```
[프론트엔드] → [모놀리식 백엔드 (사용자/주문/결제/상품 모두 포함)] → [DB]
```

문제점: 배포 단위가 너무 크고, 팀 간 의존성이 높음.

**2단계: 마이크로서비스**

기능별로 서비스를 분리했습니다.

```
[프론트엔드] → [User Service]
            → [Order Service]
            → [Product Service]
            → [Payment Service]
```

문제점: 프론트엔드가 여러 서비스를 직접 호출해야 하고, 각 서비스의 응답을 클라이언트에서 직접 조합해야 합니다. 서비스 주소, 인증 토큰, 에러 처리를 모두 클라이언트가 알아야 합니다.

**3단계: BFF 등장**

```
[프론트엔드] → [BFF] → [User Service]
                     → [Order Service]
                     → [Product Service]
                     → [Payment Service]
```

BFF가 마이크로서비스 복잡성을 숨기고, 프론트엔드가 필요한 형태로 데이터를 정제해서 반환합니다.

---

## 3. BFF의 역할

### 3-1. 데이터 집계 (Data Aggregation)

여러 서비스의 응답을 하나로 합칩니다.

```typescript
// BFF 코드 예시
app.get('/dashboard', async (req, res) => {
  const userId = req.user.id;

  // 여러 마이크로서비스 병렬 호출
  const [user, orders, recommendations] = await Promise.all([
    userService.getUser(userId),
    orderService.getRecentOrders(userId, { limit: 5 }),
    recommendService.getRecommendations(userId),
  ]);

  // 프론트엔드가 원하는 형태로 조합
  res.json({
    user: { name: user.name, avatar: user.profileImage },
    recentOrders: orders.map(o => ({
      id: o.orderId,
      status: o.currentStatus,
      total: o.totalAmount,
    })),
    recommendations: recommendations.items,
  });
});
```

프론트엔드는 `/dashboard` 하나만 호출하면 됩니다.

### 3-2. 데이터 변환 (Data Transformation)

클라이언트에 맞는 형태로 데이터를 변환합니다.

```typescript
// 백엔드 서비스 원본 응답
const rawProduct = {
  product_id: 'PROD-001',
  product_name_ko: '노트북',
  price_krw: 1500000,
  stock_quantity: 10,
  created_at_unix: 1718000000,
};

// BFF에서 프론트엔드용으로 변환
const transformed = {
  id: rawProduct.product_id,
  name: rawProduct.product_name_ko,
  price: rawProduct.price_krw,
  inStock: rawProduct.stock_quantity > 0,
  createdAt: new Date(rawProduct.created_at_unix * 1000).toISOString(),
};
```

### 3-3. 인증/인가 게이트웨이

마이크로서비스에 요청을 전달하기 전에 토큰을 검증합니다.

```typescript
// JWT 검증 미들웨어
const authMiddleware = async (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'Unauthorized' });

  try {
    req.user = jwt.verify(token, process.env.JWT_SECRET);
    next();
  } catch {
    res.status(401).json({ error: 'Invalid token' });
  }
};

// 내부 서비스 호출 시 내부 토큰 사용
const callInternalService = (url, data) =>
  axios.post(url, data, {
    headers: { 'X-Internal-Token': process.env.INTERNAL_TOKEN },
  });
```

### 3-4. 캐싱 레이어

자주 바뀌지 않는 데이터를 BFF에서 캐싱합니다.

```typescript
import { createClient } from 'redis';

const redis = createClient({ url: process.env.REDIS_URL });

app.get('/categories', async (req, res) => {
  const cacheKey = 'categories:all';
  const cached = await redis.get(cacheKey);

  if (cached) {
    return res.json(JSON.parse(cached));
  }

  const categories = await categoryService.getAll();
  await redis.setEx(cacheKey, 300, JSON.stringify(categories)); // 5분 캐시
  res.json(categories);
});
```

---

## 4. BFF vs API Gateway

두 개념은 자주 혼동되지만 역할이 다릅니다.

| 구분 | API Gateway | BFF |
|------|-------------|-----|
| 목적 | 트래픽 라우팅, 보안, 로드밸런싱 | 클라이언트별 데이터 최적화 |
| 관리 주체 | 인프라/플랫폼 팀 | 프론트엔드/풀스택 팀 |
| 비즈니스 로직 | 없음 (순수 라우팅) | 있음 (집계, 변환) |
| 클라이언트 의존성 | 없음 (범용) | 있음 (특정 클라이언트 전용) |
| 예시 | AWS API Gateway, Kong, Nginx | Next.js Route Handler, Express BFF |

실제 아키텍처에서는 두 가지를 함께 씁니다.

```
[클라이언트] → [API Gateway (인증, 라우팅)] → [BFF (집계, 변환)] → [마이크로서비스]
```

---

## 5. 프론트엔드 개발자가 BFF를 구현하는 이유

### 풀스택 트렌드

```
전통적 역할 분리:
  프론트엔드 개발자 → 화면만 담당
  백엔드 개발자 → API 설계 + 구현

현대적 역할:
  프론트엔드 개발자 → 화면 + BFF 레이어 담당
  백엔드 개발자 → 도메인 마이크로서비스 담당
```

### 실질적인 이유

1. **프론트엔드가 데이터 형태를 제일 잘 안다** — 어떤 필드가 필요한지, 어떤 구조가 렌더링에 최적인지
2. **백엔드 팀 의존성 제거** — UI 변경에 따라 API 수정 요청을 기다리지 않아도 됨
3. **민감 정보 보호** — API 키, 내부 서비스 주소를 클라이언트에 노출하지 않음
4. **성능 최적화** — 클라이언트가 받아야 할 데이터만 정확히 내려줌 (over-fetching 방지)

---

## 6. Next.js Route Handlers와 BFF

Next.js의 **Route Handlers** (`app/api/` 하위 파일)는 그 자체로 BFF입니다.

```typescript
// app/api/dashboard/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { cookies } from 'next/headers';

export async function GET(request: NextRequest) {
  // 1. 인증 확인 (서버에서 처리 — 클라이언트에 토큰 노출 없음)
  const cookieStore = cookies();
  const token = cookieStore.get('auth-token')?.value;
  if (!token) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  // 2. 여러 내부 서비스 집계
  const [userData, ordersData] = await Promise.all([
    fetch(`${process.env.USER_SERVICE_URL}/users/me`, {
      headers: { Authorization: `Bearer ${token}` },
    }).then(r => r.json()),

    fetch(`${process.env.ORDER_SERVICE_URL}/orders?limit=5`, {
      headers: { Authorization: `Bearer ${token}` },
    }).then(r => r.json()),
  ]);

  // 3. 프론트엔드용 응답 반환
  return NextResponse.json({
    user: { name: userData.name },
    recentOrders: ordersData.items,
  });
}
```

**Server Actions**도 BFF 패턴의 일종입니다.

```typescript
// app/actions/order.ts
'use server';

export async function createOrder(formData: FormData) {
  const token = cookies().get('auth-token')?.value;

  const response = await fetch(`${process.env.ORDER_SERVICE_URL}/orders`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({
      productId: formData.get('productId'),
      quantity: Number(formData.get('quantity')),
    }),
  });

  if (!response.ok) throw new Error('Order failed');
  return response.json();
}
```

---

## 7. tRPC로 타입 안전 BFF 구현

tRPC는 프론트엔드와 BFF 사이에 타입을 공유해 런타임 에러를 컴파일 타임에 잡을 수 있게 합니다.

```typescript
// server/router.ts (BFF 서버 코드)
import { initTRPC } from '@trpc/server';
import { z } from 'zod';

const t = initTRPC.create();

export const appRouter = t.router({
  getUser: t.procedure
    .input(z.object({ id: z.string() }))
    .query(async ({ input }) => {
      const user = await userService.findById(input.id);
      return { id: user.id, name: user.name, email: user.email };
    }),

  createOrder: t.procedure
    .input(z.object({
      productId: z.string(),
      quantity: z.number().min(1).max(100),
    }))
    .mutation(async ({ input, ctx }) => {
      return orderService.create({ ...input, userId: ctx.userId });
    }),
});

export type AppRouter = typeof appRouter; // 이 타입을 프론트엔드와 공유
```

```typescript
// client/pages/Dashboard.tsx (프론트엔드)
import { trpc } from '../utils/trpc';

function Dashboard() {
  // 타입 자동 완성, 런타임 에러 없음
  const { data } = trpc.getUser.useQuery({ id: '123' });
  //              ^^^^^^^^^^^^^ 존재하지 않는 procedure면 컴파일 에러

  const mutation = trpc.createOrder.useMutation();

  return <div>{data?.name}</div>; // data 타입이 자동으로 추론됨
}
```

---

## 8. 면접 포인트

**Q. BFF 패턴이란 무엇이고, 언제 사용하나요?**

> BFF는 특정 클라이언트에 최적화된 전용 백엔드 레이어입니다. 마이크로서비스 환경에서 여러 서비스 데이터를 클라이언트 입장에서 집계·변환하는 역할을 합니다. 웹과 모바일이 서로 다른 데이터 구조를 필요로 할 때, 또는 프론트엔드 팀이 백엔드 팀 없이 API 형태를 직접 제어하고 싶을 때 도입합니다.

**Q. API Gateway와 BFF의 차이는?**

> API Gateway는 인프라 레이어로 트래픽 라우팅, 인증, 속도 제한을 담당하며 비즈니스 로직이 없습니다. BFF는 애플리케이션 레이어로 데이터 집계·변환 등 비즈니스 로직을 포함하며, 특정 클라이언트에 종속됩니다. 실무에서는 두 레이어를 함께 사용합니다.

**Q. Next.js에서 BFF를 어떻게 구현하나요?**

> `app/api/` 하위의 Route Handlers를 BFF로 사용합니다. 서버 코드이므로 API 키를 안전하게 보관하고, 여러 내부 서비스를 호출해 집계한 결과만 클라이언트에 내려줍니다. Server Actions도 같은 맥락에서 폼 제출이나 데이터 변경을 서버 코드로 처리하는 BFF 패턴입니다.

**Q. BFF 도입 시 단점은?**

> 관리할 서비스가 하나 더 생깁니다. 클라이언트가 늘어날수록 BFF도 늘어나 운영 부담이 증가할 수 있습니다. 또한 BFF에서 집계 로직이 복잡해지면 테스트와 유지보수가 어려워질 수 있습니다. 팀 규모가 작다면 오히려 오버엔지니어링이 될 수 있습니다.
