# Visitor (비지터 패턴)

## 목차
1. [개념](#1-개념)
2. [기본 구현](#2-기본-구현)
3. [AST 순회 예제](#3-ast-순회-예제)
4. [더블 디스패치](#4-더블-디스패치)
5. [실제 활용 — Babel, ESLint](#5-실제-활용--babel-eslint)
6. [함수형 방식으로 구현](#6-함수형-방식으로-구현)
7. [면접 포인트](#7-면접-포인트)

---

## 1. 개념

> 객체 구조를 변경하지 않고, **새로운 연산을 추가**할 수 있게 한다.
> 연산(방문자)과 데이터 구조(요소)를 분리한다.

**언제 쓰는가?**
- 안정적인 자료구조에 새로운 연산을 자주 추가해야 할 때
- 서로 다른 타입의 객체들에 대해 여러 연산을 수행해야 할 때
- 자료구조와 알고리즘을 분리하고 싶을 때

**핵심 아이디어**: "더블 디스패치"
1. 클라이언트가 `element.accept(visitor)` 호출
2. Element가 `visitor.visit(this)` 호출
→ 런타임에 element 타입과 visitor 타입 모두에 따라 올바른 메서드 호출

---

## 2. 기본 구현

```typescript
// 방문 가능한 요소 인터페이스
interface Shape {
  accept(visitor: ShapeVisitor): void;
}

// 비지터 인터페이스
interface ShapeVisitor {
  visitCircle(circle: Circle): void;
  visitRectangle(rectangle: Rectangle): void;
  visitTriangle(triangle: Triangle): void;
}

// 구체 요소들
class Circle implements Shape {
  constructor(public radius: number) {}
  accept(visitor: ShapeVisitor): void {
    visitor.visitCircle(this);
  }
}

class Rectangle implements Shape {
  constructor(public width: number, public height: number) {}
  accept(visitor: ShapeVisitor): void {
    visitor.visitRectangle(this);
  }
}

class Triangle implements Shape {
  constructor(public base: number, public height: number) {}
  accept(visitor: ShapeVisitor): void {
    visitor.visitTriangle(this);
  }
}

// 구체 비지터 — 새 연산 추가 시 새 Visitor 클래스 추가
class AreaCalculator implements ShapeVisitor {
  private totalArea = 0;

  visitCircle(circle: Circle): void {
    this.totalArea += Math.PI * circle.radius ** 2;
  }

  visitRectangle(rect: Rectangle): void {
    this.totalArea += rect.width * rect.height;
  }

  visitTriangle(tri: Triangle): void {
    this.totalArea += 0.5 * tri.base * tri.height;
  }

  getTotal(): number { return this.totalArea; }
}

class SVGExporter implements ShapeVisitor {
  private output: string[] = [];

  visitCircle(circle: Circle): void {
    this.output.push(`<circle r="${circle.radius}" />`);
  }

  visitRectangle(rect: Rectangle): void {
    this.output.push(`<rect width="${rect.width}" height="${rect.height}" />`);
  }

  visitTriangle(tri: Triangle): void {
    this.output.push(`<polygon points="0,${tri.height} ${tri.base},${tri.height} ${tri.base / 2},0" />`);
  }

  getSVG(): string {
    return `<svg>${this.output.join('')}</svg>`;
  }
}

// 사용 — 도형 구조 변경 없이 연산만 추가
const shapes: Shape[] = [
  new Circle(5),
  new Rectangle(10, 8),
  new Triangle(6, 4),
];

const areaCalc = new AreaCalculator();
shapes.forEach(shape => shape.accept(areaCalc));
console.log(`총 면적: ${areaCalc.getTotal().toFixed(2)}`);

const svgExporter = new SVGExporter();
shapes.forEach(shape => shape.accept(svgExporter));
console.log(svgExporter.getSVG());
```

---

## 3. AST 순회 예제

코드 분석 도구(Babel, ESLint)에서 비지터 패턴을 핵심적으로 사용한다.

```typescript
// 간단한 수식 AST
interface ASTNode {
  accept<T>(visitor: ASTVisitor<T>): T;
}

interface ASTVisitor<T> {
  visitNumber(node: NumberNode): T;
  visitBinaryOp(node: BinaryOpNode): T;
  visitIdentifier(node: IdentifierNode): T;
}

class NumberNode implements ASTNode {
  constructor(public value: number) {}
  accept<T>(visitor: ASTVisitor<T>): T {
    return visitor.visitNumber(this);
  }
}

class IdentifierNode implements ASTNode {
  constructor(public name: string) {}
  accept<T>(visitor: ASTVisitor<T>): T {
    return visitor.visitIdentifier(this);
  }
}

class BinaryOpNode implements ASTNode {
  constructor(
    public operator: '+' | '-' | '*' | '/',
    public left: ASTNode,
    public right: ASTNode,
  ) {}
  accept<T>(visitor: ASTVisitor<T>): T {
    return visitor.visitBinaryOp(this);
  }
}

// 비지터 1: 계산기
class Evaluator implements ASTVisitor<number> {
  constructor(private env: Record<string, number> = {}) {}

  visitNumber(node: NumberNode): number { return node.value; }

  visitIdentifier(node: IdentifierNode): number {
    const value = this.env[node.name];
    if (value === undefined) throw new Error(`변수 미정의: ${node.name}`);
    return value;
  }

  visitBinaryOp(node: BinaryOpNode): number {
    const left = node.left.accept(this);
    const right = node.right.accept(this);
    switch (node.operator) {
      case '+': return left + right;
      case '-': return left - right;
      case '*': return left * right;
      case '/': return left / right;
    }
  }
}

// 비지터 2: 코드 생성기
class CodeGenerator implements ASTVisitor<string> {
  visitNumber(node: NumberNode): string { return String(node.value); }
  visitIdentifier(node: IdentifierNode): string { return node.name; }
  visitBinaryOp(node: BinaryOpNode): string {
    return `(${node.left.accept(this)} ${node.operator} ${node.right.accept(this)})`;
  }
}

// AST: (x + 2) * (3 - y)
const ast = new BinaryOpNode(
  '*',
  new BinaryOpNode('+', new IdentifierNode('x'), new NumberNode(2)),
  new BinaryOpNode('-', new NumberNode(3), new IdentifierNode('y')),
);

const evaluator = new Evaluator({ x: 4, y: 1 });
console.log(ast.accept(evaluator)); // (4+2)*(3-1) = 12

const generator = new CodeGenerator();
console.log(ast.accept(generator)); // ((x + 2) * (3 - y))
```

---

## 4. 더블 디스패치

```typescript
// 단일 디스패치 (일반적인 메서드 호출)
// 어떤 메서드를 호출할지: obj의 타입만으로 결정
shape.draw(); // shape가 Circle이면 Circle.draw() 호출

// 더블 디스패치 (비지터 패턴)
// 어떤 메서드를 호출할지: element 타입 + visitor 타입 둘 다 고려
shape.accept(visitor);
// 1. shape가 Circle → circle.accept(visitor) → visitor.visitCircle(this)
// 2. visitor가 AreaCalc → AreaCalc.visitCircle(circle)
// → Circle × AreaCalc 조합의 메서드 실행
```

---

## 5. 실제 활용 — Babel, ESLint

```typescript
// Babel 플러그인 = 비지터 패턴
// Babel이 AST를 순회하며 플러그인(비지터)을 호출
module.exports = function({ types: t }) {
  return {
    visitor: {
      // 각 AST 노드 타입이 visitXxx에 해당
      CallExpression(path) {
        // console.log 제거 플러그인
        if (
          t.isMemberExpression(path.node.callee) &&
          path.node.callee.object.name === 'console'
        ) {
          path.remove();
        }
      },
      ArrowFunctionExpression(path) {
        // 화살표 함수 → 일반 함수 변환
        path.replaceWith(t.functionExpression(
          null, path.node.params, path.node.body
        ));
      },
    },
  };
};

// ESLint 규칙 = 비지터 패턴
module.exports = {
  create(context) {
    return {
      // 각 AST 노드 타입을 방문
      VariableDeclaration(node) {
        if (node.kind === 'var') {
          context.report({ node, message: 'var 대신 let/const를 사용하세요' });
        }
      },
    };
  },
};
```

---

## 6. 함수형 방식으로 구현

```typescript
// 패턴 매칭 방식 — TypeScript 판별 유니온 활용
type ShapeUnion =
  | { type: 'circle'; radius: number }
  | { type: 'rectangle'; width: number; height: number }
  | { type: 'triangle'; base: number; height: number };

// 비지터 = 각 케이스를 처리하는 함수 맵
type ShapeVisitorFn<T> = {
  circle: (shape: Extract<ShapeUnion, { type: 'circle' }>) => T;
  rectangle: (shape: Extract<ShapeUnion, { type: 'rectangle' }>) => T;
  triangle: (shape: Extract<ShapeUnion, { type: 'triangle' }>) => T;
};

function visitShape<T>(shape: ShapeUnion, visitor: ShapeVisitorFn<T>): T {
  return visitor[shape.type](shape as any);
}

// 사용
const shapes: ShapeUnion[] = [
  { type: 'circle', radius: 5 },
  { type: 'rectangle', width: 10, height: 8 },
];

const totalArea = shapes.reduce((sum, shape) =>
  sum + visitShape(shape, {
    circle: ({ radius }) => Math.PI * radius ** 2,
    rectangle: ({ width, height }) => width * height,
    triangle: ({ base, height }) => 0.5 * base * height,
  }), 0,
);
```

---

## 7. 면접 포인트

**Q1. 비지터 패턴이란 무엇인가요?**
> 객체 구조를 변경하지 않고 새로운 연산을 추가하는 패턴입니다. 연산(비지터)을 데이터 구조(요소)와 분리하여, 새 연산 추가 시 요소 클래스를 수정하지 않아도 됩니다.

**Q2. 더블 디스패치란 무엇인가요?**
> 호출할 메서드를 결정할 때 두 객체의 타입(요소 타입 + 비지터 타입)을 모두 고려하는 기법입니다. `element.accept(visitor)`가 `visitor.visit(element)`를 호출하여 두 단계 디스패치가 일어납니다.

**Q3. Babel 플러그인과 비지터 패턴의 관계는?**
> Babel이 AST를 순회하면서 각 노드 타입에 해당하는 플러그인 메서드(비지터)를 호출합니다. 플러그인이 비지터 역할을 하며, AST 노드(요소)를 수정합니다.

**Q4. 비지터 패턴의 단점은?**
> 새로운 요소 타입 추가 시 모든 비지터 클래스를 수정해야 합니다(요소 추가에는 OCP 위반). 요소가 자주 바뀌면 적합하지 않으며, 자료구조가 안정적일 때 유리합니다.

---

[← Template Method](./09-template-method.md) | [← 행동 패턴 목차](./README.md) | [← 전체 목차로](../README.md)
