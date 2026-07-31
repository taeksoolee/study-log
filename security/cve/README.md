# 프론트엔드 보안 취약점 (CVE) 정리

> 프론트엔드 개발자가 반드시 알아야 할 크리티컬 CVE 이슈 20선.
> npm 생태계에서 실제로 영향을 미친 취약점을 중심으로, 공격 원리와 방어 방법을 정리한다.

---

## 왜 프론트엔드 개발자가 CVE를 알아야 하는가?

1. **의존성 지옥**: 평균 프론트엔드 프로젝트의 node_modules에는 수백~수천 개 패키지가 있다
2. **Supply Chain Attack**: 하나의 취약한 패키지가 전체 빌드를 오염시킨다
3. **BFF/SSR**: 프론트엔드 개발자가 서버 코드(Next.js, Express)도 작성하는 시대
4. **면접**: 보안 인식은 시니어 레벨에서 필수 역량

---

## CVE 목록 (크리티컬 순)

### Critical (CVSS 9.0+)

| # | CVE | 취약점 | 패키지 | CVSS |
|---|-----|--------|--------|------|
| 01 | [CVE-2021-44228](./01-log4shell.md) | Log4Shell RCE | Apache Log4j 2 | 10.0 |
| 02 | [CVE-2021-23369](./02-handlebars-rce.md) | Prototype Pollution → RCE | Handlebars | 9.8 |
| 04 | [CVE-2022-37601](./04-loader-utils-rce.md) | Prototype Pollution → RCE | loader-utils (webpack) | 9.8 |
| 12 | [CVE-2022-0691](./12-url-parse-bypass.md) | Authorization Bypass | url-parse | 9.8 |
| 14 | [CVE-2023-42282](./14-ip-package-ssrf.md) | SSRF (isPrivate 우회) | ip | 9.8 |
| 17 | [CVE-2023-36665](./17-protobufjs-pollution.md) | Prototype Pollution | protobuf.js | 9.8 |

### High (CVSS 7.0~8.9)

| # | CVE | 취약점 | 패키지 | CVSS |
|---|-----|--------|--------|------|
| 03 | [CVE-2022-46175](./03-json5-prototype-pollution.md) | Prototype Pollution | JSON5 | 8.8 |
| 16 | [CVE-2023-45133](./16-babel-code-execution.md) | 임의 코드 실행 | @babel/traverse | 8.8 |
| 09 | [CVE-2024-21538](./09-cross-spawn-injection.md) | ReDoS | cross-spawn | 7.5 |
| 05 | [CVE-2021-3807](./05-ansi-regex-redos.md) | ReDoS | ansi-regex | 7.5 |
| 06 | [CVE-2022-25883](./06-semver-redos.md) | ReDoS | semver | 7.5 |
| 08 | [CVE-2024-4067](./08-micromatch-redos.md) | ReDoS | micromatch | 7.5 |
| 13 | [CVE-2022-24999](./13-qs-prototype-pollution.md) | Prototype Pollution | qs (Express) | 7.5 |
| 19 | [CVE-2024-39338](./19-axios-ssrf.md) | SSRF (상대 URL) | axios | 7.5 |
| 10 | [CVE-2023-26159](./10-follow-redirects-ssrf.md) | SSRF (URL 파싱) | follow-redirects | 7.4 |
| 11 | [CVE-2021-23337](./11-lodash-template-injection.md) | Command Injection | lodash | 7.2 |

### Medium (CVSS 5.0~6.9)

| # | CVE | 취약점 | 패키지 | CVSS |
|---|-----|--------|--------|------|
| 18 | [CVE-2024-28849](./18-follow-redirects-data-leak.md) | Authorization 헤더 노출 | follow-redirects | 6.5 |
| 15 | [CVE-2024-29041](./15-express-open-redirect.md) | Open Redirect | Express.js | 6.1 |
| 20 | [CVE-2024-34351](./20-nextjs-ssrf.md) | SSRF (Host header) | Next.js | 7.5 |
| 07 | [CVE-2023-44270](./07-postcss-parsing.md) | CSS Injection (파싱 결함) | PostCSS | 5.3 |

---

## 취약점 유형별 분류

### 🔴 Prototype Pollution
가장 빈번한 JS 생태계 취약점. `__proto__` 또는 `constructor.prototype`을 통해 전역 객체를 오염시킨다.
- CVE-2021-23369 (Handlebars)
- CVE-2022-46175 (JSON5)
- CVE-2022-37601 (loader-utils)
- CVE-2022-24999 (qs)
- CVE-2023-36665 (protobuf.js)

### 🟠 ReDoS (Regular Expression Denial of Service)
비효율적 정규식에 악의적 입력을 넣어 CPU를 고갈시키는 공격.
- CVE-2021-3807 (ansi-regex)
- CVE-2022-25883 (semver)
- CVE-2024-4067 (micromatch)
- CVE-2024-21538 (cross-spawn)

### 🟡 SSRF (Server-Side Request Forgery)
서버가 공격자가 지정한 내부 네트워크로 요청을 보내게 만드는 공격.
- CVE-2023-26159 (follow-redirects)
- CVE-2023-42282 (ip)
- CVE-2024-39338 (axios)
- CVE-2024-34351 (Next.js)

### 🔵 RCE (Remote Code Execution)
가장 위험한 유형. 공격자가 서버에서 임의 코드를 실행할 수 있다.
- CVE-2021-44228 (Log4j)
- CVE-2021-23369 (Handlebars)
- CVE-2023-45133 (@babel/traverse)

---

## 방어 체크리스트

```bash
# 1. 의존성 감사
npm audit
pnpm audit

# 2. lockfile 커밋 필수
git add package-lock.json  # 또는 pnpm-lock.yaml

# 3. CI에서 자동 감사
npm audit --audit-level=high

# 4. 의존성 업데이트 자동화
# Renovate 또는 Dependabot 설정

# 5. postinstall 스크립트 차단
# .npmrc: ignore-scripts=true
```

---

## 참고 자료

- [NVD (National Vulnerability Database)](https://nvd.nist.gov/)
- [GitHub Advisory Database](https://github.com/advisories)
- [Snyk Vulnerability DB](https://snyk.io/vuln/)
- [Socket.dev](https://socket.dev/) — Supply chain attack 감지
- [npm audit](https://docs.npmjs.com/cli/v10/commands/npm-audit)
