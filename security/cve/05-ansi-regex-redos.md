# CVE-2021-3807 - ansi-regex ReDoS

## 개요

| 항목 | 내용 |
|------|------|
| CVE ID | CVE-2021-3807 |
| CVSS | 7.5 (High) |
| 영향 패키지 | ansi-regex |
| 영향 버전 | > 3.0.0, < 6.0.2 (5.x: < 5.0.1) |
| 수정 버전 | 6.0.2, 5.0.1 |
| 공격 유형 | Regular Expression Denial of Service (ReDoS) |
| 발견일 | 2021-09-17 |

## 왜 프론트엔드 개발자가 알아야 하는가

ansi-regex는 npm 생태계에서 가장 많이 의존되는 패키지 중 하나다:

1. **npm/yarn CLI**: 터미널 출력 처리에 사용
2. **chalk**: 터미널 색상 라이브러리 (대부분의 CLI 도구)
3. **string-width, strip-ansi**: 문자열 처리 유틸리티
4. **Jest, ESLint, Prettier**: 테스트/린팅 도구의 콘솔 출력
5. **webpack, Vite**: 빌드 로그 출력

npm 주간 다운로드 1.5억+ 건. 이 패키지 하나의 ReDoS가 CI/CD 파이프라인, 개발 서버, SSR 서버를 모두 멈출 수 있다.

## 취약점 기술 분석

ReDoS(Regular Expression Denial of Service)는 정규식 엔진의 **역추적(backtracking)** 특성을 악용한다. ansi-regex의 정규식 패턴에 특수하게 조작된 문자열을 입력하면, 정규식 매칭에 기하급수적 시간이 소요된다.

```javascript
// 취약한 정규식 (ansi-regex 5.0.0)
const ansiRegex = /[\u001B\u009B][[\]()#;?]*(?:(?:(?:[a-zA-Z\d]*(?:;[-a-zA-Z\d\/#&.:=?%@~_]*)*)?\u0007)|(?:(?:\d{1,4}(?:;\d{0,4})*)?[\dA-PR-TZcf-ntqry=><~]))/g;

// 이 정규식은 중첩된 수량자(nested quantifier)를 포함
// (?:;[-a-zA-Z\d\/#&.:=?%@~_]*)* ← 이 부분이 문제
// 내부 *와 외부 *가 중첩되어 역추적 폭발

// 악성 입력 시 CPU 100% 점유
const malicious = '\u001B[' + ';'.repeat(1000);
ansiRegex.test(malicious); // 수 초 ~ 수 분 소요
```

핵심 원인:
- 중첩된 수량자(quantifier): `(...)*` 안에 또 `(...)*`
- 매칭 실패 시 정규식 엔진이 모든 가능한 조합을 시도 (역추적)
- 입력 길이에 대해 지수적(exponential) 시간 복잡도

## 공격 시나리오

```javascript
// 시나리오 1: SSR 서버에서 사용자 입력이 로그에 포함될 때
const stripAnsi = require('strip-ansi'); // 내부적으로 ansi-regex 사용

// 공격자가 API 요청의 User-Agent나 헤더에 악성 문자열 삽입
const userAgent = '\u001B[' + ';'.repeat(50000);

// 서버 로그 처리 시 strip-ansi 호출
// → 이벤트 루프 블로킹 → 서비스 다운
console.log(stripAnsi(userAgent)); // 이 한 줄로 서버 멈춤

// 시나리오 2: CI 파이프라인
// 테스트 출력을 파싱하는 과정에서 악성 문자열이 포함되면
// CI 타임아웃 → 배포 지연

// 시나리오 3: 개발 서버
// webpack-dev-server 로그에 악성 ANSI 시퀀스 주입
// → 개발 서버 응답 불능
```

## 방어 방법

### 즉각 조치
```bash
npm ls ansi-regex
npm audit fix

# 강제 업데이트
npm install ansi-regex@^5.0.1
```

```json
{
  "overrides": {
    "ansi-regex": ">=5.0.1"
  }
}
```

### 코드 레벨 방어
```javascript
// 입력 길이 제한
function safeStripAnsi(input) {
  if (input.length > 10000) {
    return input.slice(0, 10000); // 잘라내기
  }
  return stripAnsi(input);
}

// 또는 타임아웃 설정 (Worker thread 사용)
const { Worker } = require('worker_threads');
function stripAnsiWithTimeout(input, timeout = 100) {
  return new Promise((resolve, reject) => {
    const worker = new Worker('./strip-ansi-worker.js', { workerData: input });
    const timer = setTimeout(() => {
      worker.terminate();
      resolve(input); // 타임아웃 시 원본 반환
    }, timeout);
    worker.on('message', (result) => { clearTimeout(timer); resolve(result); });
  });
}
```

### 장기 전략
- Node.js의 `--experimental-regexp-engine` 플래그로 선형 시간 정규식 엔진 사용 검토
- 사용자 입력이 정규식 처리 경로에 도달하지 않도록 아키텍처 설계
- 입력 검증 단계에서 길이 제한 적용

## 교훈 & 프론트엔드 적용 포인트

1. **ReDoS는 현실적 위협**: 정규식 하나로 서버 전체가 멈출 수 있다
2. **정규식 작성 시 주의**: 중첩된 수량자(`(a*)*`, `(a+)+`)를 피하기
3. **의존성 폭발의 위험**: 단일 유틸리티 패키지의 버그가 생태계 전체에 영향
4. **입력 길이 제한**: 모든 외부 입력에 합리적인 길이 제한을 적용하는 것이 기본 방어

## 참고 자료

- [NVD - CVE-2021-3807](https://nvd.nist.gov/vuln/detail/CVE-2021-3807)
- [GitHub Advisory GHSA-93q8-gq69-wqmw](https://github.com/advisories/GHSA-93q8-gq69-wqmw)
- [Snyk - ansi-regex ReDoS](https://security.snyk.io/vuln/SNYK-JS-ANSIREGEX-1583908)
- [OWASP - ReDoS](https://owasp.org/www-community/attacks/Regular_expression_Denial_of_Service_-_ReDoS)
