# CVE-2022-24999 - qs Prototype Pollution

## 개요

| 항목 | 내용 |
|------|------|
| CVE ID | CVE-2022-24999 |
| CVSS | 7.5 (High) |
| 영향 패키지 | qs |
| 영향 버전 | < 6.10.3, 6.7.x ~ 6.9.x 일부 |
| 수정 버전 | 6.10.3, 6.9.7, 6.8.3, 6.7.3 |
| 공격 유형 | Prototype Pollution |
| 발견일 | 2022-11-26 |

## 왜 프론트엔드 개발자가 알아야 하는가

`qs`는 Express.js의 기본 쿼리스트링 파서다. Express를 BFF(Backend For Frontend)나 API 서버로 사용하는 모든 프론트엔드 팀에 직접적 영향을 미친다.

- Express 4.x는 기본적으로 `qs`를 쿼리스트링 파싱에 사용
- Next.js API Routes, Remix loader 등에서 간접적으로 Express 미들웨어 활용
- 프론트엔드에서 직접 `qs`를 import하여 복잡한 쿼리 파라미터를 직렬화/역직렬화하는 경우도 흔함

프로토타입 오염은 DoS부터 인증 우회, RCE까지 이어질 수 있는 위험한 취약점이다.

## 취약점 기술 분석

`qs`는 중첩된 객체를 쿼리스트링으로 표현할 수 있게 해준다 (예: `a[b][c]=1`). 이 과정에서 `__proto__` 키에 대한 필터링이 불완전하여 프로토타입 체인을 오염시킬 수 있었다.

```javascript
// qs의 파싱 동작 (단순화)
// 쿼리스트링 "a[__proto__][polluted]=true" 파싱 시
// → Object.prototype.polluted = true 가 됨
// 이후 생성되는 모든 객체에 polluted 속성이 존재
```

특히 배열 인덱스나 중첩 구조를 통한 `__proto__` 접근 우회 경로가 문제였다.

## 공격 시나리오

```javascript
const express = require('express');
const app = express();

app.get('/api/user', (req, res) => {
  // 공격 URL: /api/user?__proto__[isAdmin]=true
  
  const user = {};
  
  // 프로토타입 오염 후, 모든 새 객체에 isAdmin이 true
  if (user.isAdmin) {
    // 관리자 전용 로직 실행 — 인증 우회!
    return res.json({ secret: 'admin data' });
  }
  
  res.json({ data: 'normal response' });
});
```

```bash
# 공격 요청
curl "https://app.example.com/api/user?__proto__[isAdmin]=true"
```

## 방어 방법

### 즉시 조치
```bash
npm install qs@6.10.3
npm install express@4.18.2  # qs 패치 포함
npm audit fix
```

### 코드 레벨 방어
```javascript
// ✅ Object.create(null)로 프로토타입 없는 객체 사용
const config = Object.create(null);
config.isAdmin = false;

// ✅ hasOwnProperty 체크
function safeGet(obj, key) {
  return Object.prototype.hasOwnProperty.call(obj, key) ? obj[key] : undefined;
}

// ✅ Express qs 옵션 제한
app.set('query parser', function (str) {
  return require('qs').parse(str, {
    allowPrototypes: false,
    depth: 5,
    parameterLimit: 100
  });
});
```

### 장기 전략
- Express 쿼리 파서 옵션을 명시적으로 설정
- 객체 속성 접근 시 `hasOwnProperty` 검사를 기본으로
- 보안 린트 규칙으로 프로토타입 오염 패턴 감지

## 교훈 & 프론트엔드 적용 포인트

1. **프로토타입 오염은 JS 생태계의 고질적 문제다**: `{}` 의 프로토타입 체인은 모든 객체에 영향을 미친다.
2. **Express 기본 설정을 신뢰하지 마라**: 미들웨어의 기본 동작이 항상 안전한 것은 아니다.
3. **BFF는 프론트엔드 팀의 보안 책임이다**: 프론트엔드 개발자가 운영하는 Node.js 서버에도 백엔드 수준의 보안이 필요하다.
4. **입력 깊이 제한**: 중첩 객체의 깊이와 키 이름을 제한하는 것만으로도 많은 공격을 차단한다.

## 참고 자료

- [NVD - CVE-2022-24999](https://nvd.nist.gov/vuln/detail/CVE-2022-24999)
- [GitHub Advisory - GHSA-hrpp-h998-j3pp](https://github.com/advisories/GHSA-hrpp-h998-j3pp)
- [qs npm package](https://www.npmjs.com/package/qs)
- [Express.js Security Best Practices](https://expressjs.com/en/advanced/best-practice-security.html)
