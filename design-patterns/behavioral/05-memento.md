# Memento (메멘토 패턴)

## 목차
1. [개념](#1-개념)
2. [기본 구현](#2-기본-구현)
3. [텍스트 에디터 Undo 예제](#3-텍스트-에디터-undo-예제)
4. [폼 상태 스냅샷](#4-폼-상태-스냅샷)
5. [브라우저 히스토리와의 연결](#5-브라우저-히스토리와의-연결)
6. [Immer와의 관계](#6-immer와의-관계)
7. [면접 포인트](#7-면접-포인트)

---

## 1. 개념

> 객체의 내부 상태를 **스냅샷으로 저장**하고, 캡슐화를 깨지 않으면서 나중에 그 상태로 복원할 수 있게 한다.

**핵심 구성 요소**
- **Originator**: 상태를 가진 객체. Memento를 생성하고 복원
- **Memento**: Originator 상태의 스냅샷 (불변 객체)
- **Caretaker**: Memento를 저장하고 관리 (Originator 내부 상태에는 접근 불가)

**언제 쓰는가?**
- Undo/Redo 기능이 필요할 때
- 객체의 이전 상태로 롤백이 필요할 때
- 상태 변경 히스토리 추적이 필요할 때

---

## 2. 기본 구현

```typescript
// Memento — 불변 스냅샷
class Memento<T> {
  private readonly state: T;
  private readonly timestamp: Date;

  constructor(state: T) {
    this.state = structuredClone(state); // 깊은 복사
    this.timestamp = new Date();
  }

  getState(): T {
    return structuredClone(this.state); // 복원 시도 깊은 복사
  }

  getTimestamp(): Date {
    return this.timestamp;
  }
}

// Caretaker — 스냅샷 관리
class History<T> {
  private mementos: Memento<T>[] = [];
  private currentIndex = -1;

  save(state: T): void {
    // 현재 위치 이후의 히스토리 제거 (새 분기)
    this.mementos = this.mementos.slice(0, this.currentIndex + 1);
    this.mementos.push(new Memento(state));
    this.currentIndex++;
  }

  undo(): T | null {
    if (this.currentIndex <= 0) return null;
    this.currentIndex--;
    return this.mementos[this.currentIndex].getState();
  }

  redo(): T | null {
    if (this.currentIndex >= this.mementos.length - 1) return null;
    this.currentIndex++;
    return this.mementos[this.currentIndex].getState();
  }

  canUndo(): boolean { return this.currentIndex > 0; }
  canRedo(): boolean { return this.currentIndex < this.mementos.length - 1; }
  size(): number { return this.mementos.length; }
}
```

---

## 3. 텍스트 에디터 Undo 예제

```typescript
interface EditorState {
  content: string;
  cursorPosition: number;
  selectionStart: number;
  selectionEnd: number;
}

class TextEditor {
  private state: EditorState = {
    content: '',
    cursorPosition: 0,
    selectionStart: 0,
    selectionEnd: 0,
  };
  private history = new History<EditorState>();

  constructor() {
    this.history.save(this.state); // 초기 상태 저장
  }

  private saveHistory(): void {
    this.history.save(this.state);
  }

  type(text: string): void {
    const { content, cursorPosition } = this.state;
    this.state = {
      ...this.state,
      content: content.slice(0, cursorPosition) + text + content.slice(cursorPosition),
      cursorPosition: cursorPosition + text.length,
    };
    this.saveHistory();
  }

  delete(count: number): void {
    const { content, cursorPosition } = this.state;
    if (cursorPosition === 0) return;
    this.state = {
      ...this.state,
      content: content.slice(0, cursorPosition - count) + content.slice(cursorPosition),
      cursorPosition: Math.max(0, cursorPosition - count),
    };
    this.saveHistory();
  }

  undo(): void {
    const prevState = this.history.undo();
    if (prevState) {
      this.state = prevState;
      console.log(`[Undo] content: "${this.state.content}"`);
    }
  }

  redo(): void {
    const nextState = this.history.redo();
    if (nextState) {
      this.state = nextState;
      console.log(`[Redo] content: "${this.state.content}"`);
    }
  }

  getContent(): string { return this.state.content; }
}

// 사용
const editor = new TextEditor();
editor.type('Hello');          // 'Hello'
editor.type(' World');         // 'Hello World'
editor.delete(5);              // 'Hello '
editor.type('JavaScript');     // 'Hello JavaScript'

editor.undo(); // 'Hello '
editor.undo(); // 'Hello World'
editor.redo(); // 'Hello '
```

---

## 4. 폼 상태 스냅샷

```typescript
// React 폼의 Undo 기능 구현
interface FormData {
  username: string;
  email: string;
  bio: string;
  tags: string[];
}

function useFormWithUndo(initialData: FormData) {
  const [current, setCurrent] = useState(initialData);
  const historyRef = useRef<History<FormData>>(new History());

  useEffect(() => {
    historyRef.current.save(initialData);
  }, []);

  const updateField = <K extends keyof FormData>(
    key: K,
    value: FormData[K],
  ) => {
    const newData = { ...current, [key]: value };
    setCurrent(newData);
    historyRef.current.save(newData);
  };

  const undo = () => {
    const prevState = historyRef.current.undo();
    if (prevState) setCurrent(prevState);
  };

  const redo = () => {
    const nextState = historyRef.current.redo();
    if (nextState) setCurrent(nextState);
  };

  return {
    formData: current,
    updateField,
    undo,
    redo,
    canUndo: historyRef.current.canUndo(),
    canRedo: historyRef.current.canRedo(),
  };
}
```

---

## 5. 브라우저 히스토리와의 연결

브라우저의 History API는 메멘토 패턴의 구현이다.

```typescript
// 브라우저 History API = 메멘토 패턴
// state = 메멘토
// pushState/replaceState = save()
// back()/forward() = undo()/redo()

// SPA 라우터의 히스토리 관리
history.pushState({ page: 'home' }, '', '/');      // 스냅샷 저장
history.pushState({ page: 'about' }, '', '/about'); // 스냅샷 저장

window.addEventListener('popstate', (event) => {
  console.log(event.state); // 이전 스냅샷 복원
  // { page: 'home' }
});

history.back(); // Undo
history.forward(); // Redo
```

---

## 6. Immer와의 관계

```typescript
// Immer = 메멘토 + 불변 업데이트를 편리하게 해주는 라이브러리
import produce from 'immer';

interface AppState {
  todos: { id: number; text: string; done: boolean }[];
  filter: 'all' | 'active' | 'done';
}

const state: AppState = {
  todos: [{ id: 1, text: '공부하기', done: false }],
  filter: 'all',
};

// Immer가 내부적으로 이전 상태 스냅샷을 보존하며 새 상태 생성
const nextState = produce(state, (draft) => {
  draft.todos[0].done = true;          // 직접 수정처럼 작성
  draft.todos.push({ id: 2, text: '운동하기', done: false });
});

console.log(state.todos[0].done);     // false (원본 보존)
console.log(nextState.todos[0].done); // true

// Redux Toolkit이 Immer를 내장하여 메멘토 패턴을 자동 적용
```

---

## 7. 면접 포인트

**Q1. 메멘토 패턴이란 무엇인가요?**
> 객체의 내부 상태를 스냅샷으로 저장하고, 캡슐화를 깨지 않으면서 이전 상태로 복원하는 패턴입니다. Undo/Redo 기능 구현에 주로 사용됩니다.

**Q2. 메멘토 패턴에서 캡슐화가 중요한 이유는?**
> Caretaker가 Memento를 저장하지만, Originator의 내부 상태에는 직접 접근하지 않습니다. 이는 객체의 내부 구현 변경이 외부에 영향을 주지 않도록 합니다.

**Q3. 브라우저 History API와 메멘토 패턴의 관계는?**
> `pushState()`가 스냅샷 저장, `back()/forward()`가 Undo/Redo에 해당합니다. 각 히스토리 엔트리가 Memento 객체입니다.

**Q4. 메멘토 패턴의 단점은?**
> 상태가 클수록 메모리 사용량이 증가합니다. 히스토리가 많이 쌓이면 메모리 관리가 필요합니다. 객체 참조가 포함된 상태는 깊은 복사가 필요하여 성능 비용이 있습니다.

---

[← Mediator](./04-mediator.md) | [← 행동 패턴 목차](./README.md) | [다음: Observer →](./06-observer.md)
