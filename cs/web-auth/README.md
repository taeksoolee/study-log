# 웹 인증/보안 기초

프론트엔드 개발자를 위한 웹 인증 및 보안 핵심 개념 정리입니다.

## 목차

| # | 파일 | 주제 |
|---|------|------|
| 1 | [01-session-cookie.md](./01-session-cookie.md) | 세션 기반 인증 & 쿠키 |
| 2 | [02-jwt.md](./02-jwt.md) | JWT (JSON Web Token) |
| 3 | [03-oauth2-oidc.md](./03-oauth2-oidc.md) | OAuth 2.0 & OpenID Connect |
| 4 | [04-password-security.md](./04-password-security.md) | 패스워드 보안 |
| 5 | [05-web-security-checklist.md](./05-web-security-checklist.md) | 웹 보안 체크리스트 |

---

## 학습 순서

```
인증 기초 개념
    │
    ├── 1. 세션/쿠키 → HTTP 무상태(Stateless) 극복 방법 이해
    │
    ├── 2. JWT       → 토큰 기반 인증, Access/Refresh Token 패턴
    │
    ├── 3. OAuth 2.0 → 위임 인가, 소셜 로그인 구현 원리
    │
    ├── 4. 패스워드   → 해시/Salt/bcrypt, 안전한 비밀번호 저장
    │
    └── 5. 보안 체크  → HTTPS, 보안 헤더, OWASP Top 10
```

## 핵심 용어 요약

| 용어 | 설명 |
|------|------|
| **인증 (Authentication)** | 당신이 누구인지 확인 (로그인) |
| **인가 (Authorization)** | 당신이 무엇을 할 수 있는지 결정 (권한) |
| **세션** | 서버 측에서 사용자 상태를 저장하는 방식 |
| **JWT** | 상태를 토큰 자체에 담아 서버가 저장하지 않는 방식 |
| **OAuth 2.0** | 제3자 앱에게 권한을 위임하는 인가 프레임워크 |
| **OIDC** | OAuth 2.0 위에 인증 레이어를 추가한 표준 |
| **HTTPS** | TLS로 암호화된 HTTP 통신 |
| **CSRF** | 사용자 의지와 무관하게 요청을 위조하는 공격 |
| **XSS** | 악성 스크립트를 삽입해 실행시키는 공격 |

## 관련 섹션

- [네트워크 기초 → HTTP](../network/03-http.md)
- [네트워크 기초 → HTTPS/TLS](../network/03-http.md)

---

## 참고 자료

### 공식 문서 & 학습 사이트
- **OWASP Top 10**: https://owasp.org/www-project-top-ten/
- **jwt.io (JWT 디버거 & 스펙)**: https://jwt.io/
- **MDN 웹 보안**: https://developer.mozilla.org/ko/docs/Web/Security
- **OAuth 2.0 스펙 (RFC 6749)**: https://www.rfc-editor.org/rfc/rfc6749

### 추천 도서
| 책 제목 | 교보문고 |
|---------|---------|
| 웹 해킹 & 보안 완벽 가이드 | [검색](https://search.kyobobook.co.kr/search?keyword=웹+해킹+보안+완벽+가이드) |
