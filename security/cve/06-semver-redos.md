# CVE-2022-25883 - semver ReDoS

## 개요

| 항목 | 내용 |
|------|------|
| CVE ID | CVE-2022-25883 |
| CVSS | 7.5 (High) |
| 영향 패키지 | semver |
| 영향 버전 | 6.x < 6.3.1, 7.x < 7.5.2 |
| 수정 버전 | 6.3.1, 7.5.2 |
| 공격 유형 | Regular Expression Denial of Service (ReDoS) |
| 발견일 | 2023-06-21 |

## 왜 프론트엔드 개발자가 알아야 하는가

`semver`는 npm 생태계의 근간을 이루는 패키지다:

1. **npm/yarn/pnpm**: 패키지 매니저가 버전 범위 해석에 직접 사용
2. **CI/CD 파이프라인**: 버전 비교, 릴리스 판단 로직
3. **빌드 도구**: webpack, Vite, ESLint 등이 플러그인 호환성 체크에 사용
4. **package.json 처리**: 모든 의존성 해석 과정
5. **Dependabot/Renovate**: 자동 업데이트 도구의 핵심 의존성

npm 주간 다운로드 3억+ 건. Node.js 런타임 자체에도 내장되어 있어, npm 생태계의 가장 기본적인 인프라 패키지 중 하나다.

## 취약점 기술 분석

semver의 버전 문자열 파싱에 사용되는 정규식에 ReDoS 취약점이 존재한다. 특수하게 조작된 버전 문자열을 `semver.valid()`, `semver.satisfies()` 등에 전달하면 CPU를 과도하게 점유한다.

```javascript
// semver 내부의 취약한 정규식 (간소화)
// 숫자 부분을 파싱하는 정규식에 역추적 문제
const NUMERIC = '0|[1-9]\\d*';
const MAINVERSION = `(${NUMERIC})\\.(${NUMERIC})\\.(${NUMERIC})`;
const PRERELEASE = `(?:-((?:${NUMERIC}|\\d*[a-zA-Z-][a-zA-Z0-9-]*)(?:\\.(?:${NUMERIC}|\\d*[a-zA-Z-][a-zA-Z0-9-]*))*))`;

// 프리릴리스 부분의 반복 패턴에서 역추적 폭발
// (?:...(?: \. ...)*)* 형태의 중첩

// 악성 입력
const malicious = '1.2.3-' + 'a'.repeat(50000) + '!';
semver.valid(malicious); // 극도로 느린 처리
```

핵심 원인:
- 프리릴리스 및 빌드 메타데이터 파싱 정규식의 역추적
- 유효하지 않은 버전 문자열이 입력될 때 매칭 실패 과정에서 지수적 역추적
- 버전 문자열의 길이에 대한 사전 검증 부재

## 공격 시나리오

```javascript
const semver = require('semver');

// 시나리오 1: package.json의 악성 버전 문자열
// 공격자가 npm 패키지의 version 필드에 악성 문자열 삽입
const maliciousVersion = '1.2.3-' + 'a.'.repeat(30000) + '!';

// npm install 시 semver.satisfies() 호출
// → 설치 과정이 극도로 느려짐 또는 타임아웃
semver.satisfies(maliciousVersion, '^1.0.0');

// 시나리오 2: CI/CD에서 버전 검증
// PR에서 버전 변경을 체크하는 스크립트
function checkVersion(version) {
  if (semver.valid(version)) {  // ← 여기서 블로킹
    return semver.gt(version, currentVersion);
  }
}

// 시나리오 3: 사용자가 입력한 버전 문자열 검증
// 관리자 페이지에서 "최소 버전" 설정 시
const userInput = req.body.minVersion; // 악성 입력
if (semver.satisfies(currentVersion, '>=' + userInput)) {
  // 이 검증에서 서버 블로킹
}
```

## 방어 방법

### 즉각 조치
```bash
npm ls semver
npm audit fix
npm install semver@^7.5.2
```

```json
{
  "overrides": {
    "semver": ">=7.5.2"
  }
}
```

### 코드 레벨 방어
```javascript
// 입력 길이 제한
function safeVersionCheck(version) {
  // semver 스펙상 정상적인 버전 문자열은 256자를 넘지 않음
  if (typeof version !== 'string' || version.length > 256) {
    return null;
  }
  return semver.valid(version);
}

// 사전 검증 정규식 (간단하고 안전한 패턴)
const SAFE_VERSION_REGEX = /^\d+\.\d+\.\d+(-[\w.]+)?(\+[\w.]+)?$/;
function quickValidate(version) {
  if (!SAFE_VERSION_REGEX.test(version)) {
    return false;
  }
  return semver.valid(version);
}
```

### 장기 전략
- 사용자 입력을 직접 semver 함수에 전달하기 전 반드시 사전 검증
- CI 타임아웃 설정으로 ReDoS 영향 최소화
- 정규식 대신 파서 기반 접근 방식 선호

## 교훈 & 프론트엔드 적용 포인트

1. **인프라 패키지의 취약점**: 가장 기본적인 유틸리티도 취약할 수 있다
2. **입력 검증의 중요성**: 외부 입력을 라이브러리에 직접 전달하기 전 길이/형식 체크
3. **정규식 성능 테스트**: 정규식 작성 시 악의적 입력에 대한 성능 테스트 필요
4. **CI/CD 보안**: 빌드 파이프라인도 DoS 공격의 대상이 될 수 있음

## 참고 자료

- [NVD - CVE-2022-25883](https://nvd.nist.gov/vuln/detail/CVE-2022-25883)
- [GitHub Advisory GHSA-c2qf-rxjj-qqgw](https://github.com/advisories/GHSA-c2qf-rxjj-qqgw)
- [semver GitHub](https://github.com/npm/node-semver)
- [Node.js Security Release](https://nodejs.org/en/blog/vulnerability)
