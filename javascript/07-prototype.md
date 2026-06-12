# 07. 프로토타입 (Prototype)

## 목차
1. [프로토타입이란](#1-프로토타입이란)
2. [프로토타입 체인](#2-프로토타입-체인)
3. [`__proto__` vs `prototype`](#3-__proto__-vs-prototype)
4. [`Object.create()`와 클래스 문법 내부 동작](#4-objectcreate와-클래스-문법-내부-동작)
5. [상속 패턴](#5-상속-패턴)
6. [면접 포인트](#면접-포인트)

---

## 1. 프로토타입이란

JavaScript는 **프로토타입 기반 언어**다. 객체는 다른 객체를 **프로토타입**으로 가질 수 있고, 자신에게 없는 프로퍼티를 프로토타입에서 찾는다.

```js
const animal = {
  breathe() {
    console.log('숨을 쉰다.');
  }
};

const dog = {
  bark() {
    console.log('멍멍!');
  }
};

// dog의 프로토타입을 animal로 설정
Object.setPrototypeOf(dog, animal);

dog.bark();    // '멍멍!' - 자신의 메서드
dog.breathe(); // '숨을 쉰다.' - 프로토타입(animal)의 메서드

console.log(dog.hasOwnProperty('bark'));    // true
console.log(dog.hasOwnProperty('breathe')); // false
```

---

## 2. 프로토타입 체인

프로퍼티를 찾을 때 JS 엔진은 다음 순서로 탐색한다.

```
객체 자신 → 프로토타입 → 프로토타입의 프로토타입 → ... → Object.prototype → null
```

```js
const obj = { a: 1 };

// 프로토타입 체인
// obj → Object.prototype → null

console.log(obj.a);            // 1 (자신)
console.log(obj.toString());   // '[object Object]' (Object.prototype에서 찾음)
console.log(obj.nonExistent);  // undefined (null까지 탐색 후 없으면 undefined)
```

```
obj
├── a: 1
└── [[Prototype]] → Object.prototype
                    ├── toString()
                    ├── hasOwnProperty()
                    ├── valueOf()
                    └── [[Prototype]] → null
```

### 배열의 프로토타입 체인

```js
const arr = [1, 2, 3];

// arr → Array.prototype → Object.prototype → null

console.log(arr.map);         // function (Array.prototype에 있음)
console.log(arr.toString);    // function (Object.prototype에 있음)
console.log(arr instanceof Array);  // true
console.log(arr instanceof Object); // true

// 프로토타입 체인 확인
console.log(Object.getPrototypeOf(arr) === Array.prototype);         // true
console.log(Object.getPrototypeOf(Array.prototype) === Object.prototype); // true
```

---

## 3. `__proto__` vs `prototype`

이 둘은 자주 혼동되지만 완전히 다른 것이다.

| 구분 | `__proto__` | `prototype` |
|------|-------------|-------------|
| 위치 | 모든 객체 (인스턴스 포함) | **함수 객체**에만 존재 |
| 역할 | 자신의 프로토타입(부모)을 가리킴 | `new`로 만든 인스턴스의 `__proto__`가 됨 |
| 표준 | 비표준 (레거시) | 표준 |
| 대체 | `Object.getPrototypeOf()` 사용 권장 | - |

```js
function Person(name) {
  this.name = name;
}

Person.prototype.greet = function() {
  console.log(`안녕하세요, ${this.name}입니다.`);
};

const alice = new Person('Alice');

// prototype: 함수 객체에 존재
console.log(typeof Person.prototype); // 'object'
console.log(Person.prototype.greet);  // function

// __proto__: 인스턴스에 존재, 생성자의 prototype을 가리킴
console.log(alice.__proto__ === Person.prototype); // true
console.log(Object.getPrototypeOf(alice) === Person.prototype); // true (권장)

alice.greet(); // '안녕하세요, Alice입니다.'
```

```
Person (함수)
├── prototype ─────────────────────┐
│                                  ↓
│                          Person.prototype
│                          ├── greet: function
│                          └── constructor: Person ←─────┐
│                                                         │
new Person('Alice')                                       │
└── alice                                                 │
    ├── name: 'Alice'                                     │
    └── [[Prototype]] / __proto__ → Person.prototype      │
                                    └── constructor ──────┘
```

### `new` 연산자 내부 동작

```js
function myNew(Constructor, ...args) {
  // 1. 빈 객체 생성 + 프로토타입 연결
  const obj = Object.create(Constructor.prototype);

  // 2. 생성자 함수 실행 (this = obj)
  const result = Constructor.apply(obj, args);

  // 3. 생성자가 객체를 반환하면 그것을, 아니면 obj 반환
  return result instanceof Object ? result : obj;
}

const bob = myNew(Person, 'Bob');
bob.greet(); // '안녕하세요, Bob입니다.'
```

---

## 4. `Object.create()`와 클래스 문법 내부 동작

### `Object.create()`

지정한 객체를 프로토타입으로 하는 새 객체를 생성한다.

```js
const animal = {
  type: 'Animal',
  describe() {
    console.log(`나는 ${this.name}이고, ${this.type}입니다.`);
  }
};

const cat = Object.create(animal);
cat.name = '냥이';
cat.type = 'Cat';

cat.describe(); // '나는 냥이이고, Cat입니다.'

// cat의 프로토타입이 animal임을 확인
console.log(Object.getPrototypeOf(cat) === animal); // true

// Object.create(null): 프로토타입이 없는 순수 객체
const pureObj = Object.create(null);
console.log(pureObj.toString); // undefined (Object.prototype 메서드 없음)
```

### `class` 문법 내부 동작

`class`는 프로토타입 기반 상속의 **문법적 설탕(syntactic sugar)** 이다.

```js
class Animal {
  constructor(name) {
    this.name = name;
  }

  speak() {
    console.log(`${this.name}이 소리를 냅니다.`);
  }
}

class Dog extends Animal {
  constructor(name) {
    super(name); // Animal.constructor 호출, this 바인딩
  }

  speak() {
    console.log(`${this.name}이 멍멍 짖습니다.`);
  }
}

const d = new Dog('바둑이');
d.speak(); // '바둑이이 멍멍 짖습니다.'

// 내부적으로는 프로토타입 체인
console.log(Object.getPrototypeOf(Dog) === Animal); // true (생성자 함수 간)
console.log(Object.getPrototypeOf(Dog.prototype) === Animal.prototype); // true
```

**`class`가 기존 함수 기반과 다른 점:**

```js
// class는 함수지만 반드시 new와 함께 호출해야 함
typeof Animal // 'function'
Animal()      // TypeError: Class constructor Animal cannot be invoked without 'new'

// class 내부는 항상 strict mode
// 메서드는 열거 불가(non-enumerable)
console.log(Object.keys(Animal.prototype)); // [] - 메서드 열거 안 됨
```

---

## 5. 상속 패턴

### 5-1. 프로토타입 체인 상속 (ES5 방식)

```js
function Shape(color) {
  this.color = color;
}

Shape.prototype.getColor = function() {
  return this.color;
};

function Circle(color, radius) {
  Shape.call(this, color); // 부모 생성자 호출 (속성 상속)
  this.radius = radius;
}

// 프로토타입 체인 연결 (메서드 상속)
Circle.prototype = Object.create(Shape.prototype);
Circle.prototype.constructor = Circle; // constructor 복원

Circle.prototype.getArea = function() {
  return Math.PI * this.radius ** 2;
};

const c = new Circle('red', 5);
console.log(c.getColor()); // 'red'
console.log(c.getArea().toFixed(2)); // '78.54'
console.log(c instanceof Circle); // true
console.log(c instanceof Shape);  // true
```

### 5-2. `class` 상속 (ES6+)

```js
class Shape {
  constructor(color) {
    this.color = color;
  }

  getColor() {
    return this.color;
  }

  // static 메서드: 인스턴스가 아닌 클래스에서 호출
  static create(color) {
    return new this(color);
  }
}

class Rectangle extends Shape {
  constructor(color, width, height) {
    super(color); // 반드시 this 사용 전에 호출
    this.width = width;
    this.height = height;
  }

  getArea() {
    return this.width * this.height;
  }

  // 부모 메서드 오버라이딩
  getColor() {
    return `색상: ${super.getColor()}`; // super로 부모 메서드 호출
  }
}

const rect = new Rectangle('blue', 10, 5);
console.log(rect.getColor()); // '색상: blue'
console.log(rect.getArea());  // 50
```

### 5-3. 믹스인 (Mixin) 패턴

JavaScript는 단일 상속만 지원하므로, 여러 기능을 합성할 때 믹스인을 사용한다.

```js
// 믹스인: 기능 묶음
const Serializable = (superclass) => class extends superclass {
  serialize() {
    return JSON.stringify(this);
  }

  static deserialize(json) {
    return Object.assign(new this(), JSON.parse(json));
  }
};

const Validatable = (superclass) => class extends superclass {
  validate() {
    return Object.values(this).every(v => v !== null && v !== undefined);
  }
};

class Base {
  constructor(data) {
    Object.assign(this, data);
  }
}

class User extends Serializable(Validatable(Base)) {}

const user = new User({ name: 'Alice', age: 30 });
console.log(user.validate());   // true
console.log(user.serialize());  // '{"name":"Alice","age":30}'
```

---

## 면접 포인트

**Q. 프로토타입 체인이란 무엇인가요?**
> 객체에서 프로퍼티를 찾을 때 자신에게 없으면 `[[Prototype]]`(프로토타입)에서 찾고, 없으면 그 프로토타입의 프로토타입에서 찾는 과정을 반복한다. 최종적으로 `Object.prototype`까지 탐색하고, 없으면 `undefined`를 반환한다.

**Q. `__proto__`와 `prototype`의 차이는?**
> `prototype`은 함수 객체에만 존재하며, `new`로 생성된 인스턴스의 프로토타입이 된다. `__proto__`는 모든 객체에 존재하며 자신의 프로토타입(부모 객체)을 가리킨다. `alice.__proto__ === Person.prototype`이 성립한다. 접근은 `Object.getPrototypeOf()` 사용을 권장한다.

**Q. `class`는 기존 프로토타입 방식과 다른가요?**
> 내부 동작은 같다. `class`는 프로토타입 기반 상속의 문법적 설탕이다. 다만 차이점이 있다: (1) `new` 없이 호출 불가, (2) 항상 strict mode, (3) 메서드가 non-enumerable, (4) 호이스팅되지 않음(TDZ 적용).

**Q. `Object.create(null)`은 언제 사용하나요?**
> `Object.create(null)`은 `Object.prototype`을 상속받지 않는 순수한 딕셔너리 객체를 만든다. `toString`, `hasOwnProperty` 등의 메서드가 없어 키-값 저장소로 안전하게 사용할 수 있다. 예상치 못한 프로토타입 오염을 방지할 때 유용하다.

**Q. `instanceof`는 어떻게 동작하나요?**
> `a instanceof B`는 `a`의 프로토타입 체인 어딘가에 `B.prototype`이 있는지 확인한다. `Symbol.hasInstance`를 통해 커스터마이징도 가능하다. 프로토타입 체인을 탐색하므로 부모 클래스에 대해서도 `true`를 반환한다.
