# CVE-2024-4067 - micromatch ReDoS

## 개요

| 항목 | 내용 |
|------|------|
| CVE ID | CVE-2024-4067 |
| CVSS | 7.5 (High) |
| 영향 패키지 | micromatch |
| 영향 버전 | < 4.0.8 |
| 수정 버전 | 4.0.8 |
| 공격 유형 | Regular Expression Denial of Service (ReDoS) |
| 발견일 | 2024-05-14 |

## 왜 프론트엔드 개발자가 알아야 하는가

micromatch는 glob 패턴 매칭 라이브러리로, 프론트엔드 도구 체인의 핵심 인프라:

1. **Vite**: 파일 감시(watch) 및 glob import에서 사용
2. **Jest**: 테스트 파일 패턴 매칭
3. **lint-staged**: 스테이징된 파일 필터링
4. **fast-glob**: 파일 탐색의 핵심 의존성
5. **webpack**: 파일 포함/제외 패턴 처리
6. **ESLint, Prettier**: 파일 패턴 매칭
7. **Storybook**: 스토리 파일 탐색

npm 주간 다운로드 2억+ 건. 프론트엔드 개발 환경에서 glob 패턴을 처리하는 거의 모든 도구가 직간접적으로 의존한다.

## 취약점 기술 분석

micromatch가 glob 패턴을 정규식으로 변환할 때, 특정 패턴에 대해 ReDoS에 취약한 정규식을 생성한다. 특히 중괄호(`{}`) 확장(brace expansion)과 반복 패턴에서 문제가 발생한다.

```javascript
const micromatch = require('micromatch');

// micromatch.isMatch()가 내부적으로 생성하는 정규식이 문제
// 특정 패턴 + 특정 입력 조합에서 역추적 폭발

// 취약한 패턴 예시
const pattern = '{' + '*'.repeat(10) + ','.repeat(10) + '}';

// 이 패턴으로 매칭 시도 시 지수적 역추적
micromatch.isMatch('a'.repeat(100), pattern);
// → CPU 100% 점유, 이벤트 루프 블로킹
```

핵심 원인:
- brace expansion 처리 시 생성되는 정규식에 중첩된 선택지(alternation)
- 매칭 실패 시 모든 선택지 조합을 역추적
- 패턴 복잡도에 대한 제한이 없음

## 공격 시나리오

```javascript
// 시나리오 1: 사용자가 파일 패턴을 입력할 수 있는 설정
// 예: .lintstagedrc, jest.config.js에서 glob 패턴 사용

// lint-staged 설정에 악성 glob 패턴 삽입
// .lintstagedrc.json
// {
//   "{*,*,*,*,*,*,*,*,*,*}": "eslint"
// }

// 시나리오 2: API에서 파일 경로 필터링
const micromatch = require('micromatch');

// 사용자가 파일 검색 패턴을 제공하는 API
app.get('/files', (req, res) => {
  const pattern = req.query.pattern; // 악성 패턴
  const files = getAllFiles();
  
  // 여기서 ReDoS 발생 → 서버 응답 불가
  const matched = micromatch(files, pattern);
  res.json(matched);
});

// 시나리오 3: CI에서의 공격
// PR을 통해 .lintstagedrc 수정 → CI 파이프라인 DoS
// 악성 glob 패턴이 lint-staged 실행 시 CPU 100%
```

## 방어 방법

### 즉각 조치
```bash
npm ls micromatch
npm install micromatch@^4.0.8
npm audit fix
```

```json
{
  "overrides": {
    "micromatch": ">=4.0.8"
  }
}
```

### 코드 레벨 방어
```javascript
// 사용자 입력 패턴에 복잡도 제한
function safeGlobMatch(files, pattern) {
  // 패턴 길이 제한
  if (pattern.length > 200) {
    throw new Error('Pattern too long');
  }
  
  // 위험한 패턴 감지
  const braceCount = (pattern.match(/{/g) || []).length;
  const starCount = (pattern.match(/\*/g) || []).length;
  
  if (braceCount > 3 || starCount > 5) {
    throw new Error('Pattern too complex');
  }
  
  return micromatch(files, pattern);
}

// 또는 타임아웃 래퍼
function matchWithTimeout(files, pattern, timeout = 1000) {
  const start = Date.now();
  const results = [];
  for (const file of files) {
    if (Date.now() - start > timeout) {
      throw new Error('Glob matching timeout');
    }
    if (micromatch.isMatch(file, pattern)) {
      results.push(file);
    }
  }
  return results;
}
```

### 장기 전략
- 사용자가 glob 패턴을 직접 입력하는 기능에서는 화이트리스트 기반 검증
- 설정 파일(lint-staged, jest 등)의 변경을 코드 리뷰에서 주의 깊게 검토
- CI에 실행 시간 제한(timeout) 적용

## 교훈 & 프론트엔드 적용 포인트

1. **도구 설정도 공격 벡터**: lint-staged, jest 등의 설정 파일 변경이 DoS로 이어질 수 있음
2. **Glob 패턴의 복잡도**: 단순해 보이는 glob 패턴도 내부적으로 복잡한 정규식으로 변환됨
3. **입력 복잡도 제한**: 길이뿐 아니라 구조적 복잡도도 제한해야 함
4. **CI 보안**: 외부 기여자의 설정 파일 변경을 자동으로 신뢰하지 않기
5. **Worker 격리**: 복잡한 패턴 매칭은 메인 스레드가 아닌 Worker에서 실행

## 참고 자료

- [NVD - CVE-2024-4067](https://nvd.nist.gov/vuln/detail/CVE-2024-4067)
- [GitHub Advisory GHSA-952p-6rrq-rcjv](https://github.com/advisories/GHSA-952p-6rrq-rcjv)
- [micromatch GitHub](https://github.com/micromatch/micromatch)
- [Snyk Advisory](https://security.snyk.io/vuln/SNYK-JS-MICROMATCH-6838728)
