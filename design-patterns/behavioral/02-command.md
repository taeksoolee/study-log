# Command (커맨드 패턴)

## 목차
1. [개념](#1-개념)
2. [기본 구현](#2-기본-구현)
3. [Undo/Redo 구현 예제](#3-undoredo-구현-예제)
4. [Redux Action과의 관계](#4-redux-action과의-관계)
5. [커맨드 큐 (작업 예약)](#5-커맨드-큐-작업-예약)
6. [면접 포인트](#6-면접-포인트)

---

## 1. 개념

> 요청을 **객체로 캡슐화**하여 요청에 대한 정보를 저장, 지연 실행, 취소, 로깅할 수 있게 한다.

**언제 쓰는가?**
- Undo/Redo 기능이 필요할 때
- 작업을 큐에 넣어 나중에 실행해야 할 때
- 트랜잭션을 구현해야 할 때
- 작업 히스토리 로깅이 필요할 때

**핵심 구성 요소**
- **Command**: 실행할 연산의 인터페이스 (`execute`, `undo`)
- **ConcreteCommand**: 실제 연산 구현
- **Invoker**: 커맨드를 실행하는 객체
- **Receiver**: 실제 작업을 수행하는 객체

---

## 2. 기본 구현

```typescript
interface Command {
  execute(): void;
  undo(): void;
}

// Receiver — 실제 작업을 수행
class TextEditor {
  private content = '';
  private cursorPos = 0;

  getContent(): string { return this.content; }

  insertText(text: string, position: number): void {
    this.content =
      this.content.slice(0, position) + text + this.content.slice(position);
    this.cursorPos = position + text.length;
  }

  deleteText(start: number, length: number): void {
    this.content = this.content.slice(0, start) + this.content.slice(start + length);
    this.cursorPos = start;
  }
}

// Concrete Commands
class InsertCommand implements Command {
  constructor(
    private editor: TextEditor,
    private text: string,
    private position: number,
  ) {}

  execute(): void {
    this.editor.insertText(this.text, this.position);
  }

  undo(): void {
    this.editor.deleteText(this.position, this.text.length);
  }
}

class DeleteCommand implements Command {
  private deletedText = '';

  constructor(
    private editor: TextEditor,
    private start: number,
    private length: number,
  ) {}

  execute(): void {
    this.deletedText = this.editor.getContent().slice(this.start, this.start + this.length);
    this.editor.deleteText(this.start, this.length);
  }

  undo(): void {
    this.editor.insertText(this.deletedText, this.start);
  }
}
```

---

## 3. Undo/Redo 구현 예제

```typescript
// Invoker — 커맨드를 관리하고 실행
class CommandHistory {
  private history: Command[] = [];
  private redoStack: Command[] = [];

  execute(command: Command): void {
    command.execute();
    this.history.push(command);
    this.redoStack = []; // 새 커맨드 실행 시 redo 스택 초기화
  }

  undo(): void {
    const command = this.history.pop();
    if (!command) {
      console.log('취소할 작업이 없습니다');
      return;
    }
    command.undo();
    this.redoStack.push(command);
    console.log('실행 취소');
  }

  redo(): void {
    const command = this.redoStack.pop();
    if (!command) {
      console.log('다시 실행할 작업이 없습니다');
      return;
    }
    command.execute();
    this.history.push(command);
    console.log('다시 실행');
  }

  getHistorySize(): number {
    return this.history.length;
  }
}

// 사용 시나리오
const editor = new TextEditor();
const history = new CommandHistory();

history.execute(new InsertCommand(editor, 'Hello', 0));
console.log(editor.getContent()); // 'Hello'

history.execute(new InsertCommand(editor, ' World', 5));
console.log(editor.getContent()); // 'Hello World'

history.execute(new DeleteCommand(editor, 5, 6));
console.log(editor.getContent()); // 'Hello'

history.undo();
console.log(editor.getContent()); // 'Hello World'

history.undo();
console.log(editor.getContent()); // 'Hello'

history.redo();
console.log(editor.getContent()); // 'Hello World'
```

---

## 4. Redux Action과의 관계

Redux의 Action은 커맨드 패턴의 실용적인 구현이다.

```typescript
// Redux Action = Command 객체
interface Action {
  type: string;
  payload?: any;
}

// Redux Dispatch = Invoker.execute()
// Redux Reducer = Receiver (상태 변환 로직)

// 커맨드 패턴 관점에서 본 Redux
const incrementAction: Action = { type: 'counter/increment', payload: 1 };
const addTodoAction: Action = { type: 'todos/add', payload: { text: '할 일 추가' } };

// dispatch = execute
store.dispatch(incrementAction);
store.dispatch(addTodoAction);

// Redux Toolkit의 createAction이 커맨드 팩토리 역할
const increment = createAction<number>('counter/increment');
store.dispatch(increment(5));

// Time-travel debugging (Redux DevTools) = Undo/Redo 구현
// 액션 히스토리를 저장하여 과거 상태로 되돌아갈 수 있음
```

---

## 5. 커맨드 큐 (작업 예약)

```typescript
// 비동기 커맨드 큐 — 작업을 큐에 넣어 순차/병렬 실행
interface AsyncCommand {
  execute(): Promise<void>;
  description: string;
}

class CommandQueue {
  private queue: AsyncCommand[] = [];
  private running = false;

  enqueue(command: AsyncCommand): void {
    this.queue.push(command);
    if (!this.running) this.processNext();
  }

  private async processNext(): Promise<void> {
    if (this.queue.length === 0) {
      this.running = false;
      return;
    }
    this.running = true;
    const command = this.queue.shift()!;
    console.log(`[Queue] 실행: ${command.description}`);
    try {
      await command.execute();
    } catch (err) {
      console.error(`[Queue] 실패: ${command.description}`, err);
    }
    this.processNext();
  }
}

// 실용 예시 — API 요청 큐잉
const apiQueue = new CommandQueue();

apiQueue.enqueue({
  description: '사용자 정보 업데이트',
  execute: async () => {
    await fetch('/api/users/1', { method: 'PUT', body: JSON.stringify({ name: 'Bob' }) });
  },
});

apiQueue.enqueue({
  description: '알림 전송',
  execute: async () => {
    await fetch('/api/notifications', { method: 'POST' });
  },
});
```

---

## 6. 면접 포인트

**Q1. 커맨드 패턴이란 무엇인가요?**
> 요청을 객체로 캡슐화하여 매개변수화, 큐잉, 로깅, 취소가 가능하게 하는 패턴입니다. 호출자(Invoker)와 수신자(Receiver)를 분리합니다.

**Q2. Undo/Redo를 커맨드 패턴으로 어떻게 구현하나요?**
> 각 Command에 `execute()`와 `undo()` 메서드를 구현합니다. Invoker는 실행된 커맨드를 스택에 저장하고, undo 시 pop하여 `undo()`를 호출합니다.

**Q3. Redux Action이 커맨드 패턴인 이유를 설명해주세요.**
> Redux의 Action은 "무엇을 해야 하는지"를 담은 순수 객체로, 커맨드 패턴의 Command 객체와 동일합니다. `dispatch(action)`이 Invoker, Reducer가 Receiver 역할을 합니다. Redux DevTools의 타임트래블이 Undo/Redo 구현과 같습니다.

**Q4. 커맨드 패턴의 단점은?**
> Command 클래스 수가 많아질 수 있습니다. Undo 로직이 복잡한 경우 구현하기 어렵습니다(복잡한 상태 변환의 역연산).

---

[← Chain of Responsibility](./01-chain-of-responsibility.md) | [← 행동 패턴 목차](./README.md) | [다음: Iterator →](./03-iterator.md)
