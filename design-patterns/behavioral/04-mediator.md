# Mediator (미디에이터 패턴)

## 목차
1. [개념](#1-개념)
2. [직접 참조 문제와 해결](#2-직접-참조-문제와-해결)
3. [이벤트 버스 구현](#3-이벤트-버스-구현)
4. [채팅방 미디에이터 예제](#4-채팅방-미디에이터-예제)
5. [React Context와 Redux와의 관계](#5-react-context와-redux와의-관계)
6. [면접 포인트](#6-면접-포인트)

---

## 1. 개념

> 객체 간의 직접적인 통신을 없애고, **중재자 객체를 통해 간접적으로 통신**하게 한다.
> 객체 간 결합도를 낮춘다.

**언제 쓰는가?**
- 많은 객체가 서로 복잡하게 참조할 때 (스파게티 참조)
- 컴포넌트 재사용이 어려울 때 (강한 결합)
- 객체 간 의존성을 줄이고 싶을 때

**"스타 토폴로지" 구조**
```
// 미디에이터 없이 (N*(N-1) 연결)
A ←→ B
A ←→ C
A ←→ D
B ←→ C
B ←→ D
C ←→ D

// 미디에이터 사용 (N 연결)
A → Mediator ← B
C ↗          ↖ D
```

---

## 2. 직접 참조 문제와 해결

```typescript
// 나쁜 예 — 컴포넌트들이 서로 직접 참조
class SearchBox {
  constructor(
    private resultList: ResultList,
    private filterPanel: FilterPanel,
    private pagination: Pagination,
  ) {}

  onSearch(query: string): void {
    const results = this.fetchResults(query);
    this.resultList.update(results);       // 직접 참조
    this.filterPanel.reset();              // 직접 참조
    this.pagination.reset();               // 직접 참조
  }

  private fetchResults(query: string) { return []; }
}

// 좋은 예 — 미디에이터를 통해 통신
interface SearchMediator {
  notify(sender: string, event: string, data?: any): void;
}

class SearchPageMediator implements SearchMediator {
  private components: Map<string, any> = new Map();

  register(name: string, component: any): void {
    this.components.set(name, component);
  }

  notify(sender: string, event: string, data?: any): void {
    console.log(`[Mediator] ${sender} → ${event}`);

    if (event === 'search') {
      this.components.get('resultList')?.update(data);
      this.components.get('filterPanel')?.reset();
      this.components.get('pagination')?.reset();
    }

    if (event === 'filterChange') {
      this.components.get('resultList')?.applyFilter(data);
      this.components.get('pagination')?.reset();
    }
  }
}
```

---

## 3. 이벤트 버스 구현

이벤트 버스는 미디에이터 패턴의 가장 일반적인 구현이다.

```typescript
type EventCallback<T = any> = (data: T) => void;

class EventBus {
  private listeners = new Map<string, Set<EventCallback>>();

  on<T>(event: string, callback: EventCallback<T>): () => void {
    if (!this.listeners.has(event)) {
      this.listeners.set(event, new Set());
    }
    this.listeners.get(event)!.add(callback as EventCallback);

    // 구독 해제 함수 반환
    return () => this.off(event, callback as EventCallback);
  }

  off(event: string, callback: EventCallback): void {
    this.listeners.get(event)?.delete(callback);
  }

  emit<T>(event: string, data?: T): void {
    this.listeners.get(event)?.forEach(callback => callback(data));
  }

  once<T>(event: string, callback: EventCallback<T>): void {
    const wrapper: EventCallback = (data) => {
      callback(data);
      this.off(event, wrapper);
    };
    this.on(event, wrapper);
  }

  clear(event?: string): void {
    if (event) {
      this.listeners.delete(event);
    } else {
      this.listeners.clear();
    }
  }
}

// 싱글톤 이벤트 버스 (앱 전역에서 사용)
export const eventBus = new EventBus();

// 사용 예시
const unsubscribe = eventBus.on<{ userId: number }>('user:login', ({ userId }) => {
  console.log(`사용자 ${userId} 로그인`);
});

eventBus.emit('user:login', { userId: 42 });

// 구독 해제 (메모리 누수 방지)
unsubscribe();
```

---

## 4. 채팅방 미디에이터 예제

```typescript
interface ChatMediator {
  sendMessage(message: string, sender: User): void;
  addUser(user: User): void;
}

class ChatRoom implements ChatMediator {
  private users: User[] = [];

  addUser(user: User): void {
    this.users.push(user);
    this.sendMessage(`${user.name}님이 입장했습니다.`, user);
  }

  sendMessage(message: string, sender: User): void {
    this.users
      .filter(user => user !== sender) // 발신자 제외
      .forEach(user => user.receive(message, sender.name));
  }
}

class User {
  private messages: string[] = [];

  constructor(
    public name: string,
    private mediator: ChatMediator,
  ) {}

  send(message: string): void {
    console.log(`[${this.name}] 전송: ${message}`);
    this.mediator.sendMessage(message, this); // 미디에이터를 통해 전달
  }

  receive(message: string, from: string): void {
    const entry = `[${from}] ${message}`;
    this.messages.push(entry);
    console.log(`  ${this.name} 수신: ${entry}`);
  }
}

// 사용 — 유저들은 서로를 직접 모름
const room = new ChatRoom();
const alice = new User('Alice', room);
const bob = new User('Bob', room);
const charlie = new User('Charlie', room);

room.addUser(alice);
room.addUser(bob);
room.addUser(charlie);

alice.send('안녕하세요!');
// Bob 수신: [Alice] 안녕하세요!
// Charlie 수신: [Alice] 안녕하세요!

bob.send('반갑습니다!');
// Alice 수신: [Bob] 반갑습니다!
// Charlie 수신: [Bob] 반갑습니다!
```

---

## 5. React Context와 Redux와의 관계

```tsx
// React Context = 미디에이터 패턴
// Provider가 미디에이터 역할 — 자식 컴포넌트가 직접 통신하지 않음

const ThemeContext = createContext<ThemeContextType>(null!);

// Provider = 미디에이터
function ThemeProvider({ children }: { children: ReactNode }) {
  const [theme, setTheme] = useState<'light' | 'dark'>('light');

  return (
    <ThemeContext.Provider value={{ theme, setTheme }}>
      {children}
    </ThemeContext.Provider>
  );
}

// 자식 컴포넌트들은 서로를 직접 참조하지 않고 Context를 통해 통신
function Header() {
  const { theme, setTheme } = useContext(ThemeContext);
  return <button onClick={() => setTheme(theme === 'light' ? 'dark' : 'light')}>
    테마: {theme}
  </button>;
}

function Content() {
  const { theme } = useContext(ThemeContext);
  return <div className={`content-${theme}`}>내용</div>;
}

// Redux도 같은 구조
// Store = 미디에이터
// dispatch(action) → Store → 구독자에게 알림
```

---

## 6. 면접 포인트

**Q1. 미디에이터 패턴이란 무엇인가요?**
> 객체 간의 직접 통신 대신 중재자를 통해 간접적으로 통신하게 하는 패턴입니다. 객체 간 결합도를 낮추고 복잡한 의존성 그물망을 단순화합니다.

**Q2. 이벤트 버스와 미디에이터 패턴의 관계는?**
> 이벤트 버스가 미디에이터 패턴의 구현체입니다. 컴포넌트들이 서로를 직접 알 필요 없이 이벤트 버스를 통해 통신합니다.

**Q3. Redux와 미디에이터 패턴의 관계를 설명해주세요.**
> Redux Store가 미디에이터 역할을 합니다. 컴포넌트들은 서로를 직접 참조하지 않고, 모두 Store를 통해 상태를 공유하고 변경합니다.

**Q4. 미디에이터의 단점은?**
> 미디에이터 자체가 너무 많은 책임을 가지는 "God Object"가 될 위험이 있습니다. 모든 통신이 미디에이터를 거치면 미디에이터가 복잡해집니다.

---

[← Iterator](./03-iterator.md) | [← 행동 패턴 목차](./README.md) | [다음: Memento →](./05-memento.md)
