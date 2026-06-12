# 3. SOLID 원칙

## 목차
1. SOLID란 무엇인가
2. S — Single Responsibility Principle (단일 책임 원칙)
3. O — Open/Closed Principle (개방/폐쇄 원칙)
4. L — Liskov Substitution Principle (리스코프 치환 원칙)
5. I — Interface Segregation Principle (인터페이스 분리 원칙)
6. D — Dependency Inversion Principle (의존성 역전 원칙)
7. 면접 포인트

---

## 1. SOLID란 무엇인가

Robert C. Martin(Uncle Bob)이 정리한 **객체지향 설계의 5가지 원칙**입니다. 유지보수하기 쉽고 확장 가능한 소프트웨어를 만들기 위한 가이드라인입니다.

| 원칙 | 한 줄 요약 |
|------|-----------|
| **S**RP | 클래스/함수는 하나의 이유로만 변경되어야 한다 |
| **O**CP | 확장에는 열려있고, 수정에는 닫혀있어야 한다 |
| **L**SP | 서브타입은 부모타입으로 대체 가능해야 한다 |
| **I**SP | 사용하지 않는 인터페이스에 의존하지 않아야 한다 |
| **D**IP | 고수준 모듈이 저수준 모듈에 의존하면 안 된다 |

---

## 2. S — Single Responsibility Principle (단일 책임 원칙)

**"클래스는 변경되어야 할 이유가 하나뿐이어야 한다"**

### Bad Example

```tsx
// Bad: UserCard 컴포넌트가 너무 많은 책임을 가짐
function UserCard({ userId }: { userId: string }) {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(false);

  // 책임 1: 데이터 페칭
  useEffect(() => {
    setLoading(true);
    fetch(`/api/users/${userId}`)
      .then((res) => res.json())
      .then((data) => { setUser(data); setLoading(false); });
  }, [userId]);

  // 책임 2: 날짜 포매팅 로직
  const formatDate = (iso: string) =>
    new Date(iso).toLocaleDateString('ko-KR');

  // 책임 3: 권한 판단 로직
  const isAdmin = user?.role === 'ADMIN';

  // 책임 4: UI 렌더링
  if (loading) return <Spinner />;
  return (
    <div>
      <img src={user?.avatar} />
      <h2>{user?.name} {isAdmin && '(관리자)'}</h2>
      <p>가입일: {formatDate(user?.createdAt)}</p>
    </div>
  );
}
```

### Good Example

```tsx
// Good: 각 책임을 분리

// 책임 1: 데이터 페칭 → 커스텀 훅
function useUser(userId: string) {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    setLoading(true);
    fetch(`/api/users/${userId}`)
      .then((res) => res.json())
      .then((data) => { setUser(data); setLoading(false); });
  }, [userId]);

  return { user, loading };
}

// 책임 2: 포매팅 → 유틸 함수
function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString('ko-KR');
}

// 책임 3: 권한 판단 → 도메인 함수
function isAdmin(user: User): boolean {
  return user.role === 'ADMIN';
}

// 책임 4: UI 렌더링만
function UserCard({ userId }: { userId: string }) {
  const { user, loading } = useUser(userId);
  if (loading) return <Spinner />;
  return (
    <div>
      <img src={user?.avatar} />
      <h2>{user?.name} {isAdmin(user) && '(관리자)'}</h2>
      <p>가입일: {formatDate(user?.createdAt)}</p>
    </div>
  );
}
```

---

## 3. O — Open/Closed Principle (개방/폐쇄 원칙)

**"소프트웨어 엔티티는 확장에는 열려있고, 수정에는 닫혀있어야 한다"**

새로운 기능 추가 시 기존 코드를 수정하지 않고 확장할 수 있어야 합니다.

### Bad Example

```tsx
// Bad: 새로운 알림 타입 추가 시 함수를 수정해야 함
function sendNotification(type: string, message: string) {
  if (type === 'email') {
    sendEmail(message);
  } else if (type === 'sms') {
    sendSMS(message);
  } else if (type === 'push') {   // 새 타입 추가마다 여기를 수정
    sendPush(message);
  }
}
```

### Good Example

```typescript
// Good: 전략 패턴으로 확장에 열려있음
interface NotificationStrategy {
  send(message: string): Promise<void>;
}

class EmailNotification implements NotificationStrategy {
  async send(message: string): Promise<void> {
    await sendEmail(message);
  }
}

class SMSNotification implements NotificationStrategy {
  async send(message: string): Promise<void> {
    await sendSMS(message);
  }
}

// 새 타입 추가: 기존 코드 수정 없이 클래스만 추가
class PushNotification implements NotificationStrategy {
  async send(message: string): Promise<void> {
    await sendPush(message);
  }
}

class NotificationService {
  constructor(private strategy: NotificationStrategy) {}

  async notify(message: string): Promise<void> {
    await this.strategy.send(message);
  }
}
```

### React 컴포넌트에서의 OCP

```tsx
// Bad: 새 variant마다 Button 컴포넌트를 수정
function Button({ variant, children }: ButtonProps) {
  if (variant === 'primary') return <button className="btn-primary">{children}</button>;
  if (variant === 'danger') return <button className="btn-danger">{children}</button>;
  // ...
}

// Good: 컴포지션으로 확장
function Button({ className, children, ...props }: ButtonProps) {
  return <button className={`btn ${className}`} {...props}>{children}</button>;
}

// 기존 Button 수정 없이 확장
const PrimaryButton = (props: ButtonProps) => <Button className="btn-primary" {...props} />;
const DangerButton = (props: ButtonProps) => <Button className="btn-danger" {...props} />;
```

---

## 4. L — Liskov Substitution Principle (리스코프 치환 원칙)

**"서브타입은 언제나 부모 타입으로 교체할 수 있어야 한다"**

자식 클래스가 부모 클래스의 계약(contract)을 지켜야 합니다.

### Bad Example

```typescript
// Bad: Rectangle의 계약을 Square가 위반
class Rectangle {
  constructor(protected width: number, protected height: number) {}

  setWidth(width: number): void { this.width = width; }
  setHeight(height: number): void { this.height = height; }

  area(): number { return this.width * this.height; }
}

class Square extends Rectangle {
  // LSP 위반: 너비를 바꾸면 높이도 바뀜 — 부모 계약 위반
  setWidth(width: number): void {
    this.width = width;
    this.height = width;
  }
  setHeight(height: number): void {
    this.width = height;
    this.height = height;
  }
}

// 함수가 Rectangle을 받는다고 가정했을 때 Square를 넣으면 동작이 다름
function testArea(rect: Rectangle) {
  rect.setWidth(5);
  rect.setHeight(10);
  console.log(rect.area()); // Rectangle: 50, Square: 100 — 다른 결과
}
```

### Good Example

```typescript
// Good: Shape 인터페이스로 공통 계약 정의
interface Shape {
  area(): number;
}

class Rectangle implements Shape {
  constructor(private width: number, private height: number) {}
  area(): number { return this.width * this.height; }
}

class Square implements Shape {
  constructor(private side: number) {}
  area(): number { return this.side * this.side; }
}

// Shape로 대체 가능
function printArea(shape: Shape): void {
  console.log(shape.area()); // 어떤 Shape이든 올바르게 동작
}
```

### TypeScript에서의 LSP — Props 확장

```tsx
interface ButtonProps {
  children: React.ReactNode;
  onClick?: () => void;
}

interface IconButtonProps extends ButtonProps {
  icon: React.ReactNode;
  // onClick을 절대 제거하거나 시그니처를 바꾸면 안 됨 (LSP 위반)
}

// Good: 부모 Props의 계약을 유지하며 확장
function IconButton({ icon, children, onClick }: IconButtonProps) {
  return (
    <button onClick={onClick}>
      {icon}
      {children}
    </button>
  );
}
```

---

## 5. I — Interface Segregation Principle (인터페이스 분리 원칙)

**"클라이언트가 사용하지 않는 인터페이스에 의존하도록 강요하면 안 된다"**

큰 인터페이스보다 작고 구체적인 여러 인터페이스가 낫습니다.

### Bad Example

```typescript
// Bad: 모든 컴포넌트가 거대한 인터페이스를 구현해야 함
interface Widget {
  render(): JSX.Element;
  fetchData(): Promise<void>;
  validate(): boolean;
  export(): string;
  print(): void;
}

// 간단한 표시용 컴포넌트도 불필요한 메서드를 구현해야 함
class DisplayWidget implements Widget {
  render(): JSX.Element { return <div />; }
  fetchData(): Promise<void> { throw new Error('Not needed'); }  // 억지 구현
  validate(): boolean { throw new Error('Not needed'); }
  export(): string { throw new Error('Not needed'); }
  print(): void { throw new Error('Not needed'); }
}
```

### Good Example

```typescript
// Good: 역할별로 인터페이스 분리
interface Renderable {
  render(): JSX.Element;
}

interface DataFetchable {
  fetchData(): Promise<void>;
}

interface Validatable {
  validate(): boolean;
}

interface Exportable {
  export(): string;
}

// 필요한 인터페이스만 구현
class DisplayWidget implements Renderable {
  render(): JSX.Element { return <div />; }
}

class DataWidget implements Renderable, DataFetchable {
  render(): JSX.Element { return <div />; }
  async fetchData(): Promise<void> { /* ... */ }
}
```

### React Props에서의 ISP

```tsx
// Bad: 모든 경우에 모든 Props가 전달됨
interface TableProps {
  data: unknown[];
  onSort?: (col: string) => void;
  onFilter?: (query: string) => void;
  onExport?: () => void;
  onPrint?: () => void;
  pagination?: PaginationConfig;
}

// Good: 역할별로 Props 분리 후 컴포지션
interface TableCoreProps {
  data: unknown[];
}

interface SortableTableProps extends TableCoreProps {
  onSort: (col: string) => void;
}

interface PaginatedTableProps extends TableCoreProps {
  pagination: PaginationConfig;
}

// 필요한 기능만 조합
function SortableTable({ data, onSort }: SortableTableProps) { /* ... */ }
function PaginatedTable({ data, pagination }: PaginatedTableProps) { /* ... */ }
```

---

## 6. D — Dependency Inversion Principle (의존성 역전 원칙)

**"고수준 모듈이 저수준 모듈에 의존해서는 안 된다. 둘 다 추상화에 의존해야 한다."**

### Bad Example

```typescript
// Bad: 고수준(OrderService)이 저수준(FetchApiClient)에 직접 의존
class FetchApiClient {
  async get(url: string): Promise<unknown> {
    const res = await fetch(url);
    return res.json();
  }
}

class OrderService {
  private client = new FetchApiClient(); // 직접 의존 → 교체 불가

  async getOrder(id: string) {
    return this.client.get(`/orders/${id}`);
  }
}
```

### Good Example

```typescript
// Good: 추상화(인터페이스)에 의존
interface HttpClient {
  get<T>(url: string): Promise<T>;
  post<T>(url: string, body: unknown): Promise<T>;
}

// 저수준: 구현체
class FetchHttpClient implements HttpClient {
  async get<T>(url: string): Promise<T> {
    const res = await fetch(url);
    return res.json() as T;
  }
  async post<T>(url: string, body: unknown): Promise<T> {
    const res = await fetch(url, { method: 'POST', body: JSON.stringify(body) });
    return res.json() as T;
  }
}

// 테스트용 목(mock)
class MockHttpClient implements HttpClient {
  constructor(private responses: Record<string, unknown> = {}) {}
  async get<T>(url: string): Promise<T> {
    return this.responses[url] as T;
  }
  async post<T>(_url: string, _body: unknown): Promise<T> {
    return {} as T;
  }
}

// 고수준: 인터페이스에만 의존
class OrderService {
  constructor(private client: HttpClient) {} // 주입받음

  async getOrder(id: string) {
    return this.client.get(`/orders/${id}`);
  }
}

// 실제 사용
const service = new OrderService(new FetchHttpClient());

// 테스트 사용 (교체 가능)
const testService = new OrderService(new MockHttpClient({ '/orders/1': mockOrder }));
```

### React에서의 DIP — Context를 통한 의존성 주입

```tsx
// 추상화: Context 인터페이스
interface AuthService {
  login(email: string, password: string): Promise<void>;
  logout(): Promise<void>;
  currentUser: User | null;
}

const AuthContext = createContext<AuthService | null>(null);

// 실제 구현체
class FirebaseAuthService implements AuthService {
  currentUser = null;
  async login(email: string, password: string) { /* Firebase 로직 */ }
  async logout() { /* Firebase 로직 */ }
}

// 테스트 구현체
class MockAuthService implements AuthService {
  currentUser = mockUser;
  async login() {}
  async logout() {}
}

// 컴포넌트는 구현체를 모름 — Context(추상화)에만 의존
function LoginButton() {
  const auth = useContext(AuthContext)!;
  return <button onClick={() => auth.logout()}>로그아웃</button>;
}
```

---

## 7. 면접 포인트

**Q. SOLID 원칙 중 실무에서 가장 자주 위반되는 원칙은?**

SRP가 가장 많이 위반됩니다. 컴포넌트나 함수가 점점 커지면서 여러 책임을 갖게 되는 경향이 있습니다. React에서는 데이터 페칭, 상태 관리, UI 렌더링이 하나의 컴포넌트에 섞이는 패턴이 전형적인 예입니다.

**Q. OCP를 프론트엔드에서 어떻게 적용하나요?**

컴포지션 패턴, 렌더 프롭, 고차 컴포넌트 등을 활용합니다. 기존 컴포넌트를 수정하지 않고 래핑하거나 조합해서 새로운 기능을 추가하는 방식입니다.

**Q. DIP와 의존성 주입(DI)의 관계는?**

DIP는 원칙이고, 의존성 주입은 DIP를 구현하는 패턴 중 하나입니다. React에서는 Context API, props 드릴링, 커스텀 훅이 DI 역할을 합니다.

**Q. LSP 위반의 징후는?**

instanceof나 타입 체크로 분기 처리를 하거나, 서브타입에서 부모 메서드가 `throw new Error('Not implemented')` 형태로 구현되는 경우입니다.
