# 4. 클린 코드 원칙

## 목차
1. 클린 코드란 무엇인가
2. 의미있는 이름
3. 함수: 작게, 하나만, 동사+명사
4. 주석: 코드가 설명하고 주석은 WHY만
5. 에러 처리: null 반환 금지, 예외 사용
6. 테스트: F.I.R.S.T 원칙
7. 리팩터링 신호들 (코드 냄새)
8. JS/TS 특화 클린 코드 팁
9. 면접 포인트

---

## 1. 클린 코드란 무엇인가

Robert C. Martin의 정의: **"클린 코드는 읽기 쉬운 코드다. 작성자가 아닌 다른 사람이 읽었을 때도 이해할 수 있는 코드다."**

```
나쁜 코드의 결과:
  기능 추가 시간 ↑ → 팀 속도 ↓ → 기술 부채 ↑ → 결국 재작성

클린 코드의 가치:
  읽기 시간 vs 쓰기 시간 = 10 : 1
  코드는 쓰는 시간보다 읽는 시간이 훨씬 길다
```

---

## 2. 의미있는 이름

### 변수명: 의도를 드러내라

```typescript
// Bad
const d = 7; // 경과 일수?
const list = getList();
const x = user.data;

// Good
const elapsedDaysInSprint = 7;
const activeUsers = getActiveUsers();
const profileImageUrl = user.avatarUrl;
```

### 검색 가능한 이름

```typescript
// Bad: 매직 넘버 — 5가 무엇인지 알 수 없음
if (employee.type === 5) { /* ... */ }

// Good
const MANAGER_TYPE_CODE = 5;
if (employee.type === MANAGER_TYPE_CODE) { /* ... */ }

// 더 좋음: enum 사용
enum EmployeeType {
  JUNIOR = 1,
  SENIOR = 2,
  MANAGER = 5,
}
if (employee.type === EmployeeType.MANAGER) { /* ... */ }
```

### 일관성 있는 이름

```typescript
// Bad: 같은 개념에 다른 이름 사용
function getUserInfo() { /* ... */ }
function fetchUserData() { /* ... */ }
function retrieveUserProfile() { /* ... */ }

// Good: 하나의 단어 선택 후 일관성 유지
function getUser() { /* ... */ }
function getUserOrders() { /* ... */ }
function getUserAddresses() { /* ... */ }
```

### Boolean 변수명

```typescript
// Bad
const flag = true;
const check = isValid();

// Good: is/has/can/should 접두사
const isLoggedIn = true;
const hasPermission = checkPermission();
const canEdit = user.role === 'EDITOR';
const shouldRedirect = !isAuthenticated;
```

---

## 3. 함수: 작게, 하나만, 동사+명사

### 함수는 하나의 일만

```typescript
// Bad: 여러 가지 일을 하는 함수
async function processUserRegistration(data: RegisterData) {
  // 일 1: 유효성 검사
  if (!data.email.includes('@')) throw new Error('Invalid email');
  if (data.password.length < 8) throw new Error('Password too short');

  // 일 2: DB 저장
  const user = await db.users.create(data);

  // 일 3: 이메일 발송
  await emailService.sendWelcome(user.email);

  // 일 4: 로그
  logger.info(`User registered: ${user.id}`);

  return user;
}

// Good: 각 책임을 별도 함수로
function validateRegistrationData(data: RegisterData): void {
  if (!data.email.includes('@')) throw new ValidationError('Invalid email');
  if (data.password.length < 8) throw new ValidationError('Password too short');
}

async function createUser(data: RegisterData): Promise<User> {
  return db.users.create(data);
}

async function sendWelcomeEmail(email: string): Promise<void> {
  await emailService.sendWelcome(email);
}

async function registerUser(data: RegisterData): Promise<User> {
  validateRegistrationData(data);
  const user = await createUser(data);
  await sendWelcomeEmail(user.email);
  logger.info(`User registered: ${user.id}`);
  return user;
}
```

### 함수 인수는 적게

```typescript
// Bad: 인수 4개 이상 — 순서를 기억하기 어렵고 호출부가 난해함
function createUser(name: string, email: string, age: number, role: string, isActive: boolean) { }

// Good: 객체로 묶기
interface CreateUserParams {
  name: string;
  email: string;
  age: number;
  role: string;
  isActive: boolean;
}
function createUser(params: CreateUserParams): User { }

// 호출부가 명확해짐
createUser({ name: '홍길동', email: 'hong@example.com', age: 30, role: 'USER', isActive: true });
```

### 추상화 수준을 일치시켜라

```typescript
// Bad: 함수 내 추상화 수준이 섞임
async function processOrder(orderId: string) {
  const order = await orderRepository.findById(orderId); // 고수준
  const sql = `SELECT * FROM payments WHERE order_id = '${orderId}'`; // 저수준 — 섞임
  const payment = await db.query(sql);
  await notificationService.notifyOrderConfirmed(order); // 고수준
}

// Good: 일관된 추상화 수준
async function processOrder(orderId: string) {
  const order = await orderRepository.findById(orderId);
  const payment = await paymentRepository.findByOrderId(orderId);
  await notificationService.notifyOrderConfirmed(order);
}
```

---

## 4. 주석: 코드가 설명하고 주석은 WHY만

### 나쁜 주석

```typescript
// Bad: 코드가 이미 설명하는 것을 주석으로 반복
// user의 나이를 반환한다
function getUserAge(user: User): number {
  return user.age;
}

// i를 1 증가시킨다
i++;

// 사용자 리스트를 가져온다
const users = await getUsers();
```

### 좋은 주석 — WHY를 설명

```typescript
// Good: 비즈니스 의사결정 이유를 설명
// KCP 결제 모듈은 주문 금액이 0원이면 오류를 반환하므로
// 무료 상품의 경우 결제 모듈을 우회한다
if (order.totalAmount === 0) {
  return completeOrderWithoutPayment(order);
}

// PERF: 이 계산은 렌더링마다 호출되므로 useMemo로 캐싱
// 상품 목록이 1000개 이상일 때 성능 이슈가 확인됨 (#1234)
const sortedProducts = useMemo(
  () => [...products].sort((a, b) => a.price - b.price),
  [products]
);

// TODO: API 팀의 페이지네이션 지원 후 제거 예정 (2024 Q2)
const ALL_ITEMS_LIMIT = 9999;
```

### 코드로 의도를 표현하라

```typescript
// Bad: 주석으로 의도 설명
// 관리자이고 활성 상태인 사용자인지 확인
if (user.role === 'ADMIN' && user.status === 'ACTIVE' && user.lastLoginAt > thirtyDaysAgo) {
  // ...
}

// Good: 함수 이름으로 의도 표현
function isActiveAdmin(user: User): boolean {
  const thirtyDaysAgo = subDays(new Date(), 30);
  return user.role === 'ADMIN' && user.status === 'ACTIVE' && user.lastLoginAt > thirtyDaysAgo;
}

if (isActiveAdmin(user)) { /* ... */ }
```

---

## 5. 에러 처리: null 반환 금지, 예외 사용

### null 반환 금지

```typescript
// Bad: null 반환 — 호출부에서 매번 null 체크해야 함
function findUser(id: string): User | null {
  return users.find((u) => u.id === id) || null;
}

const user = findUser('123');
if (user !== null) {       // 잊으면 런타임 에러
  user.doSomething();
}

// Good 1: 예외 던지기
function getUser(id: string): User {
  const user = users.find((u) => u.id === id);
  if (!user) throw new UserNotFoundError(id);
  return user;
}

// Good 2: Optional 패턴 (명시적으로 없을 수 있음을 표현)
function findUser(id: string): User | undefined {
  return users.find((u) => u.id === id);
}

// Good 3: Result 타입 패턴
type Result<T, E = Error> =
  | { success: true; data: T }
  | { success: false; error: E };

function findUser(id: string): Result<User> {
  const user = users.find((u) => u.id === id);
  if (!user) return { success: false, error: new UserNotFoundError(id) };
  return { success: true, data: user };
}
```

### 에러 클래스 활용

```typescript
// 도메인 에러 계층 구조
class AppError extends Error {
  constructor(
    message: string,
    public readonly code: string,
    public readonly statusCode: number = 500
  ) {
    super(message);
    this.name = this.constructor.name;
  }
}

class ValidationError extends AppError {
  constructor(field: string, message: string) {
    super(`Validation failed for ${field}: ${message}`, 'VALIDATION_ERROR', 400);
  }
}

class NotFoundError extends AppError {
  constructor(resource: string, id: string) {
    super(`${resource} with id ${id} not found`, 'NOT_FOUND', 404);
  }
}

// 사용
function getUser(id: string): User {
  const user = db.findById(id);
  if (!user) throw new NotFoundError('User', id);
  return user;
}
```

---

## 6. 테스트: F.I.R.S.T 원칙

| 원칙 | 의미 | 설명 |
|------|------|------|
| **F**ast | 빠르게 | 테스트는 빨라야 자주 실행한다 |
| **I**ndependent | 독립적으로 | 테스트간 의존성이 없어야 한다 |
| **R**epeatable | 반복 가능하게 | 어떤 환경에서도 같은 결과여야 한다 |
| **S**elf-Validating | 자기 검증 | pass/fail이 명확해야 한다 |
| **T**imely | 적시에 | 코드 작성 직전/직후에 작성한다 |

```typescript
// F: Fast — 외부 의존성은 목으로 대체
// Bad: 실제 DB 호출 (느림)
it('사용자를 저장한다', async () => {
  await realDatabase.connect();
  await userRepository.save(user);
});

// Good: 인메모리 목 사용 (빠름)
it('사용자를 저장한다', async () => {
  const repo = new InMemoryUserRepository();
  await repo.save(user);
  expect(await repo.findById(user.id)).toEqual(user);
});

// I: Independent — beforeEach로 격리
describe('Cart', () => {
  let cart: Cart;

  beforeEach(() => {
    cart = new Cart(); // 매 테스트마다 새 인스턴스
  });

  it('상품을 추가할 수 있다', () => { cart.addItem(item); });
  it('상품을 제거할 수 있다', () => { cart.addItem(item); cart.removeItem(item.id); });
  // 테스트 순서에 상관없이 동작
});

// R: Repeatable — Date 등 비결정적 요소를 제어
it('만료된 토큰을 감지한다', () => {
  vi.setSystemTime(new Date('2024-01-01'));
  const token = createToken({ expiresAt: new Date('2023-12-31') });
  expect(isExpired(token)).toBe(true);
  vi.useRealTimers();
});
```

---

## 7. 리팩터링 신호들 (코드 냄새)

```
코드 냄새                  증상                          처방
──────────────────────────────────────────────────────────────────
Long Method               함수가 50줄 이상              함수 추출
Large Class               클래스가 너무 많은 책임       클래스 분리 (SRP)
Duplicate Code            같은 코드가 여러 곳에          함수/컴포넌트 추출
Long Parameter List       파라미터 4개 이상             매개변수 객체 도입
Feature Envy              A가 B의 데이터를 과하게 사용   메서드를 B로 이동
Primitive Obsession       원시값으로 개념을 표현         Value Object 도입
Switch Statements         타입별 분기가 반복             다형성 활용 (OCP)
Data Clumps               항상 같이 다니는 데이터 묶음   객체로 묶기
Dead Code                 사용하지 않는 코드             즉시 삭제
```

### 실제 예제

```typescript
// 코드 냄새: Primitive Obsession
// Bad
function calculateDiscount(price: number, discountType: string): number {
  if (discountType === 'PERCENTAGE') return price * 0.1;
  if (discountType === 'FIXED') return 1000;
  return 0;
}

// 처방: Value Object + 다형성
abstract class Discount {
  abstract apply(price: Money): Money;
}

class PercentageDiscount extends Discount {
  constructor(private rate: number) { super(); }
  apply(price: Money): Money {
    return new Money(price.amount * (1 - this.rate), price.currency);
  }
}

class FixedDiscount extends Discount {
  constructor(private amount: Money) { super(); }
  apply(price: Money): Money {
    return new Money(price.amount - this.amount.amount, price.currency);
  }
}
```

---

## 8. JS/TS 특화 클린 코드 팁

```typescript
// 1. 옵셔널 체이닝과 nullish 병합 활용
const city = user?.address?.city ?? '알 수 없음';

// 2. 구조 분해로 의도 드러내기
// Bad
function greet(user: User) {
  return `안녕하세요, ${user.profile.name}님`;
}

// Good
function greet({ profile: { name } }: User) {
  return `안녕하세요, ${name}님`;
}

// 3. 배열 메서드 체이닝으로 선언적 코드
// Bad
const result = [];
for (const user of users) {
  if (user.isActive) {
    result.push({ id: user.id, name: user.name });
  }
}

// Good
const result = users
  .filter((user) => user.isActive)
  .map(({ id, name }) => ({ id, name }));

// 4. 조기 반환(Early Return)으로 중첩 제거
// Bad
function processUser(user: User | null) {
  if (user !== null) {
    if (user.isActive) {
      if (user.hasPermission) {
        // 실제 로직
      }
    }
  }
}

// Good
function processUser(user: User | null) {
  if (!user) return;
  if (!user.isActive) return;
  if (!user.hasPermission) return;
  // 실제 로직
}

// 5. const assertion과 readonly로 불변성 표현
const STATUS = {
  PENDING: 'PENDING',
  ACTIVE: 'ACTIVE',
  INACTIVE: 'INACTIVE',
} as const;

type Status = typeof STATUS[keyof typeof STATUS];
```

---

## 9. 면접 포인트

**Q. 클린 코드와 성능은 트레이드오프가 있나요?**

대부분의 경우 클린 코드가 성능에 부정적 영향을 주지 않습니다. 성능 최적화가 필요한 경우에는 먼저 프로파일링으로 병목을 찾고, 그 부분만 최적화하면서 주석으로 이유를 명시합니다.

**Q. 코드 주석은 항상 나쁜가요?**

아닙니다. 나쁜 코드를 설명하는 주석이 나쁜 것입니다. 비즈니스 의사결정 배경, 알고리즘의 비자명한 이유, 외부 제약사항(라이브러리 버그 등) 같은 WHY는 주석으로 남겨야 합니다.

**Q. 함수는 얼마나 짧아야 하나요?**

절대적 기준은 없지만 "한 가지 일"이 기준입니다. 한 화면에 보이는 길이(20~30줄), 들여쓰기가 2단계를 넘지 않는 수준이 실용적 가이드입니다.

**Q. F.I.R.S.T 원칙에서 가장 중요한 것은?**

Independent가 가장 중요합니다. 테스트 간 의존성이 생기면 테스트 순서에 따라 결과가 달라지고, 실패 원인 파악이 어려워집니다. beforeEach/afterEach로 상태를 격리하는 것이 핵심입니다.
