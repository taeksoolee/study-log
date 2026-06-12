# 2. Widget 시스템

## 목차
1. [Flutter Widget 개념](#1-flutter-widget-개념)
2. [StatelessWidget](#2-statelesswidget)
3. [StatefulWidget과 State](#3-statefulwidget과-state)
4. [Widget 생명주기](#4-widget-생명주기)
5. [BuildContext](#5-buildcontext)
6. [3개의 트리 구조](#6-3개의-트리-구조)
7. [자주 사용하는 기본 위젯](#7-자주-사용하는-기본-위젯)
8. [InheritedWidget](#8-inheritedwidget)
9. [면접 포인트](#9-면접-포인트)

---

## 1. Flutter Widget 개념

Flutter에서 **"Everything is a Widget"** 이라는 철학은 UI의 모든 요소가 위젯으로 표현됨을 의미합니다. 버튼, 텍스트, 레이아웃, 패딩, 애니메이션, 테마까지 전부 위젯입니다.

위젯은 **불변(immutable)** 합니다. 화면을 업데이트할 때 기존 위젯을 수정하는 것이 아니라 새로운 위젯 인스턴스를 만들어 교체합니다. Flutter는 이 과정을 매우 효율적으로 처리합니다.

```
Widget (설계도, 불변)
  ↓ Flutter 프레임워크
Element (위젯과 RenderObject를 연결, 상태 유지)
  ↓
RenderObject (실제 레이아웃 계산 및 그리기)
```

---

## 2. StatelessWidget

상태가 없는 위젯으로, 주어진 데이터(props)만으로 UI를 렌더링합니다. 외부에서 전달받은 값이 변하지 않는 한 다시 그리지 않습니다.

```dart
import 'package:flutter/material.dart';

// 기본 StatelessWidget 구조
class WelcomeCard extends StatelessWidget {
  // 생성자 파라미터로 데이터 전달 (immutable이므로 final 필수)
  final String username;
  final String avatarUrl;
  final VoidCallback? onTap;

  const WelcomeCard({
    super.key,              // Key는 Widget 식별에 사용
    required this.username,
    required this.avatarUrl,
    this.onTap,
  });

  // build 메서드: 위젯 트리를 반환, BuildContext를 통해 트리 접근
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(backgroundImage: NetworkImage(avatarUrl)),
              const SizedBox(width: 12),
              Text(
                'Welcome, $username!',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 사용 예시
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: WelcomeCard(
        username: 'Alice',
        avatarUrl: 'https://example.com/avatar.png',
        onTap: () => print('Card tapped'),
      ),
    );
  }
}
```

**StatelessWidget 사용 시점:**
- 데이터가 외부(부모 위젯)에서만 전달되는 경우
- 시간이 지나도 변하지 않는 UI
- 아이콘, 텍스트, 정적 레이아웃 등

---

## 3. StatefulWidget과 State

StatefulWidget은 내부 상태를 가지며, 상태가 변하면 `build()`를 다시 호출하여 UI를 갱신합니다.

```dart
import 'package:flutter/material.dart';

// StatefulWidget은 두 클래스로 구성됨
class CounterWidget extends StatefulWidget {
  final String title;

  const CounterWidget({
    super.key,
    this.title = 'Counter',
  });

  // createState: State 객체를 생성하는 팩토리 메서드
  @override
  State<CounterWidget> createState() => _CounterWidgetState();
}

// State 클래스: 실제 상태와 로직을 담당
// _로 시작하는 private 클래스 (외부에서 직접 접근 불가)
class _CounterWidgetState extends State<CounterWidget> {
  int _count = 0;           // 상태 변수
  bool _isLoading = false;

  // setState: 상태 변경 + UI 갱신 트리거
  void _increment() {
    setState(() {
      _count++;
    });
  }

  void _decrement() {
    setState(() {
      if (_count > 0) _count--;
    });
  }

  Future<void> _reset() async {
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 500));

    // setState는 동기 콜백만 받음
    // async 작업 완료 후 setState 호출
    setState(() {
      _count = 0;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // widget.xxx로 StatefulWidget의 속성에 접근
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          widget.title,  // StatefulWidget의 title에 접근
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        if (_isLoading)
          const CircularProgressIndicator()
        else
          Text(
            '$_count',
            style: const TextStyle(fontSize: 48),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: _decrement,
              icon: const Icon(Icons.remove),
            ),
            IconButton(
              onPressed: _increment,
              icon: const Icon(Icons.add),
            ),
            TextButton(
              onPressed: _reset,
              child: const Text('Reset'),
            ),
          ],
        ),
      ],
    );
  }
}
```

### setState() 주의사항

```dart
// 잘못된 사용: setState 밖에서 상태 변경
void badExample() {
  _count++; // UI가 갱신되지 않음
}

// 올바른 사용
void goodExample() {
  setState(() {
    _count++;
  });
}

// setState는 동기적으로 실행됨
// 비동기 작업은 완료 후 setState 내에서 변수를 변경
Future<void> asyncExample() async {
  final data = await fetchSomeData();
  if (mounted) {   // 위젯이 여전히 트리에 있는지 확인
    setState(() {
      _data = data;
    });
  }
}
```

---

## 4. Widget 생명주기

StatefulWidget의 State 클래스는 명확한 생명주기를 가집니다.

```dart
class _LifecycleDemoState extends State<LifecycleDemo> {
  late ScrollController _scrollController;

  // 1. initState: State 객체가 처음 생성될 때 한 번 호출
  // - 컨트롤러 초기화, 리스너 등록, 초기 데이터 로드 등에 사용
  // - super.initState() 반드시 호출 필요
  // - BuildContext 접근 제한 (트리에 완전히 삽입 전)
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _loadInitialData();
    print('initState called');
  }

  // 2. didChangeDependencies: initState 직후, 그리고 의존하는 InheritedWidget이
  //    변경될 때마다 호출
  // - BuildContext로 Theme, MediaQuery 등에 안전하게 접근 가능
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final theme = Theme.of(context); // 여기서 context 접근 안전
    print('didChangeDependencies called');
  }

  // 3. build: UI 렌더링. 상태 변경 시마다 호출됨
  // - 순수 함수처럼 동작해야 함 (부수 효과 없이 위젯 트리만 반환)
  @override
  Widget build(BuildContext context) {
    print('build called');
    return Container();
  }

  // 4. didUpdateWidget: 부모 위젯이 재빌드되어 이 위젯에 새로운 설정이
  //    전달될 때 호출 (StatefulWidget의 파라미터가 변경된 경우)
  @override
  void didUpdateWidget(LifecycleDemo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.someParam != widget.someParam) {
      // 파라미터 변경에 반응
      print('Widget updated: ${oldWidget.someParam} -> ${widget.someParam}');
    }
  }

  // 5. deactivate: 위젯 트리에서 일시적으로 제거될 때 호출
  //    (Navigator로 다른 화면으로 이동 시 등)
  @override
  void deactivate() {
    super.deactivate();
    print('deactivate called');
  }

  // 6. dispose: State 객체가 영구적으로 제거될 때 호출
  // - 리소스 해제 필수: 컨트롤러, 스트림 구독, 타이머 등
  // - super.dispose()는 마지막에 호출
  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    print('dispose called');
    super.dispose();
  }

  void _onScroll() {}
  Future<void> _loadInitialData() async {}
}
```

**생명주기 순서:**
```
생성: initState → didChangeDependencies → build
갱신: (setState/부모 변경) → build → didUpdateWidget → build
소멸: deactivate → dispose
```

---

## 5. BuildContext

`BuildContext`는 위젯 트리에서 위젯의 위치 정보를 담고 있는 객체입니다. 위젯 트리를 탐색하여 상위 데이터에 접근하거나 Navigator, Scaffold 등의 기능을 사용할 때 필요합니다.

```dart
class ContextExampleWidget extends StatelessWidget {
  const ContextExampleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Theme 접근
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyMedium;

    // 2. MediaQuery: 화면 크기, 방향, 패딩 등
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    // 3. Navigator: 화면 이동
    // context.findAncestorWidgetOfExactType<Navigator>()와 동일
    void goToDetail() {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const DetailScreen()),
      );
    }

    // 4. Scaffold: SnackBar, BottomSheet 등
    void showSnack() {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hello!')),
      );
    }

    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Text(
              isTablet ? 'Tablet Layout' : 'Phone Layout',
              style: textStyle,
            ),
            ElevatedButton(
              onPressed: goToDetail,
              child: const Text('Go to Detail'),
            ),
            ElevatedButton(
              onPressed: showSnack,
              child: const Text('Show SnackBar'),
            ),
          ],
        ),
      ),
    );
  }
}

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(child: Text('Detail')),
  );
}
```

**BuildContext 주의사항:**
```dart
// 잘못된 예: async 간격 후 context 사용 (위젯이 dispose되었을 수 있음)
Future<void> badAsyncContext(BuildContext context) async {
  await Future.delayed(const Duration(seconds: 2));
  // 위젯이 이미 dispose 되었을 수 있음
  Navigator.of(context).pop(); // 경고 발생 가능
}

// 올바른 예: mounted 체크
Future<void> goodAsyncContext(BuildContext context) async {
  await Future.delayed(const Duration(seconds: 2));
  if (!context.mounted) return; // Flutter 3.7+
  Navigator.of(context).pop();
}
```

---

## 6. 3개의 트리 구조

Flutter는 3개의 트리를 통해 UI를 관리합니다.

```
Widget Tree          Element Tree         RenderObject Tree
─────────────────    ─────────────────    ─────────────────
MaterialApp          ComponentElement     (없음 - 렌더링 없음)
  └─ Scaffold        ComponentElement     (없음)
       ├─ AppBar     ComponentElement     RenderBox
       │    └─ Text  LeafRenderObject     RenderParagraph
       └─ Column     MultiChildRO         RenderFlex
            ├─ Text  LeafRenderObject     RenderParagraph
            └─ Btn   ComponentElement     RenderBox
```

**각 트리의 역할:**

| 트리 | 역할 | 특징 |
|------|------|------|
| Widget Tree | UI 설계도, 구성 선언 | 불변(immutable), 매 프레임 재생성 가능 |
| Element Tree | Widget과 RenderObject 연결, 상태 보존 | 가변(mutable), 위젯 교체 시 재사용 가능 |
| RenderObject Tree | 실제 레이아웃 계산 및 화면 그리기 | 비용이 큰 작업, 필요 시에만 갱신 |

```dart
// Flutter가 위젯 업데이트 효율화하는 방식
// Element는 같은 타입의 위젯으로 교체될 때 재사용됨

// 상태: _count = 1
// build() 반환:
Column(children: [
  Text('Count: 1'),  // 기존 Text Element 재사용, 내용만 업데이트
  ElevatedButton(...), // 기존 Button Element 재사용
])

// _count = 2 후 setState → build() 재호출:
Column(children: [
  Text('Count: 2'),  // Text 타입 동일 → Element 재사용, RenderParagraph만 업데이트
  ElevatedButton(...), // 변경 없음 → RenderObject 업데이트 없음
])
```

---

## 7. 자주 사용하는 기본 위젯

```dart
import 'package:flutter/material.dart';

class BasicWidgetsDemo extends StatelessWidget {
  const BasicWidgetsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // Container: 박스 모델 (margin, padding, color, border, shadow)
            Container(
              width: double.infinity,
              height: 100,
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: const Text('Container'),
            ),

            // Row: 가로 배치
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.amber),
                const Text('Row Layout'),
                ElevatedButton(onPressed: () {}, child: const Text('OK')),
              ],
            ),

            // Column: 세로 배치 (위에서 계속 사용 중)

            // Stack: 겹쳐 쌓기
            SizedBox(
              height: 150,
              child: Stack(
                children: [
                  Container(color: Colors.blue, width: double.infinity),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: FloatingActionButton(
                      mini: true,
                      onPressed: () {},
                      child: const Icon(Icons.add),
                    ),
                  ),
                  const Center(child: Text('Stack', style: TextStyle(color: Colors.white))),
                ],
              ),
            ),

            // ListView: 스크롤 목록
            SizedBox(
              height: 200,
              child: ListView.separated(
                itemCount: 10,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) => ListTile(
                  leading: CircleAvatar(child: Text('$index')),
                  title: Text('Item $index'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ),
            ),

            // GridView: 격자 목록
            SizedBox(
              height: 200,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 9,
                itemBuilder: (context, index) => Container(
                  color: Colors.primaries[index % Colors.primaries.length],
                  child: Center(
                    child: Text('$index', style: const TextStyle(color: Colors.white)),
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
```

**주요 레이아웃 위젯 비교:**

| 위젯 | 용도 | 주요 속성 |
|------|------|----------|
| `Container` | 단일 자식, 박스 스타일링 | `margin`, `padding`, `decoration`, `width`, `height` |
| `Row` | 가로 배치 | `mainAxisAlignment`, `crossAxisAlignment`, `children` |
| `Column` | 세로 배치 | `mainAxisAlignment`, `crossAxisAlignment`, `children` |
| `Stack` | 겹쳐 쌓기 | `alignment`, `children`, `Positioned` |
| `ListView` | 세로 스크롤 목록 | `itemBuilder`, `itemCount`, `scrollDirection` |
| `GridView` | 격자형 목록 | `gridDelegate`, `itemBuilder` |
| `Expanded` | 남은 공간 채우기 | `flex` |
| `Flexible` | 유연한 크기 | `flex`, `fit` |
| `SizedBox` | 고정 크기 또는 간격 | `width`, `height` |
| `Padding` | 패딩만 추가 | `padding` |

---

## 8. InheritedWidget

`InheritedWidget`은 위젯 트리 하위 모든 자손에게 데이터를 효율적으로 전달하는 메커니즘입니다. `Theme`, `MediaQuery`, `Provider` 패키지의 기반이 되는 개념입니다.

```dart
// InheritedWidget 직접 구현 예시
class AppConfig extends InheritedWidget {
  final String apiBaseUrl;
  final String appVersion;
  final bool isDarkMode;

  const AppConfig({
    super.key,
    required this.apiBaseUrl,
    required this.appVersion,
    required this.isDarkMode,
    required super.child,
  });

  // 트리 어디서든 접근하기 위한 정적 메서드
  static AppConfig of(BuildContext context) {
    final config = context.dependOnInheritedWidgetOfExactType<AppConfig>();
    assert(config != null, 'AppConfig not found in widget tree');
    return config!;
  }

  // null-safe 접근 (없을 수도 있는 경우)
  static AppConfig? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppConfig>();
  }

  // updateShouldNotify: 데이터 변경 시 하위 위젯 재빌드 여부 결정
  @override
  bool updateShouldNotify(AppConfig oldWidget) {
    return apiBaseUrl != oldWidget.apiBaseUrl ||
        appVersion != oldWidget.appVersion ||
        isDarkMode != oldWidget.isDarkMode;
  }
}

// 사용 예시
class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return AppConfig(
      apiBaseUrl: 'https://api.example.com',
      appVersion: '1.0.0',
      isDarkMode: false,
      child: MaterialApp(
        home: const SomeDeepChild(),
      ),
    );
  }
}

class SomeDeepChild extends StatelessWidget {
  const SomeDeepChild({super.key});

  @override
  Widget build(BuildContext context) {
    // 트리 깊숙한 곳에서도 바로 접근 가능
    final config = AppConfig.of(context);
    return Text('Version: ${config.appVersion}');
  }
}
```

**InheritedWidget vs Provider:**
- `InheritedWidget`은 Flutter 내장 저수준 API
- `Provider` 패키지는 `InheritedWidget` 위에 더 편리한 API를 제공하는 래퍼
- 실무에서는 직접 `InheritedWidget`보다 `Provider`, `Riverpod` 등을 사용하는 것이 일반적

---

## 9. 면접 포인트

**Q1. StatelessWidget과 StatefulWidget의 차이점은?**
- `StatelessWidget`: 상태 없음, 외부 데이터만으로 UI 결정, `build()`가 항상 동일한 결과 반환
- `StatefulWidget`: 내부 상태(`State` 객체) 보유, `setState()` 호출로 `build()` 재실행
- 상태가 필요하지 않다면 `StatelessWidget`을 우선 사용해야 성능상 유리합니다.

**Q2. setState()의 동작 원리는?**
- `setState()`는 콜백 내 상태 변수를 변경하고, 해당 위젯을 "dirty"로 표시합니다.
- Flutter 프레임워크는 다음 프레임에서 dirty 위젯들의 `build()`를 다시 호출합니다.
- `setState()` 자체는 즉시 re-build를 일으키지 않으며, 현재 프레임이 끝난 후 일괄 처리됩니다.

**Q3. Widget, Element, RenderObject 트리의 관계를 설명하세요.**
- `Widget`: 불변 설계도, 매 빌드마다 새로 생성될 수 있음
- `Element`: Widget과 RenderObject 사이 중간 레이어, 상태와 수명을 관리, Widget 교체 시 재사용 가능
- `RenderObject`: 실제 크기/위치 계산과 화면 그리기 담당, 가장 비용이 큰 작업
- Flutter 최적화의 핵심은 Widget이 자주 재생성되어도 Element와 RenderObject를 재사용하는 것입니다.

**Q4. BuildContext란 무엇인가요?**
- 위젯이 위젯 트리 내에서 자신의 위치를 나타내는 핸들입니다.
- 실제 구현은 `Element` 클래스이며, `BuildContext`는 인터페이스입니다.
- `Theme.of(context)`, `Navigator.of(context)` 등은 context가 트리를 거슬러 올라가며 해당 위젯을 찾습니다.

**Q5. dispose()에서 반드시 해제해야 하는 것들은?**
- `AnimationController`, `TextEditingController`, `ScrollController` 등 Controller 류
- `StreamSubscription`
- `Timer`
- `FocusNode`
- 해제하지 않으면 메모리 누수 및 `setState called after dispose` 오류가 발생합니다.

**Q6. Key의 역할은 무엇인가요?**
- Flutter가 위젯 트리에서 Element를 재사용할지 새로 생성할지 결정할 때 사용합니다.
- 같은 위치에 같은 타입의 위젯이 있으면 Key가 없어도 Element를 재사용합니다.
- 리스트에서 항목 순서가 바뀌거나, 같은 타입 위젯이 위치를 바꿀 때는 Key가 필수입니다.
- `ValueKey`, `ObjectKey`, `UniqueKey`, `GlobalKey` 등이 있으며 `GlobalKey`는 트리 어디서나 접근 가능하지만 남용은 피해야 합니다.

**Q7. initState에서 context를 사용하면 안 되는 이유는?**
- `initState()`는 위젯이 트리에 완전히 삽입되기 전에 호출됩니다.
- 이 시점에는 `InheritedWidget` 의존성이 아직 설정되지 않아 `Theme.of(context)` 등이 정상 동작하지 않습니다.
- context에 의존하는 초기화가 필요하다면 `didChangeDependencies()`를 사용해야 합니다.
