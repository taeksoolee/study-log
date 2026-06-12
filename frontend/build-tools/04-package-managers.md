# 4. 패키지 매니저 비교

## 목차
1. [패키지 매니저 개요](#1-패키지-매니저-개요)
2. [npm - Node.js 기본 패키지 매니저](#2-npm---nodejs-기본-패키지-매니저)
3. [Yarn Classic (v1) - Facebook의 대안](#3-yarn-classic-v1---facebook의-대안)
4. [Yarn Berry (v2+) - PnP 혁신](#4-yarn-berry-v2---pnp-혁신)
5. [pnpm - 디스크 효율 최적화](#5-pnpm---디스크-효율-최적화)
6. [node_modules 구조 비교](#6-node_modules-구조-비교)
7. [Lock 파일 비교](#7-lock-파일-비교)
8. [Workspace 모노레포 설정](#8-workspace-모노레포-설정)
9. [면접 포인트](#9-면접-포인트)

---

## 1. 패키지 매니저 개요

JavaScript 생태계에서 패키지 매니저는 의존성 설치, 버전 관리, 스크립트 실행을 담당한다.

```
[주요 패키지 매니저 타임라인]
2010: npm v1 출시 (Node.js 기본 탑재)
2016: Yarn Classic (v1) 출시 - Facebook (lock 파일, 병렬 설치 도입)
2017: npm v5 출시 - package-lock.json 도입
2020: Yarn Berry (v2) 출시 - PnP, Zero-installs
2020: pnpm v5 출시 - 심링크 기반 디스크 효율화 대중화
2023: npm v10, pnpm v8 안정화
```

| | npm | Yarn Classic | Yarn Berry | pnpm |
|--|-----|-------------|-----------|------|
| **버전** | 10.x | 1.x | 2~4.x | 8.x |
| **lock 파일** | package-lock.json | yarn.lock | yarn.lock | pnpm-lock.yaml |
| **설치 방식** | 평탄화 | 평탄화 | PnP 또는 node_modules | 심링크 |
| **디스크 효율** | 나쁨 | 나쁨 | 좋음(PnP) | 매우 좋음 |
| **유령 의존성** | 있음 | 있음 | 없음 | 없음 |

---

## 2. npm - Node.js 기본 패키지 매니저

### 특징

npm은 Node.js 설치 시 자동으로 포함되어 별도 설치가 필요 없다.

```bash
# 패키지 설치
npm install react react-dom
npm install --save-dev typescript

# 패키지 제거
npm uninstall lodash

# 특정 버전 설치
npm install react@18.2.0

# package.json의 모든 의존성 설치
npm install

# 스크립트 실행
npm run build
npm start  # start 스크립트는 'run' 생략 가능

# 전역 설치
npm install -g create-react-app

# 캐시 정리
npm cache clean --force
```

### package.json 버전 범위 표기

```json
{
  "dependencies": {
    "react": "^18.2.0",    // ^: 마이너/패치 업데이트 허용 (18.x.x)
    "lodash": "~4.17.21",  // ~: 패치 업데이트만 허용 (4.17.x)
    "axios": "1.4.0",      // 정확한 버전 고정
    "typescript": ">=5.0"  // 5.0 이상
  }
}
```

### npm workspaces (모노레포)

```json
// package.json (루트)
{
  "name": "my-monorepo",
  "workspaces": ["packages/*", "apps/*"]
}
```

```bash
# 특정 workspace에서 명령 실행
npm run build --workspace=packages/ui

# 모든 workspace에서 명령 실행
npm run test --workspaces
```

---

## 3. Yarn Classic (v1) - Facebook의 대안

### 등장 배경

2016년 Facebook이 npm의 문제점(느린 속도, 비결정적 설치, lock 파일 부재)을 해결하기 위해 출시했다.

**npm 대비 개선점**
- **병렬 다운로드**: 패키지를 순차가 아닌 병렬로 다운로드
- **yarn.lock 도입**: 모든 팀원이 동일한 의존성 버전을 사용하도록 보장
- **오프라인 캐시**: 한 번 설치한 패키지는 캐시에서 바로 설치
- **결정적 설치**: 같은 lock 파일이면 항상 동일한 node_modules 구성

```bash
# 설치
npm install -g yarn

# 패키지 설치
yarn add react react-dom
yarn add --dev typescript

# 전체 설치
yarn install  # 또는 그냥 yarn

# 스크립트 실행
yarn build
yarn start
```

### yarn.lock 예시

```yaml
# yarn.lock
react@^18.2.0:
  version "18.2.0"
  resolved "https://registry.yarnpkg.com/react/-/react-18.2.0.tgz#..."
  integrity sha512-...
  dependencies:
    loose-envify "^1.1.0"
```

> Yarn Classic은 현재 유지보수 모드이며, 신규 프로젝트에는 Yarn Berry 또는 pnpm이 권장된다.

---

## 4. Yarn Berry (v2+) - PnP 혁신

### Plug'n'Play(PnP) 모드

Yarn Berry의 핵심 혁신은 **PnP(Plug'n'Play)** 다.
기존 node_modules 폴더를 아예 없애고, `.pnp.cjs` 파일 하나로 의존성 해결을 처리한다.

```
[기존 방식]
패키지 설치 → node_modules에 수천 개 파일 복사 → require 시 파일시스템 탐색

[PnP 방식]
패키지 설치 → .yarn/cache에 zip 파일로 저장 → .pnp.cjs가 경로를 직접 매핑
```

```bash
# Yarn Berry 설치 및 초기화
npm install -g yarn
cd my-project
yarn set version stable  # 또는 yarn set version berry

# PnP 모드 활성화 (기본값)
yarn install

# node_modules 모드로 전환 (호환성 필요 시)
# .yarnrc.yml에 추가:
# nodeLinker: node-modules
```

### .yarnrc.yml 설정

```yaml
# .yarnrc.yml
nodeLinker: pnp           # 'pnp' | 'node-modules' | 'pnpm'

yarnPath: .yarn/releases/yarn-4.0.0.cjs

# 패키지 확장 (잘못된 peer dependency 정의 수정)
packageExtensions:
  "react-beautiful-dnd@*":
    peerDependencies:
      "react-dom": "*"
```

### Zero-Installs

PnP와 함께 `.yarn/cache`를 git에 커밋하면 `yarn install` 없이 바로 실행 가능하다.

```gitignore
# .gitignore - Zero-installs 설정
.yarn/cache        # 이 폴더를 git에 포함 (주석 해제하지 않음)
.yarn/unplugged
.yarn/build-state.yml
.yarn/install-state.gz
.pnp.cjs
.pnp.loader.mjs
```

```gitignore
# Zero-installs 사용 시 .gitignore
.yarn/unplugged
.yarn/build-state.yml
.yarn/install-state.gz
# .yarn/cache는 커밋!
```

### PnP의 장단점

**장점**
- `node_modules` 폴더가 없어 파일 시스템 부담 감소
- 유령 의존성(phantom dependency) 완전 차단
- Zero-installs로 CI 속도 대폭 향상

**단점**
- 일부 도구(Jest, TypeScript Language Server 등)와 호환성 문제
- IDE 플러그인 설정 필요 (VSCode: ZipFS 확장)
- 러닝 커브 존재

---

## 5. pnpm - 디스크 효율 최적화

### 심링크(Symlink) 전략

pnpm은 **콘텐츠 주소 지정 저장소(content-addressable store)** 를 사용해 패키지를 전역에 한 번만 저장하고, 각 프로젝트에는 심링크로 연결한다.

```
[npm/yarn의 문제]
프로젝트 A: node_modules/react (100MB 복사)
프로젝트 B: node_modules/react (100MB 복사)
프로젝트 C: node_modules/react (100MB 복사)
→ 총 300MB 사용

[pnpm의 방식]
~/.pnpm-store/react@18.2.0 (100MB, 한 번만 저장)
프로젝트 A: node_modules/react → 심링크
프로젝트 B: node_modules/react → 심링크
프로젝트 C: node_modules/react → 심링크
→ 총 100MB + 심링크 크기
```

### pnpm의 node_modules 구조

```
node_modules/
├── .pnpm/                          # 실제 파일이 있는 가상 저장소
│   ├── react@18.2.0/
│   │   └── node_modules/
│   │       └── react/              # 실제 파일
│   └── lodash@4.17.21/
│       └── node_modules/
│           └── lodash/
├── react -> .pnpm/react@18.2.0/node_modules/react  # 심링크
└── lodash -> .pnpm/lodash@4.17.21/node_modules/lodash
```

이 구조 덕분에 **직접 설치한 패키지만** 최상위 node_modules에서 접근 가능하다.
→ 유령 의존성(phantom dependency) 문제 해결

```bash
# pnpm 설치
npm install -g pnpm

# 패키지 설치
pnpm add react react-dom
pnpm add --save-dev typescript

# 전체 설치
pnpm install

# 스크립트 실행
pnpm run build
pnpm build  # run 생략 가능

# 저장소 경로 확인
pnpm store path
```

### .npmrc로 pnpm 동작 제어

```ini
# .npmrc
# 유령 의존성 접근 허용 여부 (기본: false)
shamefully-hoist=false

# 모든 패키지를 최상위로 호이스팅 (npm 방식, 권장하지 않음)
# shamefully-hoist=true

# peer dependency 자동 설치
auto-install-peers=true
```

---

## 6. node_modules 구조 비교

### 유령 의존성(Phantom Dependency) 문제

npm과 Yarn Classic은 의존성 트리를 **평탄화(flatten)** 하여 중복을 줄인다.
이 과정에서 내가 직접 설치하지 않은 패키지도 node_modules 최상위에 올라온다.

```
[예: A@1.0 → B@1.0 → C@1.0 의존]

npm 설치 후 node_modules:
├── A/
├── B/      ← A의 의존성이지만 최상위에 노출
└── C/      ← B의 의존성이지만 최상위에 노출

→ 내 코드에서 import C 가 동작함 (C를 직접 설치하지 않았는데!)
→ C를 업그레이드하지 않았을 때 갑자기 동작 안 할 수 있음
```

```
[pnpm / Yarn Berry PnP]
node_modules:
└── A/      ← 직접 설치한 것만 접근 가능

→ import B, import C 하면 에러 발생 (의도한 동작)
→ 필요하면 명시적으로 설치해야 함
```

---

## 7. Lock 파일 비교

lock 파일은 **팀 전체가 동일한 의존성 버전을 사용**하도록 보장하며, 반드시 git에 커밋해야 한다.

```bash
# package-lock.json (npm)
# → npm install로 생성/갱신
# → 매우 상세하고 파일 크기가 큼

# yarn.lock (Yarn)
# → yarn install로 생성/갱신
# → 사람이 읽기 쉬운 커스텀 형식

# pnpm-lock.yaml (pnpm)
# → pnpm install로 생성/갱신
# → YAML 형식, 의존성 구조가 명확
```

```json
// package-lock.json (npm) - 일부 예시
{
  "name": "my-app",
  "lockfileVersion": 3,
  "requires": true,
  "packages": {
    "node_modules/react": {
      "version": "18.2.0",
      "resolved": "https://registry.npmjs.org/react/-/react-18.2.0.tgz",
      "integrity": "sha512-...",
      "dependencies": {
        "loose-envify": "^1.1.0"
      }
    }
  }
}
```

```yaml
# pnpm-lock.yaml - 일부 예시
lockfileVersion: '6.0'

dependencies:
  react:
    specifier: ^18.2.0
    version: 18.2.0

packages:
  /react@18.2.0:
    resolution: {integrity: sha512-...}
    dependencies:
      loose-envify: ^1.1.0
    dev: false
```

---

## 8. Workspace 모노레포 설정

모든 주요 패키지 매니저는 workspace 기능으로 모노레포를 지원한다.

### npm workspaces

```json
// package.json (루트)
{
  "name": "my-monorepo",
  "private": true,
  "workspaces": [
    "packages/*",
    "apps/*"
  ]
}
```

### pnpm workspaces

```yaml
# pnpm-workspace.yaml (루트에 별도 파일로 관리)
packages:
  - 'packages/*'
  - 'apps/*'
  - '!**/test/**'  # 제외 패턴
```

```json
// packages/ui/package.json
{
  "name": "@myorg/ui",
  "version": "1.0.0"
}

// apps/web/package.json
{
  "name": "@myorg/web",
  "dependencies": {
    "@myorg/ui": "workspace:*"  // workspace 패키지 참조
  }
}
```

```bash
# pnpm workspace 명령
pnpm add @myorg/ui --filter @myorg/web  # 특정 패키지에 의존성 추가
pnpm run build --filter @myorg/ui       # 특정 패키지에서 실행
pnpm run build --filter @myorg/web...   # 해당 패키지와 의존하는 모든 패키지에서 실행
pnpm -r run test                        # 모든 패키지에서 실행 (recursive)
```

### Yarn Berry workspaces

```json
// package.json (루트)
{
  "workspaces": ["packages/*", "apps/*"]
}
```

```bash
yarn workspace @myorg/ui add lodash
yarn workspaces foreach run build
```

---

## 9. 면접 포인트

### Q1. npm, Yarn, pnpm의 핵심 차이점은 무엇인가요?

**npm**: Node.js 기본 탑재. `package-lock.json`으로 버전 고정. 평탄화된 node_modules로 유령 의존성 문제가 있습니다.

**Yarn Classic**: npm보다 빠른 병렬 설치와 `yarn.lock` 도입. 현재는 유지보수 모드입니다.

**Yarn Berry(PnP)**: node_modules를 없애고 `.pnp.cjs` 매핑 파일로 의존성 해결. Zero-installs 가능하지만 도구 호환성 이슈가 있습니다.

**pnpm**: 전역 콘텐츠 주소 저장소에 패키지를 한 번만 저장하고 심링크로 연결. 디스크 절약, 유령 의존성 차단, 빠른 설치가 강점입니다.

---

### Q2. 유령 의존성(Phantom Dependency)이 왜 문제인가요?

유령 의존성이란 **직접 설치하지 않았는데 사용할 수 있는 패키지**를 뜻합니다. npm/Yarn의 평탄화 전략 때문에 발생합니다.

문제점:
1. **예측 불가능성**: 내가 의존하는 패키지가 자신의 의존성 버전을 바꾸면 내 코드도 영향받습니다.
2. **묵시적 의존**: 명시적으로 설치하지 않았으므로 package.json에 기록이 없고, 팀원마다 다른 버전을 사용할 수 있습니다.

pnpm과 Yarn Berry PnP는 직접 설치한 패키지만 접근 가능하게 하여 이 문제를 근본적으로 해결합니다.

---

### Q3. pnpm의 심링크 전략을 설명해주세요.

pnpm은 패키지를 `~/.pnpm-store`에 **콘텐츠 해시 기반으로 한 번만 저장**합니다. 여러 프로젝트에서 같은 버전의 패키지를 사용할 때 파일을 복사하지 않고 **하드링크(hard link)** 로 연결합니다.

프로젝트의 `node_modules`에는 직접 의존성만 심링크로 노출하고, 중첩 의존성은 `node_modules/.pnpm/` 내부에 격리합니다.

이를 통해 다음을 달성합니다.
- 디스크 공간 절약 (100개 프로젝트가 같은 react를 써도 저장은 1번)
- 유령 의존성 차단 (직접 설치한 것만 접근 가능)
- 빠른 설치 (이미 저장된 파일은 링크만 생성)

---

### Q4. lock 파일을 git에 커밋해야 하는 이유는?

lock 파일은 **의존성 트리의 정확한 스냅샷**입니다. 커밋하지 않으면 팀원마다, CI마다 `npm install` 시점에 최신 버전을 받아 **서로 다른 버전의 패키지를 사용**하게 됩니다.

예: `"react": "^18.0.0"` 명시 시 18.0.0~18.x.x 어느 버전이나 설치될 수 있음. lock 파일이 있으면 항상 동일한 버전(예: 18.2.0)이 설치됨.

라이브러리(npm 배포용) 패키지에서는 소비자의 환경을 방해하지 않도록 lock 파일을 커밋하지 않는 것이 일반적입니다.
