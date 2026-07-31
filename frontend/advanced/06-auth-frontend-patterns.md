# 인증/인가 프론트엔드 구현 패턴

## 개요

`cs/web-auth/`에서 JWT, OAuth, 세션 기반 인증의 **이론**을 다뤘다면, 이 문서에서는 프론트엔드에서 **실제로 어떻게 구현하는지**에 집중한다.

다루는 범위:
- 토큰 저장 위치와 보안 트레이드오프
- Silent Refresh (자동 갱신) 구현
- 로그인/로그아웃 전체 플로우
- 권한 기반 접근 제어 (Route Guard, 컴포넌트 레벨)
- 실전 코드 예제 (Axios Interceptor, Next.js, React Hook)

---

## 토큰 관리 전략

### Access Token + Refresh Token 패턴

| 구분 | Access Token (AT) | Refresh Token (RT) |
|------|-------------------|---------------------|
| 수명 | 짧음 (15분) | 김 (7일~30일) |
| 용도 | API 요청 시 `Authorization: Bearer <AT>` | AT 만료 시 새 AT 발급 |
| 저장 | 메모리 (변수/closure) | httpOnly cookie |
| 탈취 위험 | 짧은 수명으로 피해 최소화 | httpOnly로 JS 접근 차단 |

**왜 둘로 나누는가?**

- AT만 사용: 수명을 길게 → 탈취 시 오래 악용됨
- AT만 사용: 수명을 짧게 → 매번 로그인 필요 (UX 최악)
- AT + RT: AT는 짧게(보안), RT로 자동 갱신(UX) → **보안과 UX의 균형**

### 토큰 저장 위치 비교

| 저장 위치 | XSS 공격 | CSRF 공격 | 접근성 | 새로고침 유지 |
|-----------|----------|-----------|--------|---------------|
| localStorage | ❌ 취약 (JS로 읽기 가능) | ✅ 안전 | JS 접근 가능 | ✅ 유지 |
| sessionStorage | ❌ 취약 | ✅ 안전 | JS 접근 가능 | ❌ 탭 닫으면 소멸 |
| httpOnly cookie | ✅ 안전 (JS 접근 불가) | ❌ 취약 (SameSite로 완화) | JS 접근 불가 | ✅ 유지 |
| 메모리 (변수) | ✅ 안전 | ✅ 안전 | JS 접근 가능 | ❌ 새로고침 시 소멸 |

### 권장 패턴 (Best Practice)

```
┌─────────────────────────────────────────────────┐
│  Access Token  → 메모리 (전역 변수 또는 closure)    │
│  Refresh Token → httpOnly + Secure + SameSite   │
│  새로고침 시   → /api/refresh 호출 → 새 AT 발급   │
└─────────────────────────────────────────────────┘
```

- **AT를 메모리에 저장하는 이유**: XSS로 탈취 불가, CSRF와도 무관
- **RT를 httpOnly cookie에 저장하는 이유**: JS로 접근 불가(XSS 방어), 새로고침에도 유지
- **cookie 옵션**: `Secure`(HTTPS만), `SameSite=Strict`(CSRF 완화), `Path=/api/refresh`(최소 노출)

---

## 토큰 갱신 로직 (Silent Refresh)

### 핵심 개념

사용자가 인지하지 못하게(silent) AT를 자동으로 갱신하는 메커니즘.

```
[클라이언트]                    [서버]
    │                             │
    ├─ API 요청 (만료된 AT) ─────→│
    │←──── 401 Unauthorized ──────┤
    │                             │
    ├─ /api/refresh (RT cookie) ──→│
    │←──── 새 AT 발급 ────────────┤
    │                             │
    ├─ 원래 API 재요청 (새 AT) ───→│
    │←──── 200 OK ────────────────┤
```

### Axios Interceptor 패턴

핵심 포인트:
1. **401 응답 감지** → refresh 요청 → 원래 요청 재시도
2. **동시 다발 요청 처리** → 큐에 대기시킨 후 일괄 재시도
3. **Refresh도 실패 시** → 로그아웃 처리

```typescript
// auth/tokenManager.ts
let accessToken: string | null = null;

export const getAccessToken = () => accessToken;
export const setAccessToken = (token: string | null) => {
  accessToken = token;
};
```

```typescript
// api/axiosInstance.ts
import axios, { AxiosRequestConfig, InternalAxiosRequestConfig } from 'axios';
import { getAccessToken, setAccessToken } from '../auth/tokenManager';

const api = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL,
  withCredentials: true, // cookie 전송을 위해 필수
});

// 요청 인터셉터: AT 자동 첨부
api.interceptors.request.use((config: InternalAxiosRequestConfig) => {
  const token = getAccessToken();
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// 응답 인터셉터: 401 시 자동 갱신
let isRefreshing = false;
let failedQueue: Array<{
  resolve: (token: string) => void;
  reject: (error: unknown) => void;
}> = [];

const processQueue = (error: unknown, token: string | null = null) => {
  failedQueue.forEach(({ resolve, reject }) => {
    if (error) {
      reject(error);
    } else {
      resolve(token!);
    }
  });
  failedQueue = [];
};

api.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config as InternalAxiosRequestConfig & {
      _retry?: boolean;
    };

    // 401이 아니거나, 이미 재시도한 요청이면 그대로 에러 전파
    if (error.response?.status !== 401 || originalRequest._retry) {
      return Promise.reject(error);
    }

    // 이미 refresh 진행 중이면 큐에 대기
    if (isRefreshing) {
      return new Promise<string>((resolve, reject) => {
        failedQueue.push({ resolve, reject });
      }).then((token) => {
        originalRequest.headers.Authorization = `Bearer ${token}`;
        return api(originalRequest);
      });
    }

    originalRequest._retry = true;
    isRefreshing = true;

    try {
      // refresh 요청 (RT는 cookie로 자동 전송)
      const { data } = await axios.post(
        `${process.env.NEXT_PUBLIC_API_URL}/api/refresh`,
        {},
        { withCredentials: true }
      );

      const newToken = data.accessToken;
      setAccessToken(newToken);
      processQueue(null, newToken);

      originalRequest.headers.Authorization = `Bearer ${newToken}`;
      return api(originalRequest);
    } catch (refreshError) {
      processQueue(refreshError, null);
      // refresh 실패 → 로그아웃
      setAccessToken(null);
      window.location.href = '/login';
      return Promise.reject(refreshError);
    } finally {
      isRefreshing = false;
    }
  }
);

export default api;
```

### Token Rotation

일반적인 Refresh Token은 고정값이지만, **Rotation** 방식에서는:

1. Refresh 요청 시 **새 RT도 함께 발급** (기존 RT 무효화)
2. 만약 이미 무효화된 RT로 요청이 오면 → **탈취 감지**
3. 해당 사용자의 **모든 RT를 무효화** (전체 세션 종료)

```
정상 흐름:
  RT_v1 → 서버 → AT_new + RT_v2 발급, RT_v1 무효화

탈취 시나리오:
  공격자: RT_v1 사용 → 서버: "이미 사용된 RT" 감지 → 전체 무효화
  사용자: RT_v2 사용 → 서버: "무효화됨" → 재로그인 필요
```

---

## 로그인/로그아웃 플로우

### 로그인 (이메일/비밀번호)

```typescript
// hooks/useAuth.ts
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { setAccessToken } from '../auth/tokenManager';
import api from '../api/axiosInstance';

interface LoginCredentials {
  email: string;
  password: string;
}

export function useLogin() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (credentials: LoginCredentials) => {
      // 1. credentials 전송 (HTTPS 필수)
      const { data } = await api.post('/api/login', credentials);
      return data;
    },
    onSuccess: (data) => {
      // 2. AT 메모리 저장 (RT는 서버가 Set-Cookie로 자동 설정)
      setAccessToken(data.accessToken);

      // 3. 전역 상태 업데이트
      queryClient.setQueryData(['user'], data.user);
    },
  });
}
```

### 로그아웃

```typescript
export function useLogout() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async () => {
      // 1. 서버: RT 무효화 (DB blacklist에 추가)
      await api.post('/api/logout');
    },
    onSuccess: () => {
      // 2. AT 메모리 제거
      setAccessToken(null);

      // 3. TanStack Query 캐시 전체 클리어
      // (case-study 01: 다른 사용자 데이터가 남는 문제 방지)
      queryClient.clear();

      // 4. 리다이렉트
      window.location.href = '/login';
    },
  });
}
```

> 💡 `queryClient.clear()`가 아닌 `removeQueries`만 하면 inactive 쿼리가 남을 수 있다.
> 로그아웃 시에는 반드시 `clear()`로 전체 제거한다. (case-study 01 참고)

### OAuth 소셜 로그인 (Google, GitHub)

```
┌──────────┐     ┌──────────────┐     ┌──────────┐     ┌──────────┐
│  프론트   │────→│ OAuth 제공자  │────→│  콜백 URL │────→│  백엔드   │
│          │     │(Google 등)   │     │          │     │          │
└──────────┘     └──────────────┘     └──────────┘     └──────────┘
  1. 리다이렉트    2. 사용자 권한 허용   3. auth code    4. code→token
                                        전달            교환 → JWT 발급
```

**구현 흐름:**

```typescript
// 1. OAuth 시작 (프론트)
function handleGoogleLogin() {
  const params = new URLSearchParams({
    client_id: process.env.NEXT_PUBLIC_GOOGLE_CLIENT_ID!,
    redirect_uri: `${window.location.origin}/auth/callback`,
    response_type: 'code',
    scope: 'openid email profile',
    state: generateCSRFState(), // CSRF 방지용 랜덤 문자열
  });

  window.location.href = `https://accounts.google.com/o/oauth2/v2/auth?${params}`;
}

// 2. 콜백 페이지 (프론트)
// /auth/callback?code=xxx&state=yyy
function AuthCallback() {
  const searchParams = useSearchParams();

  useEffect(() => {
    const code = searchParams.get('code');
    const state = searchParams.get('state');

    // state 검증 (CSRF 방지)
    if (state !== getStoredCSRFState()) {
      throw new Error('Invalid state parameter');
    }

    // 3. 백엔드에 code 전달
    api.post('/api/auth/google', { code }).then(({ data }) => {
      // 4. 일반 로그인과 동일하게 처리
      setAccessToken(data.accessToken);
      window.location.href = '/dashboard';
    });
  }, [searchParams]);

  return <LoadingSpinner />;
}
```

**주의사항:**
- `client_secret`은 절대 프론트에 노출하지 않음 (백엔드에서 code→token 교환)
- `state` 파라미터로 CSRF 공격 방지
- 팝업 vs 리다이렉트: 리다이렉트가 더 안정적 (팝업 차단 이슈)

---

## 권한 기반 접근 제어

### Route Guard

#### ProtectedRoute 컴포넌트 (React)

```typescript
// components/ProtectedRoute.tsx
import { useAuth } from '../hooks/useAuth';
import { Navigate, useLocation } from 'react-router-dom';

interface ProtectedRouteProps {
  children: React.ReactNode;
  requiredRoles?: string[];
}

export function ProtectedRoute({ children, requiredRoles }: ProtectedRouteProps) {
  const { user, isLoading } = useAuth();
  const location = useLocation();

  // 인증 상태 로딩 중 → 로딩 UI (깜빡임 방지)
  if (isLoading) {
    return <FullPageSpinner />;
  }

  // 미인증 → 로그인 페이지 (현재 URL 저장)
  if (!user) {
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  // 권한 부족 → 403 페이지
  if (requiredRoles && !requiredRoles.some((role) => user.roles.includes(role))) {
    return <Navigate to="/forbidden" replace />;
  }

  return <>{children}</>;
}

// 사용 예시
<Route
  path="/admin"
  element={
    <ProtectedRoute requiredRoles={['admin']}>
      <AdminDashboard />
    </ProtectedRoute>
  }
/>
```

#### Next.js Middleware에서의 인증 체크

```typescript
// middleware.ts (Next.js App Router)
import { NextRequest, NextResponse } from 'next/server';

const protectedPaths = ['/dashboard', '/settings', '/admin'];
const adminPaths = ['/admin'];

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // 보호된 경로인지 확인
  const isProtected = protectedPaths.some((path) => pathname.startsWith(path));
  if (!isProtected) return NextResponse.next();

  // RT cookie 존재 여부로 인증 상태 판단
  // (실제 검증은 서버 사이드에서 수행)
  const refreshToken = request.cookies.get('refresh_token');

  if (!refreshToken) {
    const loginUrl = new URL('/login', request.url);
    loginUrl.searchParams.set('redirect', pathname);
    return NextResponse.redirect(loginUrl);
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/dashboard/:path*', '/settings/:path*', '/admin/:path*'],
};
```

> ⚠️ Middleware에서는 RT cookie의 **존재 여부**만 확인한다. 실제 토큰 검증은 서버 API에서 수행.
> 이는 "빠른 리다이렉트"를 위한 1차 필터링이다.

### 컴포넌트 레벨 권한 제어

#### usePermission Hook

```typescript
// hooks/usePermission.ts
type Role = 'admin' | 'editor' | 'viewer';
type Permission = 'read' | 'write' | 'delete' | 'manage_users';

// 역할별 권한 매핑 (RBAC)
const rolePermissions: Record<Role, Permission[]> = {
  admin: ['read', 'write', 'delete', 'manage_users'],
  editor: ['read', 'write'],
  viewer: ['read'],
};

export function usePermission() {
  const { user } = useAuth();

  const hasRole = (role: Role): boolean => {
    return user?.roles.includes(role) ?? false;
  };

  const hasPermission = (permission: Permission): boolean => {
    if (!user) return false;
    return user.roles.some((role: Role) =>
      rolePermissions[role]?.includes(permission)
    );
  };

  const hasAnyPermission = (permissions: Permission[]): boolean => {
    return permissions.some(hasPermission);
  };

  return { hasRole, hasPermission, hasAnyPermission };
}
```

#### Permission Guard 컴포넌트

```tsx
// components/PermissionGuard.tsx
interface PermissionGuardProps {
  permission: Permission;
  fallback?: React.ReactNode;
  children: React.ReactNode;
}

export function PermissionGuard({
  permission,
  fallback = null,
  children,
}: PermissionGuardProps) {
  const { hasPermission } = usePermission();

  if (!hasPermission(permission)) {
    return <>{fallback}</>;
  }

  return <>{children}</>;
}

// 사용 예시
<PermissionGuard permission="delete" fallback={<DisabledButton />}>
  <DeleteButton onClick={handleDelete} />
</PermissionGuard>

<PermissionGuard permission="manage_users">
  <UserManagementPanel />
</PermissionGuard>
```

#### RBAC vs ABAC

| 구분 | RBAC (Role-Based) | ABAC (Attribute-Based) |
|------|-------------------|------------------------|
| 기준 | 역할 (admin, editor) | 속성 (부서, 시간, 리소스 소유자) |
| 복잡도 | 단순 | 복잡 |
| 유연성 | 제한적 | 매우 유연 |
| 예시 | admin은 삭제 가능 | "본인 게시글만 삭제 가능" |
| 적합 | 소규모~중규모 | 대규모, 복잡한 정책 |

프론트엔드에서는 주로 **RBAC**을 사용하고, 세밀한 권한은 백엔드 API에서 처리한다.

---

## 실전 코드 예제

### useAuth Hook (전체 구현)

```typescript
// hooks/useAuth.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { setAccessToken, getAccessToken } from '../auth/tokenManager';
import api from '../api/axiosInstance';

interface User {
  id: string;
  email: string;
  name: string;
  roles: string[];
  avatar?: string;
}

export function useAuth() {
  const queryClient = useQueryClient();

  // 현재 사용자 정보 조회
  const {
    data: user,
    isLoading,
    error,
  } = useQuery<User>({
    queryKey: ['user', 'me'],
    queryFn: async () => {
      const { data } = await api.get('/api/me');
      return data;
    },
    retry: false,
    staleTime: 5 * 60 * 1000, // 5분
    // AT가 없으면 쿼리 실행하지 않음
    enabled: !!getAccessToken(),
  });

  // 앱 초기화 시 refresh로 AT 복구
  const { mutateAsync: initAuth } = useMutation({
    mutationFn: async () => {
      const { data } = await api.post('/api/refresh');
      return data;
    },
    onSuccess: (data) => {
      setAccessToken(data.accessToken);
      queryClient.invalidateQueries({ queryKey: ['user', 'me'] });
    },
    onError: () => {
      setAccessToken(null);
    },
  });

  return {
    user: user ?? null,
    isLoading,
    isAuthenticated: !!user,
    error,
    initAuth,
  };
}
```

### App 초기화에서 인증 복구

```typescript
// app/providers.tsx
'use client';

import { useEffect, useState } from 'react';
import { useAuth } from '../hooks/useAuth';

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const { initAuth } = useAuth();
  const [isInitialized, setIsInitialized] = useState(false);

  useEffect(() => {
    // 새로고침 시 RT로 AT 복구 시도
    initAuth()
      .catch(() => {
        // refresh 실패 = 미인증 상태 (정상)
      })
      .finally(() => {
        setIsInitialized(true);
      });
  }, [initAuth]);

  // 초기화 완료 전에는 로딩 표시 (깜빡임 방지)
  if (!isInitialized) {
    return <FullPageSpinner />;
  }

  return <>{children}</>;
}
```

---

## 보안 체크리스트

### 필수 사항

| # | 항목 | 설명 |
|---|------|------|
| 1 | HTTPS 필수 | 토큰이 평문으로 전송되면 의미 없음 |
| 2 | httpOnly cookie | RT를 JS로 접근 불가하게 |
| 3 | Secure flag | HTTPS에서만 cookie 전송 |
| 4 | SameSite=Strict | CSRF 1차 방어 |
| 5 | CSRF 토큰 | cookie 사용 시 추가 방어 계층 |
| 6 | XSS 방지 | 사용자 입력 sanitize, CSP 헤더 |
| 7 | AT 짧은 수명 | 15분 이하 권장 |
| 8 | RT Rotation | 사용 시마다 새 RT 발급 |
| 9 | 서버 사이드 무효화 | 로그아웃 시 RT blacklist |
| 10 | Rate Limiting | 로그인/refresh 엔드포인트 요청 제한 |

### 추가 권장 사항

- **Fingerprinting**: AT에 브라우저 fingerprint 바인딩 → 다른 기기에서 사용 불가
- **Sliding Session**: 활동 중이면 세션 연장, 비활동 시 만료
- **다중 기기 관리**: 사용자에게 활성 세션 목록 제공, 원격 로그아웃 기능
- **비밀번호 변경 시**: 모든 RT 무효화 (전체 기기 로그아웃)

---

## 면접 포인트

### Q1. Access Token과 Refresh Token을 왜 분리하는가?

> AT는 짧은 수명으로 탈취 피해를 최소화하고, RT는 긴 수명으로 UX를 유지한다.
> AT가 탈취되어도 15분이면 만료되고, RT는 httpOnly cookie에 있어 XSS로 탈취가 불가능하다.
> 하나의 토큰으로 두 가지(보안 + UX)를 동시에 만족시킬 수 없기 때문에 분리한다.

### Q2. 토큰을 어디에 저장해야 하는가?

> AT는 메모리(변수)에 저장한다. XSS로 접근 불가하고, CSRF와도 무관하다.
> RT는 httpOnly + Secure + SameSite cookie에 저장한다. JS 접근 차단 + 새로고침에도 유지.
> localStorage는 XSS에 취약하므로 토큰 저장에 부적합하다.

### Q3. Silent Refresh란 무엇이고 어떻게 구현하는가?

> AT가 만료되었을 때 사용자 개입 없이 자동으로 새 AT를 발급받는 메커니즘.
> Axios interceptor에서 401 응답을 감지하면 /api/refresh를 호출하고,
> 성공 시 새 AT로 원래 요청을 재시도한다. 실패 시 로그아웃 처리한다.

### Q4. 동시에 여러 API가 401을 받으면 어떻게 처리하는가?

> 첫 번째 401에서 refresh 요청을 보내고, 나머지 요청은 큐에 대기시킨다.
> refresh 성공 시 큐의 모든 요청을 새 AT로 재시도한다.
> `isRefreshing` 플래그와 `failedQueue` 배열로 구현한다.

### Q5. 로그아웃 시 프론트엔드에서 해야 할 일은?

> 1) 서버에 로그아웃 요청 (RT 무효화)
> 2) AT 메모리에서 제거
> 3) TanStack Query 캐시 전체 클리어 (`queryClient.clear()`)
> 4) 로그인 페이지로 리다이렉트
> 특히 캐시 클리어를 빠뜨리면 다른 사용자 로그인 시 이전 데이터가 보일 수 있다.

### Q6. CSRF와 XSS 각각에 대한 방어 전략은?

> **XSS 방어**: CSP 헤더 설정, 사용자 입력 sanitize, 토큰을 localStorage 대신 메모리/httpOnly cookie에 저장
> **CSRF 방어**: SameSite cookie 속성, CSRF 토큰 (Double Submit Cookie 또는 Synchronizer Token), Origin/Referer 헤더 검증

---

## 참고 자료

- [OWASP - JWT Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/JSON_Web_Token_for_Java_Cheat_Sheet.html)
- [Auth0 - Token Storage](https://auth0.com/docs/secure/security-guidance/data-privacy-and-compliance/token-storage)
- [web.dev - SameSite cookies explained](https://web.dev/articles/samesite-cookies-explained)
- [RFC 6749 - OAuth 2.0 Authorization Framework](https://datatracker.ietf.org/doc/html/rfc6749)
- Case Study 01: TanStack Query 캐시 무효화 & 로그아웃 세션 정리
- `cs/web-auth/` - JWT, OAuth, 세션 이론 문서
