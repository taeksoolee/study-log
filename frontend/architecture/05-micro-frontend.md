# 5. 마이크로 프론트엔드

## 목차

1. [마이크로 프론트엔드란](#1-마이크로-프론트엔드란)
2. [구현 방법 비교](#2-구현-방법-비교)
3. [Webpack Module Federation 상세 예제](#3-webpack-module-federation-상세-예제)
4. [Shell App + Remote App 구조](#4-shell-app--remote-app-구조)
5. [팀 간 독립 배포 전략](#5-팀-간-독립-배포-전략)
6. [공유 상태 및 라이브러리 버전 관리 문제](#6-공유-상태-및-라이브러리-버전-관리-문제)
7. [장단점](#7-장단점)
8. [면접 포인트](#8-면접-포인트)

---

## 1. 마이크로 프론트엔드란

**마이크로 프론트엔드**는 마이크로서비스 아이디어를 프론트엔드에 적용한 아키텍처 패턴이다.
하나의 거대한 프론트엔드 애플리케이션을 **여러 팀이 독립적으로 개발하고 배포**할 수 있는
작은 단위로 분리한다.

### 마이크로서비스와의 관계

```
마이크로서비스 (백엔드)         마이크로 프론트엔드 (프론트엔드)
┌────────────────────┐         ┌─────────────────────────────────┐
│  User Service      │         │  Shell App (컨테이너)            │
│  Order Service     │  ←→     │  ├── User MFE (팀 A)            │
│  Product Service   │         │  ├── Order MFE (팀 B)           │
│  Payment Service   │         │  └── Product MFE (팀 C)         │
└────────────────────┘         └─────────────────────────────────┘
```

### 언제 고려하는가

- 팀이 10명 이상으로 커지고 하나의 레포지토리에서 배포 병목이 발생할 때
- 서로 다른 팀이 독립적인 배포 사이클이 필요할 때
- 레거시와 신규 기술 스택을 점진적으로 마이그레이션할 때
- 하나의 팀 변경이 전체 앱 배포를 막아서는 안 될 때

---

## 2. 구현 방법 비교

| 방법 | 설명 | 장점 | 단점 |
|------|------|------|------|
| **iframe** | 각 MFE를 iframe으로 삽입 | 완벽한 격리, 기술 스택 무관 | UX 제한, SEO 불리, 상태 공유 어려움 |
| **Web Components** | Custom Elements로 MFE 노출 | 프레임워크 무관, 표준 기술 | 복잡한 구현, React와의 이벤트 통신 이슈 |
| **Module Federation** | Webpack 런타임에서 모듈 공유 | 런타임 통합, 번들 최적화, React 친화적 | Webpack 의존성, 버전 관리 복잡 |
| **빌드타임 통합** | npm 패키지로 배포 후 import | 단순함, 타입 지원 | 변경 시 재빌드 필요, 독립 배포 불가 |

### iframe 방식 (간단 예시)

```html
<!-- Shell App -->
<div id="app">
  <nav>공통 네비게이션</nav>
  <main>
    <!-- 각 팀의 앱을 iframe으로 분리 -->
    <iframe src="https://user-team.company.com" title="유저 영역"></iframe>
  </main>
</div>
```

### Web Components 방식

```typescript
// Product MFE가 Web Component로 자신을 노출
class ProductListElement extends HTMLElement {
  connectedCallback() {
    const mountPoint = document.createElement('div')
    this.attachShadow({ mode: 'open' }).appendChild(mountPoint)
    ReactDOM.render(<ProductListApp />, mountPoint)
  }
}

customElements.define('product-list-mfe', ProductListElement)

// Shell App에서 사용
// <product-list-mfe category="electronics"></product-list-mfe>
```

---

## 3. Webpack Module Federation 상세 예제

**Module Federation**은 Webpack 5에서 도입된 기능으로, 런타임에 다른 빌드의 모듈을 동적으로 가져올 수 있다.

### 구성 요소

- **Host (Shell App)**: 다른 앱의 모듈을 소비
- **Remote**: 자신의 모듈을 외부에 노출
- **Shared**: 여러 앱이 공유할 라이브러리 (React, React-DOM 등)

### Remote App (Product MFE) — webpack.config.js

```javascript
// product-mfe/webpack.config.js
const { ModuleFederationPlugin } = require('webpack').container

module.exports = {
  plugins: [
    new ModuleFederationPlugin({
      name: 'productMFE',              // 이 앱의 이름
      filename: 'remoteEntry.js',      // 진입점 파일명

      exposes: {
        // 외부에 노출할 모듈 (키: 외부에서 사용할 경로, 값: 실제 파일)
        './ProductList': './src/components/ProductList',
        './ProductDetail': './src/components/ProductDetail',
        './useProductStore': './src/stores/productStore',
      },

      shared: {
        react: { singleton: true, requiredVersion: '^18.0.0' },
        'react-dom': { singleton: true, requiredVersion: '^18.0.0' },
      },
    }),
  ],
}
```

### Shell App (Host) — webpack.config.js

```javascript
// shell-app/webpack.config.js
const { ModuleFederationPlugin } = require('webpack').container

module.exports = {
  plugins: [
    new ModuleFederationPlugin({
      name: 'shellApp',

      remotes: {
        // 키: import 시 사용할 이름, 값: "원격앱이름@URL/remoteEntry.js"
        productMFE: 'productMFE@https://product.company.com/remoteEntry.js',
        userMFE: 'userMFE@https://user.company.com/remoteEntry.js',
        orderMFE: 'orderMFE@https://order.company.com/remoteEntry.js',
      },

      shared: {
        react: { singleton: true, requiredVersion: '^18.0.0' },
        'react-dom': { singleton: true, requiredVersion: '^18.0.0' },
      },
    }),
  ],
}
```

### Remote App — 노출할 컴포넌트

```typescript
// product-mfe/src/components/ProductList.tsx
interface ProductListProps {
  category?: string
  onProductSelect?: (product: Product) => void
}

const ProductList = ({ category, onProductSelect }: ProductListProps) => {
  const { products, isLoading } = useProducts(category)

  if (isLoading) return <div>상품을 불러오는 중...</div>

  return (
    <div className="product-list">
      {products.map((product) => (
        <div
          key={product.id}
          onClick={() => onProductSelect?.(product)}
          className="product-item"
        >
          <img src={product.imageUrl} alt={product.name} />
          <h3>{product.name}</h3>
          <p>{product.price.toLocaleString()}원</p>
        </div>
      ))}
    </div>
  )
}

export default ProductList
```

### Shell App — Remote 모듈 사용

```typescript
// shell-app/src/pages/ShopPage.tsx
import React, { Suspense, lazy } from 'react'

// 런타임에 product-mfe에서 동적으로 로드
const ProductList = lazy(() => import('productMFE/ProductList'))
const UserCart = lazy(() => import('userMFE/Cart'))

const ShopPage = () => {
  const handleProductSelect = (product: Product) => {
    // Shell에서 선택 이벤트 처리
    console.log('Selected:', product)
  }

  return (
    <div className="shop-layout">
      <aside>
        <Suspense fallback={<div>장바구니 로딩...</div>}>
          <UserCart />
        </Suspense>
      </aside>
      <main>
        <Suspense fallback={<div>상품 목록 로딩...</div>}>
          <ProductList
            category="electronics"
            onProductSelect={handleProductSelect}
          />
        </Suspense>
      </main>
    </div>
  )
}
```

---

## 4. Shell App + Remote App 구조

```
                    ┌──────────────────────────────┐
                    │         Shell App             │
                    │  ┌────────────────────────┐  │
                    │  │  Global Navigation     │  │
                    │  │  Auth State            │  │
                    │  │  Routing               │  │
                    │  └────────────────────────┘  │
                    │                              │
           ┌────────┴────────────────────┬─────────┤
           ↓                             ↓         │
  ┌─────────────────┐         ┌──────────────────┐ │
  │  Product MFE    │         │   Order MFE      │ │
  │  (팀 C)         │         │   (팀 B)         │ │
  │  ─────────────  │         │  ────────────── │ │
  │  ProductList    │         │  OrderHistory   │ │
  │  ProductDetail  │         │  OrderForm      │ │
  │  own React Store│         │  own React Store│ │
  └─────────────────┘         └──────────────────┘ │
           ↑ 독립 배포                ↑ 독립 배포    │
           │                          │              │
    CI/CD (팀 C)               CI/CD (팀 B)         │
```

### Shell의 역할

```typescript
// shell-app/src/App.tsx
// Shell은 레이아웃과 라우팅만 담당하고 도메인 로직은 없음
const App = () => {
  return (
    <AuthProvider>          {/* 공통 인증 */}
      <EventBusProvider>    {/* MFE 간 통신 */}
        <Router>
          <GlobalNav />
          <Routes>
            <Route path="/products/*" element={
              <Suspense fallback={<PageLoader />}>
                <ProductMFE />
              </Suspense>
            } />
            <Route path="/orders/*" element={
              <Suspense fallback={<PageLoader />}>
                <OrderMFE />
              </Suspense>
            } />
          </Routes>
        </Router>
      </EventBusProvider>
    </AuthProvider>
  )
}
```

---

## 5. 팀 간 독립 배포 전략

### 배포 흐름

```
팀 C (Product) 코드 변경
       ↓
  PR → CI (테스트, 빌드)
       ↓
  product.company.com/remoteEntry.js 업데이트
       ↓
  Shell App은 재배포 없이 자동으로 새 버전 로드
```

### 버전이 있는 배포 (안전한 방식)

```javascript
// 운영 환경에서는 버전 해시나 날짜로 고정
remotes: {
  productMFE: `productMFE@https://product.company.com/${process.env.PRODUCT_VERSION}/remoteEntry.js`,
}

// 또는 feature flag로 카나리 배포
remotes: {
  productMFE: isCanary
    ? 'productMFE@https://product-canary.company.com/remoteEntry.js'
    : 'productMFE@https://product.company.com/remoteEntry.js',
}
```

---

## 6. 공유 상태 및 라이브러리 버전 관리 문제

### MFE 간 통신 방법

```typescript
// 방법 1: Custom Events (브라우저 네이티브)
// Product MFE에서 이벤트 발행
window.dispatchEvent(new CustomEvent('product:selected', {
  detail: { productId: '123', name: 'MacBook' }
}))

// Order MFE에서 이벤트 수신
window.addEventListener('product:selected', (e: CustomEvent) => {
  const { productId } = e.detail
  addToCart(productId)
})

// 방법 2: 공유 상태 스토어 (Shell에서 제공)
// shell이 전역 이벤트 버스를 window에 등록
window.__eventBus = {
  emit: (event: string, data: unknown) => { /* ... */ },
  on: (event: string, handler: (data: unknown) => void) => { /* ... */ },
}

// 방법 3: URL/Route 기반 통신 (가장 단순)
// Product MFE에서 선택 시
navigate('/orders/new?productId=123')
// Order MFE가 URL 파라미터를 읽어 처리
```

### 공통 라이브러리 버전 관리 문제

```javascript
// 가장 흔한 문제: React 인스턴스가 두 개 생기는 경우
// Shell: React 18.2.0
// Product MFE: React 18.0.0
// → Hooks 오류, Context 공유 실패

// 해결: singleton + requiredVersion 설정
shared: {
  react: {
    singleton: true,           // 하나의 인스턴스만 사용
    requiredVersion: '^18.0.0', // 허용 버전 범위
    eager: true,               // Shell이 먼저 로드
  },
  'react-dom': {
    singleton: true,
    requiredVersion: '^18.0.0',
    eager: true,
  },
  // 디자인 시스템도 공유 가능
  '@company/design-system': {
    singleton: true,
    requiredVersion: '^2.0.0',
  },
}
```

---

## 7. 장단점

### 장점

- **팀 독립성**: 각 팀이 독립적으로 개발, 테스트, 배포 가능
- **기술 스택 다양성**: 팀마다 다른 프레임워크 사용 가능 (Vue MFE + React MFE 공존)
- **점진적 마이그레이션**: 레거시를 한꺼번에 바꾸지 않고 모듈별로 교체 가능
- **장애 격리**: 특정 MFE 오류가 전체 앱을 중단시키지 않음

### 단점

- **초기 설정 복잡도**: Webpack Module Federation, CI/CD 파이프라인 구성이 복잡
- **성능 오버헤드**: 여러 remoteEntry.js 로드, 번들 중복 가능성
- **테스트 어려움**: MFE 간 통합 테스트가 복잡
- **버전 불일치 리스크**: 공유 라이브러리 버전 충돌 시 디버깅이 어려움
- **소규모에는 오버엔지니어링**

---

## 8. 면접 포인트

**Q. 마이크로 프론트엔드를 도입하는 이유는?**

> 팀 규모가 커지면 하나의 프론트엔드 레포지토리에서 여러 팀이 동시에 작업하면 배포 병목과 충돌이 잦아집니다.
> 마이크로 프론트엔드는 각 도메인 팀이 자신의 영역을 독립적으로 개발/배포할 수 있게 하여
> 팀 간 결합도를 낮추고 배포 속도를 높입니다.

**Q. Module Federation에서 singleton: true 옵션이 왜 중요한가요?**

> React처럼 전역 상태를 유지하는 라이브러리가 두 개의 인스턴스로 로드되면
> Hooks나 Context가 서로 다른 인스턴스를 참조하여 오류가 발생합니다.
> singleton: true 설정으로 하나의 공유 인스턴스만 사용하게 강제하면 이 문제를 방지할 수 있습니다.

**Q. MFE 간 상태 공유는 어떻게 하나요?**

> MFE 간 직접 상태 공유는 결합도를 높이므로 피해야 합니다.
> 대신 Custom Events, URL 파라미터, Shell이 제공하는 최소한의 이벤트 버스를 통해 느슨하게 통신합니다.
> 공통 데이터(인증 정보, 사용자 정보)는 Shell에서 관리하고 MFE에 prop으로 전달하거나 공유 스토어로 제공합니다.
