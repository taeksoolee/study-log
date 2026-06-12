# 1. Feature-Sliced Design (FSD)

## 목차

1. [FSD란 무엇인가](#1-fsd란-무엇인가)
2. [탄생 배경: 기존 폴더 구조의 문제](#2-탄생-배경-기존-폴더-구조의-문제)
3. [레이어 구조](#3-레이어-구조)
4. [슬라이스와 세그먼트](#4-슬라이스와-세그먼트)
5. [실제 프로젝트 폴더 구조 예제](#5-실제-프로젝트-폴더-구조-예제-쇼핑몰-앱)
6. [장단점 및 적합한 상황](#6-장단점-및-적합한-상황)
7. [면접 포인트](#7-면접-포인트)

---

## 1. FSD란 무엇인가

**Feature-Sliced Design(FSD)**은 프론트엔드 애플리케이션을 위한 아키텍처 방법론이다.
코드를 **기능(Feature)** 단위로 수직 분리하고, 각 기능을 **레이어(Layer)** 에 따라 수평 분리하는 것이 핵심 개념이다.

핵심 원칙:
- **명시적 의존성**: 상위 레이어는 하위 레이어만 참조할 수 있다
- **격리된 슬라이스**: 같은 레이어의 슬라이스끼리는 서로 참조하지 않는다 (shared 제외)
- **공개 API**: 각 슬라이스는 `index.ts`를 통해 외부에 노출할 것만 명시적으로 내보낸다

---

## 2. 탄생 배경: 기존 폴더 구조의 문제

### 전통적인 폴더 구조의 문제점

```
src/
  components/   # 수백 개의 컴포넌트가 뒤섞임
  hooks/        # 어떤 기능에 속하는지 불명확
  utils/        # 모든 유틸이 한곳에
  services/     # API 호출이 한곳에
  store/        # 전역 상태가 한곳에
```

**문제 1: 암묵적 결합**
`components/UserProfile.tsx`가 내부에서 `services/orderApi.ts`를 직접 호출하면
컴포넌트와 API 레이어가 암묵적으로 결합된다.

**문제 2: 기능 삭제가 어려움**
"회원 관리" 기능을 제거하려 할 때 관련 코드가 `components/`, `hooks/`, `store/`, `services/`에
분산되어 있으면 어디를 지워야 하는지 파악하기 어렵다.

**문제 3: 팀 규모가 커질수록 충돌 빈번**
여러 팀이 같은 `components/` 폴더에 파일을 추가하면 PR 충돌이 자주 발생한다.

---

## 3. 레이어 구조

FSD는 6개의 레이어로 구성된다. **위에서 아래 방향으로만 의존**할 수 있다.

```
┌─────────────────────────────────────┐
│              app                    │  ← 앱 진입점, 프로바이더, 라우터
├─────────────────────────────────────┤
│             pages                   │  ← 라우트 단위 페이지
├─────────────────────────────────────┤
│            widgets                  │  ← 독립적인 대형 UI 블록
├─────────────────────────────────────┤
│            features                 │  ← 사용자 인터랙션 / 비즈니스 기능
├─────────────────────────────────────┤
│            entities                 │  ← 비즈니스 엔티티 (User, Order...)
├─────────────────────────────────────┤
│             shared                  │  ← 재사용 가능한 공통 코드
└─────────────────────────────────────┘
```

### 각 레이어 역할

| 레이어 | 역할 | 예시 |
|--------|------|------|
| **app** | 전역 설정, 라우터, 전역 스타일, 프로바이더 | `App.tsx`, `Router.tsx`, `store.ts` |
| **pages** | URL 경로에 대응하는 페이지 컴포넌트 | `HomePage`, `ProductDetailPage` |
| **widgets** | 여러 features/entities를 조합한 독립 블록 | `Header`, `Sidebar`, `ProductCard` |
| **features** | 사용자 액션, 비즈니스 시나리오 | `AddToCart`, `UserLogin`, `SearchProducts` |
| **entities** | 도메인 모델과 그에 관련된 UI/로직 | `User`, `Product`, `Order` |
| **shared** | 어느 레이어에도 속하지 않는 공통 코드 | `Button`, `Input`, `api`, `lib` |

### 의존성 규칙 예시

```typescript
// pages/ProductPage — OK: pages → features, entities, shared
import { AddToCart } from '@/features/add-to-cart'
import { ProductCard } from '@/entities/product'
import { Button } from '@/shared/ui'

// features/add-to-cart — WRONG: features → pages는 금지!
import { ProductPage } from '@/pages/product'  // ❌

// features/add-to-cart — WRONG: 같은 레이어 참조 금지
import { UserLogin } from '@/features/user-login'  // ❌
```

---

## 4. 슬라이스와 세그먼트

### 슬라이스 (Slice)

레이어 아래에 있는 **비즈니스 도메인 단위**. `pages`, `widgets`, `features`, `entities` 레이어는 슬라이스로 구성된다. `app`과 `shared`는 슬라이스 없이 세그먼트로 바로 구성된다.

```
features/
  add-to-cart/    ← 슬라이스
  user-auth/      ← 슬라이스
  product-search/ ← 슬라이스
```

### 세그먼트 (Segment)

슬라이스 내부의 **기술적 역할**에 따른 폴더 구조.

| 세그먼트 | 역할 |
|---------|------|
| `ui` | React 컴포넌트, 스타일 |
| `model` | 상태 관리 (store, slice, hooks) |
| `api` | API 호출, 서버 통신 |
| `lib` | 해당 슬라이스의 유틸리티 |
| `config` | 상수, 설정값 |

```
features/add-to-cart/
  ui/
    AddToCartButton.tsx
    AddToCartButton.module.css
  model/
    addToCartSlice.ts
    useAddToCart.ts
  api/
    addToCartApi.ts
  index.ts          ← 공개 API
```

### 공개 API (index.ts)

```typescript
// features/add-to-cart/index.ts
// 외부에 공개할 것만 명시적으로 export
export { AddToCartButton } from './ui/AddToCartButton'
export { useAddToCart } from './model/useAddToCart'
// addToCartApi는 내부 구현이므로 export하지 않음
```

---

## 5. 실제 프로젝트 폴더 구조 예제 (쇼핑몰 앱)

```
src/
├── app/
│   ├── providers/
│   │   ├── RouterProvider.tsx
│   │   ├── StoreProvider.tsx
│   │   └── ThemeProvider.tsx
│   ├── styles/
│   │   └── globals.css
│   └── index.tsx
│
├── pages/
│   ├── home/
│   │   ├── ui/
│   │   │   └── HomePage.tsx
│   │   └── index.ts
│   ├── product-list/
│   │   ├── ui/
│   │   │   └── ProductListPage.tsx
│   │   └── index.ts
│   └── cart/
│       ├── ui/
│       │   └── CartPage.tsx
│       └── index.ts
│
├── widgets/
│   ├── header/
│   │   ├── ui/
│   │   │   ├── Header.tsx
│   │   │   └── Header.module.css
│   │   └── index.ts
│   └── product-list-with-filters/
│       ├── ui/
│       │   └── ProductListWithFilters.tsx
│       └── index.ts
│
├── features/
│   ├── add-to-cart/
│   │   ├── ui/
│   │   │   └── AddToCartButton.tsx
│   │   ├── model/
│   │   │   ├── addToCartSlice.ts
│   │   │   └── useAddToCart.ts
│   │   ├── api/
│   │   │   └── addToCartApi.ts
│   │   └── index.ts
│   ├── product-search/
│   │   ├── ui/
│   │   │   └── ProductSearchBar.tsx
│   │   ├── model/
│   │   │   └── useProductSearch.ts
│   │   └── index.ts
│   └── user-auth/
│       ├── ui/
│       │   ├── LoginForm.tsx
│       │   └── LogoutButton.tsx
│       ├── model/
│       │   ├── authSlice.ts
│       │   └── useAuth.ts
│       ├── api/
│       │   └── authApi.ts
│       └── index.ts
│
├── entities/
│   ├── product/
│   │   ├── ui/
│   │   │   └── ProductCard.tsx
│   │   ├── model/
│   │   │   ├── product.types.ts
│   │   │   └── productSlice.ts
│   │   ├── api/
│   │   │   └── productApi.ts
│   │   └── index.ts
│   ├── cart/
│   │   ├── model/
│   │   │   ├── cart.types.ts
│   │   │   └── cartSlice.ts
│   │   └── index.ts
│   └── user/
│       ├── ui/
│       │   └── UserAvatar.tsx
│       ├── model/
│       │   └── user.types.ts
│       └── index.ts
│
└── shared/
    ├── ui/
    │   ├── Button/
    │   │   ├── Button.tsx
    │   │   └── index.ts
    │   ├── Input/
    │   └── Modal/
    ├── api/
    │   └── baseApi.ts       ← axios 인스턴스 등
    ├── lib/
    │   ├── formatPrice.ts
    │   └── formatDate.ts
    └── config/
        └── routes.ts
```

### 실제 코드 예시

```typescript
// entities/product/model/product.types.ts
export interface Product {
  id: string
  name: string
  price: number
  imageUrl: string
  stock: number
}

// entities/product/api/productApi.ts
import { baseApi } from '@/shared/api'
import type { Product } from './product.types'

export const productApi = {
  getAll: () => baseApi.get<Product[]>('/products'),
  getById: (id: string) => baseApi.get<Product>(`/products/${id}`),
}

// features/add-to-cart/model/useAddToCart.ts
import { useAppDispatch } from '@/shared/lib'
import { cartModel } from '@/entities/cart'  // entities는 참조 가능
import type { Product } from '@/entities/product'

export const useAddToCart = () => {
  const dispatch = useAppDispatch()

  const addToCart = (product: Product, quantity: number) => {
    dispatch(cartModel.actions.addItem({ product, quantity }))
  }

  return { addToCart }
}

// pages/product-list/ui/ProductListPage.tsx
import { ProductListWithFilters } from '@/widgets/product-list-with-filters'
import { ProductSearchBar } from '@/features/product-search'

export const ProductListPage = () => {
  return (
    <div>
      <ProductSearchBar />
      <ProductListWithFilters />
    </div>
  )
}
```

---

## 6. 장단점 및 적합한 상황

### 장점

- 기능 단위로 코드가 모여 있어 **삭제/수정이 쉬움**
- 의존성 규칙이 명확해 **사이드 이펙트를 예측하기 쉬움**
- 팀이 각자 다른 슬라이스를 작업하면 **충돌이 줄어듦**
- `index.ts`를 통한 공개 API로 **내부 구현이 캡슐화됨**

### 단점

- **초기 학습 곡선**이 높음 (레이어/슬라이스/세그먼트 개념 이해 필요)
- **소규모 프로젝트**에서는 과도한 폴더 구조가 오히려 생산성을 떨어뜨림
- 어느 레이어에 넣어야 할지 **경계가 애매한 경우** 팀 내 논의 비용 발생
- 기존 프로젝트에 **점진적 도입이 어려움**

### 언제 적합한가

- 팀원이 5명 이상이고 여러 도메인이 공존하는 중대형 프로젝트
- 장기 유지보수가 예상되는 프로덕트
- 마이크로 프론트엔드 전환 전 단계
- 기능이 자주 추가/삭제되는 SaaS 제품

---

## 7. 면접 포인트

**Q. FSD에서 같은 레이어의 슬라이스끼리 참조하지 못하는 이유는?**

> 같은 레이어의 슬라이스 간 의존이 생기면 순환 의존이 발생할 수 있고,
> 특정 슬라이스를 수정할 때 같은 레이어의 다른 슬라이스에 예상치 못한 영향을 줄 수 있습니다.
> 격리를 유지함으로써 각 슬라이스를 독립적으로 개발/테스트할 수 있게 됩니다.

**Q. FSD와 기존 폴더 구조(components/hooks/utils)의 차이점은?**

> 기존 구조는 기술적 역할(컴포넌트, 훅, 유틸)로 분리하는 반면,
> FSD는 비즈니스 도메인(feature, entity)으로 먼저 분리하고, 그 안에서 기술적 역할로 나눕니다.
> 이로 인해 특정 기능과 관련된 모든 코드가 한 곳에 모이게 됩니다.

**Q. FSD에서 shared 레이어는 어떤 코드를 넣어야 하나요?**

> shared에는 특정 비즈니스 도메인에 귀속되지 않는 범용 코드를 넣습니다.
> UI 컴포넌트(Button, Input), API 기반 설정(axios 인스턴스), 날짜 포매팅 같은 순수 유틸리티가 해당됩니다.
> 반면 특정 도메인의 규칙이 담긴 로직은 entities나 features에 위치해야 합니다.
