# GraphQL & 데이터 페칭 아키텍처

> 프론트엔드 소비자 관점에서 GraphQL, REST, tRPC를 비교하고 최적의 데이터 페칭 전략을 수립한다.

---

## 개요

- REST vs GraphQL vs tRPC: **"무엇을 쓸까?"**가 아니라 **"언제 무엇을 쓸까?"**
- 프론트엔드 소비자 관점에서의 데이터 페칭 전략
- 서버 구현이 아닌 **클라이언트 소비** 관점에 집중

---

## 핵심 개념

### 1. REST vs GraphQL vs tRPC 판단 기준

| 기준 | REST | GraphQL | tRPC |
|------|------|---------|------|
| 타입 안전성 | 수동 (OpenAPI) | 스키마 기반 | 자동 (TS 추론) |
| Over-fetching | 발생 | 해결 | N/A |
| 학습 곡선 | 낮음 | 중간 | 낮음 |
| 생태계 | 최대 | 큼 | 작음 |
| 적합 | 공개 API, 3rd party | 복잡한 데이터, BFF | 모노레포, 내부 API |
| HTTP 캐싱 | 쉬움 (GET) | 어려움 (POST) | 쉬움 |

#### 판단 플로우차트

```
외부 공개 API? → REST
모노레포 풀스택 TS? → tRPC
복잡한 데이터 관계 + 화면마다 다른 필드? → GraphQL
단순 CRUD? → REST
```

### 2. GraphQL 클라이언트 핵심 개념

```graphql
# Query: 데이터 조회
query GetUser($id: ID!) {
  user(id: $id) { id name posts { title } }
}

# Mutation: 데이터 변경
mutation CreatePost($input: CreatePostInput!) {
  createPost(input: $input) { id title }
}

# Subscription: 실시간 (WebSocket)
subscription OnNewMessage($roomId: ID!) {
  messageAdded(roomId: $roomId) { id content sender { name } }
}
```

#### Fragment & Colocation

Fragment는 컴포넌트가 **자신이 필요한 데이터를 선언**하는 단위:

```graphql
fragment UserAvatarFields on User {
  id
  name
  avatarUrl
}
```

**Fragment Colocation** — 컴포넌트 옆에 fragment 배치:

```
components/UserAvatar/
  index.tsx
  UserAvatar.fragment.graphql   ← 이 컴포넌트의 데이터 요구사항
```

왜 중요한가?
- 부모가 자식의 데이터 요구사항을 알 필요 없음
- 컴포넌트 삭제 시 불필요한 필드도 함께 제거
- 관심사 분리 + over-fetching 방지

#### Directives

```graphql
query GetUser($id: ID!, $withPosts: Boolean!) {
  user(id: $id) {
    name
    posts @include(if: $withPosts) { title }
    friends @defer { name }  # 느린 필드는 나중에 스트리밍
  }
}
```

### 3. 클라이언트 라이브러리 비교

| 항목 | Apollo Client | urql | Relay |
|------|--------------|------|-------|
| 번들 크기 | ~40KB | ~7KB | ~30KB + Compiler |
| 캐시 | Normalized (자동) | Document Hash (기본) | Normalized (Compiler) |
| 장점 | 최대 생태계, DevTools | 경량, Exchange 플러그인 | 빌드타임 최적화, Fragment 강제 |
| 단점 | 번들 크기, 복잡한 캐시 | 생태계 작음 | 학습곡선, 서버 규칙 강제 |
| 적합 | 중규모 일반 프로젝트 | 소규모/초기 | 대규모/성능 중시 |

**Apollo Cache Policies:**
- `cache-first`: 캐시 우선 (기본값)
- `cache-and-network`: 캐시 먼저 + 네트워크도 요청
- `network-only`: 항상 네트워크
- `no-cache`: 캐시 읽기/쓰기 없음

### 4. Persisted Queries & 보안

**Automatic Persisted Queries (APQ):**
1. 클라이언트가 쿼리 해시(sha256)로 요청
2. 서버에 없으면 전체 쿼리 재전송 → 서버가 해시 저장
3. 이후 해시만으로 실행 → 네트워크 절약 + CDN 캐싱 가능

**보안 전략:**
- Operation Allowlist: 프로덕션에서 허용된 쿼리만 실행
- Depth Limiting: 쿼리 깊이 제한 (5~7)
- Cost Analysis: 필드별 비용 계산, 총 비용 초과 시 거부

### 5. GraphQL Code Generation

```yaml
# codegen.ts
const config: CodegenConfig = {
  schema: 'http://localhost:4000/graphql',
  documents: ['src/**/*.{ts,tsx}'],
  generates: {
    './src/__generated__/': {
      preset: 'client',
      config: { fragmentMasking: { unmaskFunctionName: 'getFragmentData' } },
    },
  },
};
```

**typed-document-node** — 쿼리별 타입 자동 적용:

```typescript
import { useQuery } from '@apollo/client';
import { GetUserDocument } from '../__generated__/graphql';

function UserProfile({ userId }: { userId: string }) {
  // data 타입이 자동 추론, variables도 타입 검증
  const { data } = useQuery(GetUserDocument, { variables: { id: userId } });
  return <div>{data?.user.name}</div>;
}
```

**Fragment Masking** — 컴포넌트 외부에서 fragment 데이터 접근 차단:

```typescript
import { FragmentType, getFragmentData } from '../__generated__';

function UserAvatar({ user }: { user: FragmentType<typeof UserAvatarFragment> }) {
  const data = getFragmentData(UserAvatarFragment, user); // 언마스킹 필요
  return <img src={data.avatarUrl} alt={data.name} />;
}
```

### 6. tRPC: GraphQL 없이 타입 안전한 API

```typescript
// server — 라우터 정의
export const appRouter = t.router({
  user: t.router({
    getById: t.procedure
      .input(z.object({ id: z.string() }))
      .query(async ({ input }) => db.user.findUnique({ where: { id: input.id } })),
  }),
});
export type AppRouter = typeof appRouter; // 타입만 export

// client — 함수처럼 호출
const { data } = trpc.user.getById.useQuery({ id: userId });
// data 타입이 서버 반환 타입과 자동 일치
```

**한계:** 모노레포 필수, TypeScript 외 클라이언트 불가, 공개 API 부적합

---

## 실전 코드 예제

### Apollo Client + Fragment Colocation

```typescript
// components/PostCard/PostCard.fragment.ts
export const PostCardFragment = graphql(`
  fragment PostCardFields on Post {
    id
    title
    excerpt
    author { ...UserAvatarFields }
  }
`);

// components/PostCard/index.tsx
export function PostCard({ post }: { post: FragmentType<typeof PostCardFragment> }) {
  const data = getFragmentData(PostCardFragment, post);
  return (
    <article>
      <UserAvatar user={data.author} />
      <h2>{data.title}</h2>
      <p>{data.excerpt}</p>
    </article>
  );
}

// pages/PostList.tsx — fragment 조합
const GetPostsQuery = graphql(`
  query GetPosts($page: Int!) {
    posts(page: $page) { id ...PostCardFields }
  }
`);
```

### Optimistic Update

```typescript
const [likePost] = useMutation(LikePostMutation, {
  optimisticResponse: {
    likePost: {
      __typename: 'Post',
      id: postId,
      likesCount: currentLikes + 1,
      isLikedByMe: true,
    },
  },
  // Normalized Cache가 __typename + id로 자동 갱신
  // 서버 에러 시 자동 롤백
});
```

### Subscription (WebSocket)

```typescript
// 링크 설정: operation 타입에 따라 HTTP/WS 분기
const splitLink = split(
  ({ query }) => {
    const def = getMainDefinition(query);
    return def.kind === 'OperationDefinition' && def.operation === 'subscription';
  },
  wsLink,   // Subscription → WebSocket
  httpLink,  // Query/Mutation → HTTP
);

// 사용: 새 메시지 수신 시 캐시 업데이트
useSubscription(NewMessageSub, {
  variables: { roomId },
  onData: ({ client, data }) => {
    client.cache.updateQuery(
      { query: MessagesQuery, variables: { roomId } },
      (prev) => ({ messages: [...prev.messages, data.data.messageAdded] })
    );
  },
});
```

### tRPC + Next.js App Router

```typescript
// app/api/trpc/[trpc]/route.ts
import { fetchRequestHandler } from '@trpc/server/adapters/fetch';
import { appRouter } from '@/server/router';

const handler = (req: Request) =>
  fetchRequestHandler({ endpoint: '/api/trpc', req, router: appRouter });

export { handler as GET, handler as POST };
```

```typescript
// app/users/[id]/page.tsx (Server Component에서 직접 호출)
import { appRouter } from '@/server/router';

export default async function UserPage({ params }: { params: { id: string } }) {
  const caller = appRouter.createCaller({});
  const user = await caller.user.getById({ id: params.id });
  return <div>{user.name}</div>;
}
```

---

## 안티패턴

| 안티패턴 | 문제점 | 해결책 |
|----------|--------|--------|
| 쿼리를 한 파일에 몰아넣기 | 컴포넌트 삭제 시 dead field 잔존 | Fragment Colocation |
| codegen 없이 수동 타입 | 스키마 변경 시 타입 불일치 | graphql-codegen 사용 |
| Normalized Cache 무시 | 뮤테이션 후 UI 불일치 | `update` / `evict` / `refetchQueries` |
| 아이템마다 개별 쿼리 | N+1 문제 → 네트워크 폭발 | 부모에서 배치 조회 |
| 모든 필드 요청 | GraphQL의 장점 상실 | 필요한 필드만 fragment로 선언 |

---

## 면접 포인트

### Q: REST와 GraphQL의 차이, 언제 GraphQL을 선택하는가?
REST는 리소스 중심(URL=리소스), GraphQL은 클라이언트 중심(필요한 것만 요청). 화면마다 필요한 데이터가 다르고 여러 리소스를 조합해야 할 때 GraphQL 선택. 단순 CRUD나 HTTP 캐싱이 중요하면 REST 유지.

### Q: Fragment Colocation이란?
컴포넌트가 필요한 GraphQL 필드를 해당 파일 옆에 fragment로 선언하는 패턴. 데이터 의존성 명시, dead field 방지, 컴포넌트 캡슐화. Relay는 강제, Apollo/urql은 권장.

### Q: Apollo Normalized Cache의 동작 원리?
모든 객체를 `__typename:id` 키로 평탄화 저장. 같은 엔티티를 여러 쿼리에서 참조해도 단일 진실 소스(SSOT). 뮤테이션 결과에 `id` + 변경 필드가 포함되면 모든 참조를 자동 갱신.

### Q: Persisted Queries의 목적?
네트워크 절약(해시로 요청), 보안(allowlist로 임의 쿼리 차단), CDN 캐싱(GET 변환 가능).

### Q: tRPC는 언제 적합하고 GraphQL과 어떻게 다른가?
풀스택 TS 모노레포에서 최적. 별도 스키마 언어 없이 TypeScript 타입을 빌드타임에 직접 공유. 모노레포 외부·다른 언어 클라이언트가 필요하면 GraphQL이 적합.

### Q: GraphQL Subscription을 언제 사용하는가?
채팅, 알림, 라이브 대시보드 등 실시간 필요 시. Polling 대비 즉시성 확보. WebSocket 연결 비용이 있으므로 업데이트 빈도가 낮으면 polling이 나을 수 있음.

---

## 심화: Normalized Cache 깊이 이해

Apollo Client의 Normalized Cache는 GraphQL 클라이언트의 핵심 차별점이다.

### 동작 원리

```
서버 응답:
{
  "data": {
    "posts": [
      { "id": "1", "title": "Hello", "author": { "id": "10", "name": "Kim" } },
      { "id": "2", "title": "World", "author": { "id": "10", "name": "Kim" } }
    ]
  }
}

Normalized Cache 저장:
{
  "Post:1": { id: "1", title: "Hello", author: { __ref: "User:10" } },
  "Post:2": { id: "2", title: "World", author: { __ref: "User:10" } },
  "User:10": { id: "10", name: "Kim" },
  "ROOT_QUERY": { posts: [{ __ref: "Post:1" }, { __ref: "Post:2" }] }
}
```

### 자동 갱신이 되는 경우 vs 안 되는 경우

**자동 갱신됨:**
- 뮤테이션 결과에 `id` + 변경된 필드 포함 → 해당 `__ref` 자동 업데이트
- 예: `updateUser(id: "10", name: "Park")` → `User:10.name`이 모든 곳에서 갱신

**수동 처리 필요:**
- 리스트에 새 아이템 추가/삭제 (캐시가 "어떤 리스트에 넣을지" 모름)
- 해결: `update` 함수로 캐시 직접 조작, 또는 `refetchQueries`

```typescript
const [deletePost] = useMutation(DeletePostMutation, {
  update(cache, { data }) {
    cache.evict({ id: cache.identify(data.deletePost) });
    cache.gc(); // 참조 없는 엔티티 정리
  },
});
```

---

## 참고 자료

- [GraphQL 공식 문서](https://graphql.org/learn/)
- [Apollo Client 문서](https://www.apollographql.com/docs/react/)
- [urql 문서](https://formidable.com/open-source/urql/docs/)
- [Relay 문서](https://relay.dev/docs/)
- [tRPC 문서](https://trpc.io/docs)
- [GraphQL Code Generator](https://the-guild.dev/graphql/codegen)
- "Production Ready GraphQL" — Marc-André Giroux
- "Learning GraphQL" — Eve Porcello, Alex Banks (O'Reilly)
