# React Server Components & Next.js App Router 심화

## 개요

React Server Components(RSC)는 React 18에서 도입된 새로운 아키텍처로, 컴포넌트를 **서버에서만 실행**하여 클라이언트로 전송되는 JavaScript 번들을 줄이고 서버 리소스에 직접 접근할 수 있게 한다.

### 기존 렌더링 방식과의 비교

| 방식 | 특징 | 한계 |
|------|------|------|
| **CSR** | 브라우저에서 모든 렌더링 수행 | 초기 로딩 느림, SEO 불리, 큰 번들 |
| **SSR** | 서버에서 HTML 생성 → 클라이언트에서 hydration | 전체 페이지 hydration 필요, TTFB 지연 |
| **RSC** | 서버 컴포넌트는 서버에서만 실행, 클라이언트 컴포넌트만 hydration | 새로운 멘탈 모델 학습 필요 |

### RSC가 필요한 이유

1. **제로 번들 사이즈**: 서버 컴포넌트의 코드는 클라이언트로 전송되지 않음
2. **직접 백엔드 접근**: DB, 파일 시스템, 내부 API에 직접 접근 가능
3. **자동 코드 스플리팅**: 클라이언트 컴포넌트만 자동으로 lazy-load
4. **점진적 스트리밍**: Suspense와 결합하여 준비된 부분부터 전송

---

## 핵심 개념

### 1. Server Component vs Client Component

#### 렌더링 위치 차이

```
┌─────────────────────────────────────────────┐
│  Server                                     │
│  ┌───────────────────────────────────────┐  │
│  │ Server Component (RSC Payload 생성)   │  │
│  │  - DB 쿼리, fs 접근, 환경변수 사용    │  │
│  │  - HTML + RSC Payload → 클라이언트    │  │
│  └───────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
          │ RSC Payload (직렬화된 UI 트리)
          ▼
┌─────────────────────────────────────────────┐
│  Client (Browser)                           │
│  ┌───────────────────────────────────────┐  │
│  │ Client Component (Hydration)          │  │
│  │  - useState, useEffect 사용 가능      │  │
│  │  - 이벤트 핸들러, 브라우저 API 접근   │  │
│  └───────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

- **Server Component**: 서버에서 실행되어 RSC Payload(직렬화된 React 트리)로 변환됨. 클라이언트에 JS가 전송되지 않음.
- **Client Component**: 서버에서 프리렌더링 후, 클라이언트에서 hydration되어 인터랙티브해짐.

#### 'use client' 디렉티브의 의미

`'use client'`는 **서버-클라이언트 경계(boundary)**를 선언하는 디렉티브다.

```tsx
// components/counter.tsx
'use client'; // ← 이 파일부터 아래로 클라이언트 경계

import { useState } from 'react';

export function Counter() {
  const [count, setCount] = useState(0);
  return <button onClick={() => setCount(c => c + 1)}>Count: {count}</button>;
}
```

핵심 포인트:
- `'use client'`가 선언된 파일과 그 하위 import 전체가 클라이언트 번들에 포함됨
- **경계를 최대한 깊이(leaf)** 설정해야 번들이 작아짐
- 모든 컴포넌트에 붙일 필요 없음 — 경계 파일만 선언하면 됨

#### Serialization 제약

서버 컴포넌트 → 클라이언트 컴포넌트로 전달되는 props는 **직렬화 가능(serializable)**해야 한다.

```tsx
// ❌ 불가능: 함수를 props로 전달
async function ServerPage() {
  const handleClick = () => console.log('click'); // 함수는 직렬화 불가
  return <ClientButton onClick={handleClick} />; // Error!
}

// ✅ 가능: 직렬화 가능한 데이터만 전달
async function ServerPage() {
  const data = await fetchData();
  return <ClientChart data={data} />; // 객체, 배열, 문자열 등 OK
}
```

전달 가능한 타입: `string`, `number`, `boolean`, `null`, `Array`, `plain object`, `Date`, `Map`, `Set`, `TypedArray`, `FormData`, JSX(React Element)

#### 컴포넌트 트리 배치 전략

```
Layout (Server) ─── 공통 UI, 데이터 fetch
  ├── Header (Server) ─── 정적 네비게이션
  │     └── SearchBar (Client) ─── 인터랙션 필요
  ├── Sidebar (Server) ─── 서버에서 메뉴 데이터 로드
  └── Content (Server) ─── 데이터 fetch
        ├── DataTable (Server) ─── 서버에서 렌더링
        └── FilterPanel (Client) ─── 사용자 입력
```

**원칙**: 가능한 한 Server Component로 유지하고, 인터랙션이 필요한 **리프 노드만** Client Component로 분리.


---

### 2. Server Actions

Server Actions는 서버에서 실행되는 비동기 함수를 클라이언트에서 직접 호출할 수 있게 하는 메커니즘이다.

#### 'use server' 디렉티브

```tsx
// app/actions.ts
'use server'; // 파일 전체를 Server Action으로 선언

import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';
import { z } from 'zod';

const CreatePostSchema = z.object({
  title: z.string().min(1).max(100),
  content: z.string().min(1),
});

export async function createPost(formData: FormData) {
  // 1. 입력 검증 (필수!)
  const parsed = CreatePostSchema.safeParse({
    title: formData.get('title'),
    content: formData.get('content'),
  });

  if (!parsed.success) {
    return { error: parsed.error.flatten().fieldErrors };
  }

  // 2. 데이터 저장
  await db.post.create({ data: parsed.data });

  // 3. 캐시 무효화
  revalidatePath('/posts');

  // 4. 리다이렉트
  redirect('/posts');
}
```

#### form action으로 사용

```tsx
// app/posts/new/page.tsx (Server Component)
import { createPost } from '@/app/actions';

export default function NewPostPage() {
  return (
    <form action={createPost}>
      <input name="title" type="text" required />
      <textarea name="content" required />
      <button type="submit">작성</button>
    </form>
  );
}
```

#### Progressive Enhancement

Server Actions를 `<form action>`에 바인딩하면 **JavaScript가 비활성화된 환경에서도** 폼 제출이 동작한다. 브라우저의 네이티브 폼 제출 메커니즘을 활용하기 때문이다.

JS가 로드되면 React가 이를 인터셉트하여 SPA처럼 동작(전체 페이지 리로드 없음).

#### revalidatePath / revalidateTag

```tsx
'use server';

import { revalidatePath, revalidateTag } from 'next/cache';

export async function updateUser(formData: FormData) {
  await db.user.update({ /* ... */ });

  // 특정 경로의 캐시 무효화
  revalidatePath('/dashboard');

  // 특정 태그가 붙은 fetch 캐시 무효화
  revalidateTag('user-profile');
}
```

#### 보안 고려사항

> ⚠️ Server Actions는 공개 HTTP 엔드포인트와 동일하게 취급해야 한다.

1. **입력 검증 필수**: `zod`, `valibot` 등으로 모든 입력을 검증
2. **인증/인가 확인**: 액션 내부에서 세션 검증
3. **클로저 변수 암호화**: Server Action에서 캡처하는 외부 변수는 자동 암호화되지만, 민감 데이터는 직접 포함하지 말 것
4. **Rate Limiting**: 무차별 호출 방지

```tsx
'use server';

import { auth } from '@/lib/auth';

export async function deletePost(postId: string) {
  const session = await auth();
  if (!session) throw new Error('Unauthorized');

  // postId도 검증 (조작 가능)
  const post = await db.post.findUnique({ where: { id: postId } });
  if (post?.authorId !== session.user.id) throw new Error('Forbidden');

  await db.post.delete({ where: { id: postId } });
  revalidatePath('/posts');
}
```


---

### 3. Streaming SSR & Suspense

#### loading.tsx vs Suspense 경계 직접 설정

Next.js App Router는 두 가지 방식으로 로딩 상태를 관리한다:

```
app/
├── dashboard/
│   ├── loading.tsx    ← 자동 Suspense 경계 (page.tsx 전체를 감싸줌)
│   └── page.tsx
```

```tsx
// app/dashboard/loading.tsx
// page.tsx 전체에 대한 로딩 UI (자동으로 Suspense boundary 생성)
export default function DashboardLoading() {
  return <div className="skeleton">대시보드 로딩 중...</div>;
}
```

더 세밀한 제어가 필요하면 **Suspense를 직접 배치**:

```tsx
// app/dashboard/page.tsx
import { Suspense } from 'react';
import { RevenueChart } from './revenue-chart';
import { LatestInvoices } from './latest-invoices';
import { CardsSkeleton, ChartSkeleton, InvoicesSkeleton } from './skeletons';

export default function DashboardPage() {
  return (
    <main>
      {/* 카드는 빠르게 로드 */}
      <Suspense fallback={<CardsSkeleton />}>
        <DashboardCards />
      </Suspense>

      <div className="grid grid-cols-2 gap-4">
        {/* 차트와 인보이스가 독립적으로 스트리밍 */}
        <Suspense fallback={<ChartSkeleton />}>
          <RevenueChart />
        </Suspense>
        <Suspense fallback={<InvoicesSkeleton />}>
          <LatestInvoices />
        </Suspense>
      </div>
    </main>
  );
}
```

#### 점진적 렌더링의 UX 이점

- 전체 데이터를 기다리지 않고 **준비된 부분부터** 사용자에게 표시
- 느린 데이터 소스가 전체 페이지를 블로킹하지 않음
- 각 Suspense 경계가 독립적으로 resolve → **병렬 스트리밍**

#### generateStaticParams과의 관계

```tsx
// app/posts/[id]/page.tsx
// 빌드 타임에 정적으로 생성할 경로 지정
export async function generateStaticParams() {
  const posts = await db.post.findMany({ select: { id: true } });
  return posts.map((post) => ({ id: post.id }));
}

// 이 페이지는 빌드 시 정적 HTML로 생성됨 (Full Route Cache에 저장)
export default async function PostPage({ params }: { params: { id: string } }) {
  const post = await db.post.findUnique({ where: { id: params.id } });
  return <article>{post?.content}</article>;
}
```

- `generateStaticParams`로 지정된 경로: 빌드 시 정적 생성 (SSG와 유사)
- 지정되지 않은 경로: 요청 시 동적 생성 후 캐시 (ISR과 유사)
- Suspense와 결합하면 정적 shell은 즉시 제공, 동적 부분만 스트리밍


---

### 4. 캐시 레이어 이해

Next.js App Router는 4개의 캐시 레이어를 가진다:

```
요청 흐름:
Browser → Router Cache → Full Route Cache → Data Cache → Request Memoization → Origin
```

| 캐시 | 위치 | 대상 | 지속시간 | 무효화 방법 |
|------|------|------|----------|------------|
| Request Memoization | 서버 | 동일 요청 중 중복 fetch | 단일 요청 | 자동 (요청 종료 시) |
| Data Cache | 서버 | fetch() 응답 | 영구 (재배포까지) | `revalidateTag`, `revalidatePath` |
| Full Route Cache | 서버 | 정적 라우트의 HTML + RSC Payload | 영구 (재배포까지) | `revalidatePath`, 재배포 |
| Router Cache | 클라이언트 | 방문한 라우트의 RSC Payload | 세션 동안 (동적: 30초, 정적: 5분) | `router.refresh()`, Server Action |

#### Request Memoization

같은 렌더링 패스 내에서 동일한 URL + 옵션의 `fetch`를 자동 중복 제거한다.

```tsx
// 같은 요청이 layout과 page에서 모두 호출되어도 실제 fetch는 1번만 실행
// layout.tsx
const user = await fetch('/api/user'); // fetch 실행됨

// page.tsx (같은 요청 내)
const user = await fetch('/api/user'); // 캐시된 결과 재사용
```

#### Data Cache

```tsx
// 기본: 영구 캐시 (opt-in 무효화)
const data = await fetch('https://api.example.com/data');

// 시간 기반 재검증: 60초마다
const data = await fetch('https://api.example.com/data', {
  next: { revalidate: 60 },
});

// 태그 기반 재검증
const data = await fetch('https://api.example.com/data', {
  next: { tags: ['posts'] },
});

// 캐시 비활성화
const data = await fetch('https://api.example.com/data', {
  cache: 'no-store',
});
```

#### revalidate 전략 비교

```tsx
// Time-based: 일정 시간 후 백그라운드에서 갱신
export const revalidate = 3600; // 1시간마다 (페이지 레벨)

// On-demand: 특정 이벤트 발생 시 즉시 무효화
'use server';
import { revalidateTag } from 'next/cache';

export async function publishPost() {
  await db.post.update({ /* ... */ });
  revalidateTag('posts'); // 'posts' 태그가 달린 모든 캐시 무효화
}
```


---

### 5. Partial Prerendering (PPR)

PPR은 Next.js 14에서 실험적으로 도입된 렌더링 모델로, **하나의 라우트에서 정적 부분과 동적 부분을 분리**한다.

#### Static Shell + Dynamic Holes

```tsx
// next.config.ts
import type { NextConfig } from 'next';

const config: NextConfig = {
  experimental: {
    ppr: true, // PPR 활성화
  },
};

export default config;
```

```tsx
// app/product/[id]/page.tsx
import { Suspense } from 'react';
import { ProductInfo } from './product-info';    // 정적 (빌드 시 생성)
import { Reviews } from './reviews';             // 동적 (요청 시 스트리밍)
import { ReviewsSkeleton } from './skeletons';

export default function ProductPage({ params }: { params: { id: string } }) {
  return (
    <main>
      {/* 정적 shell: CDN에서 즉시 제공 */}
      <ProductInfo id={params.id} />

      {/* 동적 hole: Suspense 경계 안의 동적 데이터 */}
      <Suspense fallback={<ReviewsSkeleton />}>
        <Reviews productId={params.id} />
      </Suspense>
    </main>
  );
}
```

#### 어떤 페이지에 적합한지

| 적합 | 부적합 |
|------|--------|
| 상품 상세 (정적 정보 + 동적 리뷰/재고) | 완전히 개인화된 페이지 (마이페이지) |
| 블로그 포스트 (본문 정적 + 댓글 동적) | 실시간 대시보드 (모든 데이터 동적) |
| 랜딩 페이지 (레이아웃 정적 + A/B 테스트 동적) | 인증 필수 페이지 전체 |

PPR의 이점:
- 정적 shell이 CDN에서 즉시 제공 → **TTFB 최소화**
- 동적 부분만 서버에서 스트리밍 → **사용자 체감 성능 극대화**
- 정적/동적 결정이 **컴포넌트 레벨**에서 자동으로 이루어짐


---

## 실전 예제 코드

대시보드 페이지를 RSC 아키텍처로 구성하는 전체 예제.

### layout.tsx (Server Component — 네비게이션)

```tsx
// app/dashboard/layout.tsx
import { auth } from '@/lib/auth';
import { redirect } from 'next/navigation';
import { NavLinks } from './nav-links';

export default async function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const session = await auth();
  if (!session) redirect('/login');

  return (
    <div className="flex h-screen">
      <aside className="w-64 border-r p-4">
        <h2 className="text-lg font-bold mb-4">Dashboard</h2>
        <NavLinks userName={session.user.name} />
      </aside>
      <main className="flex-1 p-6 overflow-y-auto">
        {children}
      </main>
    </div>
  );
}
```

### page.tsx (Server Component — 데이터 fetch)

```tsx
// app/dashboard/page.tsx
import { Suspense } from 'react';
import { db } from '@/lib/db';
import { SalesChart } from './sales-chart';
import { RecentOrders } from './recent-orders';
import { FilterPanel } from './filter-panel';
import { CardsSkeleton, ChartSkeleton, TableSkeleton } from './skeletons';

async function DashboardCards() {
  const [totalRevenue, totalOrders, activeUsers] = await Promise.all([
    db.order.aggregate({ _sum: { amount: true } }),
    db.order.count(),
    db.user.count({ where: { lastActiveAt: { gte: new Date(Date.now() - 86400000) } } }),
  ]);

  return (
    <div className="grid grid-cols-3 gap-4">
      <StatCard title="총 매출" value={`₩${totalRevenue._sum.amount?.toLocaleString()}`} />
      <StatCard title="총 주문" value={totalOrders.toLocaleString()} />
      <StatCard title="활성 사용자" value={activeUsers.toLocaleString()} />
    </div>
  );
}

function StatCard({ title, value }: { title: string; value: string }) {
  return (
    <div className="rounded-lg border p-4">
      <p className="text-sm text-gray-500">{title}</p>
      <p className="text-2xl font-bold">{value}</p>
    </div>
  );
}

export default function DashboardPage({
  searchParams,
}: {
  searchParams: { period?: string; status?: string };
}) {
  const period = searchParams.period ?? '7d';
  const status = searchParams.status ?? 'all';

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">대시보드</h1>

      {/* 클라이언트 컴포넌트: 필터 인터랙션 */}
      <FilterPanel currentPeriod={period} currentStatus={status} />

      {/* 서버 컴포넌트: 독립적으로 스트리밍 */}
      <Suspense fallback={<CardsSkeleton />}>
        <DashboardCards />
      </Suspense>

      <div className="grid grid-cols-2 gap-6">
        <Suspense fallback={<ChartSkeleton />}>
          <SalesChart period={period} />
        </Suspense>
        <Suspense fallback={<TableSkeleton />}>
          <RecentOrders status={status} />
        </Suspense>
      </div>
    </div>
  );
}
```

### 인터랙티브 필터 (Client Component)

```tsx
// app/dashboard/filter-panel.tsx
'use client';

import { useRouter, useSearchParams } from 'next/navigation';
import { useCallback } from 'react';

interface FilterPanelProps {
  currentPeriod: string;
  currentStatus: string;
}

export function FilterPanel({ currentPeriod, currentStatus }: FilterPanelProps) {
  const router = useRouter();
  const searchParams = useSearchParams();

  const updateFilter = useCallback(
    (key: string, value: string) => {
      const params = new URLSearchParams(searchParams.toString());
      params.set(key, value);
      router.push(`/dashboard?${params.toString()}`);
    },
    [router, searchParams]
  );

  return (
    <div className="flex gap-4">
      <select
        value={currentPeriod}
        onChange={(e) => updateFilter('period', e.target.value)}
        aria-label="기간 필터"
      >
        <option value="7d">최근 7일</option>
        <option value="30d">최근 30일</option>
        <option value="90d">최근 90일</option>
      </select>

      <select
        value={currentStatus}
        onChange={(e) => updateFilter('status', e.target.value)}
        aria-label="상태 필터"
      >
        <option value="all">전체</option>
        <option value="pending">대기중</option>
        <option value="completed">완료</option>
        <option value="cancelled">취소</option>
      </select>
    </div>
  );
}
```

### Server Action으로 데이터 mutation

```tsx
// app/dashboard/actions.ts
'use server';

import { auth } from '@/lib/auth';
import { db } from '@/lib/db';
import { revalidatePath } from 'next/cache';
import { z } from 'zod';

const UpdateOrderSchema = z.object({
  orderId: z.string().uuid(),
  status: z.enum(['pending', 'completed', 'cancelled']),
});

export async function updateOrderStatus(formData: FormData) {
  // 인증 확인
  const session = await auth();
  if (!session) throw new Error('Unauthorized');

  // 입력 검증
  const parsed = UpdateOrderSchema.safeParse({
    orderId: formData.get('orderId'),
    status: formData.get('status'),
  });

  if (!parsed.success) {
    return { error: '잘못된 입력입니다.' };
  }

  // 권한 확인
  const order = await db.order.findUnique({
    where: { id: parsed.data.orderId },
  });
  if (!order) return { error: '주문을 찾을 수 없습니다.' };

  // 업데이트
  await db.order.update({
    where: { id: parsed.data.orderId },
    data: { status: parsed.data.status },
  });

  // 캐시 무효화
  revalidatePath('/dashboard');

  return { success: true };
}
```

```tsx
// app/dashboard/order-actions.tsx
'use client';

import { useActionState } from 'react';
import { updateOrderStatus } from './actions';

export function OrderStatusForm({ orderId }: { orderId: string }) {
  const [state, formAction, isPending] = useActionState(updateOrderStatus, null);

  return (
    <form action={formAction}>
      <input type="hidden" name="orderId" value={orderId} />
      <select name="status" disabled={isPending}>
        <option value="pending">대기중</option>
        <option value="completed">완료</option>
        <option value="cancelled">취소</option>
      </select>
      <button type="submit" disabled={isPending}>
        {isPending ? '처리 중...' : '상태 변경'}
      </button>
      {state?.error && <p className="text-red-500">{state.error}</p>}
    </form>
  );
}
```


---

## 흔한 실수 & 해결

### 1. 'use client' 남용

```tsx
// ❌ 잘못된 패턴: 페이지 전체를 클라이언트로 만듦
'use client'; // 단 하나의 onClick 때문에 전체 페이지가 클라이언트 번들에 포함

export default function ProductPage() {
  const [liked, setLiked] = useState(false);
  const product = useQuery(...); // 서버에서 할 수 있는 데이터 fetch를 클라이언트에서 함
  return <div>...</div>;
}
```

```tsx
// ✅ 올바른 패턴: 인터랙션 부분만 분리
// page.tsx (Server Component)
export default async function ProductPage() {
  const product = await db.product.findUnique(...); // 서버에서 직접 fetch
  return (
    <div>
      <h1>{product.name}</h1>
      <p>{product.description}</p>
      <LikeButton productId={product.id} /> {/* 이것만 Client */}
    </div>
  );
}

// like-button.tsx (Client Component)
'use client';
export function LikeButton({ productId }: { productId: string }) {
  const [liked, setLiked] = useState(false);
  return <button onClick={() => setLiked(!liked)}>♥</button>;
}
```

### 2. Server Component에서 useState/useEffect 사용

```tsx
// ❌ 에러 발생: Server Component에서 훅 사용 불가
export default function ServerPage() {
  const [count, setCount] = useState(0); // ❌ Error!
  useEffect(() => { /* ... */ }, []);     // ❌ Error!
  return <div>{count}</div>;
}
```

서버 컴포넌트에서 사용 불가한 것들:
- `useState`, `useReducer` (상태)
- `useEffect`, `useLayoutEffect` (사이드이펙트)
- `useRef` (DOM 참조)
- 브라우저 API (`window`, `document`, `localStorage`)
- 이벤트 핸들러 (`onClick`, `onChange` 등)

### 3. 직렬화 불가능한 props 전달

```tsx
// ❌ 함수, 클래스 인스턴스, Symbol 등은 직렬화 불가
<ClientComponent
  onClick={() => {}}           // ❌ 함수
  regex={/pattern/}            // ❌ RegExp
  connection={dbConnection}    // ❌ 클래스 인스턴스
/>

// ✅ 해결: 클라이언트 컴포넌트 내부에서 정의하거나, 데이터만 전달
<ClientComponent
  productId={product.id}       // ✅ 문자열
  initialData={product}        // ✅ plain object
/>
```

### 4. 캐시 무효화 누락

```tsx
// ❌ 데이터를 변경했지만 캐시를 무효화하지 않음
'use server';
export async function deletePost(id: string) {
  await db.post.delete({ where: { id } });
  // 캐시 무효화 없음 → UI에 삭제된 게시글이 계속 보임!
}

// ✅ 반드시 관련 캐시를 무효화
'use server';
export async function deletePost(id: string) {
  await db.post.delete({ where: { id } });
  revalidatePath('/posts');          // 경로 기반
  revalidateTag('posts');            // 태그 기반 (더 정밀)
}
```

---

## 면접 포인트

### Q1. RSC와 SSR의 차이를 설명하시오

**SSR**: 서버에서 컴포넌트를 HTML 문자열로 렌더링 → 클라이언트로 전송 → **전체 컴포넌트 트리를 hydration**. 모든 컴포넌트의 JS가 클라이언트로 전송됨.

**RSC**: 서버 컴포넌트는 서버에서 RSC Payload로 직렬화 → 클라이언트 컴포넌트만 hydration. 서버 컴포넌트의 JS는 **클라이언트로 전혀 전송되지 않음**. SSR은 "렌더링 시점"의 최적화, RSC는 "번들 경계"의 최적화.

### Q2. Server Component에서 할 수 없는 것은?

- React 훅 사용 (`useState`, `useEffect`, `useRef` 등)
- 이벤트 핸들러 등록 (`onClick`, `onChange`)
- 브라우저 전용 API 접근 (`window`, `document`, `localStorage`)
- Context 생성/소비 (`createContext`, `useContext`)

### Q3. Next.js의 4가지 캐시 레이어를 설명하시오

1. **Request Memoization**: 단일 렌더링 패스에서 동일 fetch 중복 제거 (자동, 서버)
2. **Data Cache**: fetch 응답을 서버에 영구 저장, `revalidateTag`/`revalidatePath`로 무효화
3. **Full Route Cache**: 정적 라우트의 HTML + RSC Payload를 빌드 시 생성, CDN에서 제공
4. **Router Cache**: 클라이언트에서 방문한 라우트 세그먼트를 메모리에 저장, 뒤로가기/prefetch 시 활용

### Q4. Server Actions의 보안 이슈는?

Server Actions는 내부적으로 POST 엔드포인트가 생성되므로:
- 클라이언트에서 조작된 데이터가 올 수 있음 → **입력 검증 필수** (zod 등)
- 인증되지 않은 사용자가 호출 가능 → **세션 검증 필수**
- 클로저로 캡처된 변수가 암호화되어 전송됨 → 민감 데이터 직접 포함 금지
- CSRF는 Next.js가 자동 방어하지만, **Rate Limiting은 직접 구현** 필요

### Q5. 'use client'는 정확히 무엇을 의미하는가?

`'use client'`는 모듈 수준에서 **서버-클라이언트 경계(module boundary)**를 선언한다. 이 디렉티브가 있는 파일과 그 파일이 import하는 모든 모듈은 클라이언트 번들에 포함된다. "이 컴포넌트가 클라이언트에서만 렌더링된다"는 뜻이 아니라, "이 컴포넌트부터 아래로는 클라이언트 번들의 진입점(entry point)"이라는 뜻이다. Server Component에서 SSR로 프리렌더링된 후, 클라이언트에서 hydration된다.

---

## 참고 자료

- [React 공식 — Server Components](https://react.dev/reference/rsc/server-components)
- [Next.js 공식 — App Router](https://nextjs.org/docs/app)
- [Next.js 공식 — Caching](https://nextjs.org/docs/app/building-your-application/caching)
- [Next.js 공식 — Server Actions](https://nextjs.org/docs/app/building-your-application/data-fetching/server-actions-and-mutations)
- [Next.js 공식 — Partial Prerendering](https://nextjs.org/docs/app/building-your-application/rendering/partial-prerendering)
- [Dan Abramov — RSC from Scratch](https://github.com/reactwg/server-components/discussions/5)
- [Vercel Blog — Understanding React Server Components](https://vercel.com/blog/understanding-react-server-components)
- [Lee Robinson — Next.js App Router (YouTube)](https://www.youtube.com/watch?v=DrxiNfbr63s)
- [Josh Comeau — Making Sense of React Server Components](https://www.joshwcomeau.com/react/server-components/)
