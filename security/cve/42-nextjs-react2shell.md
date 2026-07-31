# CVE-2025-66478 — Next.js React2Shell

## 개요

| 항목 | 내용 |
|------|------|
| CVE ID | CVE-2025-66478 |
| CVSS | 9.8 (Critical) |
| 영향 소프트웨어 | Next.js (App Router) |
| 영향 버전 | Next.js 13.4.0 ~ 15.1.2, 14.0.0 ~ 14.2.24 |
| 수정 버전 | Next.js 15.1.3+, 14.2.25+ |
| 공격 유형 | Remote Code Execution (RCE) |
| 발견일 | 2025-12-03 |
| 공개 주체 | Vercel Security Team |

## 영향 범위 & 심각성

### CVE-2025-55182와의 관계

이 CVE는 React2Shell(CVE-2025-55182)의 **Next.js 프레임워크 측 취약점**이다. React 코어의 Flight 프로토콜 역직렬화 취약점이 근본 원인이지만, Next.js의 App Router가 Server Functions 엔드포인트를 라우팅하고 처리하는 과정에서 추가적인 공격 표면이 존재한다.

### 영향받는 범위

- **Next.js App Router를 사용하는 모든 프로젝트**
- Pages Router만 사용하는 프로젝트는 영향 없음
- `app/` 디렉토리 내 `"use server"` 지시문이 있는 파일이 하나라도 있으면 영향

### 실제 피해 규모

- Vercel 플랫폼에서만 약 30만 개의 프로덕션 배포가 영향권
- npm 주간 다운로드 기준 next 패키지는 주 500만+ 다운로드
- 공개 직후 48시간 내 Vercel은 자동 패치를 배포했으나, 셀프호스팅 환경은 수동 업데이트 필요

### CVE-2024-34351(20번)과의 차이점

| 비교 항목 | CVE-2024-34351 | CVE-2025-66478 |
|-----------|---------------|----------------|
| 취약점 유형 | SSRF (Host header injection) | RCE (Deserialization) |
| CVSS | 7.5 | 9.8 |
| 공격 결과 | 내부 네트워크 요청 위조 | 서버 임의 코드 실행 |
| 공격 표면 | Server Actions redirect | Server Functions Flight payload |
| 영향 범위 | 특정 redirect 패턴 사용 시 | RSC 사용하는 모든 앱 |
| 인증 필요 | 불필요 | 불필요 |
| 복잡도 | 중간 (Host header 조작) | 낮음 (단일 POST) |

CVE-2024-34351은 서버 사이드에서 redirect를 처리할 때 Host 헤더를 검증하지 않아 SSRF가 가능했던 취약점이었다. CVE-2025-66478은 그보다 훨씬 심각한 **완전한 RCE**다.

## 취약점 기술 분석

### Next.js App Router의 Server Function 처리 흐름

```
클라이언트 → HTTP POST (Flight payload)
    ↓
Next.js 라우터 (/__next_action__ 엔드포인트)
    ↓
Action ID 기반 함수 매핑
    ↓
React decodeReply() 호출 ← 여기서 RCE 발생
    ↓
Server Function 실행
```

### Next.js 고유의 추가 공격 표면

1. **Action ID 예측 가능성**: Next.js는 Server Function에 해시 기반 ID를 부여하지만, 빌드 시 결정론적으로 생성되어 앱 소스가 공개된 경우 예측 가능
2. **라우트 그룹 바이패스**: `(auth)` 같은 라우트 그룹의 layout 기반 인증을 우회하여 Server Function에 직접 접근 가능
3. **Edge Runtime 영향**: Edge Runtime에서도 동일하게 취약 (Cloudflare Workers, Vercel Edge 등)

```typescript
// 이 구조에서 layout의 인증 체크를 우회하여 action에 직접 접근 가능
// app/(auth)/dashboard/actions.ts
"use server";
export async function deleteUser(id: string) {
  // layout.tsx의 auth check를 거치지 않고 직접 호출 가능
  await db.user.delete({ where: { id } });
}
```

## 공격 시나리오

### Next.js 특화 공격 벡터

```bash
# 1. 타깃 앱의 빌드 매니페스트에서 Action ID 추출
curl https://target.com/_next/static/chunks/app/page.js | grep -o '"[a-f0-9]\{40\}"'

# 2. 추출된 Action ID로 조작된 Flight payload 전송
curl -X POST https://target.com \
  -H "Content-Type: text/x-component" \
  -H "Next-Action: <extracted-action-id>" \
  --data-binary @malicious-flight-payload.bin
```

### Edge Runtime에서의 공격

Edge Runtime 환경에서는 Node.js의 `child_process`를 사용할 수 없지만, 다음과 같은 공격이 가능:

- 환경변수(`process.env`) 전체 탈취
- `fetch()`를 이용한 내부 API 호출
- 데이터베이스 연결 문자열 탈취 후 직접 DB 접근

## 방어 방법

### 1. 즉시 업데이트

```bash
# Next.js 15.x 사용 시
npm install next@15.1.3

# Next.js 14.x 사용 시 (LTS)
npm install next@14.2.25

# React도 함께 업데이트
npm install react@19.1.0 react-dom@19.1.0
```

### 2. Next.js Middleware에서의 추가 방어

```typescript
// middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

const ALLOWED_ORIGINS = [
  'https://your-domain.com',
  'https://www.your-domain.com',
];

export function middleware(request: NextRequest) {
  // Server Action 요청 감지
  const isServerAction = request.headers.has('next-action');
  
  if (isServerAction) {
    // Origin 검증 — CSRF 방어와 외부 공격 차단
    const origin = request.headers.get('origin');
    if (!origin || !ALLOWED_ORIGINS.includes(origin)) {
      return new NextResponse('Forbidden', { status: 403 });
    }

    // Content-Length 제한
    const contentLength = parseInt(request.headers.get('content-length') || '0');
    if (contentLength > 1024 * 50) { // 50KB 제한
      return new NextResponse('Payload Too Large', { status: 413 });
    }

    // Action ID 형식 검증
    const actionId = request.headers.get('next-action');
    if (actionId && !/^[a-f0-9]{40}$/.test(actionId)) {
      return new NextResponse('Invalid Action', { status: 400 });
    }
  }

  return NextResponse.next();
}
```

### 3. next.config.js 보안 설정

```javascript
// next.config.js
/** @type {import('next').NextConfig} */
const nextConfig = {
  // Server Actions에 대한 크기 제한
  experimental: {
    serverActions: {
      bodySizeLimit: '1mb',
      allowedOrigins: ['your-domain.com'],
    },
  },
  // 보안 헤더
  headers: async () => [{
    source: '/:path*',
    headers: [
      { key: 'X-Content-Type-Options', value: 'nosniff' },
      { key: 'X-Frame-Options', value: 'DENY' },
    ],
  }],
};

module.exports = nextConfig;
```

### 4. Vercel 배포 시 자동 방어

Vercel은 2025-12-04부터 모든 배포에 대해 자동으로 Flight payload 검증 룰을 적용했다. 셀프호스팅 환경에서는 수동으로 업데이트해야 한다.

## 교훈

### 1. Server Functions는 API 엔드포인트다

`"use server"`로 선언된 함수는 본질적으로 **공개 API 엔드포인트**다. layout 기반 인증에만 의존하면 안 되며, 각 Server Function 내부에서 독립적으로 인증/인가를 검증해야 한다.

### 2. 프레임워크 레벨의 보안 vs 앱 레벨의 보안

Next.js가 기본 제공하는 보안(CSRF 토큰, Origin 검증)만으로는 불충분할 수 있다. 앱 개발자도 추가 방어 계층을 구축해야 한다.

### 3. 셀프호스팅의 위험

Vercel 같은 매니지드 플랫폼은 자동 패치가 가능하지만, Docker/PM2 등으로 셀프호스팅하는 환경은 수동 대응이 필요하다. 셀프호스팅 시 보안 패치 자동화 파이프라인이 필수다.

### 4. Action ID의 비밀성에 의존하지 말 것

Server Function의 Action ID는 빌드 아티팩트에서 추출 가능하므로, "ID를 모르면 호출 못한다"는 security through obscurity에 의존하면 안 된다.

## 참고 자료

- [Next.js Security Advisory — CVE-2025-66478](https://github.com/vercel/next.js/security/advisories/GHSA-nextjs-react2shell)
- [Vercel Blog — Patching React2Shell in Next.js](https://vercel.com/blog/security/nextjs-react2shell-patch)
- [NIST NVD — CVE-2025-66478](https://nvd.nist.gov/vuln/detail/CVE-2025-66478)
- [Next.js Server Actions Security Best Practices](https://nextjs.org/docs/app/building-your-application/data-fetching/server-actions-and-mutations#security)
- [CVE-2024-34351 비교 분석 (본 레포 20번 문서)](./20-nextjs-ssrf.md)
