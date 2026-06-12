# 10. Next.js 심화

## 목차
1. Parallel Routes
2. Intercepting Routes
3. Edge Runtime vs Node.js Runtime
4. Image 최적화 (next/image)
5. Font 최적화 (next/font)
6. Script 최적화 (next/script)
7. Metadata API
8. 면접 포인트

---

## 1. Parallel Routes

### 1.1 개념

Parallel Routes는 같은 레이아웃 내에서 여러 페이지를 동시에 렌더링할 수 있는 기능이다.
`@폴더명` 슬롯(slot) 방식으로 정의하며, 각 슬롯은 독립적인 로딩/에러 처리가 가능하다.

### 1.2 디렉토리 구조

```
app/
  layout.tsx           ← children + @team + @analytics를 받음
  page.tsx
  @team/
    page.tsx           → /team 슬롯
    loading.tsx
    error.tsx
  @analytics/
    page.tsx           → /analytics 슬롯
    loading.tsx
```

### 1.3 레이아웃에서 슬롯 사용

```tsx
// app/layout.tsx
export default function RootLayout({
  children,
  team,
  analytics,
}: {
  children: React.ReactNode;
  team: React.ReactNode;
  analytics: React.ReactNode;
}) {
  return (
    <html>
      <body>
        <main>{children}</main>
        <aside>
          {team}
          {analytics}
        </aside>
      </body>
    </html>
  );
}
```

### 1.4 조건부 슬롯 렌더링

```tsx
// app/layout.tsx — 로그인 여부에 따라 다른 슬롯
import { auth } from '@/auth';

export default async function Layout({
  children,
  dashboard,
  login,
}: {
  children: React.ReactNode;
  dashboard: React.ReactNode;
  login: React.ReactNode;
}) {
  const session = await auth();

  return (
    <div>
      {children}
      {session ? dashboard : login}
    </div>
  );
}
```

### 1.5 default.tsx — 슬롯 기본값

라우트 탐색 시 매칭되지 않는 슬롯은 `default.tsx`를 렌더링한다.

```tsx
// app/@team/default.tsx
export default function TeamDefault() {
  return null; // 기본값: 아무것도 렌더링하지 않음
}
```

---

## 2. Intercepting Routes

### 2.1 개념

Intercepting Routes는 현재 레이아웃 내에서 다른 라우트의 콘텐츠를 인터셉트하여 표시하는 기능이다.
대표적인 사용 사례는 **모달**이다. 목록 페이지에서 항목 클릭 시 모달로 표시하고, URL을 직접 접근하면 전체 페이지로 표시한다.

### 2.2 컨벤션

| 컨벤션 | 의미 |
|--------|------|
| `(.)폴더` | 같은 수준의 세그먼트 인터셉트 |
| `(..)폴더` | 한 수준 위 세그먼트 인터셉트 |
| `(..)(..)폴더` | 두 수준 위 |
| `(...)폴더` | 루트에서 인터셉트 |

### 2.3 예제 — 사진 모달

```
app/
  layout.tsx
  @modal/
    (.)photos/[id]/
      page.tsx        ← 모달로 보여줄 버전
    default.tsx       ← null 반환
  photos/
    page.tsx          ← 목록 페이지
    [id]/
      page.tsx        ← 전체 페이지 버전
```

```tsx
// app/@modal/(.)photos/[id]/page.tsx
import { Modal } from '@/components/Modal';

export default async function PhotoModal({ params }: { params: { id: string } }) {
  const photo = await fetchPhoto(params.id);

  return (
    <Modal>
      <img src={photo.url} alt={photo.title} />
      <h2>{photo.title}</h2>
    </Modal>
  );
}
```

```tsx
// app/layout.tsx
export default function RootLayout({
  children,
  modal,
}: {
  children: React.ReactNode;
  modal: React.ReactNode;
}) {
  return (
    <html>
      <body>
        {children}
        {modal}  {/* 모달 슬롯 — 목록에서 클릭 시 여기에 렌더 */}
      </body>
    </html>
  );
}
```

```tsx
// app/photos/page.tsx
import Link from 'next/link';

export default async function PhotosPage() {
  const photos = await fetchPhotos();

  return (
    <div className="grid">
      {photos.map(photo => (
        // Link 클릭 → 인터셉트 → 모달 표시
        // URL 직접 접근 → 전체 페이지 표시
        <Link key={photo.id} href={`/photos/${photo.id}`}>
          <img src={photo.thumbnailUrl} alt={photo.title} />
        </Link>
      ))}
    </div>
  );
}
```

---

## 3. Edge Runtime vs Node.js Runtime

### 3.1 개념

Next.js는 각 라우트 세그먼트 또는 Route Handler가 실행될 런타임을 선택할 수 있다.

| 항목 | Edge Runtime | Node.js Runtime |
|------|-------------|----------------|
| 실행 환경 | V8 + Web APIs | Node.js |
| Cold Start | 매우 빠름 | 느림 |
| 번들 크기 제한 | 1MB | 없음 |
| Node.js API | 사용 불가 | 사용 가능 |
| 가격 | 저렴 (Vercel) | 상대적으로 비쌈 |
| 사용 사례 | 미들웨어, 간단한 API | DB 접근, 파일 시스템 |

### 3.2 런타임 선택

```tsx
// Route Handler에서 런타임 지정
// app/api/hello/route.ts
export const runtime = 'edge'; // 또는 'nodejs' (기본값)

export async function GET() {
  return new Response('Hello from Edge!');
}
```

```tsx
// 페이지에서 런타임 지정
// app/dashboard/page.tsx
export const runtime = 'edge';

export default function DashboardPage() {
  return <div>Edge에서 렌더링</div>;
}
```

### 3.3 Edge Runtime 제약

```ts
// Edge Runtime에서 사용 불가
import fs from 'fs';           // Node.js 전용 모듈
import { createConnection } from 'net';

// Edge Runtime에서 사용 가능
fetch, Request, Response, URL  // Web API
crypto.randomUUID()            // Web Crypto API
```

---

## 4. Image 최적화 (next/image)

### 4.1 기본 사용

```tsx
import Image from 'next/image';

// 로컬 이미지 — 자동으로 width/height 파악
import profilePic from '@/public/profile.jpg';

export default function Profile() {
  return (
    <Image
      src={profilePic}
      alt="프로필 사진"
      placeholder="blur"       // 로딩 중 blur 효과
    />
  );
}

// 외부 이미지 — width/height 필수
<Image
  src="https://example.com/photo.jpg"
  alt="외부 이미지"
  width={800}
  height={600}
  sizes="(max-width: 768px) 100vw, 50vw"
/>
```

### 4.2 fill 레이아웃

```tsx
// 부모 크기를 채우는 이미지
<div style={{ position: 'relative', height: '400px' }}>
  <Image
    src="/hero.jpg"
    alt="히어로 이미지"
    fill
    style={{ objectFit: 'cover' }}
    priority    // LCP 이미지는 priority 설정 (preload)
    sizes="100vw"
  />
</div>
```

### 4.3 next.config.js 도메인 설정

```js
// next.config.js
module.exports = {
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'example.com',
        pathname: '/images/**',
      },
      {
        hostname: '**.githubusercontent.com',
      },
    ],
    formats: ['image/avif', 'image/webp'],  // 브라우저 지원에 따라 자동 변환
  },
};
```

---

## 5. Font 최적화 (next/font)

### 5.1 Google Fonts

```tsx
// app/layout.tsx
import { Inter, Noto_Sans_KR } from 'next/font/google';

const inter = Inter({
  subsets: ['latin'],
  variable: '--font-inter',
  display: 'swap',
});

const notoSansKR = Noto_Sans_KR({
  subsets: ['latin'],
  weight: ['400', '500', '700'],
  variable: '--font-noto-sans-kr',
});

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="ko" className={`${inter.variable} ${notoSansKR.variable}`}>
      <body>{children}</body>
    </html>
  );
}
```

```css
/* globals.css */
body {
  font-family: var(--font-noto-sans-kr), var(--font-inter), sans-serif;
}
```

### 5.2 로컬 폰트

```tsx
import localFont from 'next/font/local';

const pretendard = localFont({
  src: [
    { path: '../public/fonts/Pretendard-Regular.woff2', weight: '400' },
    { path: '../public/fonts/Pretendard-Bold.woff2', weight: '700' },
  ],
  variable: '--font-pretendard',
  display: 'swap',
});
```

---

## 6. Script 최적화 (next/script)

```tsx
import Script from 'next/script';

// afterInteractive: 페이지 인터랙티브 후 로드 (기본값, GA 등)
<Script
  src="https://www.googletagmanager.com/gtag/js?id=GA_ID"
  strategy="afterInteractive"
/>

// lazyOnload: 유휴 시간에 로드 (채팅 위젯 등 낮은 우선순위)
<Script src="https://chat-widget.example.com/widget.js" strategy="lazyOnload" />

// beforeInteractive: 가장 먼저 로드 (polyfill 등)
<Script src="https://polyfill.io/v3/polyfill.min.js" strategy="beforeInteractive" />

// onLoad 콜백
<Script
  src="https://maps.googleapis.com/maps/api/js"
  strategy="afterInteractive"
  onLoad={() => {
    initMap();
  }}
/>
```

---

## 7. Metadata API

### 7.1 정적 메타데이터

```tsx
// app/layout.tsx 또는 app/page.tsx
import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: {
    template: '%s | My App',  // 각 페이지 title 뒤에 붙는 접미사
    default: 'My App',
  },
  description: '서비스 소개',
  keywords: ['Next.js', 'React'],
  authors: [{ name: '홍길동' }],
  openGraph: {
    title: 'My App',
    description: 'OG 설명',
    url: 'https://myapp.com',
    siteName: 'My App',
    images: [{ url: 'https://myapp.com/og.png', width: 1200, height: 630 }],
    type: 'website',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'My App',
    description: 'Twitter 설명',
    images: ['https://myapp.com/og.png'],
  },
  robots: {
    index: true,
    follow: true,
  },
};
```

### 7.2 동적 메타데이터

```tsx
// app/posts/[slug]/page.tsx
import type { Metadata } from 'next';

interface Props {
  params: { slug: string };
}

// generateMetadata는 서버에서 실행되며, 페이지와 동일한 data fetching을 공유
export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const post = await fetchPost(params.slug);

  if (!post) {
    return { title: '포스트를 찾을 수 없습니다' };
  }

  return {
    title: post.title,
    description: post.excerpt,
    openGraph: {
      title: post.title,
      description: post.excerpt,
      images: [{ url: post.coverImage }],
      type: 'article',
      publishedTime: post.createdAt,
    },
  };
}

export default async function PostPage({ params }: Props) {
  const post = await fetchPost(params.slug);
  return <article>{post.content}</article>;
}
```

### 7.3 파일 기반 메타데이터

```
app/
  icon.png          → favicon
  apple-icon.png    → Apple touch icon
  opengraph-image.png  → OG 이미지 (정적)
  opengraph-image.tsx  → OG 이미지 (동적 생성)
  sitemap.ts        → sitemap.xml 자동 생성
  robots.ts         → robots.txt 자동 생성
```

```ts
// app/sitemap.ts
import { MetadataRoute } from 'next';

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const posts = await fetchAllPosts();

  return [
    { url: 'https://myapp.com', lastModified: new Date() },
    ...posts.map(post => ({
      url: `https://myapp.com/posts/${post.slug}`,
      lastModified: new Date(post.updatedAt),
    })),
  ];
}
```

---

## 8. 면접 포인트

### Q1. Parallel Routes를 사용하는 이유는?

같은 URL에서 여러 독립적인 콘텐츠 영역을 렌더링하고 각 영역마다 독립적인 로딩/에러 처리를 할 수 있습니다. 대시보드처럼 여러 데이터 소스를 병렬로 표시하거나, 로그인 여부에 따라 조건부로 다른 UI 슬롯을 보여줄 때 유용합니다.

### Q2. Intercepting Routes가 모달 구현에 적합한 이유는?

목록 페이지에서 아이템을 클릭하면 모달로 보여주되, URL을 직접 접근하면 전체 페이지로 보여주는 UX를 자연스럽게 구현할 수 있습니다. 공유 가능한 URL을 유지하면서, 현재 맥락에서는 화면 전환 없이 모달로 표시할 수 있어 사용자 경험이 향상됩니다.

### Q3. Edge Runtime을 언제 선택하나요?

미들웨어, 지역화 리다이렉트, 간단한 API처럼 빠른 응답이 중요하고 Node.js 전용 API가 필요 없는 경우에 선택합니다. Cold Start가 거의 없어 지연 시간이 매우 낮습니다. 반면 DB 연결, 파일 시스템 접근, 대형 npm 패키지가 필요한 경우는 Node.js Runtime을 사용해야 합니다.

### Q4. next/image를 사용하면 얻는 최적화는?

자동 WebP/AVIF 변환, 뷰포트에 따른 sizes 속성 기반 반응형 이미지 제공, lazy loading 기본 적용, blur placeholder, 레이아웃 시프트(CLS) 방지를 위한 크기 예약이 자동으로 처리됩니다. `priority` prop을 LCP 이미지에 설정하면 preload 링크가 자동 삽입됩니다.

### Q5. Metadata API에서 generateMetadata와 정적 metadata의 차이는?

`metadata` 객체는 빌드 타임에 결정되는 정적 메타데이터입니다. `generateMetadata` 함수는 async 함수로, 동적 라우트의 파라미터나 외부 데이터를 기반으로 메타데이터를 생성합니다. Next.js는 같은 라우트에서 `generateMetadata`와 페이지 컴포넌트가 동일한 데이터를 fetch할 경우 자동으로 요청을 중복 제거합니다.
