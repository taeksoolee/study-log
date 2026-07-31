# CVE-2024-21538 - cross-spawn Command Injection

## 개요

| 항목 | 내용 |
|------|------|
| CVE ID | CVE-2024-21538 |
| CVSS | 7.5 (High) |
| 영향 패키지 | cross-spawn |
| 영향 버전 | < 7.0.5, 6.x 전체 |
| 수정 버전 | 7.0.5 |
| 공격 유형 | Regular Expression Denial of Service (ReDoS) |
| 발견일 | 2024-11-08 |

## 왜 프론트엔드 개발자가 알아야 하는가

cross-spawn은 Node.js에서 크로스 플랫폼 프로세스 생성을 위한 핵심 패키지다:

1. **npm scripts**: `npm run` 명령이 내부적으로 cross-spawn 사용
2. **ESLint, Prettier**: 하위 프로세스 실행에 사용
3. **lint-staged**: pre-commit hook에서 명령 실행
4. **Jest**: 테스트 워커 프로세스 생성
5. **create-react-app, Vite**: 개발 서버 실행
6. **husky**: Git hooks에서 명령 실행
7. **execa**: cross-spawn의 상위 래퍼, 매우 널리 사용

npm 주간 다운로드 2억+ 건. 사실상 모든 Node.js 기반 프론트엔드 도구가 직간접적으로 의존한다.

## 취약점 기술 분석

cross-spawn이 Windows에서 명령어 인자를 처리할 때 사용하는 정규식에 ReDoS 취약점이 존재한다. 특히 쉘 메타문자를 이스케이프하는 과정에서 사용되는 정규식이 문제다.

```javascript
// cross-spawn 내부의 인자 이스케이프 로직 (Windows)
// lib/util/escape.js에서 사용되는 취약한 패턴

// 문제가 되는 정규식 (간소화)
const metaCharsRegExp = /(\\*)"/g;
// 그리고 인자를 감싸는 과정에서의 정규식
const cmdShimRegex = /(?:^|\\)"/g;

// 특수하게 조작된 인자를 전달하면
// 정규식 엔진의 역추적이 폭발적으로 증가
const malicious = '\\'.repeat(10000) + '"';

// cross-spawn이 이 인자를 이스케이프 시도 시
// CPU 100% 점유
```

핵심 원인:
- Windows 환경에서 cmd.exe로 인자를 전달할 때 메타문자 이스케이프 필요
- 이스케이프 정규식에 역추적 취약점
- 긴 백슬래시 시퀀스 + 따옴표 조합에서 지수적 역추적

## 공격 시나리오

```javascript
// 시나리오 1: 사용자 입력이 CLI 인자로 전달되는 경우
const crossSpawn = require('cross-spawn');

// 파일명에 악성 문자열이 포함된 경우
const userFilename = '\\'.repeat(50000) + '"test.js';

// 빌드 도구가 이 파일을 처리하려 할 때
crossSpawn.sync('eslint', [userFilename]);
// → ReDoS로 프로세스 블로킹

// 시나리오 2: package.json scripts를 통한 공격
// {
//   "scripts": {
//     "build": "some-cli \"\\\\\\\\\\\\\\\\\\\\\\\\...\""
//   }
// }
// npm run build 시 cross-spawn에서 인자 파싱 중 ReDoS

// 시나리오 3: git hook을 통한 CI/CD DoS
// .husky/pre-commit 에서 악성 인자를 가진 명령 실행
// → commit 시 무한 대기

// 시나리오 4: lint-staged에서 특수 파일명
// 공격자가 특수 문자가 포함된 파일명으로 PR 생성
// → lint-staged 실행 시 cross-spawn ReDoS
```

## 방어 방법

### 즉각 조치
```bash
npm ls cross-spawn
npm install cross-spawn@^7.0.5
npm audit fix
```

```json
{
  "overrides": {
    "cross-spawn": ">=7.0.5"
  }
}
```

### 코드 레벨 방어
```javascript
// 외부 입력을 CLI 인자로 전달 시 사전 검증
function sanitizeArg(arg) {
  // 길이 제한
  if (arg.length > 8192) {
    throw new Error('Argument too long');
  }
  
  // 연속된 백슬래시 제한
  if (/\\{100,}/.test(arg)) {
    throw new Error('Too many consecutive backslashes');
  }
  
  return arg;
}

// 프로세스 실행 시 타임아웃 설정
const { execSync } = require('child_process');
try {
  execSync('command', { timeout: 30000 }); // 30초 타임아웃
} catch (e) {
  if (e.killed) {
    console.error('Process killed due to timeout');
  }
}
```

### 장기 전략
- 사용자 입력이 프로세스 인자로 전달되는 경로를 최소화
- CI 작업에 타임아웃 설정
- 파일명에 대한 검증 레이어 추가
- Windows 환경에서의 추가적인 주의 (cmd.exe 인자 이스케이프)

## 교훈 & 프론트엔드 적용 포인트

1. **크로스 플랫폼의 복잡성**: OS별 쉘 차이를 처리하는 코드는 보안 취약점의 온상
2. **파일명도 입력**: 사용자가 제공하는 파일명(업로드, Git 커밋)도 공격 벡터
3. **프로세스 실행 = 위험**: `child_process`를 사용하는 모든 코드에 타임아웃/검증 필요
4. **npm scripts의 보안**: package.json의 scripts 필드도 보안 감사 대상
5. **DevDependency도 중요**: 개발 의존성의 취약점도 CI/CD를 통해 실질적 피해 가능

## 참고 자료

- [NVD - CVE-2024-21538](https://nvd.nist.gov/vuln/detail/CVE-2024-21538)
- [GitHub Advisory GHSA-3xgq-45jj-v275](https://github.com/advisories/GHSA-3xgq-45jj-v275)
- [cross-spawn GitHub](https://github.com/moxystudio/node-cross-spawn)
- [Snyk Advisory](https://security.snyk.io/vuln/SNYK-JS-CROSSSPAWN-8303230)
