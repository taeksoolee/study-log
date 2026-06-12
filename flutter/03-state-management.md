# 3. Flutter 상태 관리: Provider, Riverpod, Bloc 비교

## 목차
1. 상태 관리의 필요성
2. setState의 한계
3. Provider
4. Riverpod
5. Bloc 패턴
6. 비교표
7. 선택 기준
8. React 상태 관리와의 비교
9. 면접 포인트

---

## 1. 상태 관리의 필요성

Flutter 앱에서 "상태(State)"란 UI에 영향을 주는 모든 데이터를 의미합니다.
예를 들어 로그인 여부, 장바구니 아이템 목록, 현재 선택된 탭 등이 있습니다.

### 상태의 종류

| 종류 | 설명 | 예시 |
|------|------|------|
| Local State | 단일 위젯 내부에서만 사용 | 텍스트 필드 입력값, 체크박스 |
| Shared State | 여러 위젯이 공유 | 로그인 정보, 장바구니 |
| Global State | 앱 전체에서 접근 | 테마 설정, 언어 설정 |

상태 관리가 필요한 이유:
- 위젯 트리 깊은 곳에서 데이터를 공유해야 할 때
- 비즈니스 로직과 UI 코드를 분리하고 싶을 때
- 테스트 용이성과 유지보수성을 높이고 싶을 때

---

## 2. setState의 한계

`setState`는 `StatefulWidget` 내에서 상태를 변경하는 가장 기본적인 방법입니다.

```dart
class CounterWidget extends StatefulWidget {
  const CounterWidget({super.key});

  @override
  State<CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  int _count = 0;

  void _increment() {
    setState(() {
      _count++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Count: $_count'),
        ElevatedButton(
          onPressed: _increment,
          child: const Text('+'),
        ),
      ],
    );
  }
}
```

### setState의 문제점

**1. Prop Drilling**
부모에서 자식으로 데이터를 계속 전달해야 합니다.

```dart
// 안티패턴: 깊은 위젯 트리에서의 prop drilling
class GrandParent extends StatefulWidget {
  // ...
}
// GrandParent -> Parent -> Child -> GrandChild 순으로 data 전달
// 중간 위젯들은 단순히 데이터를 전달만 하는 역할
```

**2. 불필요한 리빌드**
`setState`를 호출하면 해당 위젯과 모든 자식 위젯이 다시 빌드됩니다.

**3. 비즈니스 로직 분리 불가**
UI 코드와 비즈니스 로직이 같은 클래스에 섞이게 됩니다.

**4. 상태 공유 어려움**
형제 위젯 간 상태 공유를 위해 공통 부모로 상태를 끌어올려야(lift state up) 합니다.

---

## 3. Provider

Provider는 InheritedWidget을 래핑한 공식 권장 상태 관리 패키지입니다.
`ChangeNotifier`와 `Consumer`를 핵심으로 사용합니다.

### 설치

```yaml
# pubspec.yaml
dependencies:
  provider: ^6.1.1
```

### ChangeNotifier 모델 생성

```dart
import 'package:flutter/foundation.dart';

class CartModel extends ChangeNotifier {
  final List<String> _items = [];

  List<String> get items => List.unmodifiable(_items);
  int get itemCount => _items.length;

  void addItem(String item) {
    _items.add(item);
    notifyListeners(); // 리스너(Consumer)에게 변경 알림
  }

  void removeItem(String item) {
    _items.remove(item);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
```

### Provider 등록 (앱 최상단)

```dart
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartModel()),
        ChangeNotifierProvider(create: (_) => UserModel()),
      ],
      child: const MyApp(),
    ),
  );
}
```

### Consumer로 상태 소비

```dart
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('장바구니')),
      body: Consumer<CartModel>(
        builder: (context, cart, child) {
          // cart가 변경될 때만 이 builder가 재실행됨
          return Column(
            children: [
              Text('총 ${cart.itemCount}개'),
              Expanded(
                child: ListView.builder(
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    return ListTile(title: Text(cart.items[index]));
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // context.read: 읽기만, 리빌드 구독 안 함
          context.read<CartModel>().addItem('새 상품');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

### context.watch vs context.read vs context.select

```dart
// watch: 값 변경 시 위젯 리빌드 (build 메서드 내부)
final cart = context.watch<CartModel>();

// read: 한 번만 읽음, 리빌드 없음 (이벤트 핸들러 내부)
context.read<CartModel>().addItem('상품');

// select: 특정 값만 구독 (최적화)
final itemCount = context.select<CartModel, int>((cart) => cart.itemCount);
```

---

## 4. Riverpod

Riverpod은 Provider의 단점을 보완한 차세대 상태 관리 라이브러리입니다.
컴파일 타임 안전성, 전역 접근, 테스트 편의성이 강점입니다.

### 설치

```yaml
# pubspec.yaml
dependencies:
  flutter_riverpod: ^2.4.9
  riverpod_annotation: ^2.3.3

dev_dependencies:
  riverpod_generator: ^2.3.9
  build_runner: ^2.4.7
```

### 기본 Provider 정의

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 단순 값 Provider
final helloWorldProvider = Provider<String>((ref) {
  return 'Hello, Riverpod!';
});

// Future Provider (비동기)
final userProvider = FutureProvider<User>((ref) async {
  final response = await http.get(Uri.parse('https://api.example.com/user'));
  return User.fromJson(jsonDecode(response.body));
});
```

### StateNotifier로 복잡한 상태 관리

```dart
// 상태 클래스
class CartState {
  final List<String> items;
  final bool isLoading;

  const CartState({
    this.items = const [],
    this.isLoading = false,
  });

  CartState copyWith({List<String>? items, bool? isLoading}) {
    return CartState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// StateNotifier
class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  void addItem(String item) {
    state = state.copyWith(items: [...state.items, item]);
  }

  void removeItem(String item) {
    state = state.copyWith(
      items: state.items.where((i) => i != item).toList(),
    );
  }

  Future<void> loadFromServer() async {
    state = state.copyWith(isLoading: true);
    // API 호출
    await Future.delayed(const Duration(seconds: 1));
    state = state.copyWith(
      isLoading: false,
      items: ['서버 상품 1', '서버 상품 2'],
    );
  }
}

// Provider 등록
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
```

### ConsumerWidget으로 상태 소비

```dart
// ProviderScope는 앱 최상단에 한 번만 감싸면 됨
void main() {
  runApp(
    const ProviderScope(child: MyApp()),
  );
}

// ConsumerWidget 사용
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch: 상태 변경 시 리빌드
    final cartState = ref.watch(cartProvider);

    return Scaffold(
      body: cartState.isLoading
          ? const CircularProgressIndicator()
          : ListView.builder(
              itemCount: cartState.items.length,
              itemBuilder: (context, index) {
                return ListTile(title: Text(cartState.items[index]));
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // ref.read: 이벤트 핸들러에서 사용
          ref.read(cartProvider.notifier).addItem('새 상품');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

### Provider 간 의존성

```dart
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

// 다른 Provider를 참조할 수 있음
final userCartProvider = Provider<CartService>((ref) {
  final auth = ref.watch(authProvider);
  return CartService(userId: auth.userId);
});
```

---

## 5. Bloc 패턴

BLoC(Business Logic Component)은 이벤트 기반의 상태 관리 패턴입니다.
대규모 앱에서 예측 가능한 상태 흐름을 제공합니다.

### 설치

```yaml
# pubspec.yaml
dependencies:
  flutter_bloc: ^8.1.3
  bloc: ^8.1.2
```

### Bloc 핵심 구조

```
UI --[Event]--> Bloc --[State]--> UI
```

### Event, State, Bloc 정의

```dart
// 1. Event 정의 (사용자 액션)
abstract class CartEvent {}

class CartItemAdded extends CartEvent {
  final String item;
  CartItemAdded(this.item);
}

class CartItemRemoved extends CartEvent {
  final String item;
  CartItemRemoved(this.item);
}

class CartCleared extends CartEvent {}

// 2. State 정의 (UI에 표현될 상태)
abstract class CartState {}

class CartInitial extends CartState {}

class CartLoading extends CartState {}

class CartLoaded extends CartState {
  final List<String> items;
  CartLoaded(this.items);
}

class CartError extends CartState {
  final String message;
  CartError(this.message);
}

// 3. Bloc 정의 (비즈니스 로직)
class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(CartInitial()) {
    on<CartItemAdded>(_onItemAdded);
    on<CartItemRemoved>(_onItemRemoved);
    on<CartCleared>(_onCleared);
  }

  void _onItemAdded(CartItemAdded event, Emitter<CartState> emit) {
    final currentItems = state is CartLoaded
        ? (state as CartLoaded).items
        : <String>[];
    emit(CartLoaded([...currentItems, event.item]));
  }

  void _onItemRemoved(CartItemRemoved event, Emitter<CartState> emit) {
    if (state is CartLoaded) {
      final items = (state as CartLoaded).items
          .where((i) => i != event.item)
          .toList();
      emit(CartLoaded(items));
    }
  }

  Future<void> _onCleared(CartCleared event, Emitter<CartState> emit) async {
    emit(CartLoading());
    await Future.delayed(const Duration(milliseconds: 500));
    emit(CartLoaded([]));
  }
}
```

### BlocProvider와 BlocBuilder 사용

```dart
// BlocProvider로 Bloc 주입
void main() {
  runApp(
    BlocProvider(
      create: (context) => CartBloc(),
      child: const MyApp(),
    ),
  );
}

// BlocBuilder로 상태에 따라 UI 렌더링
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state is CartInitial) {
            return const Text('장바구니가 비어있습니다.');
          } else if (state is CartLoading) {
            return const CircularProgressIndicator();
          } else if (state is CartLoaded) {
            return ListView.builder(
              itemCount: state.items.length,
              itemBuilder: (context, index) {
                return ListTile(title: Text(state.items[index]));
              },
            );
          } else if (state is CartError) {
            return Text('오류: ${state.message}');
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Event 발행
          context.read<CartBloc>().add(CartItemAdded('새 상품'));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

### BlocListener (사이드 이펙트 처리)

```dart
BlocListener<CartBloc, CartState>(
  listener: (context, state) {
    if (state is CartError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message)),
      );
    }
  },
  child: BlocBuilder<CartBloc, CartState>(
    builder: (context, state) {
      // UI 렌더링
      return const SizedBox.shrink();
    },
  ),
)

// BlocConsumer: Listener + Builder 통합
BlocConsumer<CartBloc, CartState>(
  listener: (context, state) { /* 사이드 이펙트 */ },
  builder: (context, state) { /* UI */ return const SizedBox.shrink(); },
)
```

---

## 6. 비교표

| 항목 | Provider | Riverpod | Bloc |
|------|----------|----------|------|
| 학습 곡선 | 낮음 | 중간 | 높음 |
| 보일러플레이트 | 적음 | 중간 | 많음 |
| 테스트 용이성 | 중간 | 높음 | 매우 높음 |
| 컴파일 타임 안전성 | 낮음 | 높음 | 높음 |
| 성능 | 중간 | 높음 | 높음 |
| 공식 문서 | 좋음 | 좋음 | 매우 좋음 |
| 커뮤니티 규모 | 큼 | 성장 중 | 큼 |
| 적합한 앱 규모 | 소~중형 | 소~대형 | 중~대형 |
| 비동기 처리 | 중간 | 편리 (FutureProvider) | 별도 처리 필요 |
| 상태 불변성 | 선택적 | 권장 | 강제 |

---

## 7. 선택 기준

### Provider를 선택할 때
- 팀이 Flutter에 익숙하지 않을 때
- 빠른 프로토타이핑이 필요할 때
- 단순한 앱 구조일 때

### Riverpod을 선택할 때
- 컴파일 타임 안전성이 중요할 때
- Provider의 단점(컨텍스트 의존성)을 극복하고 싶을 때
- 다양한 Provider 조합이 필요할 때
- 테스트 작성을 쉽게 하고 싶을 때

### Bloc을 선택할 때
- 대규모 팀 프로젝트일 때
- 엄격한 아키텍처가 필요할 때
- 상태 변경 이력 추적이 중요할 때 (디버깅)
- 복잡한 이벤트 흐름을 명확히 표현해야 할 때

---

## 8. React 상태 관리와의 비교

| React | Flutter (Riverpod 기준) | 설명 |
|-------|------------------------|------|
| useState | StateProvider | 단순 값 상태 |
| useReducer | StateNotifierProvider | 복잡한 상태 + 로직 |
| useContext | Provider (context) | 전역 상태 공유 |
| Redux | Bloc | 엄격한 단방향 흐름 |
| Zustand | Riverpod | 간편한 전역 상태 |
| React Query | FutureProvider / AsyncNotifier | 비동기 서버 상태 |
| Recoil | Riverpod (atom 개념 유사) | 원자적 상태 |

**주요 차이점:**
- React는 Hooks 기반, Flutter는 위젯 트리 + ref 기반
- Flutter의 Riverpod은 빌드 컨텍스트 없이도 Provider에 접근 가능
- React의 상태는 기본적으로 불변(immutable), Flutter는 선택적
- Flutter Bloc의 Event/State 분리는 Redux의 Action/Reducer와 유사

---

## 9. 면접 포인트

**Q1. setState와 Provider의 차이점은 무엇인가요?**

setState는 단일 위젯 내부에서만 상태를 관리하며, 위젯과 모든 자식이 리빌드됩니다.
Provider는 InheritedWidget 기반으로 위젯 트리 어디서나 상태를 공유하고,
Consumer를 통해 필요한 위젯만 선택적으로 리빌드할 수 있습니다.

**Q2. Riverpod이 Provider보다 나은 점은?**

- BuildContext 없이 Provider 접근 가능 (전역 ref)
- 컴파일 타임에 존재하지 않는 Provider 참조 오류 감지
- Provider 오버라이드가 더 쉬워 테스트 용이
- FutureProvider, StreamProvider 등 비동기 지원이 강력
- Provider 간 의존성 관리가 명확

**Q3. Bloc에서 Event와 State를 분리하는 이유는?**

단방향 데이터 흐름(Unidirectional Data Flow)을 강제하여 예측 가능성을 높입니다.
이벤트 → Bloc → 상태 순서로만 흐르므로 디버깅이 쉽고,
각 상태 변화를 추적하거나 타임라인 디버깅이 가능합니다.
또한 Event와 State를 각각 독립적으로 테스트할 수 있습니다.

**Q4. notifyListeners()는 언제 호출해야 하나요?**

ChangeNotifier에서 상태가 변경된 후 반드시 호출해야 합니다.
Consumer(또는 context.watch)가 구독하고 있는 모든 위젯에 변경을 알립니다.
불필요하게 자주 호출하면 과도한 리빌드가 발생할 수 있습니다.

**Q5. BlocBuilder의 buildWhen 파라미터는 언제 사용하나요?**

특정 조건에서만 리빌드가 필요할 때 사용하여 성능을 최적화합니다.

```dart
BlocBuilder<CartBloc, CartState>(
  buildWhen: (previous, current) {
    // CartLoaded 상태일 때만 리빌드
    return current is CartLoaded;
  },
  builder: (context, state) {
    return const SizedBox.shrink();
  },
)
```

**Q6. 상태 관리 선택 시 고려 사항을 설명해주세요.**

팀의 학습 곡선, 앱의 복잡도, 테스트 전략, 유지보수 인원 등을 고려합니다.
소규모 빠른 개발: Provider, 중~대규모 안정적 구조: Riverpod 또는 Bloc.
중요한 것은 일관성 있게 하나의 패턴을 프로젝트 전체에 적용하는 것입니다.
