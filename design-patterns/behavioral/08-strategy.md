# Strategy (전략 패턴)

## 목차
1. [개념](#1-개념)
2. [정렬 전략 예제](#2-정렬-전략-예제)
3. [결제 전략 예제](#3-결제-전략-예제)
4. [JS에서 함수를 전략으로 활용](#4-js에서-함수를-전략으로-활용)
5. [유효성 검사 전략](#5-유효성-검사-전략)
6. [면접 포인트](#6-면접-포인트)

---

## 1. 개념

> **알고리즘군을 정의하고 각각 캡슐화**하여 상호 교환 가능하게 만든다.
> 알고리즘을 사용하는 클라이언트와 독립적으로 변경할 수 있다.

**언제 쓰는가?**
- 런타임에 알고리즘을 교체해야 할 때
- 유사하지만 다른 방식으로 동작하는 여러 클래스가 있을 때
- 조건문으로 알고리즘을 선택하는 코드를 제거하고 싶을 때

**상태 패턴 vs 전략 패턴**
- 상태: 상태에 따라 자동으로 전환, 상태 객체가 컨텍스트를 인식
- 전략: 클라이언트가 명시적으로 전략을 선택, 전략 객체는 컨텍스트를 몰라도 됨

---

## 2. 정렬 전략 예제

```typescript
interface SortStrategy<T> {
  sort(data: T[]): T[];
  name: string;
}

// 버블 정렬
class BubbleSort<T> implements SortStrategy<T> {
  name = 'Bubble Sort';

  sort(data: T[]): T[] {
    const arr = [...data];
    for (let i = 0; i < arr.length; i++) {
      for (let j = 0; j < arr.length - i - 1; j++) {
        if (arr[j] > arr[j + 1]) {
          [arr[j], arr[j + 1]] = [arr[j + 1], arr[j]];
        }
      }
    }
    return arr;
  }
}

// 퀵 정렬
class QuickSort<T> implements SortStrategy<T> {
  name = 'Quick Sort';

  sort(data: T[]): T[] {
    if (data.length <= 1) return data;
    const [pivot, ...rest] = data;
    const left = rest.filter(x => x <= pivot);
    const right = rest.filter(x => x > pivot);
    return [...this.sort(left), pivot, ...this.sort(right)];
  }
}

// 삽입 정렬
class InsertionSort<T> implements SortStrategy<T> {
  name = 'Insertion Sort';

  sort(data: T[]): T[] {
    const arr = [...data];
    for (let i = 1; i < arr.length; i++) {
      const key = arr[i];
      let j = i - 1;
      while (j >= 0 && arr[j] > key) {
        arr[j + 1] = arr[j];
        j--;
      }
      arr[j + 1] = key;
    }
    return arr;
  }
}

// Context — 전략을 사용하는 객체
class Sorter<T> {
  constructor(private strategy: SortStrategy<T>) {}

  setStrategy(strategy: SortStrategy<T>): void {
    this.strategy = strategy;
  }

  sort(data: T[]): T[] {
    const start = performance.now();
    const result = this.strategy.sort(data);
    console.log(`${this.strategy.name}: ${(performance.now() - start).toFixed(2)}ms`);
    return result;
  }
}

// 데이터 크기에 따라 전략 자동 선택
function createOptimalSorter<T>(dataSize: number): SortStrategy<T> {
  if (dataSize < 10) return new InsertionSort();
  if (dataSize < 1000) return new QuickSort();
  return new BubbleSort(); // 실제로는 merge sort 사용
}

const data = [64, 34, 25, 12, 22, 11, 90];
const sorter = new Sorter(createOptimalSorter(data.length));
console.log(sorter.sort(data)); // [11, 12, 22, 25, 34, 64, 90]

// 런타임에 전략 교체
sorter.setStrategy(new QuickSort());
console.log(sorter.sort(data));
```

---

## 3. 결제 전략 예제

```typescript
interface PaymentStrategy {
  pay(amount: number): Promise<{ success: boolean; transactionId: string }>;
  validate(): boolean;
  getName(): string;
}

class CreditCardPayment implements PaymentStrategy {
  constructor(
    private cardNumber: string,
    private expiryDate: string,
    private cvv: string,
  ) {}

  validate(): boolean {
    return this.cardNumber.length === 16 && this.cvv.length === 3;
  }

  async pay(amount: number) {
    if (!this.validate()) throw new Error('카드 정보가 유효하지 않습니다');
    console.log(`[신용카드] ${this.cardNumber.slice(-4)}으로 ${amount}원 결제`);
    return { success: true, transactionId: `CC-${Date.now()}` };
  }

  getName() { return '신용카드'; }
}

class KakaoPay implements PaymentStrategy {
  constructor(private userId: string) {}

  validate(): boolean { return this.userId.length > 0; }

  async pay(amount: number) {
    console.log(`[카카오페이] ${this.userId} → ${amount}원 결제`);
    // 카카오페이 SDK 호출
    return { success: true, transactionId: `KAKAO-${Date.now()}` };
  }

  getName() { return '카카오페이'; }
}

class NaverPay implements PaymentStrategy {
  constructor(private accessToken: string) {}

  validate(): boolean { return this.accessToken.length > 0; }

  async pay(amount: number) {
    console.log(`[네이버페이] ${amount}원 결제`);
    return { success: true, transactionId: `NAVER-${Date.now()}` };
  }

  getName() { return '네이버페이'; }
}

// 결제 처리 컨텍스트
class CheckoutService {
  private strategy: PaymentStrategy | null = null;

  setPaymentMethod(strategy: PaymentStrategy): void {
    this.strategy = strategy;
  }

  async checkout(amount: number): Promise<void> {
    if (!this.strategy) throw new Error('결제 수단을 선택해주세요');
    if (!this.strategy.validate()) throw new Error('결제 정보가 유효하지 않습니다');

    console.log(`${this.strategy.getName()}으로 ${amount}원 결제 시작`);
    const result = await this.strategy.pay(amount);

    if (result.success) {
      console.log(`결제 성공! 거래번호: ${result.transactionId}`);
    }
  }
}

// 사용 — 사용자 선택에 따라 전략 교체
const checkout = new CheckoutService();

// 사용자가 카카오페이 선택
checkout.setPaymentMethod(new KakaoPay('user123'));
await checkout.checkout(50000);

// 사용자가 신용카드로 변경
checkout.setPaymentMethod(new CreditCardPayment('1234567890123456', '12/26', '123'));
await checkout.checkout(50000);
```

---

## 4. JS에서 함수를 전략으로 활용

JavaScript에서는 함수가 일급 객체이므로, 클래스 없이 함수 자체를 전략으로 사용할 수 있다.

```typescript
// 함수형 전략 패턴 — 클래스 불필요
type CompareFn<T> = (a: T, b: T) => number;

function sortWith<T>(data: T[], compareFn: CompareFn<T>): T[] {
  return [...data].sort(compareFn);
}

// 전략들 (순수 함수)
const byNameAsc: CompareFn<{ name: string }> = (a, b) =>
  a.name.localeCompare(b.name);

const byAgeDesc: CompareFn<{ age: number }> = (a, b) => b.age - a.age;

const byScore: CompareFn<{ score: number; name: string }> = (a, b) =>
  b.score - a.score || a.name.localeCompare(b.name);

const users = [
  { name: 'Charlie', age: 25, score: 85 },
  { name: 'Alice', age: 30, score: 92 },
  { name: 'Bob', age: 25, score: 88 },
];

console.log(sortWith(users, byNameAsc));    // Alice, Bob, Charlie
console.log(sortWith(users, byAgeDesc));    // Alice(30), Charlie(25), Bob(25)
console.log(sortWith(users, byScore));      // Alice(92), Bob(88), Charlie(85)
```

---

## 5. 유효성 검사 전략

```typescript
type ValidationResult = { valid: boolean; message?: string };
type Validator<T> = (value: T) => ValidationResult;

// 검증 전략들
const required: Validator<string> = (value) => ({
  valid: value.trim().length > 0,
  message: '필수 입력 항목입니다',
});

const minLength = (min: number): Validator<string> => (value) => ({
  valid: value.length >= min,
  message: `최소 ${min}자 이상 입력해주세요`,
});

const emailFormat: Validator<string> = (value) => ({
  valid: /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value),
  message: '올바른 이메일 형식이 아닙니다',
});

// 전략 조합 — 여러 유효성 검사를 체인으로
function validate<T>(value: T, ...validators: Validator<T>[]): ValidationResult {
  for (const validator of validators) {
    const result = validator(value);
    if (!result.valid) return result;
  }
  return { valid: true };
}

// 사용
console.log(validate('', required));
// { valid: false, message: '필수 입력 항목입니다' }

console.log(validate('hi', required, minLength(5)));
// { valid: false, message: '최소 5자 이상 입력해주세요' }

console.log(validate('alice@example.com', required, emailFormat));
// { valid: true }
```

---

## 6. 면접 포인트

**Q1. 전략 패턴이란 무엇인가요?**
> 알고리즘을 캡슐화하여 런타임에 교환 가능하게 만드는 패턴입니다. 클라이언트가 알고리즘 구현을 몰라도 인터페이스를 통해 사용할 수 있습니다.

**Q2. 전략 패턴과 상태 패턴의 차이는?**
> 전략은 클라이언트가 명시적으로 전략을 선택합니다. 상태는 상태 전환이 자동으로 일어나며, 상태 객체가 컨텍스트를 인식합니다.

**Q3. JavaScript에서 함수를 전략으로 사용하는 방법은?**
> JS에서 함수가 일급 객체이므로 함수 자체를 전략으로 전달할 수 있습니다. `Array.sort((a, b) => a - b)`의 비교 함수가 대표적인 예시입니다.

**Q4. 전략 패턴이 OCP(개방-폐쇄 원칙)를 어떻게 만족시키나요?**
> 새 전략(알고리즘) 추가 시 컨텍스트 코드를 수정하지 않고 새 클래스(또는 함수)만 추가합니다. 기존 코드 변경 없이 확장 가능합니다.

---

[← State](./07-state.md) | [← 행동 패턴 목차](./README.md) | [다음: Template Method →](./09-template-method.md)
