# Edge Computing & Edge Runtime

> CDN 노드에서 코드를 실행하는 새로운 패러다임. Origin 서버까지 가지 않고 사용자 근처에서 로직을 처리한다.

---

## 개요

### Edge Computing이란?

전통적인 웹 아키텍처에서는 모든 요청이 Origin 서버(특정 리전에 위치)까지 왕복해야 했다.
Edge Computing은 이 패러다임을 뒤집는다: **CDN의 각 노드(PoP, Point of Presence)에서 직접 코드를 실행**한다.

```
[전통 방식]
사용자(서울) → CDN(정적 파일만) → Origin(미국 동부) → DB → 응답

[Edge 방식]
사용자(서울) → Edge 노드(서울) → 즉시 응답 (필요시만 Origin 호출)
```

### 왜 중요한가?

1. **Latency 감소**: 물리적 거리가 줄어 RTT(Round Trip Time)가 극적으로 감소
2. **Personalization**: 사용자 위치·디바이스·쿠키 기반으로 Origin 없이 개인화
3. **Cost 절감**: Origin 서버 부하 감소, 캐시 히트율 극대화
4. **Scalability**: 전 세계 수백 개 노드에서 자동 분산 처리

### 실제 수치 비교

| 시나리오 | 전통 (Origin: us-east-1) | Edge (서울 노드) |
|----------|--------------------------|-----------------|
| 서울 사용자 TTFB | ~200-400ms | ~5-20ms |
| 인증 검증 | Origin 왕복 필요 | Edge에서 즉시 |
| A/B 테스트 분기 | 클라이언트 JS or Origin | Edge에서 HTML 변환 |

---

## 핵심 개념

### 1. Edge Runtime vs Node.js Runtime

#### V8 Isolates (Cloudflare Workers 방식)

V8 엔진의 **Isolate**는 하나의 프로세스 안에서 독립된 실행 환경을 제공한다.
컨테이너나 VM을 띄우지 않기 때문에 콜드 스타트가 사실상 없다.

```
[기존 서버리스: 컨테이너 방식]
요청 → 컨테이너 생성(~100ms+) → Node.js 부팅 → 코드 실행 → 응답

[V8 Isolate 방식]
요청 → Isolate 생성(~5ms) → 코드 실행 → 응답
```

**V8 Isolate의 특징:**
- 마이크로초 단위 콜드 스타트 (실질적으로 0ms에 가까움)
- 메모리 격리: 각 Isolate는 독립된 힙을 가짐
- 경량: 하나의 프로세스에서 수천 개의 Isolate 동시 실행 가능
- 제한: Web API만 사용 가능 (fetch, crypto, TextEncoder 등)

#### Node.js 컨테이너 (Lambda 방식)

```
[장점]
- 완전한 Node.js API 접근 (fs, child_process, net 등)
- npm 패키지 대부분 사용 가능
- 기존 코드 마이그레이션 용이

[단점]
- 콜드 스타트 100ms ~ 수 초
- 리전 단위 배포 (전 세계 분산 아님)
- 컨테이너 관리 오버헤드
```

#### Edge에서 사용할 수 없는 것들

```typescript
// ❌ Edge Runtime에서 불가능한 것들
import fs from 'fs';              // 파일 시스템 없음
import { exec } from 'child_process'; // 프로세스 생성 불가
import net from 'net';            // TCP 소켓 불가
import crypto from 'crypto';      // Node.js crypto 대신 Web Crypto API 사용

// ✅ Edge Runtime에서 가능한 것들
const response = await fetch(url);           // Fetch API
const hash = await crypto.subtle.digest(...); // Web Crypto API
const encoded = new TextEncoder().encode(text);
const url = new URL(request.url);
```

#### WinterCG 표준

**WinterCG (Web-interoperable Runtimes Community Group)**는 서버 사이드 JavaScript 런타임 간의 상호운용성을 위한 표준이다.

- 참여: Cloudflare, Deno, Vercel, Node.js, Bloomberg
- 목표: 한 번 작성한 코드가 모든 Edge 런타임에서 동작
- 표준화 대상: `fetch`, `Request/Response`, `crypto.subtle`, `TextEncoder/Decoder`, `URL`, `Headers`

```typescript
// WinterCG 호환 코드 - 모든 Edge 런타임에서 동작
export default {
  async fetch(request: Request): Promise<Response> {
    const url = new URL(request.url);
    const headers = new Headers({ 'Content-Type': 'application/json' });
    
    return new Response(JSON.stringify({ path: url.pathname }), { headers });
  }
};
```

---

### 2. 주요 Edge 플랫폼

#### Vercel Edge Functions

- Next.js middleware의 기본 런타임
- V8 기반, 전 세계 분산
- Next.js와 자연스러운 통합

```typescript
// Next.js middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  // Vercel Edge Function으로 자동 배포
  return NextResponse.next();
}
```

#### Cloudflare Workers

- 가장 큰 Edge 네트워크 (전 세계 300+ 도시)
- 통합 생태계: D1(DB), KV(키-값), R2(오브젝트 스토리지), Queues
- Wrangler CLI로 개발·배포

```typescript
// Cloudflare Worker
export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const value = await env.MY_KV.get('key');
    return new Response(value);
  }
};
```

#### Deno Deploy

- Deno 런타임 기반, TypeScript 네이티브
- GitHub 연동 자동 배포
- Fresh 프레임워크와 통합

#### AWS Lambda@Edge / CloudFront Functions

- **Lambda@Edge**: Node.js/Python, CloudFront 이벤트에 연결, 리전 단위
- **CloudFront Functions**: JavaScript만, 더 가볍고 빠름, 진정한 Edge

#### Netlify Edge Functions

- Deno 런타임 기반
- Netlify 배포 파이프라인에 통합
- `netlify/edge-functions` 디렉토리 규약

#### 플랫폼 비교표

| 플랫폼 | 런타임 | 콜드스타트 | CPU 제한 | 메모리 | 무료 티어 |
|--------|--------|-----------|----------|--------|-----------|
| Cloudflare Workers | V8 Isolate | ~0ms | 50ms (무료) / 30s (유료) | 128MB | 100K req/day |
| Vercel Edge | V8 Isolate | ~0ms | 30s | 128MB | 100K req/month |
| Deno Deploy | V8 (Deno) | ~0ms | 50ms | 512MB | 100K req/day |
| Lambda@Edge | Node.js | 100ms+ | 30s | 128MB-10GB | 1M req/month |
| CloudFront Functions | JavaScript | ~0ms | 1ms | 2MB | 2M req/month |
| Netlify Edge | Deno | ~0ms | 50ms | 512MB | 제한적 |


---

### 3. Next.js에서 Edge Runtime

#### middleware.ts의 역할

Next.js middleware는 **모든 라우트 요청 전에 실행**되며, Edge Runtime에서 동작한다.

```typescript
// middleware.ts (프로젝트 루트)
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  // 1. Routing: 특정 조건에 따라 다른 페이지로 보내기
  if (request.nextUrl.pathname.startsWith('/old-blog')) {
    return NextResponse.redirect(new URL('/blog', request.url));
  }

  // 2. Rewrite: URL은 유지하되 다른 페이지 렌더링
  if (request.geo?.country === 'KR') {
    return NextResponse.rewrite(new URL('/kr' + request.nextUrl.pathname, request.url));
  }

  // 3. Headers 수정
  const response = NextResponse.next();
  response.headers.set('x-custom-header', 'edge-processed');
  return response;
}

// 특정 경로에만 middleware 적용
export const config = {
  matcher: ['/api/:path*', '/blog/:path*'],
};
```

#### Route Handler에서 Edge Runtime 사용

```typescript
// app/api/hello/route.ts
export const runtime = 'edge'; // Edge Runtime 사용 선언

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const name = searchParams.get('name') || 'World';
  
  return new Response(JSON.stringify({ message: `Hello, ${name}!` }), {
    headers: { 'Content-Type': 'application/json' },
  });
}
```

#### Edge에서 할 수 있는 것 / 없는 것

```typescript
// ✅ 가능
export const runtime = 'edge';

export async function GET() {
  // fetch로 외부 API 호출
  const data = await fetch('https://api.example.com/data');
  
  // Web Crypto API로 해싱
  const hash = await crypto.subtle.digest('SHA-256', new TextEncoder().encode('hello'));
  
  // Response 스트리밍
  const stream = new ReadableStream({ ... });
  return new Response(stream);
}

// ❌ 불가능 (빌드 타임에 에러)
import { readFile } from 'fs/promises';      // 파일 시스템
import { PrismaClient } from '@prisma/client'; // 대부분의 ORM (TCP 필요)
import sharp from 'sharp';                     // Native addon
```

#### Streaming Responses in Edge

```typescript
export const runtime = 'edge';

export async function GET() {
  const encoder = new TextEncoder();
  
  const stream = new ReadableStream({
    async start(controller) {
      for (let i = 0; i < 5; i++) {
        controller.enqueue(encoder.encode(`data: chunk ${i}\n\n`));
        await new Promise(resolve => setTimeout(resolve, 1000));
      }
      controller.close();
    },
  });

  return new Response(stream, {
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
    },
  });
}
```

---

### 4. Edge에서의 실전 패턴

#### A/B 테스트

Origin 서버 없이 Edge에서 사용자를 실험 그룹에 배정하고 다른 콘텐츠를 제공한다.

```typescript
// middleware.ts - A/B 테스트
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

const EXPERIMENT_COOKIE = 'ab-experiment-hero';

export function middleware(request: NextRequest) {
  // 이미 그룹 배정된 사용자는 유지
  const existingGroup = request.cookies.get(EXPERIMENT_COOKIE)?.value;
  
  if (existingGroup) {
    return NextResponse.rewrite(
      new URL(`/experiments/hero/${existingGroup}`, request.url)
    );
  }

  // 새 사용자: 50/50 랜덤 배정
  const group = Math.random() < 0.5 ? 'control' : 'variant';
  const response = NextResponse.rewrite(
    new URL(`/experiments/hero/${group}`, request.url)
  );
  
  // 쿠키로 그룹 고정 (30일)
  response.cookies.set(EXPERIMENT_COOKIE, group, {
    maxAge: 60 * 60 * 24 * 30,
    httpOnly: true,
  });

  return response;
}
```

#### 지오로케이션 기반 개인화

```typescript
// middleware.ts - 지역별 개인화
export function middleware(request: NextRequest) {
  const country = request.geo?.country || 'US';
  const city = request.geo?.city || 'Unknown';
  
  // 국가별 다른 가격 페이지
  if (request.nextUrl.pathname === '/pricing') {
    return NextResponse.rewrite(
      new URL(`/pricing/${country.toLowerCase()}`, request.url)
    );
  }

  // 응답 헤더에 위치 정보 추가 (클라이언트에서 활용)
  const response = NextResponse.next();
  response.headers.set('x-user-country', country);
  response.headers.set('x-user-city', city);
  return response;
}
```

#### 인증 검증 (JWT at Edge)

```typescript
// middleware.ts - JWT 검증
import { jwtVerify } from 'jose'; // Edge 호환 JWT 라이브러리

const JWT_SECRET = new TextEncoder().encode(process.env.JWT_SECRET);

export async function middleware(request: NextRequest) {
  // 공개 경로는 통과
  if (request.nextUrl.pathname.startsWith('/public')) {
    return NextResponse.next();
  }

  const token = request.cookies.get('auth-token')?.value;
  
  if (!token) {
    return NextResponse.redirect(new URL('/login', request.url));
  }

  try {
    const { payload } = await jwtVerify(token, JWT_SECRET);
    
    // 검증 성공: 사용자 정보를 헤더에 전달
    const response = NextResponse.next();
    response.headers.set('x-user-id', payload.sub as string);
    response.headers.set('x-user-role', payload.role as string);
    return response;
  } catch {
    // 토큰 만료 또는 유효하지 않음
    return NextResponse.redirect(new URL('/login', request.url));
  }
}
```

#### Bot Detection & Rate Limiting

```typescript
// middleware.ts - Rate Limiting (Vercel KV 활용)
import { kv } from '@vercel/kv';

export async function middleware(request: NextRequest) {
  const ip = request.ip || request.headers.get('x-forwarded-for') || 'unknown';
  const key = `rate-limit:${ip}`;
  
  const current = await kv.incr(key);
  
  if (current === 1) {
    await kv.expire(key, 60); // 1분 윈도우
  }
  
  if (current > 100) { // 분당 100회 제한
    return new NextResponse('Too Many Requests', {
      status: 429,
      headers: { 'Retry-After': '60' },
    });
  }

  return NextResponse.next();
}
```

#### Feature Flag 평가

```typescript
// middleware.ts - Feature Flag
export function middleware(request: NextRequest) {
  const userAgent = request.headers.get('user-agent') || '';
  const isMobile = /Mobile|Android/.test(userAgent);
  const country = request.geo?.country;

  // Feature Flag: 한국 모바일 사용자에게만 새 UI
  const showNewUI = country === 'KR' && isMobile;
  
  const response = NextResponse.next();
  response.headers.set('x-feature-new-ui', String(showNewUI));
  
  if (showNewUI && request.nextUrl.pathname === '/dashboard') {
    return NextResponse.rewrite(new URL('/dashboard-v2', request.url));
  }

  return response;
}
```


---

### 5. Edge Database / Storage

#### Cloudflare D1 (SQLite at Edge)

글로벌 분산 SQLite. 읽기는 Edge에서, 쓰기는 Primary로 전파.

```typescript
// Cloudflare Worker + D1
export default {
  async fetch(request: Request, env: Env) {
    const { results } = await env.DB.prepare(
      'SELECT * FROM posts WHERE published = ? ORDER BY created_at DESC LIMIT 10'
    ).bind(1).all();

    return Response.json(results);
  }
};
```

#### Turso (libSQL, 분산 SQLite)

```typescript
import { createClient } from '@libsql/client';

const db = createClient({
  url: process.env.TURSO_URL!,
  authToken: process.env.TURSO_AUTH_TOKEN,
});

// Edge Function에서 사용
export const runtime = 'edge';

export async function GET() {
  const result = await db.execute('SELECT * FROM users LIMIT 10');
  return Response.json(result.rows);
}
```

#### Vercel KV (Redis at Edge)

```typescript
import { kv } from '@vercel/kv';

export const runtime = 'edge';

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const key = searchParams.get('key')!;
  
  // Redis 명령어 그대로 사용
  const cached = await kv.get(key);
  if (cached) return Response.json(cached);

  const data = await fetchFromOrigin(key);
  await kv.set(key, data, { ex: 3600 }); // 1시간 TTL
  return Response.json(data);
}
```

#### 일관성 vs 지연시간 트레이드오프

```
[Strong Consistency]                    [Eventual Consistency]
← ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ →
높은 지연시간                                   낮은 지연시간
단일 리전 DB                                  글로벌 복제

[사용 사례별 선택]
- 결제/재고: Strong Consistency (Origin DB)
- 세션/캐시: Eventual Consistency (Edge KV)
- 게시글/댓글: Read-your-write Consistency (Edge + 복제)
```

---

## 실전 코드 예제

### Cloudflare Worker로 API 캐싱 프록시

```typescript
// Edge에서 API 응답을 캐싱하는 프록시
export default {
  async fetch(request: Request, env: Env, ctx: ExecutionContext) {
    const cacheKey = new Request(request.url, request);
    const cache = caches.default;

    // 1. 캐시 확인
    let response = await cache.match(cacheKey);
    if (response) {
      return new Response(response.body, {
        ...response,
        headers: { ...Object.fromEntries(response.headers), 'X-Cache': 'HIT' },
      });
    }

    // 2. Origin으로 요청
    response = await fetch(request);
    const responseClone = response.clone();

    // 3. 성공 응답만 캐싱 (백그라운드에서 비동기 처리)
    if (response.ok) {
      const cachedResponse = new Response(responseClone.body, {
        headers: {
          ...Object.fromEntries(response.headers),
          'Cache-Control': 'public, max-age=300', // 5분 캐시
        },
      });
      ctx.waitUntil(cache.put(cacheKey, cachedResponse));
    }

    return new Response(response.body, {
      ...response,
      headers: { ...Object.fromEntries(response.headers), 'X-Cache': 'MISS' },
    });
  },
};
```

### 지역별 콘텐츠 분기 (Cloudflare Worker)

```typescript
// 사용자 위치에 따라 다른 API 엔드포인트로 라우팅
export default {
  async fetch(request: Request) {
    const country = request.headers.get('CF-IPCountry') || 'US';
    
    // 지역별 Origin 서버 매핑
    const regionMap: Record<string, string> = {
      KR: 'https://api-apne2.example.com',  // 서울
      JP: 'https://api-apne1.example.com',  // 도쿄
      US: 'https://api-use1.example.com',   // 버지니아
      DE: 'https://api-euw1.example.com',   // 프랑크푸르트
    };

    const origin = regionMap[country] || regionMap['US'];
    const url = new URL(request.url);
    
    // 가장 가까운 Origin으로 프록시
    const response = await fetch(`${origin}${url.pathname}${url.search}`, {
      method: request.method,
      headers: request.headers,
      body: request.body,
    });

    return new Response(response.body, {
      status: response.status,
      headers: {
        ...Object.fromEntries(response.headers),
        'X-Served-From': country,
        'X-Origin': origin,
      },
    });
  },
};
```

---

## Edge vs Serverless vs Traditional Server

| 항목 | Edge | Serverless (Lambda) | Traditional Server |
|------|------|--------------------|--------------------|
| **콜드스타트** | ~0ms (V8 Isolate) | 100ms ~ 수 초 | N/A (항상 대기) |
| **실행 위치** | CDN 노드 (전 세계 300+) | 특정 리전 (1~3곳) | 고정 서버 |
| **런타임** | V8 Isolate / Web API | Node.js / Python 등 | Node.js / 풀스택 |
| **API 제한** | Web API만 | 거의 없음 | 없음 |
| **실행 시간** | ms 단위 제한 | 15분까지 | 무제한 |
| **스케일링** | 자동 (무제한) | 자동 (동시성 제한) | 수동 |
| **비용 모델** | 요청당 과금 | 실행 시간 과금 | 고정 서버 비용 |
| **적합한 작업** | 라우팅, 인증, 캐시 | API, 배치 처리 | 복잡한 비즈니스 로직 |
| **DB 접근** | Edge DB만 (HTTP 기반) | 모든 DB | 모든 DB |
| **디버깅** | 제한적 | 중간 | 자유로움 |

### 언제 무엇을 선택할까?

```
Edge를 선택:
  ✓ 전 세계 사용자 대상 낮은 latency 필요
  ✓ 라우팅/리다이렉트/A/B 테스트
  ✓ 인증 토큰 검증
  ✓ 캐시 로직, 헤더 조작
  ✓ 간단한 API 응답

Serverless를 선택:
  ✓ 복잡한 비즈니스 로직
  ✓ DB 트랜잭션 (RDS, DynamoDB 등)
  ✓ 파일 처리, 이미지 리사이징
  ✓ 외부 SDK 연동 (AWS SDK 등)

Traditional Server를 선택:
  ✓ WebSocket 상시 연결
  ✓ 긴 실행 시간의 배치 처리
  ✓ 상태 유지가 필요한 서비스
  ✓ GPU 연산 (ML 추론 등)
```

---

## 한계 & 주의사항

### 1. 실행 시간 제한

| 플랫폼 | CPU 시간 제한 | 벽시계(Wall-clock) 제한 |
|--------|-------------|----------------------|
| Cloudflare (무료) | 10ms | 제한 없음 (I/O 대기 제외) |
| Cloudflare (유료) | 30s | 제한 없음 |
| Vercel Edge | - | 30s |
| CloudFront Functions | 1ms | 1ms |

> **CPU 시간 vs Wall-clock 시간**: `fetch()` 대기 시간은 CPU 시간에 포함되지 않는다.
> 따라서 여러 외부 API를 호출해도 실제 CPU 제한에 걸리지 않을 수 있다.

### 2. 메모리 제한

- Cloudflare Workers: 128MB
- Vercel Edge: 128MB
- 대용량 JSON 파싱이나 이미지 처리에는 부적합

### 3. Node.js API 사용 불가

```typescript
// ❌ 이런 라이브러리들은 Edge에서 동작하지 않는다
// - bcrypt (native addon)
// - sharp (native addon)
// - prisma (TCP 소켓)
// - mongoose (TCP 소켓)
// - nodemailer (SMTP 연결)

// ✅ Edge 호환 대안
// - bcrypt → @noble/hashes 또는 Web Crypto API
// - prisma → Prisma Accelerate (HTTP proxy) 또는 Drizzle + D1
// - 이메일 → Resend API (HTTP 기반)
```

### 4. 디버깅 난이도

- 로컬 환경과 Edge 환경의 차이
- `console.log`가 실시간으로 보이지 않을 수 있음
- `wrangler dev` (Cloudflare), `next dev` (Vercel)로 로컬 시뮬레이션
- 분산 환경에서의 로그 수집 필요 (Logflare, Axiom 등)

### 5. 벤더 락인 위험

- 각 플랫폼 고유의 API (`env.KV`, `@vercel/kv` 등)
- WinterCG 표준 준수 코드를 작성하면 이식성 확보
- 비즈니스 로직은 플랫폼 독립적으로, 인프라 바인딩만 어댑터로 분리

---

## 면접 포인트

### Q1. Edge Runtime과 Node.js Runtime의 차이는?

> Edge Runtime은 V8 Isolate 기반으로 Web API만 사용 가능하며, 콜드 스타트가 사실상 없다.
> Node.js Runtime은 완전한 Node.js API를 제공하지만, 컨테이너 부팅으로 콜드 스타트가 발생한다.
> Edge는 전 세계 CDN 노드에서 실행되고, Node.js 서버리스는 특정 리전에서 실행된다.

### Q2. V8 Isolate란 무엇이고 왜 콜드스타트가 빠른가?

> V8 Isolate는 V8 엔진 내에서 독립된 힙과 실행 컨텍스트를 가진 경량 실행 단위다.
> 컨테이너/VM처럼 OS 레벨 격리가 아닌 프로세스 내 격리이므로,
> 새 Isolate 생성에 수 마이크로초만 소요된다.
> 하나의 프로세스에서 수천 개의 Isolate가 동시 실행 가능하다.

### Q3. Next.js middleware는 어디에서 실행되고 무엇을 할 수 있는가?

> Vercel 배포 시 Edge Runtime에서 실행된다. 모든 라우트 요청 전에 실행되며,
> redirect, rewrite, headers 수정, 쿠키 조작, 인증 검증이 가능하다.
> 단, DB 직접 접근, 파일 시스템, Node.js 전용 패키지는 사용할 수 없다.

### Q4. Edge에서 인증을 처리하는 장단점은?

> **장점**: Origin 왕복 없이 즉시 검증, latency 감소, Origin 부하 감소
> **단점**: 토큰 해독만 가능 (DB 조회로 세션 검증은 Edge DB 필요),
> 토큰 블랙리스트 관리가 어려움 (결국 Edge KV 필요),
> 시크릿 키 관리의 복잡성 증가

### Q5. Edge Database를 사용할 때의 일관성 문제는?

> Edge DB는 읽기 복제본이 전 세계에 분산되어 있어 **Eventual Consistency** 특성을 가진다.
> 쓰기 후 다른 리전에서 즉시 읽으면 이전 데이터가 보일 수 있다.
> 해결: Read-your-write consistency 패턴 (쓰기 후 Primary에서 읽기),
> 또는 캐시 무효화 전략, 낙관적 UI 업데이트 활용.

---

## 참고 자료

- [Cloudflare Workers 공식 문서](https://developers.cloudflare.com/workers/)
- [Vercel Edge Functions 문서](https://vercel.com/docs/functions/edge-functions)
- [Next.js Middleware 문서](https://nextjs.org/docs/app/building-your-application/routing/middleware)
- [WinterCG 공식](https://wintercg.org/)
- [V8 Isolates 설명 (Cloudflare 블로그)](https://blog.cloudflare.com/cloud-computing-without-containers/)
- [Turso 공식 문서](https://docs.turso.tech/)
- [Upstash 공식 문서](https://docs.upstash.com/)
- [Edge Runtime npm 패키지](https://edge-runtime.vercel.app/)
