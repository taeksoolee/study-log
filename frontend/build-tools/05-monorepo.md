# 5. 모노레포 (Monorepo)

## 목차
1. [모노레포 개념과 장단점](#1-모노레포-개념과-장단점)
2. [모노레포 vs 폴리레포](#2-모노레포-vs-폴리레포)
3. [Turborepo - 캐싱과 병렬 실행](#3-turborepo---캐싱과-병렬-실행)
4. [Nx - 의존성 그래프와 affected 명령](#4-nx---의존성-그래프와-affected-명령)
5. [Workspace 패키지 구조 예제](#5-workspace-패키지-구조-예제)
6. [모노레포 도구 선택 가이드](#6-모노레포-도구-선택-가이드)
7. [면접 포인트](#7-면접-포인트)

---

## 1. 모노레포 개념과 장단점

### 모노레포(Monorepo)란?

모노레포(Monorepo, Monolithic Repository)는 **여러 프로젝트/패키지를 하나의 git 저장소에서 관리**하는 방식이다.

```
[모노레포 구조 예시]
my-company/
├── apps/
│   ├── web/          → Next.js 웹 앱
│   ├── mobile/       → React Native 앱
│   └── admin/        → 관리자 대시보드
├── packages/
│   ├── ui/           → 공통 UI 컴포넌트
│   ├── utils/        → 공통 유틸리티
│   ├── config/       → 공통 설정 (ESLint, TSConfig)
│   └── api-client/   → API 클라이언트
├── package.json      → 루트 (private: true)
└── turbo.json / nx.json
```

### 장점

**1. 코드 재사용**
공통 로직을 패키지로 분리하고 모든 앱이 참조. 중복 코드 제거.

**2. 원자적 변경(Atomic Change)**
API 변경 시 API 패키지와 사용하는 모든 앱을 하나의 PR에서 동시에 변경 가능.

**3. 의존성 통합 관리**
모든 패키지가 같은 버전의 React, TypeScript 등을 사용하도록 강제 가능.

**4. 도구/설정 통일**
ESLint, Prettier, TypeScript 설정을 루트에서 관리하여 팀 전체 일관성 유지.

**5. 테스트 가시성**
변경이 영향 미치는 범위를 도구(Nx의 affected)로 파악 가능.

### 단점

**1. git 성능 저하**
저장소가 커질수록 `git clone`, `git log` 등이 느려질 수 있음.

**2. 복잡한 CI 설정**
변경된 패키지만 빌드/테스트하는 파이프라인 구성 필요.

**3. 권한 관리 어려움**
git은 레포 단위로 권한을 관리하므로, 팀별 접근 제어가 복잡.

**4. 학습 비용**
Turborepo, Nx 등 도구 학습 및 초기 세팅에 시간 투자 필요.

---

## 2. 모노레포 vs 폴리레포

### 폴리레포(Polyrepo)

```
[폴리레포 - 저장소 분리]
repo: web-app (별도 저장소)
repo: mobile-app (별도 저장소)
repo: ui-library (별도 저장소)

각 저장소가 독립적인 package.json, CI, 설정 보유
```

| 항목 | 모노레포 | 폴리레포 |
|------|---------|--------|
| **코드 공유** | 즉시 참조 가능 | npm 배포 후 설치 필요 |
| **원자적 변경** | O | X (여러 PR 필요) |
| **팀 독립성** | 낮음 | 높음 |
| **초기 설정** | 복잡 | 단순 |
| **CI 최적화** | 복잡하지만 가능 | 단순 |
| **적합한 상황** | 밀접하게 연관된 여러 앱 | 독립적인 제품/팀 |

---

## 3. Turborepo - 캐싱과 병렬 실행

### Turborepo 개요

[Turborepo](https://turbo.build/repo)는 Vercel이 인수한 JavaScript/TypeScript 모노레포 빌드 시스템이다.
**원격 캐싱(Remote Caching)** 과 **태스크 병렬화**가 핵심 기능이다.

```bash
# 설치
npx create-turbo@latest

# 기존 프로젝트에 추가
npm install --save-dev turbo
```

### turbo.json 설정

```json
// turbo.json
{
  "$schema": "https://turbo.build/schema.json",
  "globalDependencies": ["**/.env.*local"],
  "pipeline": {
    "build": {
      // 빌드 전에 해당 패키지의 의존성 패키지 빌드 먼저
      "dependsOn": ["^build"],
      // 캐시 키로 사용할 output 파일/폴더
      "outputs": ["dist/**", ".next/**", "!.next/cache/**"]
    },
    "test": {
      "dependsOn": ["build"],
      // 캐시 기준이 되는 입력 파일 (변경 감지)
      "inputs": ["src/**/*.ts", "src/**/*.tsx", "test/**/*.ts"],
      "outputs": []
    },
    "lint": {
      "outputs": []
    },
    "dev": {
      "cache": false,   // 개발 서버는 캐시하지 않음
      "persistent": true
    }
  }
}
```

### 캐싱 동작 원리

```
[Turborepo 캐시 동작]

첫 번째 실행:
입력 파일 해시 계산 → 태스크 실행 → 결과 캐시 저장

두 번째 실행 (변경 없음):
입력 파일 해시 계산 → 캐시 HIT → 저장된 결과 복원 (실행 안 함)

→ 이미 계산한 결과를 재사용하므로 실질적으로 0초

[캐시 키 구성 요소]
- 소스 파일 내용 (inputs에 정의한 파일)
- 환경 변수 값
- turbo.json 설정
- 의존하는 패키지의 캐시 결과
```

```bash
# 태스크 실행 (자동으로 병렬 처리)
turbo run build
turbo run test lint --parallel

# 특정 패키지만 실행
turbo run build --filter=@myorg/web

# 변경된 패키지와 영향받는 패키지만 실행
turbo run build --filter=...[origin/main]

# 캐시 상태 확인
turbo run build --dry-run
```

### 원격 캐시 (Remote Cache)

팀원 간, CI 간에 캐시를 공유해 중복 빌드를 제거한다.

```bash
# Vercel Remote Cache (공식)
npx turbo link  # Vercel 계정 연결

# 자체 호스팅 (Turborepo Remote Cache Server)
# TURBO_TOKEN, TURBO_TEAM 환경 변수 설정
```

```json
// turbo.json - 원격 캐시 설정
{
  "remoteCache": {
    "enabled": true,
    "signature": true  // 캐시 무결성 검증
  }
}
```

### 파이프라인 시각화

```
[태스크 의존성 그래프 예시]

packages/ui:build ──┐
                    ├──→ apps/web:build ──→ apps/web:test
packages/utils:build ─┘

→ ui, utils 빌드가 완료된 후 web 빌드 시작
→ web 빌드 완료 후 web 테스트 시작
→ ui, utils 빌드는 병렬 실행 가능
```

---

## 4. Nx - 의존성 그래프와 affected 명령

### Nx 개요

[Nx](https://nx.dev/)는 Nrwl이 만든 강력한 모노레포 빌드 시스템이다.
**의존성 그래프(Dependency Graph)** 와 **영향 분석(Affected Analysis)** 이 핵심이다.

```bash
# 새 Nx 워크스페이스 생성
npx create-nx-workspace@latest my-org

# 기존 프로젝트에 Nx 추가
npx nx@latest init
```

### nx.json 설정

```json
// nx.json
{
  "$schema": "./node_modules/nx/schemas/nx-schema.json",
  "namedInputs": {
    "default": ["{projectRoot}/**/*", "sharedGlobals"],
    "sharedGlobals": ["{workspaceRoot}/.github/workflows/ci.yml"],
    "production": [
      "default",
      "!{projectRoot}/**/?(*.)+(spec|test).[jt]s?(x)"
    ]
  },
  "targetDefaults": {
    "build": {
      "dependsOn": ["^build"],
      "inputs": ["production", "^production"],
      "cache": true
    },
    "test": {
      "inputs": ["default", "^production"],
      "cache": true
    }
  }
}
```

### project.json (각 패키지 설정)

```json
// packages/ui/project.json
{
  "name": "@myorg/ui",
  "$schema": "../../node_modules/nx/schemas/project-schema.json",
  "sourceRoot": "packages/ui/src",
  "projectType": "library",
  "targets": {
    "build": {
      "executor": "@nx/rollup:rollup",
      "options": {
        "outputPath": "dist/packages/ui",
        "tsConfig": "packages/ui/tsconfig.lib.json",
        "project": "packages/ui/package.json"
      }
    },
    "test": {
      "executor": "@nx/jest:jest",
      "options": {
        "jestConfig": "packages/ui/jest.config.ts"
      }
    }
  }
}
```

### affected 명령 - 변경 영향 분석

Nx의 가장 강력한 기능으로, **현재 변경이 영향 미치는 프로젝트만** 실행한다.

```bash
# main 브랜치 대비 변경된 파일이 영향 미치는 프로젝트에서만 빌드
nx affected:build --base=origin/main

# 영향받는 프로젝트에서만 테스트 실행
nx affected:test --base=origin/main

# 영향받는 프로젝트 목록 확인
nx affected:apps --base=origin/main
nx affected:libs --base=origin/main

# 의존성 그래프 시각화 (브라우저에서 열림)
nx graph

# 영향받는 것만 그래프로 보기
nx affected:graph --base=origin/main
```

```
[영향 분석 예시]

packages/utils가 변경됨
  ↓
의존성 그래프 분석
  ↓
영향받는 패키지: packages/ui (utils 사용), apps/web (utils 사용)
영향 없는 패키지: apps/mobile (utils 미사용)
  ↓
packages/ui, apps/web만 빌드/테스트 실행
```

---

## 5. Workspace 패키지 구조 예제

### 디렉토리 구조

```
my-monorepo/
├── apps/
│   └── web/
│       ├── package.json
│       ├── src/
│       └── next.config.js
├── packages/
│   ├── ui/
│   │   ├── package.json
│   │   ├── src/
│   │   │   ├── Button.tsx
│   │   │   └── index.ts
│   │   └── tsconfig.json
│   └── config/
│       ├── eslint-config/
│       │   └── package.json
│       └── tsconfig/
│           ├── base.json
│           └── package.json
├── package.json       (루트, private: true)
├── pnpm-workspace.yaml
└── turbo.json
```

### 루트 package.json

```json
{
  "name": "my-monorepo",
  "private": true,
  "scripts": {
    "build": "turbo run build",
    "dev": "turbo run dev",
    "test": "turbo run test",
    "lint": "turbo run lint",
    "type-check": "turbo run type-check"
  },
  "devDependencies": {
    "turbo": "^1.13.0",
    "typescript": "^5.0.0"
  },
  "engines": {
    "node": ">=18",
    "pnpm": ">=8"
  }
}
```

### 공유 UI 패키지

```json
// packages/ui/package.json
{
  "name": "@myorg/ui",
  "version": "0.0.0",
  "private": true,
  "exports": {
    ".": {
      "import": "./src/index.ts",
      "types": "./src/index.ts"
    }
  },
  "scripts": {
    "lint": "eslint src/",
    "type-check": "tsc --noEmit"
  },
  "peerDependencies": {
    "react": "^18.0.0"
  },
  "devDependencies": {
    "@myorg/config-eslint": "workspace:*",
    "@myorg/config-typescript": "workspace:*",
    "react": "^18.2.0"
  }
}
```

### 앱 패키지에서 공유 패키지 사용

```json
// apps/web/package.json
{
  "name": "@myorg/web",
  "version": "0.0.0",
  "private": true,
  "dependencies": {
    "@myorg/ui": "workspace:*",
    "next": "^14.0.0",
    "react": "^18.2.0"
  },
  "devDependencies": {
    "@myorg/config-typescript": "workspace:*"
  }
}
```

```tsx
// apps/web/src/app/page.tsx
import { Button } from '@myorg/ui';  // workspace 패키지 직접 import

export default function Home() {
  return <Button onClick={() => alert('clicked')}>Click me</Button>;
}
```

### 공유 TypeScript 설정

```json
// packages/config/tsconfig/base.json
{
  "$schema": "https://json.schemastore.org/tsconfig",
  "display": "Default",
  "compilerOptions": {
    "target": "ES2017",
    "lib": ["ES2017", "DOM", "DOM.Iterable"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "ESNext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true
  },
  "exclude": ["node_modules"]
}
```

```json
// apps/web/tsconfig.json
{
  "extends": "@myorg/config-typescript/base.json",
  "compilerOptions": {
    "plugins": [{ "name": "next" }],
    "paths": { "@/*": ["./src/*"] }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx"],
  "exclude": ["node_modules"]
}
```

---

## 6. 모노레포 도구 선택 가이드

| 상황 | 추천 도구 |
|------|---------|
| Next.js 중심, Vercel 배포 | Turborepo |
| 대규모 엔터프라이즈, 다양한 프레임워크 | Nx |
| 단순한 workspace만 필요 | pnpm workspaces만으로 충분 |
| Angular 프로젝트 | Nx (Angular 공식 지원) |
| 오픈소스 라이브러리 | pnpm + Changesets |

### Turborepo vs Nx 비교

| 항목 | Turborepo | Nx |
|------|-----------|-----|
| **설정 복잡도** | 낮음 | 높음 |
| **러닝 커브** | 낮음 | 높음 |
| **원격 캐시** | Vercel (유료/자체 호스팅) | Nx Cloud (유료/자체 호스팅) |
| **영향 분석** | 기본 제공 | 정교한 affected 분석 |
| **코드 생성** | 미지원 | Nx Generators 지원 |
| **플러그인** | 제한적 | 풍부 (React, Angular, Node 등) |
| **적합한 규모** | 중소~중대형 | 대형 엔터프라이즈 |

---

## 7. 면접 포인트

### Q1. 모노레포와 폴리레포의 장단점을 설명해주세요.

**모노레포 장점**: 코드 공유 용이, 원자적 변경(cross-cutting change를 단일 PR로), 의존성 통일 관리, 도구 설정 일원화.

**모노레포 단점**: git 저장소 비대화, 복잡한 CI 설정 필요, 팀 독립성 저하 가능성.

**선택 기준**: 앱 간 코드 공유가 많고 팀이 함께 작업한다면 모노레포, 앱이 독립적이고 팀이 분리된다면 폴리레포가 적합합니다.

---

### Q2. Turborepo의 캐싱 원리를 설명해주세요.

Turborepo는 태스크의 **입력값(소스 파일, 환경 변수, 설정 파일 등)의 해시**를 계산합니다. 같은 해시가 이미 실행된 적 있다면 실제로 태스크를 실행하지 않고 캐시된 결과물(output 파일, stdout 로그)을 복원합니다.

**로컬 캐시**: 같은 머신에서 재실행 시 즉시 복원
**원격 캐시**: CI 서버나 팀원 머신의 캐시를 공유. 예를 들어 CI에서 이미 빌드한 결과를 팀원 로컬에서 재사용 가능.

이를 통해 변경되지 않은 패키지는 완전히 건너뛰기 때문에 대규모 모노레포에서도 빠른 빌드가 가능합니다.

---

### Q3. Nx의 affected 명령은 어떻게 동작하나요?

Nx는 프로젝트 간 의존성을 분석해 **의존성 그래프(Dependency Graph)** 를 생성합니다.

`nx affected:build --base=origin/main` 실행 시:
1. `git diff origin/main`으로 변경된 파일 목록을 파악합니다.
2. 변경된 파일이 속한 프로젝트를 찾습니다.
3. 의존성 그래프에서 해당 프로젝트에 **직접/간접적으로 의존하는** 모든 프로젝트를 찾습니다.
4. 그 프로젝트들에 대해서만 build를 실행합니다.

예를 들어 공유 `utils` 라이브러리를 변경하면, utils를 사용하는 모든 앱과 라이브러리가 affected 범위에 포함되어 안전하게 재빌드/재테스트됩니다.

---

### Q4. 모노레포에서 workspace:* 프로토콜은 무엇인가요?

`workspace:*`는 pnpm과 Yarn Berry에서 지원하는 **workspace 패키지 참조 프로토콜**입니다.

```json
{ "dependencies": { "@myorg/ui": "workspace:*" } }
```

이렇게 설정하면 npm registry에서 설치하지 않고 **같은 모노레포 내의 packages/ui 디렉토리를 직접 참조**합니다. 개발 중 변경 사항이 즉시 반영되고, publish 시에는 실제 버전 번호로 자동 변환됩니다.

`workspace:^`는 range 형태로, `workspace:1.0.0`은 정확한 버전을 지정합니다.
