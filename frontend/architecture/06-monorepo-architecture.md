# 6. 모노레포 아키텍처

## 목차

1. [모노레포 vs 폴리레포](#1-모노레포-vs-폴리레포)
2. [선택 기준](#2-선택-기준)
3. [공유 패키지 설계](#3-공유-패키지-설계)
4. [빌드 파이프라인 최적화](#4-빌드-파이프라인-최적화)
5. [버전 관리 전략 (Changesets)](#5-버전-관리-전략-changesets)
6. [주요 도구 비교](#6-주요-도구-비교)
7. [실전 모노레포 구조 예제](#7-실전-모노레포-구조-예제)
8. [면접 포인트](#8-면접-포인트)

---

## 1. 모노레포 vs 폴리레포

### 폴리레포 (Poly-repo)

각 프로젝트/패키지가 별도의 Git 저장소에 관리된다.

```
github.com/company/
├── frontend-app          (레포 1)
├── admin-app             (레포 2)
├── design-system         (레포 3)
└── shared-utils          (레포 4)
```

**폴리레포의 문제점:**
- `shared-utils`를 수정하면 npm 배포 → `frontend-app`에서 버전 업데이트 → PR 과정이 반복
- 여러 레포의 타입을 한 번에 변경하기 어려움 (cross-repo refactoring)
- 각 레포마다 ESLint, TypeScript, Jest 설정을 따로 관리

### 모노레포 (Mono-repo)

여러 프로젝트/패키지를 **하나의 Git 저장소**에서 관리한다.

```
github.com/company/monorepo/
├── apps/
│   ├── frontend-app
│   └── admin-app
└── packages/
    ├── design-system
    └── shared-utils
```

**모노레포의 이점:**
- `shared-utils` 수정 시 즉시 `frontend-app`에서 반영 확인 가능
- 단일 PR로 여러 패키지에 걸친 변경 처리 가능
- 공통 설정(ESLint, TypeScript) 루트에서 한 번만 설정
- 코드 재사용이 npm 배포 없이 가능

---

## 2. 선택 기준

| 상황 | 추천 |
|------|------|
| 팀이 3명 이하, 앱이 1~2개 | 폴리레포 (단순함 우선) |
| 여러 앱이 UI 컴포넌트를 공유 | **모노레포** |
| 팀이 10명 이상, 도메인 분리 필요 | **모노레포** |
| 마이크로 프론트엔드 운영 | **모노레포** (관리 단순화) |
| 외부 오픈소스 라이브러리 | 폴리레포 (독립적 릴리즈) |
| 팀마다 기술 스택이 완전히 다름 | 폴리레포 |

### 팀 규모별 선택

```
소규모 (1~5명)
└── 단일 레포 또는 폴리레포
    이유: 오버헤드 없이 빠르게 개발

중규모 (6~20명)
└── 모노레포 (Turborepo 추천)
    이유: 코드 공유 + 빌드 캐싱으로 생산성 향상

대규모 (20명+)
└── 모노레포 (Turborepo/Nx) + 마이크로 프론트엔드 조합
    이유: 팀 독립성 + 코드 공유 모두 필요
```

---

## 3. 공유 패키지 설계

### 패키지 구조 원칙

```
packages/
├── ui/              ← 디자인 시스템 (Atoms, Molecules)
├── utils/           ← 순수 유틸리티 함수
├── types/           ← 공통 TypeScript 타입
├── config/          ← ESLint, TypeScript, Tailwind 공통 설정
└── hooks/           ← 재사용 가능한 React Hooks
```

### @company/ui — 디자인 시스템 패키지

```typescript
// packages/ui/src/Button/Button.tsx
import React from 'react'
import styles from './Button.module.css'

export interface ButtonProps {
  children: React.ReactNode
  variant?: 'primary' | 'secondary' | 'ghost'
  size?: 'sm' | 'md' | 'lg'
  disabled?: boolean
  onClick?: () => void
}

export const Button = ({
  children,
  variant = 'primary',
  size = 'md',
  disabled = false,
  onClick,
}: ButtonProps) => {
  return (
    <button
      className={[styles.btn, styles[variant], styles[size]].join(' ')}
      disabled={disabled}
      onClick={onClick}
    >
      {children}
    </button>
  )
}

// packages/ui/src/index.ts — 공개 API
export { Button } from './Button/Button'
export type { ButtonProps } from './Button/Button'
export { Input } from './Input/Input'
export { Modal } from './Modal/Modal'
export { Badge } from './Badge/Badge'
```

```json
// packages/ui/package.json
{
  "name": "@company/ui",
  "version": "1.0.0",
  "main": "./dist/index.js",
  "types": "./dist/index.d.ts",
  "exports": {
    ".": {
      "import": "./dist/index.mjs",
      "require": "./dist/index.js",
      "types": "./dist/index.d.ts"
    }
  },
  "scripts": {
    "build": "tsup src/index.ts --format esm,cjs --dts",
    "dev": "tsup src/index.ts --format esm,cjs --dts --watch"
  },
  "peerDependencies": {
    "react": "^18.0.0"
  }
}
```

### @company/utils — 순수 유틸리티

```typescript
// packages/utils/src/formatPrice.ts
export const formatPrice = (price: number, currency = 'KRW'): string => {
  return new Intl.NumberFormat('ko-KR', {
    style: 'currency',
    currency,
    maximumFractionDigits: 0,
  }).format(price)
}

// packages/utils/src/formatDate.ts
export const formatDate = (
  date: Date | string,
  format: 'short' | 'long' | 'relative' = 'short'
): string => {
  const d = typeof date === 'string' ? new Date(date) : date
  if (format === 'relative') {
    const diff = Date.now() - d.getTime()
    const minutes = Math.floor(diff / 60000)
    if (minutes < 60) return `${minutes}분 전`
    const hours = Math.floor(minutes / 60)
    if (hours < 24) return `${hours}시간 전`
    return `${Math.floor(hours / 24)}일 전`
  }
  return new Intl.DateTimeFormat('ko-KR', {
    dateStyle: format === 'long' ? 'full' : 'short',
  }).format(d)
}

// packages/utils/src/index.ts
export { formatPrice } from './formatPrice'
export { formatDate } from './formatDate'
export { debounce } from './debounce'
export { throttle } from './throttle'
```

### @company/types — 공통 타입

```typescript
// packages/types/src/common.ts
export interface PaginatedResponse<T> {
  data: T[]
  total: number
  page: number
  pageSize: number
  hasNext: boolean
}

export interface ApiError {
  code: string
  message: string
  details?: Record<string, string[]>
}

// packages/types/src/entities.ts
export interface User {
  id: string
  email: string
  name: string
  role: 'admin' | 'user' | 'guest'
  createdAt: string
}

export interface Product {
  id: string
  name: string
  price: number
  stock: number
  categoryId: string
}
```

### 앱에서 공유 패키지 사용

```typescript
// apps/frontend-app/src/components/ProductCard.tsx
import { Button, Badge } from '@company/ui'           // 디자인 시스템
import { formatPrice } from '@company/utils'          // 유틸
import type { Product } from '@company/types'         // 타입

interface ProductCardProps {
  product: Product
  onAddToCart: (product: Product) => void
}

export const ProductCard = ({ product, onAddToCart }: ProductCardProps) => {
  const isOutOfStock = product.stock === 0

  return (
    <div className="product-card">
      <h3>{product.name}</h3>
      <p>{formatPrice(product.price)}</p>
      {isOutOfStock && <Badge variant="error">품절</Badge>}
      <Button
        variant="primary"
        disabled={isOutOfStock}
        onClick={() => onAddToCart(product)}
      >
        장바구니 담기
      </Button>
    </div>
  )
}
```

---

## 4. 빌드 파이프라인 최적화

### Turborepo 설정

```json
// turbo.json (루트)
{
  "$schema": "https://turbo.build/schema.json",
  "pipeline": {
    "build": {
      "dependsOn": ["^build"],  // 의존 패키지 먼저 빌드
      "outputs": ["dist/**", ".next/**"],
      "cache": true
    },
    "test": {
      "dependsOn": ["^build"],
      "outputs": ["coverage/**"],
      "cache": true
    },
    "lint": {
      "outputs": [],
      "cache": true
    },
    "dev": {
      "cache": false,           // 개발 서버는 캐시 없이
      "persistent": true
    }
  }
}
```

### 루트 package.json

```json
// package.json (루트)
{
  "name": "company-monorepo",
  "private": true,
  "workspaces": ["apps/*", "packages/*"],
  "scripts": {
    "build": "turbo run build",
    "test": "turbo run test",
    "lint": "turbo run lint",
    "dev": "turbo run dev --parallel",
    "build:affected": "turbo run build --filter=...[HEAD^1]"
  },
  "devDependencies": {
    "turbo": "^1.13.0"
  }
}
```

### 빌드 캐싱 메커니즘

```
첫 번째 빌드:
packages/ui 변경 없음 → 캐시 HIT → 빌드 SKIP (0.1초)
packages/utils 변경 없음 → 캐시 HIT → 빌드 SKIP (0.1초)
apps/frontend-app 변경 있음 → 캐시 MISS → 실제 빌드 (45초)

두 번째 빌드 (변경 없음):
모든 패키지 → 캐시 HIT → 전체 SKIP (0.5초)
```

### 영향받은 패키지만 테스트

```bash
# HEAD^1 이후 변경된 패키지와 그에 의존하는 패키지만 테스트
turbo run test --filter=...[HEAD^1]

# 특정 패키지와 의존 앱만 빌드
turbo run build --filter=@company/ui...
```

---

## 5. 버전 관리 전략 (Changesets)

**Changesets**는 모노레포에서 패키지 버전을 관리하고 CHANGELOG를 자동 생성하는 도구다.

### 기본 워크플로우

```bash
# 1. 코드 변경 후 changeset 파일 생성
npx changeset

# 대화형 프롬프트:
# ? Which packages would you like to include? @company/ui
# ? semver bump type? patch (버그 수정) / minor (기능 추가) / major (브레이킹 변경)
# ? Summary: Button 컴포넌트에 loading 상태 prop 추가

# 2. .changeset 폴더에 파일 생성됨
# .changeset/purple-dragons-eat.md

# 3. PR 머지 후 버전 적용
npx changeset version
# → 각 패키지의 package.json 버전 자동 업데이트
# → CHANGELOG.md 자동 생성

# 4. npm 배포 (필요한 경우)
npx changeset publish
```

### 생성된 changeset 파일

```markdown
<!-- .changeset/purple-dragons-eat.md -->
---
"@company/ui": minor
---

Button 컴포넌트에 `isLoading` prop 추가.
로딩 중에는 Spinner 아이콘을 표시하고 클릭이 비활성화됩니다.
```

### 자동화된 버전 관리 (GitHub Actions)

```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    branches: [main]

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3

      - name: Install dependencies
        run: npm ci

      - name: Create Release PR or Publish
        uses: changesets/action@v1
        with:
          publish: npm run release
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

---

## 6. 주요 도구 비교

| 도구 | 특징 | 추천 상황 |
|------|------|----------|
| **Turborepo** | 빠른 빌드 캐싱, 설정 간단 | 중소규모, 빠른 시작 |
| **Nx** | 강력한 코드 생성기, 플러그인 생태계 | 대규모 엔터프라이즈 |
| **pnpm workspaces** | 패키지 관리에 집중, 디스크 효율 | 빌드 도구 없이 패키지만 공유 |
| **Lerna** | 역사 깊은 도구, Changesets와 조합 | 패키지 배포에 특화 |

---

## 7. 실전 모노레포 구조 예제

```
company-monorepo/
├── apps/
│   ├── web/                      ← 사용자용 웹 앱 (Next.js)
│   │   ├── src/
│   │   ├── package.json          → @company/ui, @company/utils 의존
│   │   └── next.config.js
│   ├── admin/                    ← 관리자 앱 (Vite + React)
│   │   ├── src/
│   │   └── package.json          → @company/ui, @company/types 의존
│   └── mobile/                   ← 모바일 앱 (Expo)
│       └── package.json          → @company/utils, @company/types 의존
│
├── packages/
│   ├── ui/                       ← @company/ui (디자인 시스템)
│   │   ├── src/
│   │   ├── package.json
│   │   └── tsconfig.json
│   ├── utils/                    ← @company/utils
│   ├── types/                    ← @company/types
│   ├── hooks/                    ← @company/hooks
│   └── config/                   ← @company/config
│       ├── eslint/
│       │   └── index.js          ← 공통 ESLint 설정
│       └── typescript/
│           ├── base.json         ← 공통 tsconfig
│           └── nextjs.json
│
├── .changeset/                   ← Changesets 파일들
├── turbo.json
├── package.json
├── pnpm-workspace.yaml
└── tsconfig.json                 ← 루트 TypeScript 설정
```

### 루트 tsconfig.json (paths 설정)

```json
{
  "compilerOptions": {
    "paths": {
      "@company/ui": ["./packages/ui/src/index.ts"],
      "@company/utils": ["./packages/utils/src/index.ts"],
      "@company/types": ["./packages/types/src/index.ts"]
    }
  }
}
```

---

## 8. 면접 포인트

**Q. 모노레포를 선택하는 기준은 무엇인가요?**

> 여러 앱이 공통 컴포넌트나 유틸리티를 공유할 때, 폴리레포에서는 변경 시마다 npm 배포 → 버전 업데이트 사이클이 필요합니다.
> 팀이 5명 이상이고 공유 코드의 변경이 자주 일어난다면 모노레포가 생산성을 높입니다.
> 반면 팀마다 기술 스택이 완전히 다르거나, 독립적인 배포가 더 중요하다면 폴리레포를 선택합니다.

**Q. Turborepo의 빌드 캐싱은 어떻게 동작하나요?**

> Turborepo는 각 태스크의 입력(소스 파일, 환경 변수, lock 파일)의 해시를 계산하여 캐시 키로 사용합니다.
> 이전과 동일한 입력이면 이전 빌드 결과를 재사용하여 빌드를 건너뜁니다.
> Remote Cache 기능을 사용하면 팀 내 다른 개발자나 CI 서버가 이미 빌드한 결과를
> 클라우드(Vercel Remote Cache)에서 내려받아 사용할 수 있어 CI 시간도 단축됩니다.

**Q. 모노레포에서 Changesets를 사용하는 이유는?**

> 모노레포에서 여러 패키지를 수동으로 버전 관리하면 어떤 패키지가 어떤 버전에서 어떤 변경이 있었는지 추적하기 어렵습니다.
> Changesets는 변경 사항을 `.changeset` 파일로 명시적으로 기록하게 하고,
> 배포 시 이 파일들을 기반으로 semver를 자동으로 올리고 CHANGELOG를 생성합니다.
> 이로써 패키지 소비자가 버전 업그레이드 시 무엇이 바뀌었는지 쉽게 파악할 수 있습니다.
