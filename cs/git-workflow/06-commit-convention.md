# 6. 커밋 컨벤션

## 목차

1. [좋은 커밋 메시지의 중요성](#1-좋은-커밋-메시지의-중요성)
2. [Conventional Commits 스펙](#2-conventional-commits-스펙)
3. [BREAKING CHANGE](#3-breaking-change)
4. [Scope 사용법](#4-scope-사용법)
5. [멀티라인 커밋 메시지 (body, footer)](#5-멀티라인-커밋-메시지-body-footer)
6. [commitlint 설정](#6-commitlint-설정)
7. [husky 연동](#7-husky-연동)
8. [Changelog 자동 생성](#8-changelog-자동-생성)
9. [좋은 예 vs 나쁜 예 비교](#9-좋은-예-vs-나쁜-예-비교)
10. [면접 포인트](#10-면접-포인트)

---

## 1. 좋은 커밋 메시지의 중요성

커밋 메시지는 단순한 로그가 아니라 **코드베이스의 역사(history)**다. 잘 작성된 커밋 메시지는 다음과 같은 실질적인 이점을 제공한다.

### 왜 중요한가

1. **디버깅 시 원인 추적**
   - `git log --oneline`으로 빠르게 문제가 도입된 커밋을 찾을 수 있다.
   - `git bisect`와 함께 사용하면 버그 도입 시점을 정밀하게 추적할 수 있다.

2. **코드 리뷰 효율화**
   - 리뷰어가 변경의 의도를 이해하는 데 걸리는 시간이 줄어든다.
   - "왜 이렇게 바꿨나요?"라는 질문을 커밋 메시지가 미리 답한다.

3. **자동화 도구와 연동**
   - Conventional Commits 형식을 지키면 Changelog 자동 생성, 자동 버전 업이 가능하다.
   - CI/CD에서 커밋 타입에 따라 다른 파이프라인을 실행할 수 있다.

4. **신규 팀원 온보딩**
   - 커밋 히스토리가 곧 프로젝트의 진화 과정 문서가 된다.
   - 특정 기능이 왜, 언제, 어떻게 추가되었는지 추적할 수 있다.

### 나쁜 커밋 메시지의 실제 비용

```bash
# 이런 커밋 히스토리에서는 아무것도 알 수 없다
git log --oneline
a3f2c1d fix
b8e9d2c update
c7f4a3b wip
d2c8b1a asdf
e9a3f2c 수정
```

---

## 2. Conventional Commits 스펙

Conventional Commits는 커밋 메시지에 사람과 기계 모두 읽을 수 있는 의미를 부여하는 명세다. ([conventionalcommits.org](https://www.conventionalcommits.org))

### 기본 형식

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

- `type`: 커밋의 종류 (필수)
- `scope`: 변경 범위 (선택)
- `description`: 변경 내용 요약 (필수, 소문자 시작, 마침표 없음)
- `body`: 상세 설명 (선택, 빈 줄로 구분)
- `footer`: 메타데이터 (선택, 빈 줄로 구분)

### 타입(Type) 목록

| 타입 | 설명 | 예시 |
|---|---|---|
| `feat` | 새로운 기능 추가 | 로그인 기능, 새 API 엔드포인트 |
| `fix` | 버그 수정 | null pointer 오류 수정, 잘못된 계산 수정 |
| `docs` | 문서 변경 (코드 변경 없음) | README 수정, 주석 추가 |
| `style` | 코드 포맷팅 변경 (기능 변경 없음) | 들여쓰기, 세미콜론, 공백 정리 |
| `refactor` | 리팩터링 (기능 변경 없음, 버그 수정 아님) | 함수 분리, 변수명 변경 |
| `test` | 테스트 추가 또는 수정 | 단위 테스트, 통합 테스트 추가 |
| `chore` | 빌드 프로세스, 도구 설정 변경 | 패키지 업데이트, .gitignore 수정 |
| `build` | 빌드 시스템 또는 외부 의존성 변경 | webpack, npm 설정 변경 |
| `ci` | CI 설정 변경 | GitHub Actions, CircleCI 설정 |
| `perf` | 성능 개선 | 쿼리 최적화, 캐싱 추가 |
| `revert` | 이전 커밋 되돌리기 | revert "feat(auth): 소셜 로그인 추가" |

### 예시 메시지들

```bash
# 기능 추가
feat: 사용자 이메일 인증 기능 추가

# 버그 수정
fix: 결제 금액 소수점 계산 오류 수정

# 문서 업데이트
docs: API 응답 형식 명세 추가

# 스타일 정리 (eslint 자동 수정)
style: eslint --fix 적용

# 리팩터링
refactor: 사용자 인증 로직을 AuthService로 분리

# 테스트 추가
test: 장바구니 금액 계산 단위 테스트 추가

# 빌드 설정 변경
chore: lodash 4.17.21로 업그레이드

# CI 설정 변경
ci: main 브랜치 push 시 자동 배포 워크플로우 추가

# 성능 개선
perf: 상품 목록 조회 N+1 쿼리 문제 해결
```

---

## 3. BREAKING CHANGE

하위 호환성이 깨지는 변경 사항은 반드시 명시해야 한다. 이를 통해 자동화 도구가 메이저 버전(v1 → v2)을 올린다.

### 방법 1: 느낌표(!) 표기

```bash
# type 뒤에 !를 붙여 BREAKING CHANGE를 간결하게 표시
feat!: 사용자 인증 방식을 세션에서 JWT로 변경

fix!: 결제 API 응답 형식 변경 (amount 필드 타입 변경)

refactor(api)!: REST API v1 제거, v2로 완전 전환
```

### 방법 2: footer에 BREAKING CHANGE 명시 (더 상세한 설명 가능)

```
feat(auth): JWT 기반 인증으로 전환

기존 세션 기반 인증에서 JWT 기반 인증으로 전환합니다.
모든 API 클라이언트는 요청 헤더를 업데이트해야 합니다.

BREAKING CHANGE: Authorization 헤더 형식 변경
이전: Authorization: Session <session_id>
이후: Authorization: Bearer <jwt_token>
```

### 방법 3: ! 와 footer 동시 사용 (명시성 최대화)

```
feat(api)!: 페이지네이션 파라미터 이름 변경

BREAKING CHANGE: page, per_page 파라미터가 각각
cursor, limit으로 변경되었습니다.
기존 클라이언트는 반드시 파라미터명을 업데이트해야 합니다.
```

---

## 4. Scope 사용법

scope는 변경이 영향을 미치는 **범위(모듈, 컴포넌트, 파일)**를 나타낸다.

### 프론트엔드 프로젝트 scope 예시

```bash
feat(auth): 소셜 로그인 버튼 추가
fix(cart): 수량 변경 시 합계 금액 미갱신 버그 수정
style(header): 모바일 반응형 레이아웃 수정
refactor(api): axios 인스턴스 공통 설정 분리
test(checkout): 결제 흐름 E2E 테스트 추가
```

### 백엔드 프로젝트 scope 예시

```bash
feat(user): 사용자 프로필 이미지 업로드 API 추가
fix(payment): 중복 결제 방지 로직 수정
perf(search): Elasticsearch 쿼리 최적화
build(docker): 멀티 스테이지 빌드로 이미지 크기 감소
ci(deploy): 스테이징 환경 자동 배포 파이프라인 추가
```

### 모노레포(monorepo) scope 예시

```bash
feat(web): 대시보드 차트 컴포넌트 추가
fix(api): 인증 미들웨어 토큰 검증 오류 수정
chore(shared): 공통 타입 정의 패키지 버전 업데이트
```

### scope 네이밍 권장사항

- 소문자, 단수형 사용 (`users` 대신 `user`)
- 프로젝트 팀 내에서 일관된 scope 목록을 README에 문서화한다.
- 너무 세분화하거나 너무 광범위하지 않게 적절한 단위로 정한다.

---

## 5. 멀티라인 커밋 메시지 (body, footer)

### 구조

```
제목 (type[scope]: description)
                          ← 빈 줄 필수
본문 (body)
                          ← 빈 줄 필수
꼬리말 (footer)
```

### body 작성 가이드

- 무엇을 변경했는지보다 **왜** 변경했는지를 설명한다.
- 72자 이내로 줄바꿈한다.
- 현재 시제, 명령문 형식 사용 ("변경했음" 보다 "변경함" 또는 "변경한다")

### 실제 예시

```
refactor(auth): 토큰 갱신 로직을 미들웨어로 분리

기존에는 각 API 핸들러에서 개별적으로 토큰 만료를 확인했는데,
이로 인해 동일한 코드가 15개 파일에 중복되어 있었음.

토큰 갱신 책임을 단일 미들웨어로 집중시켜
유지보수성을 높이고 코드 중복을 제거함.

Refs #89
```

### footer 형식

```
fix(payment): 카드 결제 실패 시 환불 누락 버그 수정

간헐적으로 결제 실패 응답을 받아도 트랜잭션이 롤백되지
않아 사용자 계좌에서 금액이 차감되는 문제가 있었음.

결제 실패 응답 코드(400, 500)에 대한 예외 처리 로직을
추가하고, 트랜잭션 롤백을 명시적으로 호출하도록 수정함.

Closes #123
Reviewed-by: 김철수 <chulsoo@example.com>
BREAKING CHANGE: 결제 실패 응답 형식이 변경됨
```

- `Closes #이슈번호`: MR merge 시 해당 이슈 자동 Close
- `Refs #이슈번호`: 이슈와 연관만 시키고 Close는 하지 않음
- `Reviewed-by`: 리뷰어 명시
- `Co-authored-by`: 공동 작업자 명시

---

## 6. commitlint 설정

commitlint는 커밋 메시지가 규칙을 지키는지 자동으로 검사하는 도구다.

### 설치

```bash
# commitlint CLI와 Conventional Commits 설정 패키지 설치
npm install --save-dev @commitlint/cli @commitlint/config-conventional
```

### `.commitlintrc.js` 설정 예시

```javascript
// .commitlintrc.js
module.exports = {
  // Conventional Commits 기본 규칙 상속
  extends: ['@commitlint/config-conventional'],

  // 프로젝트 커스텀 규칙
  rules: {
    // 허용할 type 목록 지정 (기본값에 custom 추가 가능)
    'type-enum': [
      2,  // level: 0=disable, 1=warn, 2=error
      'always',
      [
        'feat',
        'fix',
        'docs',
        'style',
        'refactor',
        'test',
        'chore',
        'build',
        'ci',
        'perf',
        'revert',
        'hotfix',  // 커스텀 타입 추가
      ],
    ],

    // scope 허용 목록 지정 (없으면 모든 scope 허용)
    'scope-enum': [
      1,  // warn 수준
      'always',
      ['auth', 'user', 'payment', 'cart', 'api', 'ui', 'config'],
    ],

    // 제목 최대 길이
    'header-max-length': [2, 'always', 100],

    // 제목 마침표 금지
    'subject-full-stop': [2, 'never', '.'],

    // 제목 첫 글자 소문자 (한글 사용 시 비활성화 가능)
    // 'subject-case': [2, 'always', 'lower-case'],
    'subject-case': [0],  // 한국어 프로젝트에서는 비활성화
  },
};
```

### 검사 실행

```bash
# 가장 최근 커밋 메시지 검사
npx commitlint --from HEAD~1 --to HEAD --verbose

# 특정 메시지 직접 검사
echo "feat: 새 기능 추가" | npx commitlint

# 잘못된 메시지 검사 (에러 출력 확인)
echo "수정함" | npx commitlint
# ✖ subject may not be empty [subject-empty]
# ✖ type may not be empty [type-empty]
```

---

## 7. husky 연동

husky는 Git hooks를 손쉽게 설정할 수 있는 도구다. `commit-msg` hook을 설정하면 커밋 시 commitlint가 자동으로 실행된다.

### 설치 및 초기화

```bash
# husky 설치
npm install --save-dev husky

# husky 초기화 (package.json에 prepare 스크립트 추가)
npx husky init
```

### `commit-msg` hook 설정

```bash
# .husky/commit-msg 파일 생성
echo "npx --no -- commitlint --edit \$1" > .husky/commit-msg
chmod +x .husky/commit-msg
```

```bash
# .husky/commit-msg 내용 확인
cat .husky/commit-msg
# #!/usr/bin/env sh
# . "$(dirname -- "$0")/_/husky.sh"
# npx --no -- commitlint --edit $1
```

### `pre-commit` hook 설정 (lint-staged 연동)

```bash
# lint-staged 설치 (커밋 대상 파일만 lint 실행)
npm install --save-dev lint-staged
```

```javascript
// package.json
{
  "lint-staged": {
    "*.{js,jsx,ts,tsx}": [
      "eslint --fix",
      "prettier --write"
    ],
    "*.{css,scss}": [
      "prettier --write"
    ]
  }
}
```

```bash
# .husky/pre-commit 설정
echo "npx lint-staged" > .husky/pre-commit
chmod +x .husky/pre-commit
```

### 동작 확인

```bash
# 잘못된 커밋 메시지로 커밋 시도
git commit -m "수정"

# 출력 예시
# ⧗  input: 수정
# ✖  subject may not be empty [subject-empty]
# ✖  type may not be empty [type-empty]
# ✖  found 2 problems, 0 warnings
# husky - commit-msg hook exited with code 1 (error)
```

---

## 8. Changelog 자동 생성

Conventional Commits 형식으로 커밋하면 Changelog를 자동으로 생성하고 버전을 자동으로 올릴 수 있다.

### standard-version

```bash
# 설치
npm install --save-dev standard-version

# package.json scripts에 추가
{
  "scripts": {
    "release": "standard-version",
    "release:minor": "standard-version --release-as minor",
    "release:major": "standard-version --release-as major",
    "release:patch": "standard-version --release-as patch"
  }
}
```

```bash
# 릴리즈 실행 (버전 자동 결정)
npm run release

# 동작 순서:
# 1. 마지막 태그 이후의 커밋을 분석
# 2. feat → minor 버전 업, fix → patch 버전 업, BREAKING CHANGE → major 버전 업
# 3. package.json의 version 업데이트
# 4. CHANGELOG.md 생성/업데이트
# 5. 버전 태그 생성 (예: v1.2.0)
```

### 생성되는 CHANGELOG.md 예시

```markdown
# Changelog

## [1.2.0] - 2024-01-15

### Features
- **auth:** 소셜 로그인 버튼 추가 ([#42](issue링크))
- **cart:** 장바구니 저장 기능 추가 ([#55](issue링크))

### Bug Fixes
- **payment:** 카드 결제 실패 시 환불 누락 수정 ([#60](issue링크))
- **user:** 프로필 이미지 업로드 오류 수정 ([#63](issue링크))

### Performance Improvements
- **search:** Elasticsearch 쿼리 최적화 ([#70](issue링크))

## [1.1.0] - 2024-01-01
...
```

### semantic-release와의 차이점

| 항목 | standard-version | semantic-release |
|---|---|---|
| 실행 방식 | 로컬에서 수동 실행 | CI/CD에서 자동 실행 |
| npm publish | 수동 | 자동 (설정 시) |
| GitHub Release | 수동 생성 | 자동 생성 |
- 복잡도 | 낮음 (설정 간단) | 높음 (플러그인 구성 필요) |
| 적합한 경우 | 소규모, 수동 릴리즈 선호 | CI/CD 완전 자동화 지향 |

```bash
# semantic-release 예시 - CI 환경에서 자동 실행
# .releaserc.json
{
  "branches": ["main"],
  "plugins": [
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
    "@semantic-release/changelog",
    "@semantic-release/npm",
    "@semantic-release/github"
  ]
}
```

---

## 9. 좋은 예 vs 나쁜 예 비교

### 제목(subject) 비교

| 나쁜 예 | 좋은 예 | 이유 |
|---|---|---|
| `수정` | `fix(auth): 토큰 만료 시 로그인 페이지 미리다이렉트 버그 수정` | type과 변경 내용이 명확함 |
| `update api` | `feat(api): 상품 검색 필터 엔드포인트 추가` | feat/update 의미 구분, scope 포함 |
| `wip` | `refactor(user): 사용자 서비스 레이어 분리 (미완성)` | Draft PR 사용하거나 진행 상태 명시 |
| `버그 픽스` | `fix(payment): 중복 결제 요청 방지 로직 추가` | type, scope, 구체적 설명 포함 |
| `feat: 기능 추가.` | `feat(cart): 위시리스트에서 장바구니 담기 기능 추가` | 마침표 제거, scope 추가, 구체화 |

### body 비교

나쁜 예:
```
fix: 버그 수정

파일 수정함
```

좋은 예:
```
fix(checkout): 쿠폰 적용 후 최종 금액 음수 오류 수정

쿠폰 할인 금액이 상품 금액보다 클 경우 최종 결제 금액이
음수로 계산되는 버그가 있었음.

할인 금액이 상품 금액을 초과하지 못하도록 Math.max(0, ...)
처리를 추가하고, 해당 케이스에 대한 단위 테스트를 함께 작성함.

Closes #88
```

### 자주 저지르는 실수 모음

```bash
# 실수 1: 여러 변경을 하나의 커밋에 몰아넣기
feat: 로그인, 회원가입, 프로필 수정, 비밀번호 변경 기능 추가
# → 각 기능별로 별도 커밋으로 분리해야 함

# 실수 2: 과거 시제 사용
feat(auth): 로그인 기능을 추가했음
# → "추가" 또는 "추가함" (명령/현재 시제 권장)

# 실수 3: 코드 변경 없는 커밋에 feat/fix 사용
feat: README 업데이트
# → docs: README에 배포 방법 섹션 추가

# 실수 4: scope에 파일 경로 사용
fix(src/components/auth/Login.jsx): 버튼 클릭 오류 수정
# → fix(auth): 로그인 버튼 클릭 이벤트 누락 오류 수정

# 실수 5: 제목에 마침표
feat(user): 회원 탈퇴 기능 추가.
# → feat(user): 회원 탈퇴 기능 추가
```

---

## 10. 면접 포인트

**Q1. Conventional Commits를 사용하는 이유는 무엇인가요?**

> Conventional Commits는 커밋 메시지에 구조화된 형식을 부여하여 사람과 자동화 도구 모두 의미를 파악할 수 있게 합니다. 이를 통해 Changelog 자동 생성, 시맨틱 버전 자동 결정, CI/CD 파이프라인 조건 분기 등 다양한 자동화가 가능해집니다.

**Q2. BREAKING CHANGE를 커밋에 표시하는 방법은 무엇인가요?**

> 두 가지 방법이 있습니다. 첫째, `feat!:` 또는 `fix(api)!:`와 같이 type 뒤에 느낌표를 붙이는 간결한 방식입니다. 둘째, 커밋 메시지 footer에 `BREAKING CHANGE: 변경 내용`을 명시하는 상세한 방식입니다. 두 방법을 동시에 사용하여 표시와 설명을 모두 제공할 수도 있습니다.

**Q3. commitlint와 husky는 어떻게 함께 사용하나요?**

> husky는 Git hooks를 설정하는 도구이고, commitlint는 커밋 메시지 규칙을 검사하는 도구입니다. husky의 `commit-msg` hook에 commitlint 실행 명령을 등록하면, 개발자가 `git commit`을 실행할 때마다 commitlint가 자동으로 메시지를 검사하여 규칙에 맞지 않으면 커밋을 차단합니다.

**Q4. standard-version과 semantic-release의 차이점은 무엇인가요?**

> standard-version은 개발자가 로컬에서 수동으로 실행하는 도구로, 버전 업, CHANGELOG 생성, 태그 생성을 처리합니다. semantic-release는 CI/CD 환경에서 완전 자동으로 실행되며, npm 배포와 GitHub Release 생성까지 자동화합니다. 자동화 수준과 설정 복잡도에서 차이가 있으며, semantic-release가 더 완전한 자동화를 제공합니다.

**Q5. feat과 fix의 차이, style과 refactor의 차이를 설명해주세요.**

> `feat`은 사용자가 인지할 수 있는 새로운 기능 추가이고, `fix`는 기존 기능의 버그를 수정하는 것입니다. `style`은 코드의 동작에 영향을 주지 않는 포맷팅 변경(공백, 세미콜론 등)이고, `refactor`는 기능을 바꾸거나 버그를 수정하지 않으면서 코드 구조를 개선하는 것입니다. `fix`와 `refactor`의 차이는 버그 수정 여부이고, `style`과 `refactor`의 차이는 코드 로직 변경 여부입니다.

**Q6. 커밋 메시지에서 body를 작성할 때 가장 중요한 원칙은 무엇인가요?**

> "무엇을 변경했는가(what)"보다 "왜 변경했는가(why)"를 설명하는 것이 가장 중요합니다. "무엇"은 코드 diff를 보면 알 수 있지만, "왜"는 개발자의 의도와 당시의 맥락을 모르면 알 수 없습니다. 6개월 후의 동료(또는 미래의 자신)가 이 결정을 이해할 수 있도록 작성해야 합니다.

**Q7. scope는 어떤 기준으로 정하는 것이 좋은가요?**

> scope는 변경이 영향을 미치는 모듈, 도메인, 또는 컴포넌트 단위로 정합니다. 너무 세분화(파일 경로 수준)하거나 너무 광범위(프로젝트 전체)하지 않게 적절한 단위를 정하고, 팀 내에서 허용 scope 목록을 합의하여 README나 `.commitlintrc.js`에 문서화하는 것이 좋습니다. 일관성이 가장 중요합니다.
