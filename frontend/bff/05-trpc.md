# 5. tRPC (타입 안전 API)

## 목차

1. [tRPC란?](#1-trpc란)
2. [프론트-백엔드 타입 공유의 장점](#2-프론트백엔드-타입-공유의-장점)
3. [Router 정의, Query/Mutation](#3-router-정의-querymutation)
4. [React Query 통합](#4-react-query-통합-usequery-usemutation)
5. [Next.js + tRPC 풀스택 예제](#5-nextjs--trpc-풀스택-예제)
6. [언제 tRPC, 언제 REST/GraphQL?](#6-언제-trpc-언제-restgraphql)
7. [면접 포인트](#7-면접-포인트)

---

## 1. tRPC란?

**tRPC(TypeScript Remote Procedure Call)**는 REST나 GraphQL 없이 TypeScript 타입만으로 프론트엔드와 백엔드 사이의 계약을 만드는 라이브러리입니다.

**기존 방식의 문제:**

```
백엔드: POST /users → { name: string, email: string } 반환
프론트엔드: fetch('/users', ...) → 응답 타입을 수동으로 정의하거나 any 사용

백엔드에서 필드명 변경 → 프론트엔드 런타임 에러 발생
코드 리뷰, 문서, 타입 정의를 수동으로 동기화해야 함
```

**tRPC 방식:**

```
서버에서 router 정의 → 타입 export
클라이언트에서 타입 import → 자동 완성, 컴파일 에러

백엔드에서 필드명 변경 → 프론트엔드에서 즉시 컴파일 에러
```

```bash
npm i @trpc/server @trpc/client @trpc/react-query @tanstack/react-query zod
```

---

## 2. 프론트-백엔드 타입 공유의 장점

```typescript
// 서버 코드 (server/router.ts)
export const appRouter = router({
  getUser: procedure
    .input(z.object({ id: z.string() }))
    .query(async ({ input }) => {
      return { id: input.id, name: 'Lee', email: 'lee@example.com' };
      //       ↑ 이 반환 타입이 클라이언트까지 전파됨
    }),
});

export type AppRouter = typeof appRouter; // 핵심: 이 타입을 프론트에서 import
```

```typescript
// 클라이언트 코드 (client/App.tsx)
import type { AppRouter } from '../server/router'; // 타입만 import (런타임 0 오버헤드)
import { createTRPCReact } from '@trpc/react-query';

const trpc = createTRPCReact<AppRouter>();

function UserProfile({ userId }: { userId: string }) {
  const { data } = trpc.getUser.useQuery({ id: userId });
  //  data 타입: { id: string; name: string; email: string } | undefined
  //  id, name, email — 자동 완성됨
  //  존재하지 않는 procedure 호출 시 컴파일 에러

  return <div>{data?.name}</div>;
}
```

---

## 3. Router 정의, Query/Mutation

```typescript
// server/trpc.ts — tRPC 인스턴스 초기화
import { initTRPC, TRPCError } from '@trpc/server';
import { z } from 'zod';

// 컨텍스트 타입 (인증 정보 등)
type Context = {
  userId: string | null;
};

const t = initTRPC.context<Context>().create();

export const router = t.router;
export const publicProcedure = t.procedure;

// 인증이 필요한 procedure
export const protectedProcedure = t.procedure.use(({ ctx, next }) => {
  if (!ctx.userId) {
    throw new TRPCError({ code: 'UNAUTHORIZED', message: 'Not authenticated' });
  }
  return next({ ctx: { ...ctx, userId: ctx.userId } }); // userId가 null이 아님을 보장
});
```

```typescript
// server/routers/users.ts
import { z } from 'zod';
import { router, publicProcedure, protectedProcedure } from '../trpc';
import { TRPCError } from '@trpc/server';

export const usersRouter = router({
  // Query: 데이터 조회 (GET과 유사)
  getById: publicProcedure
    .input(z.object({ id: z.string() }))
    .query(async ({ input }) => {
      const user = await db.user.findUnique({ where: { id: input.id } });
      if (!user) throw new TRPCError({ code: 'NOT_FOUND', message: 'User not found' });
      return user;
    }),

  // 페이지네이션 Query
  list: publicProcedure
    .input(z.object({
      page: z.number().int().min(1).default(1),
      limit: z.number().int().min(1).max(100).default(20),
    }))
    .query(async ({ input }) => {
      const { page, limit } = input;
      const [items, total] = await Promise.all([
        db.user.findMany({ skip: (page - 1) * limit, take: limit }),
        db.user.count(),
      ]);
      return { items, total, page, limit, totalPages: Math.ceil(total / limit) };
    }),

  // Mutation: 데이터 변경 (POST/PUT/DELETE와 유사)
  create: protectedProcedure // 인증 필요
    .input(z.object({
      name: z.string().min(2).max(50),
      email: z.string().email(),
    }))
    .mutation(async ({ input, ctx }) => {
      const existing = await db.user.findUnique({ where: { email: input.email } });
      if (existing) throw new TRPCError({ code: 'CONFLICT', message: 'Email already exists' });

      return db.user.create({
        data: { ...input, createdBy: ctx.userId },
      });
    }),

  update: protectedProcedure
    .input(z.object({
      id: z.string(),
      name: z.string().min(2).max(50).optional(),
    }))
    .mutation(async ({ input }) => {
      const { id, ...data } = input;
      return db.user.update({ where: { id }, data });
    }),

  delete: protectedProcedure
    .input(z.string()) // 단순 string도 가능
    .mutation(async ({ input: id }) => {
      await db.user.delete({ where: { id } });
      return { success: true };
    }),
});
```

```typescript
// server/router.ts — 라우터 통합
import { router } from './trpc';
import { usersRouter } from './routers/users';
import { ordersRouter } from './routers/orders';

export const appRouter = router({
  users: usersRouter,    // /users.getById, /users.list, ...
  orders: ordersRouter,  // /orders.create, ...
});

export type AppRouter = typeof appRouter;
```

---

## 4. React Query 통합 (useQuery, useMutation)

tRPC는 내부적으로 React Query를 사용합니다.

```typescript
// client/providers.tsx — Provider 설정
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { httpBatchLink } from '@trpc/client';
import { trpc } from './utils/trpc';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: { staleTime: 60 * 1000 }, // 1분 캐시
  },
});

const trpcClient = trpc.createClient({
  links: [
    httpBatchLink({
      url: '/api/trpc',
      headers: () => ({
        Authorization: `Bearer ${localStorage.getItem('token')}`,
      }),
    }),
  ],
});

export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <trpc.Provider client={trpcClient} queryClient={queryClient}>
      <QueryClientProvider client={queryClient}>
        {children}
      </QueryClientProvider>
    </trpc.Provider>
  );
}
```

```typescript
// client/components/UserList.tsx
import { trpc } from '../utils/trpc';

function UserList() {
  // useQuery와 동일한 API
  const { data, isLoading, error } = trpc.users.list.useQuery({ page: 1, limit: 20 });

  const createUser = trpc.users.create.useMutation({
    onSuccess: () => {
      // 성공 후 목록 캐시 무효화 (React Query와 동일)
      trpc.useUtils().users.list.invalidate();
    },
    onError: (err) => {
      console.error(err.message); // tRPC 에러 메시지
    },
  });

  const handleCreate = () => {
    createUser.mutate({ name: 'New User', email: 'new@example.com' });
  };

  if (isLoading) return <div>Loading...</div>;
  if (error) return <div>Error: {error.message}</div>;

  return (
    <div>
      {data?.items.map(user => <div key={user.id}>{user.name}</div>)}
      <button onClick={handleCreate} disabled={createUser.isPending}>
        {createUser.isPending ? 'Creating...' : 'Create User'}
      </button>
    </div>
  );
}
```

---

## 5. Next.js + tRPC 풀스택 예제

```typescript
// app/api/trpc/[trpc]/route.ts — tRPC 엔드포인트
import { fetchRequestHandler } from '@trpc/server/adapters/fetch';
import { appRouter } from '@/server/router';
import { createContext } from '@/server/context';

const handler = (req: Request) =>
  fetchRequestHandler({
    endpoint: '/api/trpc',
    req,
    router: appRouter,
    createContext: () => createContext(req),
  });

export { handler as GET, handler as POST };
```

```typescript
// server/context.ts — 컨텍스트 생성 (요청마다 실행)
import { cookies } from 'next/headers';
import { verifyToken } from './auth';

export async function createContext(req: Request) {
  const cookieStore = cookies();
  const token = cookieStore.get('auth-token')?.value;

  let userId: string | null = null;
  if (token) {
    try {
      const payload = await verifyToken(token);
      userId = payload.id;
    } catch {}
  }

  return { userId };
}

export type Context = Awaited<ReturnType<typeof createContext>>;
```

```typescript
// Server Component에서 직접 호출 (HTTP 요청 없음, 직접 함수 호출)
import { createCaller } from '@/server/router';
import { createContext } from '@/server/context';

async function DashboardPage() {
  // 서버 컴포넌트에서는 tRPC caller로 직접 호출 가능
  const ctx = await createContext(new Request('http://localhost'));
  const caller = createCaller(ctx);

  const users = await caller.users.list({ page: 1, limit: 10 });
  // HTTP 요청 없이 직접 함수 호출 — 성능 최적

  return <div>{users.items.length} users</div>;
}
```

---

## 6. 언제 tRPC, 언제 REST/GraphQL?

| 상황 | 권장 선택 |
|------|-----------|
| TypeScript 모노레포, 프론트-백 같은 저장소 | tRPC |
| 외부 파트너/써드파티 API 제공 | REST |
| 다양한 클라이언트(iOS, Android, 서드파티) | REST / GraphQL |
| 복잡한 데이터 관계, 유연한 쿼리 필요 | GraphQL |
| 작은 팀, Next.js 풀스택 | tRPC |
| 마이크로서비스 간 통신 | REST / gRPC |

**tRPC의 한계:**

- TypeScript를 쓰지 않는 클라이언트는 타입 공유 불가
- REST처럼 URL로 리소스를 표현하지 않아 RESTful API 설계가 어려움
- 공개 API(외부 개발자 대상)에는 REST가 표준
- 서버-서버 간 호출에는 적합하지 않음

---

## 7. 면접 포인트

**Q. tRPC가 REST API보다 나은 점은?**

> TypeScript 타입을 서버와 클라이언트가 공유하므로, 백엔드에서 응답 구조가 바뀌면 프론트엔드에서 즉시 컴파일 에러로 발견됩니다. API 문서나 별도 타입 정의 파일 없이도 자동 완성이 됩니다. 또한 React Query와 통합되어 로딩/에러 상태 관리가 편리합니다.

**Q. tRPC와 GraphQL 중 어떤 걸 선택하나요?**

> TypeScript 모노레포에서 프론트-백이 같은 저장소를 공유한다면 tRPC가 설정이 간단하고 오버헤드가 적습니다. 다양한 클라이언트(앱, 파트너사 등)에서 각자 필요한 필드만 요청해야 한다면 GraphQL이 적합합니다. tRPC는 "같은 팀의 TypeScript 개발자들" 사이에서만 이점이 있습니다.

**Q. tRPC에서 인증은 어떻게 처리하나요?**

> `createContext` 함수에서 요청의 쿠키나 헤더에서 토큰을 검증하고 Context에 `userId`를 담습니다. 인증이 필요한 procedure는 미들웨어(`t.procedure.use(...)`)로 Context에 userId가 없으면 `UNAUTHORIZED` 에러를 던집니다. `protectedProcedure`로 만들어두면 각 라우터에서 재사용합니다.

**Q. Next.js에서 Server Component와 tRPC를 함께 쓰는 방법은?**

> Server Component에서는 HTTP 요청 없이 `createCaller()`로 tRPC 함수를 직접 호출합니다. 클라이언트 컴포넌트에서는 `useQuery`/`useMutation`으로 API 엔드포인트를 통해 호출합니다. 이렇게 하면 같은 비즈니스 로직을 서버/클라이언트 모두에서 재사용할 수 있습니다.
