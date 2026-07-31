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

## 백엔드 & 인프라 (21~40)

### Critical (CVSS 9.0+)

| # | CVE | 취약점 | 소프트웨어 | CVSS |
|---|-----|--------|-----------|------|
| 25 | [CVE-2022-22947](./25-spring-cloud-gateway-rce.md) | SpEL Injection RCE | Spring Cloud Gateway | 10.0 |
| 28 | [CVE-2024-3094](./28-xz-utils-backdoor.md) | 공급망 백도어 (SSH RCE) | xz-utils | 10.0 |
| 34 | [CVE-2023-22515](./34-confluence-access-control.md) | 관리자 계정 생성 | Atlassian Confluence | 10.0 |
| 22 | [CVE-2022-22965](./22-spring4shell.md) | Spring4Shell RCE | Spring Framework | 9.8 |
| 26 | [CVE-2023-34362](./26-moveit-sqli.md) | SQL Injection | MOVEit Transfer | 9.8 |
| 30 | [CVE-2023-23397](./30-outlook-ntlm-relay.md) | Zero-Click NTLM 탈취 | Microsoft Outlook | 9.8 |
| 31 | [CVE-2022-42889](./31-commons-text-rce.md) | Text4Shell RCE | Apache Commons Text | 9.8 |
| 32 | [CVE-2022-1388](./32-f5-bigip-auth-bypass.md) | 인증 우회 → RCE | F5 BIG-IP | 9.8 |
| 33 | [CVE-2021-26855](./33-proxylogon-exchange.md) | ProxyLogon SSRF → RCE | Microsoft Exchange | 9.8 |
| 37 | [CVE-2023-38545](./37-curl-socks5-overflow.md) | 힙 오버플로우 | curl/libcurl | 9.8 |
| 40 | [CVE-2022-29078](./40-ejs-ssti.md) | SSTI → RCE | EJS | 9.8 |
| 21 | [CVE-2021-45046](./21-log4j-additional-rce.md) | Log4Shell 패치 우회 | Log4j 2 | 9.0 |

### High (CVSS 7.0~8.9)

| # | CVE | 취약점 | 소프트웨어 | CVSS |
|---|-----|--------|-----------|------|
| 39 | [CVE-2024-21626](./39-runc-container-escape.md) | 컨테이너 탈출 | runc (Docker/K8s) | 8.6 |
| 35 | [CVE-2024-6387](./35-openssh-regresshion.md) | regreSSHion (root RCE) | OpenSSH | 8.1 |
| 29 | [CVE-2023-32233](./29-linux-netfilter-uaf.md) | 커널 UAF 권한 상승 | Linux Kernel | 7.8 |
| 23 | [CVE-2021-41773](./23-apache-path-traversal.md) | 경로 순회 → RCE | Apache HTTP Server | 7.5 |
| 27 | [CVE-2023-44487](./27-http2-rapid-reset.md) | HTTP/2 Rapid Reset DDoS | Nginx/Apache/모든 HTTP/2 | 7.5 |
| 38 | [CVE-2022-3602](./38-openssl-x509-overflow.md) | X.509 버퍼 오버플로우 | OpenSSL 3.x | 7.5 |

### Medium

| # | CVE | 취약점 | 소프트웨어 | CVSS |
|---|-----|--------|-----------|------|
| 24 | [CVE-2021-44832](./24-log4j-jdbc-rce.md) | JDBC Appender RCE | Log4j 2 | 6.6 |
| 36 | [CVE-2023-25136](./36-openssh-double-free.md) | Double Free DoS | OpenSSH 9.1 | 6.5 |

---

## 취약점 유형별 분류 (백엔드/인프라 포함)

### 🔴 RCE (Remote Code Execution)
- CVE-2021-44228 / 45046 / 44832 (Log4j 시리즈)
- CVE-2022-22965 (Spring4Shell)
- CVE-2022-22947 (Spring Cloud Gateway)
- CVE-2022-42889 (Commons Text)
- CVE-2022-29078 (EJS SSTI)
- CVE-2024-3094 (xz-utils 백도어)
- CVE-2024-6387 (OpenSSH regreSSHion)

### 🟠 인증 우회 / 권한 상승
- CVE-2022-1388 (F5 BIG-IP)
- CVE-2023-22515 (Confluence)
- CVE-2023-23397 (Outlook NTLM)
- CVE-2023-32233 (Linux Netfilter)
- CVE-2024-21626 (runc 컨테이너 탈출)

### 🟡 Supply Chain Attack
- CVE-2024-3094 (xz-utils) — 역대급 오픈소스 공급망 공격
- CVE-2022-37601 (loader-utils) — npm 생태계

### 🔵 프로토콜 / 인프라 취약점
- CVE-2023-44487 (HTTP/2 Rapid Reset)
- CVE-2023-38545 (curl SOCKS5)
- CVE-2022-3602 (OpenSSL)

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
