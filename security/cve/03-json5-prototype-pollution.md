# CVE-2022-46175 - JSON5 Prototype Pollution

## 개요

| 항목 | 내용 |
|------|------|
| CVE ID | CVE-2022-46175 |
| CVSS | 8.8 (High) |
| 영향 패키지 | json5 |
| 영향 버전 | < 2.2.2, < 1.0.2 |
| 수정 버전 | 2.2.2, 1.0.2 |
| 공격 유형 | Prototype Pollution |
| 발견일 | 2022-12-24 |

## 왜 프론트엔드 개발자가 알아야 하는가

JSON5는 프론트엔드 빌드 체인의 핵심 의존성이다:

1. **TypeScript**: `tsconfig.json`은 실제로 JSON5 형식을 지원 (주석, trailing comma)
2. **Babel**: `babel.config.json`이 JSON5로 파싱됨
3. **Webpack**: 설정 파일 내에서 JSON5 로더 사용
4. **ESLint**: 설정 파일에서 JSON5 형식 지원
5. **Parcel**: 내부적으로 JSON5 사용

npm 주간 다운로드 6,000만+ 건. 거의 모든 프론트엔드 프로젝트의 `node_modules`에 존재한다. 빌드 도구가 설정 파일을 파싱할 때 이 라이브러리를 사용하므로, 악의적으로 조작된 설정 파일을 통해 빌드 파이프라인을 오염시킬 수 있다.

## 취약점 기술 분석

JSON5의 `parse()` 함수가 `__proto__` 키를 가진 객체를 파싱할 때, 해당 키-값 쌍을 결과 객체에 그대로 할당한다. 이로 인해 `Object.prototype`이 오염된다.

```javascript
const JSON5 = require('json5');

// 이 문자열을 파싱하면 Object.prototype이 오염됨
const malicious = '{ "__proto__": { "isAdmin": true } }';
const parsed = JSON5.parse(malicious);

// 이후 생성되는 모든 객체가 영향받음
const user = {};
console.log(user.isAdmin); // true ← 프로토타입 오염!
```

핵심 원인:
- `JSON5.parse()`가 반환 객체를 생성할 때 `Object.defineProperty` 대신 직접 할당 사용
- `__proto__`를 일반 키로 처리하여 프로토타입 체인을 오염시킴
- 표준 `JSON.parse()`는 이 문제가 없음 (`__proto__`를 일반 속성으로 안전하게 처리)

## 공격 시나리오

```javascript
// 시나리오: 악성 설정 파일이 포함된 패키지
// 악성 .babelrc (JSON5 형식)
// {
//   "presets": ["@babel/preset-env"],
//   "__proto__": { "polluted": true }
// }

const JSON5 = require('json5');
const fs = require('fs');

// 빌드 도구가 설정 파일을 읽을 때
const config = JSON5.parse(fs.readFileSync('.babelrc', 'utf8'));

// 이후 빌드 과정에서 의도치 않은 동작 유발
const options = {};
console.log(options.polluted); // true - 오염됨!

// 이를 이용해 조건분기 우회, 보안 체크 무력화 가능
if (!options.skipValidation) {
  // 오염으로 이 블록을 건너뛸 수 있음
}
```

## 방어 방법

### 즉각 조치
```bash
npm ls json5
npm install json5@^2.2.2

# 간접 의존성인 경우 (npm 8.3+)
npm audit fix
```

```json
{
  "overrides": {
    "json5": ">=2.2.2"
  }
}
```

### 코드 레벨 방어
```javascript
// JSON5 파싱 결과의 프로토타입 오염 방지
function safeParse(text) {
  const parsed = JSON5.parse(text);
  return JSON.parse(JSON.stringify(parsed));
}

// reviver 함수 사용
function safeParseWithReviver(text) {
  return JSON5.parse(text, (key, value) => {
    if (key === '__proto__') return undefined;
    return value;
  });
}
```

### 장기 전략
- 빌드 도구 의존성을 정기적으로 업데이트하는 Dependabot/Renovate 설정
- CI에서 `npm audit --audit-level=high` 게이트 추가
- 프로토타입 오염을 방지하는 린팅 규칙 적용

## 교훈 & 프론트엔드 적용 포인트

1. **빌드 도구도 공격 표면**: 런타임 코드뿐 아니라 빌드 설정 파일도 공격 벡터가 됨
2. **JSON.parse vs JSON5.parse**: 표준 JSON.parse는 `__proto__`를 안전하게 처리하지만, 서드파티 파서는 그렇지 않을 수 있음
3. **설정 파일도 신뢰하지 마라**: 외부에서 유입되는 설정 파일은 보안 위험
4. **Object.create(null)**: 프로토타입 없는 객체를 딕셔너리로 사용하면 근본적 방어 가능

## 참고 자료

- [NVD - CVE-2022-46175](https://nvd.nist.gov/vuln/detail/CVE-2022-46175)
- [GitHub Advisory GHSA-9c47-m6qq-7p4h](https://github.com/advisories/GHSA-9c47-m6qq-7p4h)
- [JSON5 Fix PR](https://github.com/json5/json5/pull/295)
- [json5 npm page](https://www.npmjs.com/package/json5)
