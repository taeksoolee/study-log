# 3. Clean Architecture in Frontend

## 목차

1. [Clean Architecture란](#1-clean-architecture란)
2. [핵심 원칙](#2-핵심-원칙)
3. [프론트엔드 레이어 구조](#3-프론트엔드-레이어-구조)
4. [React에서 Clean Architecture 적용 예제](#4-react에서-clean-architecture-적용-예제)
5. [Use Case 패턴](#5-use-case-패턴)
6. [Repository 패턴 (API 추상화)](#6-repository-패턴-api-추상화)
7. [장단점](#7-장단점)
8. [면접 포인트](#8-면접-포인트)

---

## 1. Clean Architecture란

**Clean Architecture**는 Robert C. Martin(Uncle Bob)이 제안한 소프트웨어 설계 원칙이다.
핵심은 **비즈니스 로직(도메인)을 외부 세계(UI, 데이터베이스, 프레임워크)로부터 완전히 격리**하는 것이다.

원의 안쪽일수록 고수준(핵심 비즈니스 로직), 바깥쪽일수록 저수준(구현 세부사항)이다.

```
      ┌──────────────────────────────────┐
      │         Infrastructure           │  ← HTTP, LocalStorage, 외부 API
      │  ┌────────────────────────────┐  │
      │  │       Presentation         │  │  ← React 컴포넌트, 상태 관리
      │  │  ┌──────────────────────┐  │  │
      │  │  │     Application      │  │  │  ← Use Cases, 앱 서비스
      │  │  │  ┌────────────────┐  │  │  │
      │  │  │  │    Domain      │  │  │  │  ← 엔티티, 도메인 규칙
      │  │  │  └────────────────┘  │  │  │
      │  │  └──────────────────────┘  │  │
      │  └────────────────────────────┘  │
      └──────────────────────────────────┘
```

**의존성 방향**: 항상 안쪽을 향한다 (바깥쪽 → 안쪽).
Domain 레이어는 어떤 것에도 의존하지 않는다.

---

## 2. 핵심 원칙

### 의존성 역전 원칙 (Dependency Inversion Principle)

고수준 모듈이 저수준 모듈에 의존하는 것이 아니라, **둘 다 추상화(인터페이스)에 의존**해야 한다.

```typescript
// 나쁜 예: Domain이 Infrastructure에 직접 의존
class OrderService {
  async createOrder(userId: string, items: CartItem[]) {
    // axios를 직접 호출 → Infrastructure에 결합됨
    const response = await axios.post('/api/orders', { userId, items })
    return response.data
  }
}

// 좋은 예: Domain은 인터페이스(추상화)에만 의존
interface IOrderRepository {
  create(order: CreateOrderDto): Promise<Order>
}

class OrderService {
  constructor(private orderRepository: IOrderRepository) {}  // 인터페이스에 의존

  async createOrder(userId: string, items: CartItem[]) {
    // 비즈니스 규칙 검증
    if (items.length === 0) throw new Error('장바구니가 비어있습니다')

    const order = new Order({ userId, items })
    return this.orderRepository.create(order)  // 구현 방식 몰라도 됨
  }
}
```

---

## 3. 프론트엔드 레이어 구조

```
src/
├── domain/           ← 가장 안쪽: 순수 비즈니스 로직
├── application/      ← Use Cases
├── infrastructure/   ← 외부 세계 연동 (API, Storage)
└── presentation/     ← UI 컴포넌트, 상태 관리
```

| 레이어 | 역할 | 의존 가능 | 예시 |
|--------|------|----------|------|
| **Domain** | 엔티티, 도메인 규칙, 인터페이스 | 없음 (독립) | `User`, `Order`, `IUserRepository` |
| **Application** | Use Case (앱의 비즈니스 흐름) | Domain | `LoginUseCase`, `CreateOrderUseCase` |
| **Infrastructure** | 외부 통신 구현체 | Domain (인터페이스 구현) | `AxiosUserRepository`, `LocalStorageAuthService` |
| **Presentation** | React 컴포넌트, 훅, 상태 | Application, Domain | `LoginForm`, `useLogin`, `UserStore` |

---

## 4. React에서 Clean Architecture 적용 예제

전체 폴더 구조:

```
src/
├── domain/
│   ├── entities/
│   │   ├── User.ts
│   │   └── Order.ts
│   ├── repositories/
│   │   ├── IUserRepository.ts
│   │   └── IOrderRepository.ts
│   └── services/
│       └── OrderDomainService.ts   ← 도메인 규칙 (할인 계산 등)
│
├── application/
│   └── use-cases/
│       ├── LoginUseCase.ts
│       ├── CreateOrderUseCase.ts
│       └── GetProductListUseCase.ts
│
├── infrastructure/
│   ├── repositories/
│   │   ├── AxiosUserRepository.ts   ← IUserRepository 구현체
│   │   └── AxiosOrderRepository.ts
│   ├── services/
│   │   └── LocalStorageAuthService.ts
│   └── di/
│       └── container.ts             ← 의존성 주입 설정
│
└── presentation/
    ├── components/
    │   ├── LoginForm.tsx
    │   └── OrderForm.tsx
    ├── hooks/
    │   ├── useLogin.ts
    │   └── useCreateOrder.ts
    └── pages/
        └── LoginPage.tsx
```

---

## 5. Use Case 패턴

Use Case는 하나의 **사용자 시나리오**를 캡슐화한다.

```typescript
// domain/entities/User.ts
export class User {
  constructor(
    public readonly id: string,
    public readonly email: string,
    public readonly name: string,
    private readonly role: 'admin' | 'user'
  ) {}

  isAdmin(): boolean {
    return this.role === 'admin'
  }

  canAccessDashboard(): boolean {
    return this.isAdmin()
  }
}

// domain/repositories/IUserRepository.ts
export interface IUserRepository {
  findByEmail(email: string): Promise<User | null>
  save(user: User): Promise<void>
}

// domain/repositories/IAuthService.ts
export interface IAuthService {
  login(email: string, password: string): Promise<string>  // JWT 토큰 반환
  logout(): Promise<void>
  getCurrentToken(): string | null
}

// application/use-cases/LoginUseCase.ts
import type { IUserRepository } from '@/domain/repositories/IUserRepository'
import type { IAuthService } from '@/domain/repositories/IAuthService'

interface LoginInput {
  email: string
  password: string
}

interface LoginOutput {
  user: User
  token: string
}

export class LoginUseCase {
  constructor(
    private userRepository: IUserRepository,
    private authService: IAuthService
  ) {}

  async execute({ email, password }: LoginInput): Promise<LoginOutput> {
    // 1. 인증 (Infrastructure에 위임)
    const token = await this.authService.login(email, password)

    // 2. 사용자 정보 조회
    const user = await this.userRepository.findByEmail(email)
    if (!user) throw new Error('사용자를 찾을 수 없습니다')

    // 3. 비즈니스 규칙 검증 (Domain 로직 활용)
    // 예: 정지된 계정 확인, 접근 권한 확인 등

    return { user, token }
  }
}
```

---

## 6. Repository 패턴 (API 추상화)

Repository 패턴은 데이터 접근 로직을 **인터페이스 뒤에 숨기는** 패턴이다.
Use Case는 데이터가 어디서 오는지(REST API, GraphQL, Mock)를 알 필요 없다.

```typescript
// domain/repositories/IUserRepository.ts
export interface IUserRepository {
  findByEmail(email: string): Promise<User | null>
  findById(id: string): Promise<User | null>
  save(user: User): Promise<void>
}

// infrastructure/repositories/AxiosUserRepository.ts
// IUserRepository의 실제 구현체 — HTTP API 사용
import { AxiosInstance } from 'axios'
import type { IUserRepository } from '@/domain/repositories/IUserRepository'
import { User } from '@/domain/entities/User'

export class AxiosUserRepository implements IUserRepository {
  constructor(private http: AxiosInstance) {}

  async findByEmail(email: string): Promise<User | null> {
    try {
      const { data } = await this.http.get(`/users?email=${email}`)
      return new User(data.id, data.email, data.name, data.role)
    } catch {
      return null
    }
  }

  async findById(id: string): Promise<User | null> {
    try {
      const { data } = await this.http.get(`/users/${id}`)
      return new User(data.id, data.email, data.name, data.role)
    } catch {
      return null
    }
  }

  async save(user: User): Promise<void> {
    await this.http.put(`/users/${user.id}`, user)
  }
}

// infrastructure/repositories/MockUserRepository.ts
// 테스트용 Mock 구현체 — 같은 인터페이스를 구현
export class MockUserRepository implements IUserRepository {
  private users: User[] = [
    new User('1', 'admin@test.com', 'Admin', 'admin'),
  ]

  async findByEmail(email: string): Promise<User | null> {
    return this.users.find((u) => u.email === email) ?? null
  }

  async findById(id: string): Promise<User | null> {
    return this.users.find((u) => u.id === id) ?? null
  }

  async save(user: User): Promise<void> {
    this.users.push(user)
  }
}

// infrastructure/di/container.ts — 의존성 주입
import axios from 'axios'
import { AxiosUserRepository } from '../repositories/AxiosUserRepository'
import { LoginUseCase } from '@/application/use-cases/LoginUseCase'

const httpClient = axios.create({ baseURL: '/api' })
const userRepository = new AxiosUserRepository(httpClient)
const authService = new LocalStorageAuthService()

export const loginUseCase = new LoginUseCase(userRepository, authService)

// presentation/hooks/useLogin.ts — React와 연결
import { useState } from 'react'
import { loginUseCase } from '@/infrastructure/di/container'

export const useLogin = () => {
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const login = async (email: string, password: string) => {
    setIsLoading(true)
    setError(null)
    try {
      const { user, token } = await loginUseCase.execute({ email, password })
      // 상태 관리 스토어에 저장
      return { user, token }
    } catch (err) {
      setError(err instanceof Error ? err.message : '로그인 실패')
    } finally {
      setIsLoading(false)
    }
  }

  return { login, isLoading, error }
}
```

---

## 7. 장단점

### 장점

- **테스트 용이성**: Domain과 Application 레이어는 프레임워크/HTTP 없이 순수 단위 테스트 가능
- **교체 가능성**: API를 REST에서 GraphQL로 바꿔도 Repository 구현체만 교체하면 됨
- **비즈니스 로직 보호**: UI 변경이나 라이브러리 교체가 핵심 로직에 영향을 주지 않음
- **장기 유지보수성**: 시스템이 커져도 각 레이어의 역할이 명확함

### 단점

- **초기 보일러플레이트 과다**: 인터페이스, 구현체, Use Case 등 파일이 급격히 늘어남
- **소규모 프로젝트에는 오버엔지니어링**: TODO 앱에 Clean Architecture는 불필요
- **러닝 커브**: 팀 전체가 패턴을 이해해야 효과적으로 적용 가능
- **DI 설정 복잡성**: 의존성 주입 컨테이너 관리가 번거로울 수 있음

### 언제 적합한가

- 복잡한 비즈니스 도메인을 가진 엔터프라이즈 애플리케이션
- 장기간 유지보수가 필요한 대형 프로젝트
- 다양한 데이터 소스(REST, GraphQL, WebSocket)를 유연하게 교체해야 할 때
- 단위 테스트 커버리지를 높게 유지해야 하는 팀

---

## 8. 면접 포인트

**Q. 프론트엔드에서 Clean Architecture를 적용하는 이유는?**

> React 컴포넌트 안에 API 호출과 비즈니스 로직이 뒤섞이면 테스트하기 어렵고 변경에 취약해집니다.
> Clean Architecture를 적용하면 비즈니스 로직을 Domain/Application 레이어에 격리하여
> 프레임워크 없이 순수 함수로 테스트할 수 있고, UI와 API를 독립적으로 교체할 수 있습니다.

**Q. Repository 패턴을 왜 사용하나요?**

> Application 레이어(Use Case)가 axios나 fetch 같은 특정 HTTP 구현에 직접 의존하면,
> 나중에 라이브러리를 바꾸거나 테스트 시 Mock으로 교체하기 어렵습니다.
> Repository 인터페이스를 정의하고 구현체를 분리하면 Use Case는 추상화에만 의존하게 되어
> 테스트 시 MockRepository를 주입하고, 프로덕션에서는 AxiosRepository를 주입하는 방식으로 유연하게 사용할 수 있습니다.

**Q. Clean Architecture가 소규모 프로젝트에 오버엔지니어링인 이유는?**

> 인터페이스, 구현체, Use Case, DI 컨테이너 등 파일이 급격히 늘어나 생산성이 저하됩니다.
> 프로젝트 규모가 작을 때는 컴포넌트에 직접 API 호출을 두거나 간단한 서비스 함수를 사용하는 것이
> 더 효율적입니다. 아키텍처 복잡도는 실제 비즈니스 복잡도와 비례해야 합니다.
