# 2. Atomic Design

## 목차

1. [Atomic Design이란](#1-atomic-design이란)
2. [5단계 구조](#2-5단계-구조)
3. [각 단계 상세 예시](#3-각-단계-상세-예시)
4. [Storybook과의 궁합](#4-storybook과의-궁합)
5. [FSD와 비교](#5-fsd와-비교-ui-중심-vs-기능-중심)
6. [장단점](#6-장단점)
7. [면접 포인트](#7-면접-포인트)

---

## 1. Atomic Design이란

**Atomic Design**은 Brad Frost가 2013년에 제안한 UI 컴포넌트 설계 방법론이다.
화학에서 원자(Atom)가 결합하여 분자(Molecule)가 되고, 분자가 모여 유기체(Organism)가 되듯,
UI 컴포넌트도 작은 단위에서 큰 단위로 조합하여 설계한다는 개념이다.

핵심 철학:
- **재사용성**: 작은 단위를 조합하여 큰 컴포넌트를 만든다
- **일관성**: 동일한 Atom을 사용하기 때문에 디자인 시스템 전체가 일관성을 유지한다
- **독립성**: 각 단계의 컴포넌트는 상위 컨텍스트에 의존하지 않아야 한다

---

## 2. 5단계 구조

```
Pages
  └── Templates
        └── Organisms
              └── Molecules
                    └── Atoms
```

| 단계 | 설명 | 비유 |
|------|------|------|
| **Atoms** | 더 이상 쪼갤 수 없는 최소 단위 UI | 원자 |
| **Molecules** | Atoms의 조합으로 이루어진 단순한 UI 그룹 | 분자 |
| **Organisms** | Molecules/Atoms를 조합한 독립적인 섹션 | 유기체 |
| **Templates** | 실제 콘텐츠 없이 레이아웃만 정의한 와이어프레임 | 골격 |
| **Pages** | Templates에 실제 데이터가 채워진 최종 화면 | 완성된 페이지 |

---

## 3. 각 단계 상세 예시

### Atoms — 최소 단위

```typescript
// components/atoms/Button/Button.tsx
interface ButtonProps {
  label: string
  variant: 'primary' | 'secondary' | 'danger'
  size: 'sm' | 'md' | 'lg'
  disabled?: boolean
  onClick?: () => void
}

export const Button = ({ label, variant, size, disabled, onClick }: ButtonProps) => {
  return (
    <button
      className={`btn btn-${variant} btn-${size}`}
      disabled={disabled}
      onClick={onClick}
    >
      {label}
    </button>
  )
}
```

Atoms의 예:
- `Button`, `Input`, `Label`, `Icon`, `Badge`, `Spinner`
- `Typography` (H1, H2, P, Span)
- `Avatar` (사용자 이미지)
- `Checkbox`, `Radio`, `Toggle`

### Molecules — Atoms의 조합

```typescript
// components/molecules/SearchBar/SearchBar.tsx
import { Input } from '@/atoms/Input'
import { Button } from '@/atoms/Button'
import { Icon } from '@/atoms/Icon'

interface SearchBarProps {
  placeholder?: string
  onSearch: (query: string) => void
}

export const SearchBar = ({ placeholder = '검색어를 입력하세요', onSearch }: SearchBarProps) => {
  const [query, setQuery] = useState('')

  const handleSearch = () => onSearch(query)

  return (
    <div className="search-bar">
      <Icon name="search" />
      <Input
        value={query}
        placeholder={placeholder}
        onChange={(e) => setQuery(e.target.value)}
        onKeyDown={(e) => e.key === 'Enter' && handleSearch()}
      />
      <Button label="검색" variant="primary" size="md" onClick={handleSearch} />
    </div>
  )
}
```

Molecules의 예:
- `SearchBar` (Input + Button + Icon)
- `FormField` (Label + Input + ErrorMessage)
- `ProductPrice` (원가 + 할인가 + 할인율 Badge)
- `UserInfo` (Avatar + Name + Role Label)

### Organisms — 독립적인 섹션

```typescript
// components/organisms/Header/Header.tsx
import { Logo } from '@/atoms/Logo'
import { NavigationMenu } from '@/molecules/NavigationMenu'
import { SearchBar } from '@/molecules/SearchBar'
import { UserDropdown } from '@/molecules/UserDropdown'
import { CartIcon } from '@/molecules/CartIcon'

interface HeaderProps {
  user: User | null
  cartItemCount: number
  onSearch: (query: string) => void
}

export const Header = ({ user, cartItemCount, onSearch }: HeaderProps) => {
  return (
    <header className="header">
      <Logo />
      <NavigationMenu />
      <SearchBar onSearch={onSearch} />
      <div className="header-actions">
        <CartIcon count={cartItemCount} />
        <UserDropdown user={user} />
      </div>
    </header>
  )
}
```

Organisms의 예:
- `Header` (Logo + Nav + SearchBar + UserMenu)
- `ProductCard` (Image + Title + Price + AddToCartButton)
- `CommentSection` (CommentList + CommentForm)
- `Footer` (Links + Copyright + SocialIcons)

### Templates — 레이아웃 골격

```typescript
// components/templates/MainLayout/MainLayout.tsx
// 실제 데이터 없이 레이아웃(골격)만 정의
interface MainLayoutProps {
  header: ReactNode
  sidebar?: ReactNode
  content: ReactNode
  footer: ReactNode
}

export const MainLayout = ({ header, sidebar, content, footer }: MainLayoutProps) => {
  return (
    <div className="layout">
      <div className="layout-header">{header}</div>
      <div className="layout-body">
        {sidebar && <aside className="layout-sidebar">{sidebar}</aside>}
        <main className="layout-content">{content}</main>
      </div>
      <div className="layout-footer">{footer}</div>
    </div>
  )
}
```

### Pages — 실제 데이터가 채워진 화면

```typescript
// components/pages/HomePage/HomePage.tsx
// 실제 데이터(API, 상태)를 연결하는 곳
import { MainLayout } from '@/templates/MainLayout'
import { Header } from '@/organisms/Header'
import { ProductGrid } from '@/organisms/ProductGrid'
import { Footer } from '@/organisms/Footer'

export const HomePage = () => {
  const { user } = useAuth()
  const { cartItems } = useCart()
  const { products } = useProducts()
  const navigate = useNavigate()

  const handleSearch = (query: string) => {
    navigate(`/search?q=${query}`)
  }

  return (
    <MainLayout
      header={
        <Header
          user={user}
          cartItemCount={cartItems.length}
          onSearch={handleSearch}
        />
      }
      content={<ProductGrid products={products} />}
      footer={<Footer />}
    />
  )
}
```

### 폴더 구조

```
src/
└── components/
    ├── atoms/
    │   ├── Button/
    │   │   ├── Button.tsx
    │   │   ├── Button.stories.tsx
    │   │   ├── Button.test.tsx
    │   │   └── index.ts
    │   ├── Input/
    │   ├── Icon/
    │   └── Badge/
    ├── molecules/
    │   ├── SearchBar/
    │   ├── FormField/
    │   └── UserInfo/
    ├── organisms/
    │   ├── Header/
    │   ├── ProductCard/
    │   └── CommentSection/
    ├── templates/
    │   ├── MainLayout/
    │   └── AuthLayout/
    └── pages/
        ├── HomePage/
        └── ProductPage/
```

---

## 4. Storybook과의 궁합

Atomic Design은 **Storybook**과 매우 잘 어울린다. 각 단계의 컴포넌트를 독립적으로 개발하고 문서화할 수 있기 때문이다.

```typescript
// components/atoms/Button/Button.stories.tsx
import type { Meta, StoryObj } from '@storybook/react'
import { Button } from './Button'

const meta: Meta<typeof Button> = {
  title: 'Atoms/Button',
  component: Button,
  tags: ['autodocs'],
  argTypes: {
    variant: {
      control: { type: 'select' },
      options: ['primary', 'secondary', 'danger'],
    },
    size: {
      control: { type: 'radio' },
      options: ['sm', 'md', 'lg'],
    },
  },
}

export default meta
type Story = StoryObj<typeof Button>

export const Primary: Story = {
  args: { label: '확인', variant: 'primary', size: 'md' },
}

export const Disabled: Story = {
  args: { label: '비활성화', variant: 'primary', size: 'md', disabled: true },
}
```

Storybook 계층 구조:
```
Atoms/
  Button
  Input
  Badge
Molecules/
  SearchBar
  FormField
Organisms/
  Header
  ProductCard
```

---

## 5. FSD와 비교: UI 중심 vs 기능 중심

| 관점 | Atomic Design | FSD |
|------|--------------|-----|
| **분류 기준** | UI 복잡도 (작은 → 큰) | 비즈니스 도메인 |
| **주요 관심사** | 컴포넌트 재사용성, 디자인 일관성 | 기능 독립성, 의존성 방향 |
| **적합한 팀** | 디자인 시스템 구축 팀, UI 라이브러리 | 서비스 개발 팀, 도메인이 복잡한 앱 |
| **Storybook** | 매우 자연스러운 연동 | 상대적으로 덜 자연스러움 |
| **비즈니스 로직** | Pages에 집중됨 | features/entities에 분산됨 |
| **학습 난이도** | 상대적으로 쉬움 | 다소 높음 |

### 함께 사용하는 방법

두 방법론은 상호 보완적으로 사용할 수 있다.

```
FSD의 shared/ui 또는 entities/product/ui 안에서 Atomic Design 적용
shared/
  ui/
    atoms/
      Button/
      Input/
    molecules/
      SearchBar/
```

---

## 6. 장단점

### 장점

- UI 컴포넌트의 **재사용성과 일관성** 극대화
- **디자인 시스템**을 구축할 때 자연스러운 흐름
- Storybook과 결합하면 **컴포넌트 문서화 자동화** 가능
- 개발자와 디자이너 간 **공통 언어** 제공

### 단점

- **어느 단계에 넣어야 하는지** 경계가 모호한 경우 많음
  (SearchBar는 Molecule인가 Organism인가?)
- 비즈니스 로직이 복잡해지면 Pages에 **로직이 집중**되는 문제
- 도메인 변경 시 여러 레이어에 걸쳐 수정이 필요할 수 있음
- **순수 UI 분류**이므로 상태 관리, API 연동 방식에 대한 가이드 부재

---

## 7. 면접 포인트

**Q. Atomic Design에서 Organisms과 Templates의 차이는?**

> Organisms는 재사용 가능한 독립적인 UI 섹션이고, Templates는 페이지의 레이아웃 골격(와이어프레임)입니다.
> Organisms는 실제 데이터와 무관하게 특정 UI 블록(예: Header)을 나타내고,
> Templates는 데이터 없이 페이지 전체의 구조(레이아웃)를 정의합니다.
> Pages는 Templates에 실제 데이터가 주입된 결과물입니다.

**Q. Atomic Design의 단점은 무엇이고, 실무에서 어떻게 보완하나요?**

> 컴포넌트를 어느 단계에 분류할지 경계가 애매한 문제가 있습니다.
> 실무에서는 팀 내 기준을 명확히 정하거나, Atomic Design을 UI 컴포넌트 라이브러리(shared/ui)에만 적용하고
> 비즈니스 로직은 FSD나 별도 레이어로 관리하는 방식으로 보완합니다.

**Q. Atomic Design과 Storybook을 함께 쓸 때의 이점은?**

> 컴포넌트 계층 구조가 Storybook의 폴더 구조와 1:1로 매핑되어 문서화가 자연스럽습니다.
> Atoms 단계부터 독립적으로 개발하고 테스트할 수 있으며,
> 디자이너와 개발자가 동일한 컴포넌트 목록을 보며 소통할 수 있습니다.
