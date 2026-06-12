# 2. DDD (도메인 주도 설계)

## 목차
1. DDD란 무엇인가
2. Ubiquitous Language (공통 언어)
3. Bounded Context (경계된 컨텍스트)
4. Entity vs Value Object
5. Aggregate (집계 루트)
6. Domain Service & Application Service
7. Repository 패턴
8. Domain Event
9. 프론트엔드에서 DDD 적용
10. FSD와 DDD의 관계
11. 면접 포인트

---

## 1. DDD란 무엇인가

DDD(Domain-Driven Design)는 Eric Evans가 2003년 저서에서 정립한 설계 접근법으로, **비즈니스 도메인의 복잡성을 소프트웨어 모델에 반영**하는 데 집중합니다.

```
전통적 접근:  DB 스키마 → 서비스 → UI
DDD 접근:     도메인 모델 → 도메인 서비스 → 인프라 / UI
```

핵심 사상: **소프트웨어의 복잡성은 비즈니스 복잡성에서 온다. 도메인 전문가와 개발자가 같은 언어로 대화해야 한다.**

---

## 2. Ubiquitous Language (공통 언어)

도메인 전문가와 개발자가 **동일한 용어**를 사용하는 것입니다. 코드의 클래스 이름, 메서드 이름이 비즈니스 용어와 일치해야 합니다.

```typescript
// Bad: 기술 용어 중심
class UserDataProcessor {
  processUserRecord(data: Record<string, unknown>): void { }
}

// Good: 도메인 언어 중심 (전자상거래)
class OrderFulfillmentService {
  shipOrder(order: Order): void { }
  cancelOrder(order: Order, reason: CancellationReason): void { }
}
```

도메인 용어 사전 예시 (전자상거래):

```
주문(Order)      - 고객이 상품 구매를 요청한 행위
배송(Shipment)   - 주문된 상품을 발송하는 물류 단위
정산(Settlement) - 판매 대금을 정산하는 회계 단위
취소(Cancellation) - 주문을 철회하는 행위 (배송 전/후 구분)
```

---

## 3. Bounded Context (경계된 컨텍스트)

하나의 도메인 모델이 유효한 **경계**입니다. 같은 단어도 컨텍스트마다 다른 의미를 가질 수 있습니다.

```
┌─────────────────────────┐    ┌─────────────────────────┐
│   주문 컨텍스트          │    │   배송 컨텍스트          │
│                         │    │                         │
│  User = 주문자          │    │  User = 수령인          │
│  Product = 주문 상품    │    │  Product = 배송 물품    │
│  Order = 주문 엔티티    │    │  Order = 배송 지시서    │
└─────────────────────────┘    └─────────────────────────┘
           │  Context Map  │
           └───────────────┘
```

프론트엔드 폴더 구조 반영:

```
src/
├── features/
│   ├── order/          # 주문 컨텍스트
│   │   ├── domain/
│   │   ├── api/
│   │   └── ui/
│   ├── shipping/       # 배송 컨텍스트
│   │   ├── domain/
│   │   ├── api/
│   │   └── ui/
│   └── payment/        # 결제 컨텍스트
```

---

## 4. Entity vs Value Object

### Entity (엔티티)
- **고유 식별자(id)**로 동일성을 판단
- 상태가 변할 수 있음 (mutable)
- 생명주기가 있음

```typescript
class User {
  constructor(
    public readonly id: string,   // 식별자
    public name: string,
    public email: string
  ) {}

  // 같은 id면 같은 User (이름이 바뀌어도)
  equals(other: User): boolean {
    return this.id === other.id;
  }
}
```

### Value Object (값 객체)
- **속성 값**으로 동일성을 판단
- 불변(immutable)
- 식별자 없음

```typescript
class Money {
  constructor(
    public readonly amount: number,
    public readonly currency: 'KRW' | 'USD'
  ) {}

  add(other: Money): Money {
    if (this.currency !== other.currency) {
      throw new Error('통화가 다릅니다');
    }
    return new Money(this.amount + other.amount, this.currency);
  }

  equals(other: Money): boolean {
    return this.amount === other.amount && this.currency === other.currency;
  }
}

class Address {
  constructor(
    public readonly city: string,
    public readonly street: string,
    public readonly zipCode: string
  ) {}
}

// 사용
const price = new Money(10000, 'KRW');
const tax = new Money(1000, 'KRW');
const total = price.add(tax); // 새 객체 반환 (불변)
```

---

## 5. Aggregate (집계 루트)

연관된 객체들의 묶음으로, **Aggregate Root**를 통해서만 내부 객체에 접근합니다.

```typescript
// Order가 Aggregate Root
class Order {
  private _items: OrderItem[] = [];

  constructor(
    public readonly id: string,
    private readonly customerId: string
  ) {}

  // 외부에서 OrderItem에 직접 접근 불가 — Order를 통해서만
  addItem(productId: string, price: Money, quantity: number): void {
    const existing = this._items.find((i) => i.productId === productId);
    if (existing) {
      existing.increaseQuantity(quantity);
    } else {
      this._items.push(new OrderItem(productId, price, quantity));
    }
  }

  removeItem(productId: string): void {
    this._items = this._items.filter((i) => i.productId !== productId);
  }

  get totalAmount(): Money {
    return this._items.reduce(
      (sum, item) => sum.add(item.subtotal),
      new Money(0, 'KRW')
    );
  }

  get items(): readonly OrderItem[] {
    return this._items;
  }
}

class OrderItem {
  constructor(
    public readonly productId: string,
    private price: Money,
    private _quantity: number
  ) {}

  increaseQuantity(amount: number): void {
    this._quantity += amount;
  }

  get subtotal(): Money {
    return new Money(this.price.amount * this._quantity, this.price.currency);
  }

  get quantity(): number {
    return this._quantity;
  }
}
```

---

## 6. Domain Service & Application Service

### Domain Service
- 특정 엔티티에 속하지 않는 **도메인 로직**
- 비즈니스 규칙 포함

```typescript
// 도메인 서비스: 두 개의 엔티티에 걸쳐 있는 비즈니스 로직
class TransferService {
  transfer(from: Account, to: Account, amount: Money): void {
    if (from.balance.amount < amount.amount) {
      throw new InsufficientFundsError();
    }
    from.withdraw(amount);
    to.deposit(amount);
  }
}
```

### Application Service
- 유스케이스 오케스트레이션
- 도메인 로직 없음, 도메인 서비스/엔티티 호출 조율

```typescript
// 애플리케이션 서비스: 유스케이스 실행 흐름 조율
class OrderApplicationService {
  constructor(
    private orderRepository: OrderRepository,
    private paymentService: PaymentService,
    private eventBus: EventBus
  ) {}

  async placeOrder(command: PlaceOrderCommand): Promise<string> {
    const order = Order.create(command.customerId, command.items);
    await this.paymentService.authorize(order.totalAmount);
    await this.orderRepository.save(order);
    this.eventBus.publish(new OrderPlacedEvent(order.id));
    return order.id;
  }
}
```

---

## 7. Repository 패턴

도메인 객체의 **영속성(persistence)을 추상화**합니다. 도메인 레이어는 저장 방식을 알 필요가 없습니다.

```typescript
// 인터페이스 (도메인 레이어)
interface OrderRepository {
  findById(id: string): Promise<Order | null>;
  findByCustomerId(customerId: string): Promise<Order[]>;
  save(order: Order): Promise<void>;
  delete(id: string): Promise<void>;
}

// 구현체 (인프라 레이어 — REST API)
class OrderApiRepository implements OrderRepository {
  constructor(private http: HttpClient) {}

  async findById(id: string): Promise<Order | null> {
    const data = await this.http.get(`/orders/${id}`);
    return data ? OrderMapper.toDomain(data) : null;
  }

  async save(order: Order): Promise<void> {
    await this.http.put(`/orders/${order.id}`, OrderMapper.toDto(order));
  }

  // ...
}

// 테스트용 인메모리 구현체
class InMemoryOrderRepository implements OrderRepository {
  private store = new Map<string, Order>();

  async findById(id: string): Promise<Order | null> {
    return this.store.get(id) ?? null;
  }

  async save(order: Order): Promise<void> {
    this.store.set(order.id, order);
  }

  // ...
}
```

---

## 8. Domain Event

도메인 내에서 발생한 **중요한 사건**을 이벤트로 표현합니다.

```typescript
// 도메인 이벤트 정의
class OrderPlacedEvent {
  readonly occurredAt: Date = new Date();

  constructor(
    public readonly orderId: string,
    public readonly customerId: string,
    public readonly totalAmount: Money
  ) {}
}

class OrderCancelledEvent {
  readonly occurredAt: Date = new Date();

  constructor(
    public readonly orderId: string,
    public readonly reason: string
  ) {}
}

// Aggregate에서 이벤트 발행
class Order {
  private _domainEvents: unknown[] = [];

  cancel(reason: string): void {
    this._status = 'CANCELLED';
    this._domainEvents.push(new OrderCancelledEvent(this.id, reason));
  }

  pullDomainEvents(): unknown[] {
    const events = [...this._domainEvents];
    this._domainEvents = [];
    return events;
  }
}
```

---

## 9. 프론트엔드에서 DDD 적용

프론트엔드도 비즈니스 로직이 복잡해지면 DDD 개념을 적용할 수 있습니다.

```typescript
// 상태 관리에 도메인 모델 반영 (Zustand + DDD)
interface CartState {
  cart: Cart;
  addItem: (item: CartItem) => void;
  removeItem: (id: string) => void;
  applyDiscount: (code: string) => void;
}

const useCartStore = create<CartState>((set) => ({
  cart: new Cart(),

  addItem: (item) =>
    set((state) => {
      const newCart = state.cart.clone();
      newCart.addItem(item);           // 도메인 메서드 호출
      return { cart: newCart };
    }),

  applyDiscount: (code) =>
    set((state) => {
      const discount = DiscountService.resolve(code); // 도메인 서비스
      const newCart = state.cart.applyDiscount(discount);
      return { cart: newCart };
    }),
}));
```

---

## 10. FSD와 DDD의 관계

Feature-Sliced Design(FSD)은 프론트엔드에서 DDD의 Bounded Context를 구현하는 아키텍처 패턴입니다.

```
DDD 개념               FSD 레이어
─────────────────────────────────────
Bounded Context   ↔   feature/
Domain Model      ↔   entities/
Application Svc   ↔   features/ (model layer)
Infrastructure    ↔   shared/api/
UI                ↔   widgets/, pages/
```

```
src/
├── entities/
│   ├── order/          # Order Entity
│   │   ├── model/      # Order 클래스, Value Objects
│   │   └── api/        # OrderRepository 구현
│   └── user/
├── features/
│   ├── place-order/    # Application Service
│   └── cancel-order/
├── shared/
│   └── api/            # HttpClient (Infrastructure)
```

---

## 11. 면접 포인트

**Q. DDD에서 Entity와 Value Object의 차이는?**

Entity는 고유 식별자로 동일성을 판단하며 상태가 변할 수 있습니다. Value Object는 속성 값으로 동일성을 판단하며 불변입니다. 예를 들어 `User`는 Entity(id로 구별), `Money`나 `Address`는 Value Object입니다.

**Q. Bounded Context가 왜 중요한가요?**

하나의 도메인 모델이 모든 컨텍스트에서 동일한 의미를 가지면 모델이 점점 비대해지고 복잡해집니다. Bounded Context로 경계를 명확히 하면 각 컨텍스트 내에서 일관된 모델을 유지할 수 있습니다.

**Q. Repository 패턴을 사용하는 이유는?**

도메인 레이어가 데이터 저장 방식(REST, GraphQL, localStorage 등)에 의존하지 않도록 추상화합니다. 저장소 구현체를 교체해도 도메인 로직은 변경되지 않으며, 테스트 시 InMemory 구현체로 대체할 수 있습니다.

**Q. 프론트엔드에서 DDD가 필요한 경우는?**

비즈니스 로직이 UI 컴포넌트 안에 산재해 있거나, 같은 도메인 개념이 여러 곳에 중복 구현되거나, 요구사항 변경 시 수정 범위가 불명확한 경우에 DDD 접근법이 도움이 됩니다.
