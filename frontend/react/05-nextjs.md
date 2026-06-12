# 5. Next.js — 렌더링 방식과 App Router

## 목차
1. 렌더링 방식 비교 개요
2. CSR (Client-Side Rendering)
3. SSR (Server-Side Rendering)
4. SSG (Static Site Generation)
5. ISR (Incremental Static Regeneration)
6. Pages Router vs App Router
7. React Server Components
8. Client Components vs Server Components
9. Next.js 데이터 페칭 패턴
10. 면접 포인트

---

## 1. 렌더링 방식 비교 개요

| 방식 | 렌더링 시점 | HTML 생성 위치 | 데이터 최신성 |
|------|------------|----------------|--------------|
| CSR | 브라우저 요청 후 | 클라이언트 | 항상 최신 |
| SSR | 사용자 요청 시 | 서버 (매 요청) | 항상 최신 |
| SSG | 빌드 타임 | 서버 (1회) | 빌드 시점 기준 |
| ISR | 빌드 + 주기적 재생성 | 서버 | revalidate 주기 기준 |

---

## 2. CSR (Client-Side Rendering)

### 2.1 특징

- 서버는 빈 HTML과 JavaScript 번들만 전달
- 브라우저에서 JavaScript가 실행되며 DOM을 구성
- React의 기본 동작 방식 (Create React App 등)

### 2.2 장단점

**장점**
- 초기 로드 후 페이지 전환이 빠름 (SPA)
- 서버 부하가 낮음
- 인터랙티브한 앱 구성이 쉬움

**단점**
- 초기 로딩이 느림 (JavaScript 다운로드 + 실행 후에 콘텐츠 표시)
- SEO 불리 (크롤러가 빈 HTML을 읽음)
- 느린 기기/네트워크에서 FCP(First Contentful Paint) 저하

### 2.3 Next.js에서 CSR

```tsx
// app/dashboard/page.tsx (App Router)
'use client';

import { useState, useEffect } from 'react';

export default function Dashboard() {
  const [data, setData] = useState(null);

  useEffect(() => {
    fetch('/api/dashboard')
      .then(res => res.json())
      .then(setData);
  }, []);

  if (!data) return <div>로딩 중...</div>;
  return <div>{data.title}</div>;
}
```

---

## 3. SSR (Server-Side Rendering)

### 3.1 특징

- 사용자가 페이지를 요청할 때마다 서버에서 HTML을 생성
- 완성된 HTML을 클라이언트에 전달하므로 FCP가 빠름
- 항상 최신 데이터를 보여줄 수 있음

### 3.2 장단점

**장점**
- SEO 최적화 (완성된 HTML을 크롤러가 읽음)
- 항상 최신 데이터 제공
- 인증이 필요한 개인화 페이지에 적합

**단점**
- 매 요청마다 서버 연산 발생 → 서버 부하
- TTFB(Time To First Byte)가 SSG보다 느릴 수 있음
- 서버 인프라 필요

### 3.3 Pages Router: getServerSideProps

```tsx
// pages/profile/[id].tsx (Pages Router)
import { GetServerSideProps } from 'next';

interface Props {
  user: { name: string; email: string };
}

export default function ProfilePage({ user }: Props) {
  return (
    <div>
      <h1>{user.name}</h1>
      <p>{user.email}</p>
    </div>
  );
}

// 매 요청마다 실행됨
export const getServerSideProps: GetServerSideProps = async context => {
  const { id } = context.params!;
  const res = await fetch(`https://api.example.com/users/${id}`);

  if (!res.ok) {
    return { notFound: true };
  }

  const user = await res.json();
  return { props: { user } };
};
```

### 3.4 App Router: 기본이 SSR (Server Component)

```tsx
// app/profile/[id]/page.tsx (App Router)
interface Props {
  params: { id: string };
}

// async 서버 컴포넌트 = 기본적으로 SSR
export default async function ProfilePage({ params }: Props) {
  const res = await fetch(`https://api.example.com/users/${params.id}`, {
    cache: 'no-store', // 매 요청마다 새로 가져오기 (SSR)
  });
  const user = await res.json();

  return (
    <div>
      <h1>{user.name}</h1>
      <p>{user.email}</p>
    </div>
  );
}
```

---

## 4. SSG (Static Site Generation)

### 4.1 특징

- 빌드 타임에 HTML을 미리 생성하여 CDN에 배포
- 요청 시 미리 만들어진 HTML을 즉시 반환
- 빠른 응답 속도, 높은 확장성

### 4.2 장단점

**장점**
- 매우 빠른 응답 속도 (CDN에서 바로 서빙)
- 서버 부하 없음
- SEO 최적화

**단점**
- 데이터 최신성 보장 불가 (빌드 시점 데이터)
- 콘텐츠 변경 시 전체 재빌드 필요
- 동적 데이터(사용자별 맞춤 등)에 부적합

### 4.3 Pages Router: getStaticProps + getStaticPaths

```tsx
// pages/posts/[slug].tsx (Pages Router)
import { GetStaticProps, GetStaticPaths } from 'next';

export default function PostPage({ post }: { post: Post }) {
  return <article>{post.content}</article>;
}

// 빌드 타임에 어떤 경로를 생성할지 정의
export const getStaticPaths: GetStaticPaths = async () => {
  const posts = await fetchAllPosts();
  const paths = posts.map(post => ({ params: { slug: post.slug } }));

  return {
    paths,
    fallback: false, // 정의되지 않은 경로는 404
    // fallback: 'blocking' → 첫 요청 시 SSR로 생성 후 캐싱
    // fallback: true → 로딩 상태 표시 후 생성
  };
};

// 빌드 타임에 한 번 실행
export const getStaticProps: GetStaticProps = async context => {
  const { slug } = context.params!;
  const post = await fetchPost(slug as string);
  return { props: { post } };
};
```

### 4.4 App Router: 기본 fetch 캐싱 (SSG)

```tsx
// app/posts/[slug]/page.tsx (App Router)
export default async function PostPage({ params }: { params: { slug: string } }) {
  const post = await fetch(`https://api.example.com/posts/${params.slug}`, {
    cache: 'force-cache', // 기본값 - 빌드 시 캐싱 (SSG와 유사)
  }).then(res => res.json());

  return <article>{post.content}</article>;
}

// 정적으로 생성할 경로 명시
export async function generateStaticParams() {
  const posts = await fetch('https://api.example.com/posts').then(res => res.json());
  return posts.map((post: Post) => ({ slug: post.slug }));
}
```

---

## 5. ISR (Incremental Static Regeneration)

### 5.1 특징

- SSG의 빠른 응답 속도 + 주기적 데이터 갱신
- 백그라운드에서 페이지를 재생성하여 캐시를 업데이트
- 전체 재빌드 없이 특정 페이지만 갱신 가능

### 5.2 장단점

**장점**
- SSG의 속도 유지
- 콘텐츠 변경 시 전체 재빌드 불필요
- 수백만 페이지도 효율적으로 관리 가능

**단점**
- revalidate 기간 동안은 오래된 데이터를 서빙할 수 있음 (Stale-While-Revalidate)
- 실시간 데이터에는 부적합

### 5.3 Pages Router: revalidate

```tsx
// pages/products/[id].tsx (Pages Router)
export const getStaticProps: GetStaticProps = async context => {
  const product = await fetchProduct(context.params!.id as string);
  return {
    props: { product },
    revalidate: 60, // 60초마다 백그라운드 재생성
  };
};
```

### 5.4 App Router: next.revalidate

```tsx
// app/products/[id]/page.tsx (App Router)
export default async function ProductPage({ params }: { params: { id: string } }) {
  const product = await fetch(`https://api.example.com/products/${params.id}`, {
    next: { revalidate: 60 }, // 60초마다 재검증
  }).then(res => res.json());

  return <div>{product.name}</div>;
}
```

### 5.5 On-Demand ISR (필요할 때 즉시 재생성)

```tsx
// app/api/revalidate/route.ts
import { revalidatePath, revalidateTag } from 'next/cache';
import { NextRequest } from 'next/server';

export async function POST(request: NextRequest) {
  const { path, secret } = await request.json();

  if (secret !== process.env.REVALIDATE_SECRET) {
    return Response.json({ error: 'Invalid token' }, { status: 401 });
  }

  revalidatePath(path);           // 특정 경로 재검증
  // revalidateTag('products');   // 태그 기반 재검증

  return Response.json({ revalidated: true });
}
```

---

## 6. Pages Router vs App Router

### 6.1 Pages Router (Next.js 12 이하의 방식)

```
pages/
  index.tsx          → /
  about.tsx          → /about
  posts/[slug].tsx   → /posts/:slug
  api/
    users.ts         → /api/users
```

- 파일 기반 라우팅, `pages/` 디렉토리 사용
- 데이터 페칭: `getServerSideProps`, `getStaticProps`, `getStaticPaths`
- 레이아웃: `_app.tsx`, `_document.tsx`

### 6.2 App Router (Next.js 13+ 권장 방식)

```
app/
  layout.tsx          → 루트 레이아웃
  page.tsx            → /
  about/
    page.tsx          → /about
  posts/
    [slug]/
      page.tsx        → /posts/:slug
      loading.tsx     → 로딩 UI
      error.tsx       → 에러 UI
  api/
    users/
      route.ts        → /api/users
```

### 6.3 주요 차이점

| 항목 | Pages Router | App Router |
|------|-------------|------------|
| 기본 컴포넌트 | Client Component | Server Component |
| 데이터 페칭 | getServerSideProps 등 | async/await + fetch |
| 레이아웃 | `_app.tsx` (전역) | `layout.tsx` (중첩 가능) |
| 로딩 UI | 직접 구현 | `loading.tsx` 자동 처리 |
| 에러 처리 | 직접 구현 | `error.tsx` 자동 처리 |
| Streaming | 미지원 | Suspense 기반 지원 |
| Server Actions | 미지원 | 지원 (`'use server'`) |

---

## 7. React Server Components

### 7.1 개념

Server Components는 서버에서만 실행되는 컴포넌트다.
클라이언트로 JavaScript 번들이 전송되지 않으며, 데이터베이스/파일시스템에 직접 접근 가능하다.

```tsx
// app/posts/page.tsx — Server Component (기본값)
import { db } from '@/lib/db'; // 서버 전용 코드 사용 가능

export default async function PostsPage() {
  // 서버에서 직접 DB 접근 (API 라우트 불필요)
  const posts = await db.post.findMany({ orderBy: { createdAt: 'desc' } });

  return (
    <ul>
      {posts.map(post => (
        <li key={post.id}>{post.title}</li>
      ))}
    </ul>
  );
}
```

### 7.2 Server Components의 특징

- `useState`, `useEffect` 등 훅 사용 불가
- 브라우저 API (`window`, `document`) 사용 불가
- 이벤트 핸들러 사용 불가
- 서버 비밀 키(API Key, DB URL 등)를 안전하게 사용 가능
- 번들 크기에 포함되지 않음 (대형 라이브러리도 클라이언트에 전송 안 됨)

---

## 8. Client Components vs Server Components

### 8.1 선택 기준

| 필요한 기능 | 선택 |
|------------|------|
| useState, useEffect | Client Component |
| 브라우저 API (window, localStorage) | Client Component |
| 이벤트 핸들러 (onClick 등) | Client Component |
| DB, 파일시스템 직접 접근 | Server Component |
| 서버 전용 환경 변수 | Server Component |
| 번들 크기 최소화 | Server Component |
| SEO가 중요한 콘텐츠 | Server Component |

### 8.2 'use client' 지시어

```tsx
// app/components/LikeButton.tsx
'use client'; // 이 파일부터 하위는 Client Component

import { useState } from 'react';

export default function LikeButton({ initialCount }: { initialCount: number }) {
  const [count, setCount] = useState(initialCount);

  return (
    <button onClick={() => setCount(c => c + 1)}>
      좋아요 {count}
    </button>
  );
}
```

### 8.3 Server Component 내에 Client Component 포함

```tsx
// app/posts/[id]/page.tsx — Server Component
import LikeButton from '@/components/LikeButton'; // Client Component

export default async function PostPage({ params }: { params: { id: string } }) {
  // 서버에서 데이터 페칭
  const post = await fetchPost(params.id);

  return (
    <article>
      <h1>{post.title}</h1>
      <p>{post.content}</p>
      {/* Client Component를 Server Component 안에 포함 가능 */}
      <LikeButton initialCount={post.likeCount} />
    </article>
  );
}
```

### 8.4 Client Component에 Server Component 전달 (children 패턴)

```tsx
// Client Component (상태/인터랙션 담당)
'use client';
import { useState } from 'react';

export default function Accordion({ children }: { children: React.ReactNode }) {
  const [open, setOpen] = useState(false);
  return (
    <div>
      <button onClick={() => setOpen(o => !o)}>토글</button>
      {open && children}
    </div>
  );
}

// Server Component에서 사용
import Accordion from '@/components/Accordion';
import HeavyContent from '@/components/HeavyContent'; // Server Component

export default function Page() {
  return (
    <Accordion>
      {/* HeavyContent는 서버에서 렌더링됨 */}
      <HeavyContent />
    </Accordion>
  );
}
```

---

## 9. Next.js 데이터 페칭 패턴

### 9.1 fetch with 캐시 제어 (App Router)

```tsx
// SSG: 빌드 시 캐싱
const data = await fetch(url, { cache: 'force-cache' });

// SSR: 매 요청마다 새로 가져오기
const data = await fetch(url, { cache: 'no-store' });

// ISR: 60초마다 재검증
const data = await fetch(url, { next: { revalidate: 60 } });

// 태그 기반 재검증
const data = await fetch(url, { next: { tags: ['products'] } });
```

### 9.2 병렬 데이터 페칭

```tsx
// 순차 페칭 (느림)
const user = await fetchUser(id);
const posts = await fetchUserPosts(id); // user 완료 후 시작

// 병렬 페칭 (빠름)
const [user, posts] = await Promise.all([
  fetchUser(id),
  fetchUserPosts(id),
]);
```

### 9.3 Streaming with Suspense

```tsx
// app/dashboard/page.tsx
import { Suspense } from 'react';
import UserInfo from './UserInfo';
import RecentPosts from './RecentPosts';

export default function DashboardPage() {
  return (
    <div>
      {/* 각 컴포넌트가 독립적으로 스트리밍됨 */}
      <Suspense fallback={<UserInfoSkeleton />}>
        <UserInfo />
      </Suspense>
      <Suspense fallback={<PostsSkeleton />}>
        <RecentPosts />
      </Suspense>
    </div>
  );
}
```

### 9.4 Server Actions (폼 처리)

```tsx
// app/posts/new/page.tsx
export default function NewPostPage() {
  async function createPost(formData: FormData) {
    'use server'; // 이 함수는 서버에서 실행됨

    const title = formData.get('title') as string;
    await db.post.create({ data: { title } });
    redirect('/posts');
  }

  return (
    <form action={createPost}>
      <input name="title" />
      <button type="submit">작성</button>
    </form>
  );
}
```

---

## 10. 면접 포인트

### Q1. SSR과 SSG의 차이를 설명하고 각각 어떤 경우에 사용하나요?

**SSR**은 사용자 요청마다 서버에서 HTML을 생성합니다. 항상 최신 데이터가 필요하거나 사용자별 맞춤 콘텐츠(대시보드, 프로필)에 적합합니다.

**SSG**는 빌드 타임에 HTML을 미리 생성합니다. 마케팅 페이지, 블로그 포스트처럼 데이터 변경이 드물고 빠른 응답 속도가 중요한 경우에 적합합니다.

### Q2. ISR이란 무엇이고 어떻게 동작하나요?

ISR(Incremental Static Regeneration)은 SSG처럼 빌드 타임에 정적 페이지를 생성하되, `revalidate` 시간이 지난 후 다음 요청이 오면 백그라운드에서 페이지를 재생성합니다. 재생성이 완료되기 전까지는 이전 캐시를 서빙합니다(Stale-While-Revalidate). 실시간성이 필요하지 않지만 주기적 갱신이 필요한 이커머스 상품 페이지, 뉴스 등에 적합합니다.

### Q3. App Router에서 Server Component와 Client Component의 차이는?

**Server Component**는 서버에서만 실행되어 클라이언트 번들에 포함되지 않습니다. DB 직접 접근, 서버 API Key 사용이 가능하지만 useState/useEffect/이벤트 핸들러를 사용할 수 없습니다. App Router의 기본값입니다.

**Client Component**는 브라우저에서 실행되며 `'use client'` 지시어로 선언합니다. 상호작용(useState, 이벤트), 브라우저 API 사용이 가능합니다. 가능하면 트리의 말단(leaf)에 배치해 번들 크기를 최소화하는 것이 좋습니다.

### Q4. Next.js App Router에서 데이터를 SSR로 가져오려면?

`fetch`에 `cache: 'no-store'` 옵션을 사용하거나, `export const dynamic = 'force-dynamic'`을 페이지에 선언합니다. async 서버 컴포넌트에서 직접 `await fetch(...)` 하면 됩니다.

### Q5. Pages Router와 App Router 중 어떤 것을 선택하겠습니까?

신규 프로젝트라면 **App Router**를 선택합니다. React Server Components, Streaming, 중첩 레이아웃, Server Actions 등 최신 기능을 활용할 수 있고, Next.js 공식 권장 방향이기 때문입니다. 다만 레거시 프로젝트나 Pages Router에 익숙한 팀이라면 마이그레이션 비용을 고려해 점진적으로 전환합니다. 두 라우터는 Next.js 내에서 공존 가능합니다.
