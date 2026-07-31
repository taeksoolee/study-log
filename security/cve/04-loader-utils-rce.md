# CVE-2022-37601 - webpack loader-utils RCE

## 개요

| 항목 | 내용 |
|------|------|
| CVE ID | CVE-2022-37601 |
| CVSS | 9.8 (Critical) |
| 영향 패키지 | loader-utils |
| 영향 버전 | < 1.4.2, < 2.0.4, 3.x < 3.2.1 |
| 수정 버전 | 1.4.2, 2.0.4, 3.2.1 |
| 공격 유형 | Prototype Pollution → RCE |
| 발견일 | 2022-10-06 |

## 왜 프론트엔드 개발자가 알아야 하는가

`loader-utils`는 webpack 로더 개발의 핵심 유틸리티 패키지다:

1. **webpack 프로젝트 전체**: css-loader, file-loader, url-loader, babel-loader 등 거의 모든 로더가 의존
2. **CRA(Create React App)**: 내부적으로 webpack 사용, loader-utils 포함
3. **Next.js (Pages Router)**: webpack 기반 빌드에서 사용
4. **Vue CLI**: webpack 기반 프로젝트
5. **Storybook**: webpack 기반 빌드 시스템

npm 주간 다운로드 2억+ 건. webpack을 사용하는 사실상 모든 프론트엔드 프로젝트가 영향을 받았다.

## 취약점 기술 분석

`loader-utils`의 `parseQuery()` 함수가 쿼리 문자열을 객체로 파싱할 때, `__proto__` 속성에 대한 필터링 없이 결과 객체에 할당한다.

```javascript
// loader-utils의 parseQuery 내부 로직 (취약 버전)
function parseQuery(query) {
  const result = {};
  // URL 쿼리 파라미터를 파싱하여 객체에 할당
  for (const [key, value] of params) {
    // __proto__ 필터링 없음!
    result[key] = value;
  }
  return result;
}

// webpack 로더에서의 사용
module.exports = function(source) {
  // this.resourceQuery: ?name=file&__proto__[polluted]=true
  const options = loaderUtils.parseQuery(this.resourceQuery);
  // Object.prototype.polluted = true 가 됨
};
```

또한 `interpolateName()` 함수에서도 프로토타입 오염을 통해 파일 경로를 조작하여 RCE로 이어질 수 있다.

## 공격 시나리오

```javascript
// 시나리오: webpack 빌드 시 악성 import 경로를 통한 공격

// 1. 악성 소스 코드에 특수한 import 포함
// import icon from './icon.svg?__proto__[type]=constructor&__proto__[type]=process';

// 2. webpack이 이 import를 처리할 때 loader-utils.parseQuery() 호출
const loaderUtils = require('loader-utils');

// 취약한 parseQuery
const query = '?__proto__[polluted]=yes&__proto__[toString]=polluted';
const parsed = loaderUtils.parseQuery(query);

// 3. Object.prototype이 오염됨
const obj = {};
console.log(obj.polluted); // "yes"

// 4. interpolateName에서의 RCE 경로
// 오염된 프로토타입을 통해 파일명 생성 로직을 조작
// → 임의 코드 실행 가능
```

## 방어 방법

### 즉각 조치
```bash
npm ls loader-utils
npm audit fix

# 강제 업데이트가 필요한 경우
npm install loader-utils@^2.0.4
```

```json
{
  "overrides": {
    "loader-utils": ">=2.0.4"
  }
}
```

### 빌드 환경 방어
```bash
# 의존성 잠금 파일을 항상 커밋
# package-lock.json 또는 yarn.lock을 통해 버전 고정

# CI에서 audit 검사
npm audit --audit-level=critical
```

### 장기 전략
- webpack 5로 마이그레이션 (loader-utils 의존도 감소)
- Vite 등 esbuild 기반 도구로의 전환 고려
- `npm audit` 또는 Snyk를 CI 파이프라인에 통합
- Dependabot/Renovate로 자동 보안 업데이트 PR 생성

## 교훈 & 프론트엔드 적용 포인트

1. **빌드 타임 공격**: 프로덕션 런타임이 아닌 빌드 과정에서도 RCE가 발생할 수 있다
2. **의존성 깊이의 위험**: 직접 설치하지 않아도 간접 의존성이 취약하면 전체가 위험
3. **쿼리 파싱의 보안**: URL 파라미터, 쿼리 문자열 파싱 시 항상 `__proto__` 필터링 필요
4. **모던 도구로의 마이그레이션**: webpack → Vite 전환이 보안 측면에서도 이점

## 참고 자료

- [NVD - CVE-2022-37601](https://nvd.nist.gov/vuln/detail/CVE-2022-37601)
- [GitHub Advisory GHSA-76p3-8jx3-jpfq](https://github.com/advisories/GHSA-76p3-8jx3-jpfq)
- [loader-utils Fix PR](https://github.com/webpack/loader-utils/pull/220)
- [Webpack Blog - Security Advisory](https://webpack.js.org/)
