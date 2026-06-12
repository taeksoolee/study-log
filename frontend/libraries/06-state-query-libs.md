# 6. 서버 상태 관리

## 목차

1. [클라이언트 상태 vs 서버 상태](#1-클라이언트-상태-vs-서버-상태)
2. [TanStack Query (React Query)](#2-tanstack-query-react-query)
3. [useQuery, useMutation, useInfiniteQuery](#3-usequery-usemutation-useinfinitequery)
4. [쿼리 키 전략](#4-쿼리-키-전략)
5. [SWR](#5-swr)
6. [React Query vs SWR 비교](#6-react-query-vs-swr-비교)
7. [클라이언트 상태와 서버 상태 분리 전략](#7-클라이언트-상태와-서버-상태-분리-전략)
8. [면접 포인트](#8-면접-포인트)

---

## 1. 클라이언트 상태 vs 서버 상태

| 구분 | 클라이언트 상태 | 서버 상태 |
|------|--------------|---------|
| 위치 | 브라우저 메모리 | 서버 DB |
| 예시 | 모달 열림/닫힘, 선택한 탭, 장바구니 UI 상태 | 유저 목록, 상품 정보, 주문 내역 |
| 동기화 | 필요 없음 | 항상 최신 상태 유지 필요 |
| 관리 도구 | Zustand, Jotai, Redux, useState | TanStack Query, SWR |
| 특징 | 개발자가 완전히 통제 | 캐싱, 리페치, 동기화 복잡성 |

---

## 2. TanStack Query (React Query)

서버 상태를 위한 비동기 데이터 패칭, 캐싱, 동기화 라이브러리.

```bash
npm install @tanstack/react-query
npm install --save-dev @tanstack/react-query-devtools
```

### 설정

```tsx
// main.tsx
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ReactQueryDevtools } from '@tanstack/react-query-devtools';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60 * 5,    // 5분: 데이터를 fresh로 간주하는 시간
      gcTime: 1000 * 60 * 10,       // 10분: 캐시 유지 시간 (v5: gcTime, v4: cacheTime)
      retry: 3,                      // 실패 시 재시도 횟수
      refetchOnWindowFocus: true,   // 탭 포커스 시 리페치
    },
  },
});

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <Router />
      <ReactQueryDevtools />
    </QueryClientProvider>
  );
}
```

### 데이터 상태 흐름

```
fresh → stale → (백그라운드 리페치) → fresh
                ↓
         gcTime 초과 → 캐시 삭제

- fresh: staleTime 이내, 리페치 안 함
- stale: staleTime 초과, 조건 만족 시 백그라운드 리페치
- fetching: 현재 네트워크 요청 중
- paused: 오프라인 등으로 일시 중단
```

---

## 3. useQuery, useMutation, useInfiniteQuery

### useQuery

```tsx
import { useQuery } from '@tanstack/react-query';

// API 함수 분리
const userApi = {
  getUser: async (id: number) => {
    const res = await fetch(`/api/users/${id}`);
    if (!res.ok) throw new Error('유저를 찾을 수 없습니다');
    return res.json() as Promise<User>;
  },
  getUsers: async () => {
    const res = await fetch('/api/users');
    return res.json() as Promise<User[]>;
  },
};

function UserProfile({ userId }: { userId: number }) {
  const {
    data: user,
    isLoading,
    isError,
    error,
    isFetching,         // 백그라운드 리페치 포함
    refetch,            // 수동 리페치
  } = useQuery({
    queryKey: ['user', userId],
    queryFn: () => userApi.getUser(userId),
    enabled: !!userId,  // userId가 있을 때만 실행
    staleTime: 1000 * 60, // 이 쿼리만 1분
    select: (data) => ({ ...data, fullName: `${data.firstName} ${data.lastName}` }),
  });

  if (isLoading) return <Spinner />;
  if (isError) return <ErrorMessage message={error.message} />;

  return (
    <div>
      <h1>{user?.fullName}</h1>
      {isFetching && <span>업데이트 중...</span>}
    </div>
  );
}
```

### useMutation

```tsx
import { useMutation, useQueryClient } from '@tanstack/react-query';

function CreateUserForm() {
  const queryClient = useQueryClient();

  const createMutation = useMutation({
    mutationFn: (newUser: CreateUserDto) =>
      fetch('/api/users', {
        method: 'POST',
        body: JSON.stringify(newUser),
      }).then(res => res.json()),

    // 낙관적 업데이트 (요청 전 UI 먼저 반영)
    onMutate: async (newUser) => {
      await queryClient.cancelQueries({ queryKey: ['users'] });
      const previous = queryClient.getQueryData(['users']);

      queryClient.setQueryData(['users'], (old: User[]) => [
        ...old,
        { ...newUser, id: Date.now(), pending: true },
      ]);

      return { previous }; // 롤백을 위해 이전 데이터 저장
    },

    onError: (error, variables, context) => {
      // 실패 시 롤백
      queryClient.setQueryData(['users'], context?.previous);
    },

    onSuccess: () => {
      // 성공 시 관련 쿼리 무효화 → 자동 리페치
      queryClient.invalidateQueries({ queryKey: ['users'] });
    },
  });

  return (
    <form onSubmit={(e) => {
      e.preventDefault();
      createMutation.mutate({ name: '홍길동', email: 'hong@example.com' });
    }}>
      <button disabled={createMutation.isPending}>
        {createMutation.isPending ? '저장 중...' : '저장'}
      </button>
      {createMutation.isError && <p>저장 실패: {createMutation.error.message}</p>}
    </form>
  );
}
```

### useInfiniteQuery

```tsx
import { useInfiniteQuery } from '@tanstack/react-query';
import { useInView } from 'react-intersection-observer';

function InfiniteUserList() {
  const { ref, inView } = useInView();

  const {
    data,
    fetchNextPage,
    hasNextPage,
    isFetchingNextPage,
  } = useInfiniteQuery({
    queryKey: ['users', 'infinite'],
    queryFn: ({ pageParam }) =>
      fetch(`/api/users?cursor=${pageParam}&limit=20`).then(r => r.json()),
    initialPageParam: 0,
    getNextPageParam: (lastPage) => lastPage.nextCursor ?? undefined,
  });

  useEffect(() => {
    if (inView && hasNextPage) fetchNextPage();
  }, [inView, hasNextPage]);

  const allUsers = data?.pages.flatMap(page => page.users) ?? [];

  return (
    <>
      {allUsers.map(user => <UserCard key={user.id} user={user} />)}
      <div ref={ref}>
        {isFetchingNextPage && <Spinner />}
      </div>
    </>
  );
}
```

---

## 4. 쿼리 키 전략

쿼리 키는 캐시의 고유 식별자. 배열 형식 권장.

```ts
// 계층적 구조로 관리
const queryKeys = {
  // 모든 user 관련 쿼리
  users: () => ['users'] as const,

  // 목록 쿼리
  userList: (filters?: UserFilters) =>
    [...queryKeys.users(), 'list', filters] as const,

  // 상세 쿼리
  userDetail: (id: number) =>
    [...queryKeys.users(), 'detail', id] as const,
};

// 사용
useQuery({ queryKey: queryKeys.userDetail(1) });
useQuery({ queryKey: queryKeys.userList({ active: true }) });

// 특정 사용자 관련 쿼리 모두 무효화
queryClient.invalidateQueries({ queryKey: queryKeys.users() });

// 특정 사용자 상세만 무효화
queryClient.invalidateQueries({ queryKey: queryKeys.userDetail(1) });
```

---

## 5. SWR

Vercel이 만든 경량 데이터 패칭 라이브러리. stale-while-revalidate 전략.

```bash
npm install swr
```

```tsx
import useSWR from 'swr';
import useSWRMutation from 'swr/mutation';

// fetcher 함수 정의
const fetcher = (url: string) => fetch(url).then(r => r.json());

function UserProfile({ userId }: { userId: number }) {
  const { data: user, error, isLoading, mutate } = useSWR(
    userId ? `/api/users/${userId}` : null, // null이면 요청 안 함
    fetcher,
    {
      revalidateOnFocus: true,      // 탭 포커스 시 재검증
      refreshInterval: 0,           // 폴링 간격 (0 = 비활성)
      dedupingInterval: 2000,       // 중복 요청 방지
    }
  );

  // 낙관적 업데이트
  const updateName = async (name: string) => {
    mutate({ ...user, name }, false); // 즉시 반영, 재검증 없음
    await fetch(`/api/users/${userId}`, {
      method: 'PATCH',
      body: JSON.stringify({ name }),
    });
    mutate(); // 서버에서 다시 가져옴
  };

  if (isLoading) return <Spinner />;
  if (error) return <ErrorMessage />;
  return <div>{user?.name}</div>;
}

// Mutation
function CreateUser() {
  const { trigger, isMutating } = useSWRMutation(
    '/api/users',
    (url, { arg }: { arg: CreateUserDto }) =>
      fetch(url, { method: 'POST', body: JSON.stringify(arg) }).then(r => r.json())
  );

  return (
    <button onClick={() => trigger({ name: '홍길동' })} disabled={isMutating}>
      생성
    </button>
  );
}
```

---

## 6. React Query vs SWR 비교

| 항목 | TanStack Query | SWR |
|------|---------------|-----|
| 번들 크기 | ~13KB | ~4KB |
| 캐시 무효화 | `invalidateQueries` (세밀한 제어) | `mutate(key)` |
| 쿼리 키 | 배열 (계층적 관리 용이) | 문자열/함수 |
| Mutation | `useMutation` (onMutate, onError, onSuccess) | `useSWRMutation` |
| 낙관적 업데이트 | `onMutate` | `mutate(data, false)` |
| 무한 스크롤 | `useInfiniteQuery` 내장 | `useSWRInfinite` |
| DevTools | `@tanstack/react-query-devtools` | 없음 |
| 전역 상태 읽기 | `useQueryClient` | `useSWRConfig` |
| 프리패칭 | `prefetchQuery` | `preload` |
| 의존 쿼리 | `enabled` 옵션 | `null` 키로 중단 |

**선택 기준:**
- 복잡한 캐시 무효화, Mutation 처리, DevTools 필요 → **TanStack Query**
- 단순 데이터 패칭, 번들 크기 중요, Next.js 앱 → **SWR**

---

## 7. 클라이언트 상태와 서버 상태 분리 전략

```tsx
// 나쁜 예: 서버 상태를 클라이언트 상태(useState)로 관리
function BadComponent() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    setLoading(true);
    fetch('/api/users')
      .then(r => r.json())
      .then(data => { setUsers(data); setLoading(false); });
  }, []);

  // 문제: 캐싱 없음, 중복 요청, 갱신 로직 복잡, 오류 처리 불편
}

// 좋은 예: 역할 분리
// - 서버 상태 → TanStack Query
// - UI 상태 → useState / Zustand
function GoodComponent() {
  // 서버 상태
  const { data: users } = useQuery({
    queryKey: ['users'],
    queryFn: () => fetch('/api/users').then(r => r.json()),
  });

  // 클라이언트(UI) 상태
  const [selectedUserId, setSelectedUserId] = useState<number | null>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);

  const { data: selectedUser } = useQuery({
    queryKey: ['user', selectedUserId],
    queryFn: () => fetch(`/api/users/${selectedUserId}`).then(r => r.json()),
    enabled: selectedUserId !== null,
  });

  return (/* ... */);
}
```

---

## 8. 면접 포인트

**Q. TanStack Query가 해결하는 문제는?**
> API 데이터 패칭의 반복적인 패턴(로딩/에러/성공 상태, 캐싱, 중복 요청 제거, 백그라운드 동기화)을 추상화합니다. `useEffect + useState` 조합으로 서버 상태를 관리하면 캐시 무효화, 낙관적 업데이트, 무한 스크롤 등을 직접 구현해야 하는 복잡함이 있습니다.

**Q. staleTime과 gcTime(cacheTime)의 차이는?**
> `staleTime`은 데이터를 "신선함(fresh)"으로 간주하는 시간입니다. 이 시간 동안은 동일 쿼리 요청 시 네트워크 요청 없이 캐시를 반환합니다. `gcTime`은 쿼리가 비활성(구독 컴포넌트가 없음) 상태에서 캐시가 메모리에 유지되는 시간입니다. gcTime 초과 후 캐시는 삭제됩니다.

**Q. 낙관적 업데이트(Optimistic Update)란?**
> 서버 응답을 기다리지 않고 먼저 UI를 업데이트하는 기법입니다. UX가 즉각적으로 느껴집니다. 서버 요청 실패 시 `onError`에서 이전 상태로 롤백합니다. 성공률이 높은 단순 작업(좋아요, 체크박스 등)에 적합합니다.

**Q. 서버 상태와 클라이언트 상태를 왜 분리해야 하는가?**
> 서버 상태는 여러 클라이언트에서 공유되고, 언제든 변할 수 있으며, 비동기로 로드됩니다. 이를 단순 `useState`로 관리하면 캐싱, 동기화, 중복 요청, 리페치 타이밍을 모두 직접 구현해야 합니다. TanStack Query 같은 도구로 서버 상태를 분리하면 클라이언트 상태 관리(Zustand 등)가 훨씬 단순해집니다.
