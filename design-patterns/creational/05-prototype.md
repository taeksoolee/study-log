# Prototype (프로토타입 패턴)

## 목차
1. [개념](#1-개념)
2. [JS의 프로토타입 체인과 연결](#2-js의-프로토타입-체인과-연결)
3. [얕은 복사 vs 깊은 복사](#3-얕은-복사-vs-깊은-복사)
4. [Object.create와 프로토타입 패턴](#4-objectcreate와-프로토타입-패턴)
5. [structuredClone으로 깊은 복사](#5-structuredclone으로-깊은-복사)
6. [실용 예시 — 게임 캐릭터 템플릿](#6-실용-예시--게임-캐릭터-템플릿)
7. [React의 불변 상태 업데이트와 프로토타입](#7-react의-불변-상태-업데이트와-프로토타입)
8. [면접 포인트](#8-면접-포인트)

---

## 1. 개념

> **기존 객체를 복사(클론)**하여 새 객체를 생성한다. 클래스에 의존하지 않고 기존 객체를 원형(prototype)으로 사용한다.

**언제 쓰는가?**
- 객체 생성 비용이 클 때 (네트워크 요청, 복잡한 초기화)
- 유사한 객체를 여러 개 만들어야 할 때
- 런타임에 동적으로 클래스를 결정하기 어려울 때
- 기존 객체를 기반으로 약간 수정된 버전이 필요할 때

**패턴 구조**
```
Prototype (interface)
└─ clone(): Prototype

ConcretePrototype
└─ clone(): ConcretePrototype  ← this를 복사하여 반환
```

---

## 2. JS의 프로토타입 체인과 연결

JavaScript는 언어 자체가 **프로토타입 기반 언어**다.
GoF 프로토타입 패턴과 JS 프로토타입 체인은 이름이 같지만 다른 개념이다.

```javascript
// JS 프로토타입 체인
const animal = {
  type: 'Animal',
  describe() {
    return `나는 ${this.type}입니다`;
  },
};

// Object.create는 JS 프로토타입 패턴의 핵심
const dog = Object.create(animal);
dog.type = 'Dog';
dog.bark = function() { return '멍멍!'; };

console.log(dog.describe()); // '나는 Dog입니다' — 프로토타입 체인으로 animal.describe 호출
console.log(Object.getPrototypeOf(dog) === animal); // true

// GoF 패턴의 관점: animal이 prototype, dog이 clone
```

---

## 3. 얕은 복사 vs 깊은 복사

```typescript
const original = {
  name: 'Alice',
  scores: [95, 87, 91],
  address: { city: 'Seoul', zip: '04522' },
};

// 얕은 복사 (Shallow Copy) — Object.assign, 스프레드 연산자
const shallow = { ...original };
shallow.name = 'Bob';       // 독립적 ✓
shallow.scores.push(100);   // 원본도 변경됨 ✗ (참조 공유)
shallow.address.city = 'Busan'; // 원본도 변경됨 ✗

console.log(original.scores);      // [95, 87, 91, 100] — 오염됨!
console.log(original.address.city); // 'Busan' — 오염됨!

// 깊은 복사 (Deep Copy)
const deep = JSON.parse(JSON.stringify(original));
// 단점: undefined, Function, Date, Map, Set 등 처리 불가
```

---

## 4. Object.create와 프로토타입 패턴

```typescript
// clone 메서드를 명시적으로 구현하는 패턴
interface Cloneable<T> {
  clone(): T;
}

class UserSettings implements Cloneable<UserSettings> {
  constructor(
    public theme: 'light' | 'dark',
    public language: string,
    public notifications: { email: boolean; push: boolean },
  ) {}

  clone(): UserSettings {
    return new UserSettings(
      this.theme,
      this.language,
      { ...this.notifications }, // 중첩 객체는 수동 복사
    );
  }

  withTheme(theme: 'light' | 'dark'): UserSettings {
    const copy = this.clone();
    copy.theme = theme;
    return copy;
  }
}

const defaultSettings = new UserSettings('light', 'ko', {
  email: true,
  push: false,
});

// 기존 설정을 복사하여 일부만 변경
const darkSettings = defaultSettings.withTheme('dark');

console.log(defaultSettings.theme); // 'light' — 원본 유지
console.log(darkSettings.theme);    // 'dark'
console.log(defaultSettings === darkSettings); // false
```

---

## 5. structuredClone으로 깊은 복사

Node.js 17+, 모던 브라우저에서 사용 가능한 네이티브 깊은 복사 API다.

```typescript
const original = {
  name: 'Alice',
  birthDate: new Date('1990-01-01'),
  scores: [95, 87, 91],
  metadata: {
    tags: ['admin', 'user'],
    settings: { theme: 'light' },
  },
};

// structuredClone — Date, Map, Set, ArrayBuffer도 처리 가능
const clone = structuredClone(original);

clone.scores.push(100);
clone.metadata.settings.theme = 'dark';
clone.birthDate.setFullYear(2000);

console.log(original.scores);                   // [95, 87, 91] — 안전
console.log(original.metadata.settings.theme); // 'light' — 안전
console.log(original.birthDate.getFullYear()); // 1990 — 안전

// 단점: Function, Symbol, DOM 노드 복사 불가
```

**복사 방법 비교**

| 방법 | 깊이 | 주의사항 |
|------|------|----------|
| `{ ...obj }` | 얕은 | 중첩 객체 공유 |
| `Object.assign({}, obj)` | 얕은 | 중첩 객체 공유 |
| `JSON.parse(JSON.stringify(obj))` | 깊은 | Function, Date, undefined 손실 |
| `structuredClone(obj)` | 깊은 | Function, Symbol 불가 |
| 수동 `clone()` 메서드 | 원하는 깊이 | 코드 작성 필요 |

---

## 6. 실용 예시 — 게임 캐릭터 템플릿

```typescript
class Character {
  constructor(
    public name: string,
    public hp: number,
    public mp: number,
    public skills: string[],
    public equipment: { weapon: string; armor: string },
  ) {}

  clone(): Character {
    return new Character(
      this.name,
      this.hp,
      this.mp,
      [...this.skills],               // 배열 복사
      { ...this.equipment },          // 객체 복사
    );
  }
}

// 기본 전사 템플릿
const warriorTemplate = new Character(
  '전사',
  1000,
  200,
  ['검격', '방패 막기'],
  { weapon: '롱소드', armor: '판금 갑옷' },
);

// 템플릿에서 복사하여 개별 캐릭터 생성
const warrior1 = warriorTemplate.clone();
warrior1.name = '레온';
warrior1.skills.push('강타');

const warrior2 = warriorTemplate.clone();
warrior2.name = '아르테';
warrior2.equipment.weapon = '대검';

console.log(warriorTemplate.skills); // ['검격', '방패 막기'] — 원본 유지
console.log(warrior1.skills);        // ['검격', '방패 막기', '강타']
console.log(warrior2.equipment.weapon); // '대검'
```

---

## 7. React의 불변 상태 업데이트와 프로토타입

React에서 상태를 업데이트할 때 항상 새 객체를 만드는 것은 프로토타입 패턴의 응용이다.

```typescript
// React 상태 업데이트 — 불변성 유지
const [user, setUser] = useState({
  name: 'Alice',
  preferences: { theme: 'light', lang: 'ko' },
});

// 나쁜 예 — 직접 수정 (React가 변경 감지 못함)
user.preferences.theme = 'dark'; // ✗

// 좋은 예 — 프로토타입 패턴처럼 복사 후 수정
setUser(prev => ({
  ...prev,                              // 얕은 복사
  preferences: {
    ...prev.preferences,                // 중첩 객체도 복사
    theme: 'dark',
  },
}));

// Immer 라이브러리 — 내부적으로 structuredClone과 유사하게 처리
import produce from 'immer';
setUser(produce(draft => {
  draft.preferences.theme = 'dark'; // 마치 직접 수정하는 것처럼 작성
}));
```

---

## 8. 면접 포인트

**Q1. 프로토타입 패턴이란 무엇인가요?**
> 기존 객체를 복사하여 새 객체를 생성하는 패턴입니다. 클래스를 직접 인스턴스화하는 대신 원형 객체를 복제합니다.

**Q2. JS 프로토타입 체인과 GoF 프로토타입 패턴의 차이는?**
> JS 프로토타입 체인은 메서드/속성 상속을 위한 언어 메커니즘입니다. GoF 프로토타입 패턴은 객체 복사를 통한 생성 방법을 의미합니다. 이름은 같지만 다른 개념입니다.

**Q3. 얕은 복사와 깊은 복사의 차이와 각각 언제 사용하나요?**
> 얕은 복사는 최상위 속성만 복사하고 중첩 객체는 참조를 공유합니다. 중첩 객체가 변경되지 않는다면 성능이 좋은 얕은 복사를 사용합니다. 중첩 객체도 독립적이어야 한다면 깊은 복사(structuredClone)를 사용합니다.

**Q4. React의 불변 상태 업데이트와 프로토타입 패턴의 관계는?**
> React의 `setState`에서 `{ ...prev, key: newValue }` 패턴은 기존 상태를 원형으로 복사하여 새 상태를 만드는 프로토타입 패턴의 응용입니다.

---

[← Builder](./04-builder.md) | [← 생성 패턴 목차](./README.md) | [구조 패턴으로 →](../structural/README.md)
