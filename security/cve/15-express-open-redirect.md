# CVE-2024-29041 - Express.js Open Redirect

## 개요

| 항목 | 내용 |
|------|------|
| CVE ID | CVE-2024-29041 |
| CVSS | 6.1 (Medium) |
| 영향 패키지 | express |
| 영향 버전 | < 4.19.2 |
| 수정 버전 | 4.19.2 |
| 공격 유형 | Open Redirect |
| 발견일 | 2024-03-25 |

## 왜 프론트엔드 개발자가 알아야 하는가

Express.js는 Node.js 웹 프레임워크의 사실상 표준이다. BFF, API 서버, SSR 서버 등 프론트엔드 팀이 직접 운영하는 서버에서 광범위하게 사용된다.

`res.redirect()`는 로그인 후 리다이렉트, OAuth 콜백 처리, 단축 URL 서비스 등에서 핵심적으로 사용되는 API다. 이 함수의 입력 검증 우회는 피싱 공격의 직접적 벡터가 된다.

## 취약점 기술 분석

Express의 `res.redirect()`는 URL 입력을 검증할 때, 특정 문자 조합으로 시작하는 URL을 프로토콜-상대(protocol-relative) URL로 인식하지 못하는 결함이 있었다.

```javascript
// Express 내부에서 URL이 절대 경로인지 판단하는 로직에 결함
// 특정 인코딩이나 문자 조합으로 검증을 우회할 수 있었음

// 예: 아래와 같은 입력이 "상대 경로"로 오판됨
res.redirect('//evil.com');        // 일부 케이스에서 우회
res.redirect('/\\evil.com');       // 백슬래시로 혼동 유발
res.redirect('\x2f\x2fevil.com'); // 인코딩된 슬래시
```

문제의 핵심은 Express가 사용자 제공 URL을 `Location` 헤더에 설정할 때, 외부 도메인으로의 리다이렉트를 적절히 차단하지 못한다는 것이다.

## 공격 시나리오

```javascript
const express = require('express');
const app = express();

// 로그인 후 원래 페이지로 돌려보내는 패턴 (흔한 구현)
app.get('/login/callback', (req, res) => {
  const returnUrl = req.query.returnUrl || '/';
  
  // 개발자는 상대 경로만 올 것이라 기대
  // 하지만 공격자가 returnUrl을 조작
  res.redirect(returnUrl);
});

// 공격 URL:
// https://myapp.com/login/callback?returnUrl=//evil.com/phishing
// → 사용자가 evil.com의 피싱 페이지로 리다이렉트됨
// 브라우저 주소창에는 myapp.com에서 온 것처럼 보임
```

피싱 시나리오:
1. 공격자가 `https://myapp.com/login/callback?returnUrl=%2f%2fevil.com` 링크를 이메일로 발송
2. 사용자가 정상적인 myapp.com 링크로 보고 클릭
3. 로그인 완료 후 evil.com의 가짜 로그인 페이지로 이동
4. "세션이 만료되었습니다" 메시지와 함께 비밀번호 재입력 유도

## 방어 방법

### 즉시 조치
```bash
npm install express@4.19.2
```

### 코드 레벨 방어
```javascript
// ✅ 리다이렉트 URL을 화이트리스트로 검증
function isSafeRedirect(url) {
  try {
    const parsed = new URL(url, 'https://myapp.com');
    // 같은 origin만 허용
    return parsed.origin === 'https://myapp.com';
  } catch {
    return false;
  }
}

app.get('/login/callback', (req, res) => {
  const returnUrl = req.query.returnUrl || '/';
  
  if (!isSafeRedirect(returnUrl)) {
    return res.redirect('/'); // 안전한 기본값
  }
  
  res.redirect(returnUrl);
});

// ✅ 절대 경로만 허용하는 패턴
function sanitizeRedirect(url) {
  if (!url || !url.startsWith('/') || url.startsWith('//')) {
    return '/';
  }
  return url;
}
```

### 장기 전략
- 리다이렉트 URL은 절대 사용자 입력을 그대로 사용하지 않는다
- 허용된 경로 목록(allowlist)을 유지
- CSP `navigate-to` 디렉티브 검토 (브라우저 지원 확인 필요)

## 교훈 & 프론트엔드 적용 포인트

1. **Open Redirect는 "낮은 심각도"가 아니다**: 피싱 체인의 핵심 고리이며, OAuth 토큰 탈취에도 악용된다.
2. **프레임워크를 맹신하지 마라**: Express의 `res.redirect()`가 안전하게 처리해줄 것이라 가정하면 안 된다.
3. **리다이렉트 URL 검증은 필수다**: 경로 기반 리다이렉트에서도 `//`, `\/`, 인코딩된 문자를 검사해야 한다.
4. **URL 파싱은 어렵다**: 다양한 인코딩과 특수문자 조합이 검증 로직을 우회할 수 있다.

## 참고 자료

- [NVD - CVE-2024-29041](https://nvd.nist.gov/vuln/detail/CVE-2024-29041)
- [GitHub Advisory - GHSA-rv95-896h-c2vc](https://github.com/advisories/GHSA-rv95-896h-c2vc)
- [Express.js Release Notes](https://github.com/expressjs/express/releases/tag/4.19.2)
- [OWASP - Unvalidated Redirects](https://cheatsheetseries.owasp.org/cheatsheets/Unvalidated_Redirects_and_Forwards_Cheat_Sheet.html)
