# Factory Method (팩토리 메서드 패턴)

## 목차
1. [개념](#1-개념)
2. [생성자 직접 호출 vs 팩토리 함수](#2-생성자-직접-호출-vs-팩토리-함수)
3. [클래스 기반 팩토리 메서드](#3-클래스-기반-팩토리-메서드)
4. [프레임워크 예시 — React.createElement](#4-프레임워크-예시--reactcreateelement)
5. [실용 예시 — UI 컴포넌트 팩토리](#5-실용-예시--ui-컴포넌트-팩토리)
6. [면접 포인트](#6-면접-포인트)

---

## 1. 개념

> 객체 생성을 위한 인터페이스를 정의하되, **어떤 클래스를 인스턴스화할지는 서브클래스가 결정**하도록 한다.

팩토리 메서드는 `new` 키워드 직접 사용을 추상화하여, 생성될 객체의 타입을 유연하게 변경할 수 있게 해준다.

**핵심 아이디어**: 생성 로직을 별도의 메서드(팩토리)로 분리한다.

**구조**
```
Creator (abstract)              Product (interface)
├─ createProduct(): Product ←→  ConcreteProductA
└─ someOperation()              ConcreteProductB

ConcreteCreatorA ──overrides──→ createProduct() → ConcreteProductA
ConcreteCreatorB ──overrides──→ createProduct() → ConcreteProductB
```

---

## 2. 생성자 직접 호출 vs 팩토리 함수

### 문제: 직접 생성 방식

```typescript
// 나쁜 예 — 생성 로직이 사용 코드에 분산됨
function renderButton(type: string) {
  if (type === 'primary') {
    return new PrimaryButton();
  } else if (type === 'secondary') {
    return new SecondaryButton();
  } else if (type === 'danger') {
    return new DangerButton();
  }
  // 새 타입 추가 시 이 함수를 수정해야 함 (OCP 위반)
}
```

### 해결: 팩토리 함수

```typescript
interface Button {
  render(): string;
  onClick(handler: () => void): void;
}

class PrimaryButton implements Button {
  render() { return '<button class="btn-primary">클릭</button>'; }
  onClick(handler: () => void) { handler(); }
}

class SecondaryButton implements Button {
  render() { return '<button class="btn-secondary">클릭</button>'; }
  onClick(handler: () => void) { handler(); }
}

class DangerButton implements Button {
  render() { return '<button class="btn-danger">삭제</button>'; }
  onClick(handler: () => void) { handler(); }
}

// 팩토리 함수 — 생성 책임 집중
function createButton(type: 'primary' | 'secondary' | 'danger'): Button {
  const map = {
    primary: PrimaryButton,
    secondary: SecondaryButton,
    danger: DangerButton,
  };
  return new map[type]();
}

// 사용 코드는 구체 클래스를 몰라도 됨
const btn = createButton('primary');
console.log(btn.render());
```

---

## 3. 클래스 기반 팩토리 메서드

GoF 원서의 방식: 추상 클래스에 팩토리 메서드를 두고 서브클래스가 오버라이드한다.

```typescript
// 추상 Creator
abstract class Dialog {
  // 팩토리 메서드 — 서브클래스가 구현
  abstract createButton(): Button;

  // 팩토리 메서드를 활용하는 템플릿 로직
  render(): string {
    const button = this.createButton();
    return `<dialog>${button.render()}</dialog>`;
  }
}

// Concrete Creators
class WebDialog extends Dialog {
  createButton(): Button {
    return new PrimaryButton();
  }
}

class MobileDialog extends Dialog {
  createButton(): Button {
    return new SecondaryButton();
  }
}

// 클라이언트는 Dialog 타입만 알면 된다
function renderDialog(dialog: Dialog): void {
  console.log(dialog.render());
}

renderDialog(new WebDialog());
renderDialog(new MobileDialog());
```

---

## 4. 프레임워크 예시 — React.createElement

React의 `createElement`는 팩토리 메서드 패턴의 대표적인 사례다.

```jsx
// JSX 코드
const element = <MyComponent name="Alice" />;

// 위 코드는 트랜스파일 후 팩토리 메서드 호출로 변환됨
const element = React.createElement(
  MyComponent,   // 타입 (문자열 또는 컴포넌트)
  { name: 'Alice' }, // props
);

// React.createElement의 역할
// - 어떤 DOM 요소 혹은 컴포넌트를 만들지 추상화
// - 클라이언트(JSX 작성자)는 생성 세부사항을 몰라도 됨
```

```typescript
// 비슷한 원리의 커스텀 팩토리
function createElement(
  type: string | Function,
  props: Record<string, any>,
  ...children: any[]
) {
  return { type, props: { ...props, children } };
}
```

Vue의 `h()` 함수, Svelte의 컴파일 결과도 같은 패턴이다.

---

## 5. 실용 예시 — 알림(Notification) 팩토리

```typescript
interface Notification {
  send(message: string): Promise<void>;
}

class EmailNotification implements Notification {
  constructor(private email: string) {}
  async send(message: string) {
    console.log(`[Email → ${this.email}] ${message}`);
  }
}

class SlackNotification implements Notification {
  constructor(private channel: string) {}
  async send(message: string) {
    console.log(`[Slack → ${this.channel}] ${message}`);
  }
}

class PushNotification implements Notification {
  constructor(private deviceToken: string) {}
  async send(message: string) {
    console.log(`[Push → ${this.deviceToken}] ${message}`);
  }
}

// 팩토리 메서드 — 설정 기반 생성
type NotificationConfig =
  | { type: 'email'; email: string }
  | { type: 'slack'; channel: string }
  | { type: 'push'; deviceToken: string };

function createNotification(config: NotificationConfig): Notification {
  switch (config.type) {
    case 'email':
      return new EmailNotification(config.email);
    case 'slack':
      return new SlackNotification(config.channel);
    case 'push':
      return new PushNotification(config.deviceToken);
  }
}

// 사용
const notifier = createNotification({ type: 'slack', channel: '#alerts' });
notifier.send('배포 완료!');
```

---

## 6. 면접 포인트

**Q1. 팩토리 메서드 패턴이란 무엇인가요?**
> 객체 생성을 서브클래스에 위임하는 패턴입니다. 생성 로직을 호출부로부터 분리하여 OCP(개방-폐쇄 원칙)를 지킬 수 있습니다.

**Q2. 단순 팩토리 함수와 팩토리 메서드 패턴의 차이는?**
> 단순 팩토리는 조건문으로 분기하는 하나의 함수입니다. 팩토리 메서드는 상속과 오버라이딩을 사용해 생성 책임을 서브클래스에 위임합니다. 팩토리 메서드가 더 확장에 열려 있습니다.

**Q3. React.createElement와 팩토리 메서드의 관계를 설명해주세요.**
> `React.createElement`는 어떤 DOM 요소나 컴포넌트를 생성할지 추상화하는 팩토리 함수입니다. 호출자는 구체 구현을 몰라도 동일한 인터페이스(`type`, `props`)로 엘리먼트를 생성할 수 있습니다.

**Q4. Abstract Factory와의 차이는?**
> 팩토리 메서드는 단일 객체 생성 방법을 정의합니다. Abstract Factory는 연관된 객체들의 군(family)을 함께 생성합니다.

---

[← Singleton](./01-singleton.md) | [← 생성 패턴 목차](./README.md) | [다음: Abstract Factory →](./03-abstract-factory.md)
