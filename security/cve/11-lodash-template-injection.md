# CVE-2021-23337 - Lodash Template Command Injection

## 개요

| 항목 | 내용 |
|------|------|
| CVE ID | CVE-2021-23337 |
| CVSS | 7.2 (High) |
| 영향 패키지 | lodash |
| 영향 버전 | < 4.17.21 |
| 수정 버전 | 4.17.21 |
| 공격 유형 | Command Injection / RCE |
| 발견일 | 2021-02-15 |

## 왜 프론트엔드 개발자가 알아야 하는가

lodash는 npm에서 가장 많이 다운로드되는 유틸리티 라이브러리 중 하나다. 많은 프로젝트에서 직접 또는 간접 의존성으로 사용되며, `_.template()` 함수는 서버사이드 렌더링이나 이메일 템플릿 생성 등에서 활용된다.

특히 SSR 환경이나 Node.js BFF에서 사용자 입력을 `_.template()`의 옵션으로 전달하는 경우, 서버에서 임의 코드 실행이 가능해진다.

## 취약점 기술 분석

`_.template()` 함수는 JavaScript 템플릿 문자열을 컴파일하여 함수를 생성한다. 이때 `variable` 옵션에 사용자 입력이 주입되면, 생성되는 함수의 매개변수명에 임의 코드를 삽입할 수 있다.

내부적으로 lodash는 `Function` 생성자를 사용하여 템플릿 함수를 만든다:

```javascript
// lodash 내부 구현 (단순화)
function template(string, options) {
  const variable = options.variable; // 사용자 제어 가능!
  // variable이 Function 생성자의 매개변수명으로 직접 삽입됨
  const result = Function(variable, 'return ' + source);
  return result;
}
```

`variable` 옵션에 대한 적절한 검증 없이 `Function()` 생성자에 전달되어 임의 코드 실행이 가능하다.

## 공격 시나리오

```javascript
const _ = require('lodash');

// 취약한 코드: 사용자 입력이 variable 옵션으로 전달됨
const userInput = 'a]){return process.mainModule.require("child_process").execSync("id")}//';

const compiled = _.template('Hello <%= name %>', {
  variable: userInput
});

// 템플릿 함수 실행 시 시스템 명령어가 실행됨
compiled({ name: 'world' });
// → 서버에서 `id` 명령어가 실행됨
```

## 방어 방법

### 즉시 조치
```bash
npm install lodash@4.17.21
npm audit fix
```

### 코드 레벨 방어
```javascript
// ❌ 위험: 사용자 입력을 variable 옵션에 전달
_.template(tmpl, { variable: req.body.varName });

// ✅ 안전: variable 옵션을 하드코딩
_.template(tmpl, { variable: 'data' });

// ✅ 더 안전: lodash template 대신 안전한 대안 사용
// - handlebars, mustache 등 로직-less 템플릿 엔진
// - ES6 템플릿 리터럴 (정적 문자열만)
```

### 장기 전략
- `lodash` 전체 대신 개별 함수만 설치하거나 네이티브 JS 대체
- `npm audit`를 CI/CD 파이프라인에 필수 포함
- `Function()`, `eval()` 사용 라이브러리에 대한 코드 리뷰 강화

## 교훈 & 프론트엔드 적용 포인트

1. **동적 코드 생성은 항상 위험하다**: `Function()`, `eval()`을 사용하는 라이브러리는 주입 공격에 취약할 수 있다.
2. **유틸리티 라이브러리도 공격 표면이다**: "안전한 유틸리티"라는 인식이 보안 검토를 건너뛰게 만든다.
3. **최소 권한 원칙**: BFF/SSR 서버의 프로세스 권한을 최소화하라.
4. **의존성 최소화**: lodash 전체 설치 대신 필요한 함수만 사용하거나 네이티브 대안을 검토하라.

## 참고 자료

- [NVD - CVE-2021-23337](https://nvd.nist.gov/vuln/detail/CVE-2021-23337)
- [GitHub Advisory - GHSA-35jh-r3h4-6jhm](https://github.com/advisories/GHSA-35jh-r3h4-6jhm)
- [Snyk - SNYK-JS-LODASH-1040724](https://snyk.io/vuln/SNYK-JS-LODASH-1040724)
- [lodash 4.17.21 Release](https://github.com/lodash/lodash/releases/tag/4.17.21)
