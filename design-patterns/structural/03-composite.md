# Composite (컴포짓 패턴)

## 목차
1. [개념](#1-개념)
2. [파일 시스템 예제](#2-파일-시스템-예제)
3. [React 컴포넌트 트리와의 연결](#3-react-컴포넌트-트리와의-연결)
4. [메뉴 트리 구조 예제](#4-메뉴-트리-구조-예제)
5. [면접 포인트](#5-면접-포인트)

---

## 1. 개념

> 객체들을 **트리 구조**로 구성하여 부분-전체 계층을 표현한다.
> 클라이언트가 **단일 객체와 복합 객체를 동일하게 다룰 수 있게** 한다.

핵심: 리프(leaf) 노드와 컨테이너(composite) 노드를 **같은 인터페이스**로 처리한다.

**언제 쓰는가?**
- 트리 구조로 데이터를 표현해야 할 때
- 개별 객체와 그 컬렉션을 같은 방식으로 처리하고 싶을 때
- 재귀적인 구조를 표현할 때

**구조**
```
Component (interface)
├─ operation()
└─ add/remove/getChildren()

Leaf                    Composite
└─ operation()          ├─ children: Component[]
                        ├─ operation()  ← 자식들에게 위임
                        ├─ add(c: Component)
                        └─ remove(c: Component)
```

---

## 2. 파일 시스템 예제

```typescript
// 공통 인터페이스
interface FileSystemItem {
  name: string;
  getSize(): number;
  print(indent?: number): void;
}

// 리프 노드 — 파일
class File implements FileSystemItem {
  constructor(
    public name: string,
    private size: number,
  ) {}

  getSize(): number {
    return this.size;
  }

  print(indent: number = 0): void {
    console.log(`${'  '.repeat(indent)}📄 ${this.name} (${this.size}KB)`);
  }
}

// 복합 노드 — 폴더
class Folder implements FileSystemItem {
  private children: FileSystemItem[] = [];

  constructor(public name: string) {}

  add(item: FileSystemItem): void {
    this.children.push(item);
  }

  remove(item: FileSystemItem): void {
    const index = this.children.indexOf(item);
    if (index !== -1) this.children.splice(index, 1);
  }

  getSize(): number {
    // 재귀적으로 모든 자식의 크기 합산
    return this.children.reduce((total, child) => total + child.getSize(), 0);
  }

  print(indent: number = 0): void {
    console.log(`${'  '.repeat(indent)}📁 ${this.name}/`);
    this.children.forEach(child => child.print(indent + 1));
  }
}

// ─── 트리 구성 ────────────────────────────────────────────
const root = new Folder('project');

const src = new Folder('src');
src.add(new File('index.ts', 5));
src.add(new File('app.ts', 12));

const components = new Folder('components');
components.add(new File('Button.tsx', 3));
components.add(new File('Modal.tsx', 8));
src.add(components);

const dist = new Folder('dist');
dist.add(new File('bundle.js', 240));

root.add(src);
root.add(dist);
root.add(new File('package.json', 2));

// ─── 동일한 인터페이스로 사용 ─────────────────────────────
root.print();
// 📁 project/
//   📁 src/
//     📄 index.ts (5KB)
//     📄 app.ts (12KB)
//     📁 components/
//       📄 Button.tsx (3KB)
//       📄 Modal.tsx (8KB)
//   📁 dist/
//     📄 bundle.js (240KB)
//   📄 package.json (2KB)

console.log(`총 크기: ${root.getSize()}KB`); // 270KB
console.log(`src 크기: ${src.getSize()}KB`); // 28KB
```

---

## 3. React 컴포넌트 트리와의 연결

React의 컴포넌트 시스템 자체가 컴포짓 패턴이다.

```tsx
// 모든 React 요소는 동일한 인터페이스(JSX.Element)를 가진다
// 리프 노드도, 복합 노드도 같은 방식으로 사용된다

// 리프 컴포넌트 (children 없음)
const Button: React.FC<{ label: string }> = ({ label }) => (
  <button>{label}</button>
);

// 복합 컴포넌트 (children 포함)
const Card: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <div className="card">{children}</div>
);

const Form: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <form>{children}</form>
);

// 트리 구성 — 단일 객체와 복합 객체를 동일하게 다룸
const App = () => (
  <Card>                         {/* Composite */}
    <Form>                       {/* Composite */}
      <input type="text" />      {/* Leaf */}
      <Button label="제출" />    {/* Leaf */}
    </Form>
  </Card>
);
```

React의 재조정(Reconciliation) 알고리즘도 컴포넌트 트리를 재귀적으로 순회한다.

---

## 4. 메뉴 트리 구조 예제

중첩 메뉴(드롭다운, 사이드바 네비게이션)를 컴포짓 패턴으로 구현한다.

```typescript
interface MenuItem {
  label: string;
  render(depth?: number): string;
  getPath(): string[];
}

class MenuLeaf implements MenuItem {
  constructor(
    public label: string,
    private href: string,
  ) {}

  render(depth: number = 0): string {
    const indent = '  '.repeat(depth);
    return `${indent}<a href="${this.href}">${this.label}</a>`;
  }

  getPath(): string[] {
    return [this.label];
  }
}

class MenuGroup implements MenuItem {
  private items: MenuItem[] = [];

  constructor(public label: string) {}

  add(item: MenuItem): this {
    this.items.push(item);
    return this;
  }

  render(depth: number = 0): string {
    const indent = '  '.repeat(depth);
    const children = this.items
      .map(item => item.render(depth + 1))
      .join('\n');
    return `${indent}<div class="menu-group">
${indent}  <span>${this.label}</span>
${children}
${indent}</div>`;
  }

  getPath(): string[] {
    return [this.label];
  }

  find(label: string): MenuItem | null {
    for (const item of this.items) {
      if (item.label === label) return item;
      if (item instanceof MenuGroup) {
        const found = item.find(label);
        if (found) return found;
      }
    }
    return null;
  }
}

// 트리 구성
const nav = new MenuGroup('Navigation')
  .add(new MenuLeaf('홈', '/'))
  .add(
    new MenuGroup('제품')
      .add(new MenuLeaf('소개', '/products'))
      .add(new MenuLeaf('가격', '/pricing'))
      .add(
        new MenuGroup('카테고리')
          .add(new MenuLeaf('프론트엔드', '/category/frontend'))
          .add(new MenuLeaf('백엔드', '/category/backend'))
      )
  )
  .add(new MenuLeaf('문의', '/contact'));

console.log(nav.render());
console.log(nav.find('가격')); // MenuLeaf { label: '가격', href: '/pricing' }
```

---

## 5. 면접 포인트

**Q1. 컴포짓 패턴이란 무엇인가요?**
> 객체들을 트리 구조로 구성하여, 단일 객체와 복합 객체(컨테이너)를 동일한 인터페이스로 처리하는 패턴입니다. 부분-전체 계층 구조를 표현할 때 사용합니다.

**Q2. React 컴포넌트 트리와 컴포짓 패턴의 관계를 설명해주세요.**
> React의 모든 컴포넌트(리프든 복합이든)는 JSX.Element라는 동일한 인터페이스를 가집니다. `<Button>`(리프)이든 `<Card children={...}>`(복합)이든 동일한 방식으로 트리에 배치되는 것이 컴포짓 패턴입니다.

**Q3. 컴포짓 패턴에서 리프와 컴포짓의 차이는?**
> 리프는 자식을 가질 수 없는 말단 노드입니다. 컴포짓은 자식을 포함하고 위임(delegation)으로 자식들의 연산을 집계합니다.

**Q4. 컴포짓 패턴의 단점은?**
> 모든 컴포넌트에 동일한 인터페이스를 강제하면, 리프에서는 의미 없는 메서드(add/remove)도 구현해야 할 수 있습니다. 타입 안전성이 낮아질 수 있습니다.

---

[← Bridge](./02-bridge.md) | [← 구조 패턴 목차](./README.md) | [다음: Decorator →](./04-decorator.md)
