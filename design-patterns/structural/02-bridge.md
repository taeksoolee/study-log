# Bridge (브리지 패턴)

## 목차
1. [개념](#1-개념)
2. [상속의 폭발 문제](#2-상속의-폭발-문제)
3. [추상화와 구현 분리 예제](#3-추상화와-구현-분리-예제)
4. [렌더러 교체 예제](#4-렌더러-교체-예제)
5. [프론트엔드 실무 사례](#5-프론트엔드-실무-사례)
6. [면접 포인트](#6-면접-포인트)

---

## 1. 개념

> **추상화(abstraction)와 구현(implementation)을 분리**하여 두 가지가 독립적으로 변경될 수 있게 한다.

브리지는 두 클래스 계층 사이에 "다리"를 놓는다.
추상화 클래스에 구현 객체를 **합성**으로 참조하게 함으로써,
추상화와 구현 각각을 독립적으로 확장할 수 있다.

**언제 쓰는가?**
- 기능과 구현 두 차원으로 독립적으로 확장해야 할 때
- 런타임에 구현체를 교체해야 할 때
- 플랫폼 독립적인 코드를 작성할 때

**구조**
```
Abstraction ──has-a──→ Implementor (interface)
     │                      │
RefinedAbstraction    ConcreteImplementorA
                      ConcreteImplementorB
```

---

## 2. 상속의 폭발 문제

브리지 패턴이 해결하는 핵심 문제다.

```
상속으로 해결하면:
Shape
├─ Circle
│   ├─ RedCircle
│   ├─ BlueCircle
│   └─ GreenCircle
└─ Rectangle
    ├─ RedRectangle
    ├─ BlueRectangle
    └─ GreenRectangle

도형 N가지 × 색상 M가지 = N×M 클래스 필요!

브리지로 해결하면:
Shape + Color (합성)
├─ Shape: Circle, Rectangle  (N개)
└─ Color: Red, Blue, Green   (M개)
총 N+M 클래스로 해결!
```

---

## 3. 추상화와 구현 분리 예제

```typescript
// ─── 구현 계층 (Implementation) ─────────────────────────
interface Renderer {
  renderCircle(radius: number): void;
  renderRectangle(width: number, height: number): void;
}

class SVGRenderer implements Renderer {
  renderCircle(radius: number): void {
    console.log(`<circle r="${radius}" />`);
  }
  renderRectangle(width: number, height: number): void {
    console.log(`<rect width="${width}" height="${height}" />`);
  }
}

class CanvasRenderer implements Renderer {
  constructor(private ctx: CanvasRenderingContext2D) {}
  renderCircle(radius: number): void {
    this.ctx.beginPath();
    this.ctx.arc(0, 0, radius, 0, Math.PI * 2);
    this.ctx.stroke();
    console.log(`Canvas arc: radius=${radius}`);
  }
  renderRectangle(width: number, height: number): void {
    this.ctx.strokeRect(0, 0, width, height);
    console.log(`Canvas rect: ${width}x${height}`);
  }
}

// ─── 추상화 계층 (Abstraction) ───────────────────────────
abstract class Shape {
  constructor(protected renderer: Renderer) {}
  abstract draw(): void;
  abstract resize(factor: number): void;
}

class Circle extends Shape {
  constructor(renderer: Renderer, private radius: number) {
    super(renderer);
  }

  draw(): void {
    this.renderer.renderCircle(this.radius);
  }

  resize(factor: number): void {
    this.radius *= factor;
  }
}

class Rectangle extends Shape {
  constructor(
    renderer: Renderer,
    private width: number,
    private height: number,
  ) {
    super(renderer);
  }

  draw(): void {
    this.renderer.renderRectangle(this.width, this.height);
  }

  resize(factor: number): void {
    this.width *= factor;
    this.height *= factor;
  }
}

// ─── 사용 ────────────────────────────────────────────────
const svgRenderer = new SVGRenderer();
const circle = new Circle(svgRenderer, 50);
circle.draw(); // <circle r="50" />

// 런타임에 렌더러 교체 (다리를 바꿈)
// const canvasCircle = new Circle(canvasRenderer, 50);
// canvasCircle.draw();

const rect = new Rectangle(svgRenderer, 100, 80);
rect.draw(); // <rect width="100" height="80" />
```

---

## 4. 렌더러 교체 예제

메시지 전송 시스템: 메시지 타입과 전송 채널을 독립적으로 확장한다.

```typescript
// 구현: 전송 채널
interface MessageSender {
  send(to: string, content: string): Promise<void>;
}

class EmailSender implements MessageSender {
  async send(to: string, content: string): Promise<void> {
    console.log(`[Email] to: ${to}\n${content}`);
  }
}

class SMSSender implements MessageSender {
  async send(to: string, content: string): Promise<void> {
    console.log(`[SMS] to: ${to}\n${content.slice(0, 160)}`);
  }
}

class PushSender implements MessageSender {
  async send(to: string, content: string): Promise<void> {
    console.log(`[Push] to: ${to}\n${content}`);
  }
}

// 추상화: 메시지 타입
abstract class Message {
  constructor(protected sender: MessageSender) {}
  abstract send(recipient: string): Promise<void>;
}

class AlertMessage extends Message {
  constructor(sender: MessageSender, private alertText: string) {
    super(sender);
  }
  async send(recipient: string): Promise<void> {
    const content = `[긴급 알림] ${this.alertText}`;
    await this.sender.send(recipient, content);
  }
}

class PromotionMessage extends Message {
  constructor(sender: MessageSender, private offer: string) {
    super(sender);
  }
  async send(recipient: string): Promise<void> {
    const content = `[특별 혜택] ${this.offer}\n수신 거부: 설정에서 변경`;
    await this.sender.send(recipient, content);
  }
}

// 사용 — 메시지 타입 × 전송 채널을 자유롭게 조합
const emailAlert = new AlertMessage(new EmailSender(), '서버 다운!');
await emailAlert.send('admin@company.com');

const smsPromo = new PromotionMessage(new SMSSender(), '오늘만 50% 할인');
await smsPromo.send('010-1234-5678');
```

---

## 5. 프론트엔드 실무 사례

### React 렌더러 구조

React 코어는 추상화 계층, `react-dom`과 `react-native`는 구현 계층이다.
동일한 컴포넌트 코드(추상화)가 다른 렌더러(구현)로 동작한다.

```
React (추상화)
├─ react-dom (웹 구현)
├─ react-native (모바일 구현)
└─ react-three-fiber (3D 구현)
```

### 로깅 시스템

```typescript
// 추상화: 로그 레벨별 동작
abstract class Logger {
  constructor(protected transport: LogTransport) {}
  abstract format(message: string): string;

  log(message: string): void {
    this.transport.write(this.format(message));
  }
}

// 구현: 전송 방식
interface LogTransport {
  write(entry: string): void;
}

class ConsoleTransport implements LogTransport {
  write(entry: string) { console.log(entry); }
}

class FileTransport implements LogTransport {
  write(entry: string) { /* 파일 쓰기 */ }
}

class RemoteTransport implements LogTransport {
  write(entry: string) { /* API 전송 */ }
}
```

---

## 6. 면접 포인트

**Q1. 브리지 패턴이란 무엇인가요?**
> 추상화와 구현을 분리하여 독립적으로 확장 가능하게 하는 패턴입니다. 합성을 사용하여 상속의 폭발적 증가 문제를 해결합니다.

**Q2. 어댑터와 브리지의 차이는?**
> 어댑터는 기존 코드의 호환성 문제를 해결하는 사후 수정입니다. 브리지는 설계 초기부터 추상화와 구현을 분리하는 선제적 설계입니다.

**Q3. 상속 vs 브리지 패턴의 트레이드오프를 설명해주세요.**
> 상속은 N종류의 기능 × M종류의 구현 = N×M 클래스를 만들어야 합니다. 브리지는 N+M 클래스로 동일한 조합을 구성할 수 있어, 클래스 폭발 문제를 해결합니다.

**Q4. React의 렌더러와 브리지 패턴의 관계는?**
> React 코어(추상화)와 react-dom/react-native(구현)의 관계가 브리지 패턴입니다. 동일한 React 컴포넌트가 다른 렌더러에서 동작하는 것이 구현과 추상화의 분리 덕분입니다.

---

[← Adapter](./01-adapter.md) | [← 구조 패턴 목차](./README.md) | [다음: Composite →](./03-composite.md)
