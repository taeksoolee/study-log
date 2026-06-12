# 6. GraphQL (BFF 계층에서)

## 목차

1. [GraphQL이 BFF 계층에 적합한 이유](#1-graphql이-bff-계층에-적합한-이유)
2. [Schema, Query, Mutation, Subscription](#2-schema-query-mutation-subscription)
3. [Apollo Client (프론트엔드)](#3-apollo-client-프론트엔드)
4. [Apollo Server (BFF 서버)](#4-apollo-server-bff-서버)
5. [N+1 문제와 DataLoader](#5-n1-문제와-dataloader)
6. [REST vs GraphQL vs tRPC 비교](#6-rest-vs-graphql-vs-trpc-비교표)
7. [면접 포인트](#7-면접-포인트)

---

## 1. GraphQL이 BFF 계층에 적합한 이유

**REST API의 문제점:**

```
over-fetching: 클라이언트가 필요 없는 데이터까지 받음
  GET /users/123 → { id, name, email, address, phone, createdAt, updatedAt, ... }
  화면에는 name만 필요한데 전체를 받음

under-fetching: 필요한 데이터를 얻으려면 여러 요청 필요
  화면에 user + user의 orders + 각 order의 products 필요
  → 3번의 API 호출 필요
```

**GraphQL 해결책:**

```graphql
# 클라이언트가 원하는 필드만 요청
query {
  user(id: "123") {
    name                    # name만 요청
    orders(limit: 5) {
      id
      status
      products {
        name
        price
      }
    }
  }
}
# 한 번의 요청으로 모든 데이터 취득
```

**BFF로 GraphQL이 적합한 이유:**

- 여러 마이크로서비스를 하나의 GraphQL 스키마로 통합 가능
- 클라이언트(웹/앱)가 각자 필요한 필드만 쿼리 — BFF 로직이 줄어듦
- 스키마가 곧 API 문서 역할
- Subscription으로 실시간 데이터도 처리

---

## 2. Schema, Query, Mutation, Subscription

### Schema Definition Language (SDL)

```graphql
# schema.graphql

# 기본 타입
type User {
  id: ID!           # !: non-null (필수)
  name: String!
  email: String!
  orders: [Order!]! # Order 배열 (null 불가)
  createdAt: String!
}

type Order {
  id: ID!
  status: OrderStatus!
  total: Float!
  items: [OrderItem!]!
  user: User!
}

enum OrderStatus {
  PENDING
  PROCESSING
  COMPLETED
  CANCELLED
}

type OrderItem {
  product: Product!
  quantity: Int!
  price: Float!
}

type Product {
  id: ID!
  name: String!
  price: Float!
  stock: Int!
}

# 페이지네이션 타입
type UserConnection {
  nodes: [User!]!
  totalCount: Int!
  pageInfo: PageInfo!
}

type PageInfo {
  hasNextPage: Boolean!
  endCursor: String
}

# 입력 타입 (Mutation에서 사용)
input CreateUserInput {
  name: String!
  email: String!
  password: String!
}

input UpdateOrderInput {
  status: OrderStatus
}

# Query: 읽기 전용 작업
type Query {
  user(id: ID!): User             # 단건 조회 (null 가능)
  users(first: Int, after: String): UserConnection!
  order(id: ID!): Order
  me: User                        # 현재 로그인 사용자
}

# Mutation: 데이터 변경
type Mutation {
  createUser(input: CreateUserInput!): User!
  updateOrder(id: ID!, input: UpdateOrderInput!): Order!
  deleteUser(id: ID!): Boolean!
}

# Subscription: 실시간 데이터
type Subscription {
  orderStatusChanged(orderId: ID!): Order!
  newNotification(userId: ID!): Notification!
}
```

---

## 3. Apollo Client (프론트엔드)

```bash
npm i @apollo/client graphql
```

```typescript
// client/lib/apolloClient.ts
import { ApolloClient, InMemoryCache, createHttpLink, split } from '@apollo/client';
import { setContext } from '@apollo/client/link/context';
import { GraphQLWsLink } from '@apollo/client/link/subscriptions';
import { getMainDefinition } from '@apollo/client/utilities';
import { createClient } from 'graphql-ws';

// HTTP 링크 (Query, Mutation)
const httpLink = createHttpLink({ uri: '/graphql' });

// 인증 헤더 추가
const authLink = setContext((_, { headers }) => ({
  headers: {
    ...headers,
    authorization: `Bearer ${localStorage.getItem('token')}`,
  },
}));

// WebSocket 링크 (Subscription)
const wsLink = new GraphQLWsLink(
  createClient({
    url: 'ws://localhost:4000/graphql',
    connectionParams: {
      authorization: `Bearer ${localStorage.getItem('token')}`,
    },
  }),
);

// Subscription은 WebSocket, 나머지는 HTTP
const splitLink = split(
  ({ query }) => {
    const def = getMainDefinition(query);
    return def.kind === 'OperationDefinition' && def.operation === 'subscription';
  },
  wsLink,
  authLink.concat(httpLink),
);

export const client = new ApolloClient({
  link: splitLink,
  cache: new InMemoryCache({
    typePolicies: {
      Query: {
        fields: {
          users: { keyArgs: false }, // 페이지네이션 캐시 설정
        },
      },
    },
  }),
});
```

```typescript
// client/components/UserProfile.tsx
import { useQuery, useMutation, gql } from '@apollo/client';

const GET_USER = gql`
  query GetUser($id: ID!) {
    user(id: $id) {
      id
      name
      email
      orders(limit: 3) {
        id
        status
        total
      }
    }
  }
`;

const UPDATE_ORDER = gql`
  mutation UpdateOrder($id: ID!, $status: OrderStatus!) {
    updateOrder(id: $id, input: { status: $status }) {
      id
      status
    }
  }
`;

function UserProfile({ userId }: { userId: string }) {
  const { loading, error, data } = useQuery(GET_USER, {
    variables: { id: userId },
    fetchPolicy: 'cache-and-network', // 캐시 우선, 백그라운드에서 최신화
  });

  const [updateOrder, { loading: updating }] = useMutation(UPDATE_ORDER, {
    // optimistic update — 서버 응답 전에 UI 먼저 업데이트
    optimisticResponse: ({ id, status }) => ({
      updateOrder: { __typename: 'Order', id, status },
    }),
  });

  if (loading) return <Spinner />;
  if (error) return <ErrorMessage error={error} />;

  return (
    <div>
      <h1>{data.user.name}</h1>
      {data.user.orders.map(order => (
        <div key={order.id}>
          {order.status}
          <button onClick={() => updateOrder({ variables: { id: order.id, status: 'CANCELLED' } })}>
            Cancel
          </button>
        </div>
      ))}
    </div>
  );
}
```

```typescript
// Subscription 사용
const ORDER_STATUS = gql`
  subscription OnOrderStatusChanged($orderId: ID!) {
    orderStatusChanged(orderId: $orderId) {
      id
      status
    }
  }
`;

function OrderTracker({ orderId }: { orderId: string }) {
  const { data } = useSubscription(ORDER_STATUS, {
    variables: { orderId },
  });

  return <div>Status: {data?.orderStatusChanged.status}</div>;
}
```

---

## 4. Apollo Server (BFF 서버)

```bash
npm i @apollo/server graphql
```

```typescript
// server/schema/resolvers.ts
import { GraphQLError } from 'graphql';
import DataLoader from 'dataloader';

// Context 타입 (각 요청마다 생성)
export interface Context {
  userId: string | null;
  loaders: {
    user: DataLoader<string, User>;
    order: DataLoader<string, Order[]>;
  };
}

export const resolvers = {
  Query: {
    // 단건 조회
    user: async (_: unknown, { id }: { id: string }, ctx: Context) => {
      return ctx.loaders.user.load(id); // DataLoader로 N+1 방지
    },

    // 현재 사용자
    me: async (_: unknown, __: unknown, ctx: Context) => {
      if (!ctx.userId) throw new GraphQLError('Not authenticated', {
        extensions: { code: 'UNAUTHORIZED' },
      });
      return ctx.loaders.user.load(ctx.userId);
    },

    // 페이지네이션
    users: async (_: unknown, { first = 20, after }: { first?: number; after?: string }) => {
      const cursor = after ? decodeCursor(after) : undefined;
      const items = await db.user.findMany({
        take: first + 1, // 다음 페이지 존재 여부 확인용
        skip: cursor ? 1 : 0,
        cursor: cursor ? { id: cursor } : undefined,
        orderBy: { createdAt: 'desc' },
      });

      const hasNextPage = items.length > first;
      const nodes = hasNextPage ? items.slice(0, -1) : items;

      return {
        nodes,
        totalCount: await db.user.count(),
        pageInfo: {
          hasNextPage,
          endCursor: nodes.length ? encodeCursor(nodes[nodes.length - 1].id) : null,
        },
      };
    },
  },

  Mutation: {
    createUser: async (_: unknown, { input }: { input: CreateUserInput }) => {
      const existing = await db.user.findUnique({ where: { email: input.email } });
      if (existing) throw new GraphQLError('Email already exists', {
        extensions: { code: 'CONFLICT' },
      });

      const hashedPassword = await bcrypt.hash(input.password, 10);
      return db.user.create({ data: { ...input, password: hashedPassword } });
    },
  },

  // 타입 리졸버 (User의 orders 필드)
  User: {
    orders: async (user: User, _: unknown, ctx: Context) => {
      return ctx.loaders.order.load(user.id); // DataLoader 사용
    },
  },

  // Order의 user 필드
  Order: {
    user: async (order: Order, _: unknown, ctx: Context) => {
      return ctx.loaders.user.load(order.userId);
    },
  },
};
```

```typescript
// server/index.ts
import { ApolloServer } from '@apollo/server';
import { expressMiddleware } from '@apollo/server/express4';
import { readFileSync } from 'fs';
import express from 'express';
import { createLoaders } from './loaders';
import { verifyToken } from './auth';

const typeDefs = readFileSync('./schema.graphql', 'utf-8');

const apolloServer = new ApolloServer({
  typeDefs,
  resolvers,
  formatError: (error) => {
    console.error('GraphQL Error:', error);
    // 프로덕션에서는 내부 에러 메시지 숨김
    if (process.env.NODE_ENV === 'production' && !error.extensions?.code) {
      return new GraphQLError('Internal server error');
    }
    return error;
  },
});

await apolloServer.start();

const app = express();
app.use('/graphql', expressMiddleware(apolloServer, {
  context: async ({ req }) => {
    const token = req.headers.authorization?.split(' ')[1];
    let userId = null;
    if (token) {
      try { userId = (await verifyToken(token)).id; } catch {}
    }

    return {
      userId,
      loaders: createLoaders(), // 요청마다 새 DataLoader 인스턴스
    };
  },
}));
```

---

## 5. N+1 문제와 DataLoader

N+1 문제는 GraphQL에서 가장 중요한 성능 이슈입니다.

```
users 쿼리로 100명의 사용자 조회 (쿼리 1번)
각 user.orders 리졸버가 실행 → 100번 DB 쿼리 발생
= 총 101번 (N+1) 쿼리
```

**DataLoader로 해결:**

```typescript
// server/loaders.ts
import DataLoader from 'dataloader';

export function createLoaders() {
  return {
    // user ID 배열을 한 번에 조회
    user: new DataLoader<string, User>(async (ids) => {
      const users = await db.user.findMany({
        where: { id: { in: [...ids] } },
      });

      // DataLoader는 입력 순서와 결과 순서가 일치해야 함
      const userMap = new Map(users.map(u => [u.id, u]));
      return ids.map(id => userMap.get(id) ?? new Error(`User ${id} not found`));
      //     ↑ 결과가 없으면 Error 반환 (null 대신)
    }),

    // userId별 orders 배치 조회
    ordersByUser: new DataLoader<string, Order[]>(async (userIds) => {
      const orders = await db.order.findMany({
        where: { userId: { in: [...userIds] } },
      });

      // userId별로 그룹화
      const orderMap = new Map<string, Order[]>();
      for (const order of orders) {
        const list = orderMap.get(order.userId) ?? [];
        list.push(order);
        orderMap.set(order.userId, list);
      }

      return userIds.map(id => orderMap.get(id) ?? []);
    }),
  };
}
```

DataLoader는 같은 이벤트 루프 틱(tick)에서 발생한 요청들을 모아 한 번에 처리합니다. 100개의 개별 `load(id)` 호출 → 1번의 배치 DB 쿼리로 처리됩니다.

---

## 6. REST vs GraphQL vs tRPC 비교표

| 구분 | REST | GraphQL | tRPC |
|------|------|---------|------|
| 타입 안전성 | 수동 (OpenAPI/Swagger) | 스키마 기반 | TypeScript 자동 |
| 클라이언트 유연성 | 낮음 (고정 응답) | 높음 (원하는 필드만) | 중간 |
| over-fetching | 있음 | 없음 | 없음 (TS 설계 의존) |
| 학습 곡선 | 낮음 | 중간 | 낮음 (TS 필수) |
| 외부 API 제공 | 최적 | 가능 | 부적합 |
| 실시간 (Subscription) | WebSocket 별도 | 내장 | 별도 |
| N+1 문제 | 없음 | DataLoader 필요 | 없음 |
| 캐싱 | HTTP 캐시 활용 용이 | 복잡 (persisted query) | React Query |
| 팀 규모 | 모든 규모 | 중대형 | 소중형 (TS 팀) |
| 공개 API | 표준 | 가능 | 부적합 |

**선택 가이드:**

```
공개 API / 서드파티 연동 → REST
다양한 클라이언트, 복잡한 데이터 관계 → GraphQL
TypeScript 모노레포, 작은 팀 → tRPC
```

---

## 7. 면접 포인트

**Q. GraphQL의 over-fetching, under-fetching 문제란?**

> REST API는 엔드포인트별로 고정된 응답을 반환합니다. over-fetching은 화면에 필요하지 않은 필드까지 응답에 포함되는 것이고, under-fetching은 한 화면에 필요한 데이터를 얻으려면 여러 API를 호출해야 하는 것입니다. GraphQL은 클라이언트가 쿼리에 원하는 필드와 중첩 관계를 직접 명시해 한 번의 요청으로 정확히 필요한 데이터만 가져올 수 있습니다.

**Q. N+1 문제가 무엇이고 어떻게 해결하나요?**

> 목록을 조회할 때 각 항목의 연관 데이터를 개별적으로 조회해 N개의 추가 쿼리가 발생하는 문제입니다. 예를 들어 100명 사용자를 조회한 후 각 사용자의 주문을 개별 쿼리로 가져오면 101번의 DB 쿼리가 발생합니다. DataLoader로 해결합니다. DataLoader는 같은 이벤트 루프 틱에 발생한 ID 요청들을 모아 단 1번의 배치 쿼리로 처리합니다.

**Q. GraphQL Subscription은 언제 사용하나요?**

> 실시간으로 데이터가 변경될 때 서버가 클라이언트에게 푸시해야 하는 경우 사용합니다. 주문 상태 변경 알림, 채팅 메시지, 실시간 대시보드 등이 대표적입니다. 내부적으로 WebSocket을 사용하며, Apollo에서는 `graphql-ws` 라이브러리와 함께 사용합니다.

**Q. BFF에서 GraphQL을 사용할 때 장점은?**

> 여러 마이크로서비스의 데이터를 하나의 GraphQL 스키마로 통합해 클라이언트에게 단일 엔드포인트를 제공합니다. 클라이언트별로 필요한 필드를 쿼리하면 BFF에서 각 서비스를 선택적으로 호출하므로 불필요한 서비스 호출이 줄어듭니다. 또한 스키마 자체가 API 계약서 역할을 해 프론트-백 협업 시 명확한 인터페이스를 보장합니다.
