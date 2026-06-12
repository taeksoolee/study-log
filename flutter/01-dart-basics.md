# 1. Dart 기초

## 목차
1. [Dart vs JavaScript 비교](#1-dart-vs-javascript-비교)
2. [변수 선언](#2-변수-선언)
3. [Null Safety](#3-null-safety)
4. [기본 타입](#4-기본-타입)
5. [함수](#5-함수)
6. [클래스](#6-클래스)
7. [Mixins와 Extensions](#7-mixins와-extensions)
8. [비동기 처리](#8-비동기-처리)
9. [Stream 기초](#9-stream-기초)
10. [JS 개발자 주의사항](#10-js-개발자-주의사항)
11. [면접 포인트](#11-면접-포인트)

---

## 1. Dart vs JavaScript 비교

Dart는 Google이 개발한 정적 타입 언어로, JS 개발자에게 친숙한 문법을 갖추고 있으나 몇 가지 핵심 차이점이 있습니다.

| 항목 | JavaScript | Dart |
|------|-----------|------|
| 타입 시스템 | 동적 타입 (런타임) | 정적 타입 (컴파일 타임) |
| Null 처리 | `null`, `undefined` 모두 존재 | `null`만 존재, Null Safety 적용 |
| 클래스 | Prototype 기반 | 클래스 기반 (Java 유사) |
| 비동기 | Promise / async-await | Future / async-await |
| 스트림 | Observable (RxJS) | Stream (내장) |
| 컴파일 | JIT/AOT (V8) | AOT (네이티브) / JIT (개발) |
| 엔트리 포인트 | 없음 (브라우저 환경) | `main()` 함수 필수 |

```dart
// Dart 엔트리 포인트
void main() {
  print('Hello, Dart!');
}
```

```javascript
// JavaScript - 엔트리 포인트 없음
console.log('Hello, JavaScript!');
```

---

## 2. 변수 선언

Dart는 타입 추론을 지원하며 다양한 변수 선언 방식을 제공합니다.

```dart
void main() {
  // var: 타입 추론, 재할당 가능
  var name = 'Flutter';       // String으로 추론
  var age = 5;                // int로 추론
  name = 'Dart';              // 재할당 가능
  // name = 123;              // 오류: String 타입에 int 할당 불가

  // 타입 명시
  String language = 'Dart';
  int version = 3;
  double pi = 3.14159;

  // final: 런타임 상수, 한 번만 할당 가능
  final String platform = 'Flutter';
  final currentTime = DateTime.now(); // 런타임에 결정되는 값도 가능
  // platform = 'React Native';       // 오류: final 변수 재할당 불가

  // const: 컴파일 타임 상수
  const double gravity = 9.8;
  const String appName = 'MyApp';
  // const time = DateTime.now();     // 오류: 런타임 값은 const 불가

  print('$name, $language $version, $pi');
}
```

### final vs const 차이점

```dart
// final: 런타임에 값이 결정됨
final List<int> finalList = [1, 2, 3];
finalList.add(4);            // 가능: 리스트 내용 변경 가능
// finalList = [5, 6];       // 불가: 참조 자체 변경 불가

// const: 컴파일 타임에 값이 완전히 고정됨
const List<int> constList = [1, 2, 3];
// constList.add(4);         // 오류: const 리스트는 불변
```

---

## 3. Null Safety

Dart 2.12부터 도입된 Null Safety는 null 관련 런타임 오류를 컴파일 타임에 방지합니다.

```dart
// Non-nullable: 기본값, null 불가
String name = 'Dart';
// name = null;              // 컴파일 오류

// Nullable: ? 붙이면 null 허용
String? nullableName = null;
nullableName = 'Flutter';   // 가능

// late: 나중에 초기화, non-nullable이지만 선언 시 초기화 안 함
late String lateValue;
// print(lateValue);         // 초기화 전 접근 시 런타임 오류
lateValue = 'initialized';
print(lateValue);            // 정상 동작
```

### Null 관련 연산자

```dart
void main() {
  String? maybeNull = null;

  // ?? (null 병합 연산자): null이면 오른쪽 값 사용
  String result = maybeNull ?? 'default';
  print(result); // 'default'

  // ??= (null 할당 연산자): null일 때만 할당
  maybeNull ??= 'assigned';
  print(maybeNull); // 'assigned'

  // ?. (null 안전 호출 연산자): null이면 null 반환
  String? text = null;
  int? length = text?.length; // null (오류 없음)
  print(length); // null

  // ! (null 단언 연산자): null이 아님을 단언 (런타임 오류 가능)
  String? knownNotNull = 'Hello';
  String definitelyString = knownNotNull!; // null이면 런타임 오류
  print(definitelyString.length);          // 5
}
```

---

## 4. 기본 타입

```dart
void main() {
  // int: 정수
  int count = 10;
  int hex = 0xFF;

  // double: 부동소수점
  double price = 99.9;

  // num: int와 double의 상위 타입
  num value = 10;
  value = 10.5; // 가능

  // String: 문자열
  String greeting = 'Hello';
  String multiLine = '''
    여러 줄
    문자열
  ''';
  String interpolation = '${greeting}, Dart! Count: $count';

  // bool
  bool isFlutter = true;
  bool isDart = false;

  // List (JS의 Array)
  List<int> numbers = [1, 2, 3, 4, 5];
  List<String> fruits = ['apple', 'banana', 'cherry'];
  numbers.add(6);
  numbers.removeAt(0);
  print(numbers.length);

  // Map (JS의 Object/Map)
  Map<String, dynamic> person = {
    'name': 'Alice',
    'age': 30,
    'isAdmin': true,
  };
  person['email'] = 'alice@example.com';
  print(person['name']); // 'Alice'

  // Set: 중복 없는 컬렉션
  Set<String> uniqueTags = {'flutter', 'dart', 'mobile'};
  uniqueTags.add('flutter'); // 중복 추가 무시
  print(uniqueTags.length);  // 3
}
```

---

## 5. 함수

```dart
// 일반 함수
int add(int a, int b) {
  return a + b;
}

// 화살표 함수 (단일 표현식)
int multiply(int a, int b) => a * b;

// void 함수
void printMessage(String message) => print(message);

// Named Parameters: 이름 있는 매개변수 (중괄호 사용)
// 기본적으로 optional이며, required 키워드로 필수 지정 가능
void createUser({
  required String name,
  required int age,
  String role = 'user', // 기본값 지정
}) {
  print('$name ($age) - $role');
}

// Optional Positional Parameters: 선택적 위치 매개변수 (대괄호 사용)
String greet(String name, [String? title]) {
  if (title != null) {
    return 'Hello, $title $name!';
  }
  return 'Hello, $name!';
}

// 고차 함수
List<int> filterPositive(List<int> numbers) {
  return numbers.where((n) => n > 0).toList();
}

void main() {
  print(add(3, 4));       // 7
  print(multiply(3, 4));  // 12

  // Named parameters 호출 - 순서 무관
  createUser(name: 'Bob', age: 25);
  createUser(age: 30, name: 'Alice', role: 'admin');

  // Optional positional 호출
  print(greet('World'));         // Hello, World!
  print(greet('Alice', 'Dr.')); // Hello, Dr. Alice!

  // 익명 함수 / 람다
  var square = (int x) => x * x;
  print(square(5)); // 25

  // 함수를 변수처럼 전달
  List<int> nums = [-2, -1, 0, 1, 2, 3];
  print(filterPositive(nums)); // [1, 2, 3]

  // 컬렉션 메서드
  var doubled = nums.map((n) => n * 2).toList();
  var positives = nums.where((n) => n > 0).toList();
  var sum = nums.reduce((a, b) => a + b);
  print(doubled);   // [-4, -2, 0, 2, 4, 6]
  print(positives); // [1, 2, 3]
  print(sum);       // 3
}
```

---

## 6. 클래스

```dart
// 기본 클래스
class Animal {
  // 인스턴스 변수
  String name;
  int age;

  // 기본 생성자
  Animal(this.name, this.age);

  // Named constructor: 다양한 생성 방식 제공
  Animal.unnamed() : name = 'Unknown', age = 0;
  Animal.fromMap(Map<String, dynamic> map)
      : name = map['name'] as String,
        age = map['age'] as int;

  // 메서드
  void speak() {
    print('$name says something');
  }

  // getter
  String get info => '$name ($age years old)';

  // setter
  set newAge(int value) {
    if (value >= 0) age = value;
  }

  @override
  String toString() => 'Animal(name: $name, age: $age)';
}

// 상속
class Dog extends Animal {
  String breed;

  Dog(String name, int age, this.breed) : super(name, age);

  @override
  void speak() {
    print('$name says: Woof!');
  }
}

// Factory constructor: 인스턴스 생성 로직을 커스터마이징
class Singleton {
  static final Singleton _instance = Singleton._internal();

  factory Singleton() {
    return _instance;
  }

  Singleton._internal();
}

// 추상 클래스
abstract class Shape {
  double area();         // 추상 메서드
  void describe() {
    print('This shape has area: ${area()}');
  }
}

class Circle extends Shape {
  double radius;
  Circle(this.radius);

  @override
  double area() => 3.14159 * radius * radius;
}

void main() {
  var dog = Dog('Rex', 3, 'Labrador');
  dog.speak();             // Rex says: Woof!
  print(dog.info);         // Rex (3 years old)

  var unnamed = Animal.unnamed();
  print(unnamed);          // Animal(name: Unknown, age: 0)

  var fromMap = Animal.fromMap({'name': 'Buddy', 'age': 2});
  print(fromMap);          // Animal(name: Buddy, age: 2)

  var circle = Circle(5.0);
  circle.describe();       // This shape has area: 78.53975

  // Singleton 패턴
  var s1 = Singleton();
  var s2 = Singleton();
  print(identical(s1, s2)); // true
}
```

---

## 7. Mixins와 Extensions

```dart
// Mixin: 다중 상속 없이 기능 재사용
mixin Flyable {
  void fly() => print('$runtimeType is flying!');
  double get maxAltitude => 1000.0;
}

mixin Swimmable {
  void swim() => print('$runtimeType is swimming!');
}

class Bird extends Animal with Flyable {
  Bird(String name) : super(name, 0);
}

class Duck extends Animal with Flyable, Swimmable {
  Duck(String name) : super(name, 0);
}

// Extension: 기존 타입에 메서드 추가 (소스 수정 없이)
extension StringExtension on String {
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  bool get isEmail => contains('@') && contains('.');

  String repeat(int times) => this * times;
}

extension ListExtension<T> on List<T> {
  T? get secondOrNull => length >= 2 ? this[1] : null;
}

void main() {
  var duck = Duck('Donald');
  duck.fly();   // Duck is flying!
  duck.swim();  // Duck is swimming!

  // Extension 사용
  print('hello'.capitalize);   // Hello
  print('test@email.com'.isEmail); // true
  print('ha'.repeat(3));       // hahaha

  List<int> nums = [1, 2, 3];
  print(nums.secondOrNull);    // 2
  List<int> single = [1];
  print(single.secondOrNull);  // null
}
```

---

## 8. 비동기 처리

```dart
import 'dart:async';

// Future: 비동기 작업의 결과 (JS의 Promise)
Future<String> fetchData() async {
  // 네트워크 요청 시뮬레이션
  await Future.delayed(Duration(seconds: 2));
  return 'Fetched Data';
}

Future<int> divide(int a, int b) async {
  if (b == 0) throw ArgumentError('Cannot divide by zero');
  return a ~/ b;
}

// async/await 사용
Future<void> processData() async {
  try {
    String data = await fetchData();
    print('Result: $data');

    int result = await divide(10, 2);
    print('Division: $result');

    await divide(10, 0); // 예외 발생
  } catch (e) {
    print('Error: $e');
  } finally {
    print('Cleanup done');
  }
}

// then/catchError 체이닝 (Promise 체인과 유사)
void processWithChain() {
  fetchData()
      .then((data) {
        print('Got: $data');
        return divide(10, 2);
      })
      .then((result) => print('Divided: $result'))
      .catchError((error) => print('Chain error: $error'))
      .whenComplete(() => print('Chain complete'));
}

// Future.wait: 여러 Future 병렬 실행 (JS의 Promise.all)
Future<void> parallelFetch() async {
  final results = await Future.wait([
    fetchData(),
    Future.delayed(Duration(seconds: 1), () => 'Quick data'),
    Future.value('Immediate data'),
  ]);
  print(results); // ['Fetched Data', 'Quick data', 'Immediate data']
}

void main() async {
  await processData();
  processWithChain();
  await parallelFetch();
}
```

---

## 9. Stream 기초

```dart
import 'dart:async';

// Stream: 비동기 데이터 시퀀스 (RxJS Observable과 유사)
Stream<int> countStream(int max) async* {
  for (int i = 0; i <= max; i++) {
    await Future.delayed(Duration(milliseconds: 500));
    yield i; // 값을 하나씩 방출
  }
}

// StreamController: 수동으로 Stream 제어
void streamControllerExample() {
  final controller = StreamController<String>();

  // 구독
  controller.stream.listen(
    (data) => print('Received: $data'),
    onError: (error) => print('Error: $error'),
    onDone: () => print('Stream closed'),
  );

  // 데이터 추가
  controller.add('First');
  controller.add('Second');
  controller.addError('Something went wrong');
  controller.add('Third');
  controller.close();
}

// await for: Stream을 동기처럼 처리
Future<void> consumeStream() async {
  await for (int value in countStream(5)) {
    print('Count: $value');
  }
  print('Stream completed');
}

// Broadcast Stream: 여러 리스너 허용
void broadcastExample() {
  final controller = StreamController<int>.broadcast();

  controller.stream.listen((v) => print('Listener 1: $v'));
  controller.stream.listen((v) => print('Listener 2: $v'));

  controller.add(1);
  controller.add(2);
  controller.close();
}
```

---

## 10. JS 개발자 주의사항

1. **타입 강제**: `var`로 선언해도 타입이 고정됩니다. JS처럼 `var x = 1; x = 'string';`은 불가합니다.

2. **`==` vs `identical()`**: Dart의 `==`는 값 비교(JS의 `===` 유사), `identical()`은 참조 비교입니다.
   ```dart
   String a = 'hello';
   String b = 'hello';
   print(a == b);          // true (값 비교)
   print(identical(a, b)); // true (리터럴 풀링으로 같은 참조)
   ```

3. **`dynamic` 타입 주의**: `dynamic`은 JS처럼 타입 체크를 우회하므로 최소화해야 합니다.

4. **`int` 나눗셈**: Dart에서 `10 / 3`은 `double`을 반환합니다. 정수 나눗셈은 `~/` 사용합니다.
   ```dart
   print(10 / 3);   // 3.3333...
   print(10 ~/ 3);  // 3
   ```

5. **`for-in` vs JS `for...of`**: 문법은 유사하지만 Dart는 타입 안전합니다.

6. **`??` vs JS `||`**: Dart의 `??`는 null만 체크, JS의 `||`는 falsy 값 모두 체크합니다.
   ```dart
   int? value = 0;
   print(value ?? 10);  // 0 (null이 아니므로 원래 값)
   // JS: value || 10 → 10 (0은 falsy)
   ```

---

## 11. 면접 포인트

**Q1. `final`과 `const`의 차이점은?**
- `final`: 런타임에 한 번 할당, 객체 내용 변경 가능 (컬렉션 등)
- `const`: 컴파일 타임 상수, 객체 전체가 완전히 불변, 동일 값이면 같은 인스턴스 공유

**Q2. Null Safety에서 `late` 키워드는 언제 사용하나요?**
- 선언 시 초기화가 불가능하지만 사용 전 반드시 초기화되는 non-nullable 변수에 사용합니다.
- `late`는 초기화 지연을 약속하는 것으로, 접근 전 초기화하지 않으면 LateInitializationError가 발생합니다.
- Flutter에서는 `initState()`에서 초기화하는 컨트롤러 등에 주로 사용됩니다.

**Q3. Factory constructor의 용도는?**
- 싱글톤 패턴 구현
- 캐싱된 인스턴스 반환
- 서브타입 인스턴스 반환
- 복잡한 초기화 로직 처리 (예: `fromJson`)

**Q4. Mixin과 상속의 차이점은?**
- 상속(`extends`)은 단일 상속만 가능하고 is-a 관계를 표현합니다.
- Mixin(`with`)은 다중 적용이 가능하며 has-a 관계로 기능을 조합합니다. 상태와 메서드를 모두 포함할 수 있습니다.

**Q5. Future와 Stream의 차이점은?**
- `Future`: 단일 비동기 값 (0개 또는 1개의 결과)
- `Stream`: 여러 비동기 값의 시퀀스, 시간이 지남에 따라 여러 이벤트 방출
- Flutter에서 Stream은 실시간 데이터 (WebSocket, 센서, 상태 변화 등)에 적합합니다.

**Q6. Dart의 `dynamic`과 `Object?`의 차이는?**
- `dynamic`: 타입 체크를 런타임으로 미룸, 컴파일 타임 안전성 없음
- `Object?`: null 포함 모든 타입의 최상위 타입, 메서드 호출 시 컴파일 타임 체크 적용
- 타입 안전성을 유지하려면 `Object?` + 타입 캐스팅이 `dynamic`보다 권장됩니다.
