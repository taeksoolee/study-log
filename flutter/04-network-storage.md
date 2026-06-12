# 4. Flutter 네트워크 & 스토리지: http/dio, SharedPreferences, SQLite

## 목차
1. http 패키지 기본 사용법
2. Dio 패키지 심화
3. JSON 파싱 전략
4. SharedPreferences
5. SQLite (sqflite)
6. Secure Storage
7. 스토리지 비교표
8. REST API 응답 모델 패턴
9. 면접 포인트

---

## 1. http 패키지 기본 사용법

Flutter 공식 팀이 제공하는 기본 HTTP 클라이언트입니다.
단순한 API 요청에 적합하며, Dart의 `Future`와 자연스럽게 통합됩니다.

### 설치

```yaml
# pubspec.yaml
dependencies:
  http: ^1.2.0
```

### GET 요청

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<List<Post>> fetchPosts() async {
  final response = await http.get(
    Uri.parse('https://jsonplaceholder.typicode.com/posts'),
    headers: {
      'Authorization': 'Bearer token123',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Post.fromJson(json)).toList();
  } else {
    throw Exception('데이터 로드 실패: ${response.statusCode}');
  }
}
```

### POST 요청

```dart
Future<Post> createPost(String title, String body) async {
  final response = await http.post(
    Uri.parse('https://jsonplaceholder.typicode.com/posts'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'title': title,
      'body': body,
      'userId': 1,
    }),
  );

  if (response.statusCode == 201) {
    return Post.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('생성 실패: ${response.statusCode}');
  }
}
```

### http 패키지의 한계
- 인터셉터(요청/응답 가로채기) 기능 없음
- 요청 취소 기능 없음
- FormData/파일 업로드 처리가 복잡
- 재시도 로직 직접 구현 필요

---

## 2. Dio 패키지 심화

Dio는 강력한 HTTP 클라이언트로 인터셉터, 취소, FormData 등 고급 기능을 제공합니다.

### 설치

```yaml
# pubspec.yaml
dependencies:
  dio: ^5.4.0
```

### 기본 Dio 클라이언트 설정

```dart
import 'package:dio/dio.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  late final Dio _dio;

  void init() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.example.com',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      AuthInterceptor(),
      LogInterceptor(requestBody: true, responseBody: true),
    ]);
  }

  Dio get dio => _dio;
}
```

### 인터셉터 구현

```dart
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 요청 전: 토큰 주입
    final token = await SecureStorageService.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options); // 요청 계속 진행
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // 응답 수신 후 처리
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // 401 Unauthorized: 토큰 갱신 후 재시도
    if (err.response?.statusCode == 401) {
      try {
        await _refreshToken();
        final retryResponse = await _retry(err.requestOptions);
        handler.resolve(retryResponse);
      } catch (e) {
        handler.reject(err);
      }
    } else {
      handler.next(err);
    }
  }

  Future<void> _refreshToken() async {
    // 토큰 갱신 로직
  }

  Future<Response> _retry(RequestOptions requestOptions) async {
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
    );
    return ApiClient().dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }
}
```

### 요청 취소 (CancelToken)

```dart
class SearchService {
  CancelToken? _cancelToken;

  Future<List<SearchResult>> search(String query) async {
    // 이전 요청 취소
    _cancelToken?.cancel('새 검색 요청으로 취소');
    _cancelToken = CancelToken();

    try {
      final response = await ApiClient().dio.get(
        '/search',
        queryParameters: {'q': query},
        cancelToken: _cancelToken,
      );
      return (response.data as List)
          .map((json) => SearchResult.fromJson(json))
          .toList();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        return []; // 취소된 경우 빈 결과 반환
      }
      rethrow;
    }
  }
}
```

### FormData와 파일 업로드

```dart
Future<String> uploadProfileImage(File imageFile) async {
  final formData = FormData.fromMap({
    'image': await MultipartFile.fromFile(
      imageFile.path,
      filename: 'profile.jpg',
      contentType: DioMediaType('image', 'jpeg'),
    ),
    'userId': '123',
  });

  final response = await ApiClient().dio.post(
    '/upload/profile',
    data: formData,
    onSendProgress: (sent, total) {
      final progress = (sent / total * 100).toStringAsFixed(0);
      print('업로드 진행: $progress%');
    },
  );

  return response.data['imageUrl'];
}
```

### Dio 에러 처리

```dart
Future<T> safeApiCall<T>(Future<T> Function() apiCall) async {
  try {
    return await apiCall();
  } on DioException catch (e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        throw NetworkException('요청 시간이 초과되었습니다.');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 404) throw NotFoundException('리소스를 찾을 수 없습니다.');
        if (statusCode == 500) throw ServerException('서버 오류가 발생했습니다.');
        throw ApiException('API 오류: $statusCode');
      case DioExceptionType.connectionError:
        throw NetworkException('인터넷 연결을 확인해주세요.');
      default:
        throw UnknownException('알 수 없는 오류: ${e.message}');
    }
  }
}
```

---

## 3. JSON 파싱 전략

### 방법 1: 수동 파싱 (json.decode)

```dart
class User {
  final int id;
  final String name;
  final String email;

  const User({required this.id, required this.name, required this.email});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }
}

// 사용
final String jsonStr = '{"id": 1, "name": "홍길동", "email": "hong@test.com"}';
final user = User.fromJson(jsonDecode(jsonStr));
```

### 방법 2: json_serializable (코드 생성)

```yaml
# pubspec.yaml
dependencies:
  json_annotation: ^4.8.1

dev_dependencies:
  json_serializable: ^6.7.1
  build_runner: ^2.4.7
```

```dart
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart'; // 코드 생성 파일

@JsonSerializable()
class User {
  final int id;
  final String name;
  @JsonKey(name: 'email_address') // JSON 키 매핑
  final String email;
  final Address? address; // 중첩 객체

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.address,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}

// 코드 생성 명령: dart run build_runner build
```

### 방법 3: Freezed (불변 클래스 + JSON)

```yaml
# pubspec.yaml
dependencies:
  freezed_annotation: ^2.4.1
  json_annotation: ^4.8.1

dev_dependencies:
  freezed: ^2.4.6
  json_serializable: ^6.7.1
  build_runner: ^2.4.7
```

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const factory User({
    required int id,
    required String name,
    required String email,
    @Default([]) List<String> roles, // 기본값 설정
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

// Freezed 사용의 장점:
// 1. 불변성 보장 (copyWith 자동 생성)
// 2. ==, hashCode, toString 자동 생성
// 3. 패턴 매칭 (sealed class) 지원

// copyWith 사용 예시
final updatedUser = user.copyWith(name: '새 이름');
```

---

## 4. SharedPreferences

앱의 간단한 키-값 데이터를 영구 저장하는 가장 간편한 방법입니다.
iOS는 NSUserDefaults, Android는 SharedPreferences를 내부적으로 사용합니다.

### 설치

```yaml
# pubspec.yaml
dependencies:
  shared_preferences: ^2.2.2
```

### 기본 사용법

```dart
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _keyTheme = 'theme_mode';
  static const String _keyLanguage = 'language';
  static const String _keyFirstLaunch = 'is_first_launch';

  // 저장
  Future<void> saveThemeMode(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTheme, theme);
  }

  // 읽기
  Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyTheme) ?? 'system'; // 기본값 설정
  }

  // bool 저장/읽기
  Future<void> setFirstLaunch(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFirstLaunch, value);
  }

  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyFirstLaunch) ?? true;
  }

  // 삭제
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // 특정 키 삭제
  Future<void> removeTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyTheme);
  }
}
```

### SharedPreferences 지원 타입

| 타입 | 메서드 |
|------|--------|
| String | setString / getString |
| int | setInt / getInt |
| double | setDouble / getDouble |
| bool | setBool / getBool |
| List<String> | setStringList / getStringList |

> 주의: 객체나 복잡한 데이터는 jsonEncode로 문자열 변환 후 저장해야 합니다.
> 민감한 정보(비밀번호, 토큰)는 절대 SharedPreferences에 저장하지 마세요.

---

## 5. SQLite (sqflite)

복잡한 관계형 데이터를 로컬에 저장할 때 사용합니다.
sqflite는 SQLite의 Flutter 래퍼입니다.

### 설치

```yaml
# pubspec.yaml
dependencies:
  sqflite: ^2.3.2
  path: ^1.9.0
```

### 데이터베이스 헬퍼 클래스

```dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'app.db');

    return await openDatabase(
      path,
      version: 2, // 버전 업 시 마이그레이션 트리거
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE posts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        content TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE users ADD COLUMN avatar_url TEXT');
    }
  }
}
```

### CRUD 예제

```dart
class UserRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // CREATE
  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'users',
      {
        ...user,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // READ - 전체 조회
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await _dbHelper.database;
    return await db.query(
      'users',
      orderBy: 'created_at DESC',
    );
  }

  // READ - 조건 조회
  Future<Map<String, dynamic>?> getUserById(int id) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  // UPDATE
  Future<int> updateUser(int id, Map<String, dynamic> updates) async {
    final db = await _dbHelper.database;
    return await db.update(
      'users',
      updates,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // DELETE
  Future<int> deleteUser(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 트랜잭션
  Future<void> insertUserWithPosts(
    Map<String, dynamic> user,
    List<Map<String, dynamic>> posts,
  ) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      final userId = await txn.insert('users', user);
      for (final post in posts) {
        await txn.insert('posts', {...post, 'user_id': userId});
      }
    });
  }

  // Raw 쿼리 (JOIN 등 복잡한 쿼리)
  Future<List<Map<String, dynamic>>> getUsersWithPosts() async {
    final db = await _dbHelper.database;
    return await db.rawQuery('''
      SELECT u.*, COUNT(p.id) as post_count
      FROM users u
      LEFT JOIN posts p ON u.id = p.user_id
      GROUP BY u.id
      ORDER BY post_count DESC
    ''');
  }
}
```

---

## 6. Secure Storage

민감한 데이터(토큰, 비밀번호)를 안전하게 저장합니다.
iOS Keychain, Android Keystore를 내부적으로 사용합니다.

### 설치

```yaml
# pubspec.yaml
dependencies:
  flutter_secure_storage: ^9.0.0
```

### 사용법

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true, // Android 추가 보안
    ),
  );

  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';

  // 토큰 저장
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _keyAccessToken, value: accessToken),
      _storage.write(key: _keyRefreshToken, value: refreshToken),
    ]);
  }

  // 토큰 읽기
  static Future<String?> getToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  // 로그아웃 시 토큰 삭제
  static Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _keyAccessToken),
      _storage.delete(key: _keyRefreshToken),
    ]);
  }

  // 모든 데이터 삭제
  static Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}
```

---

## 7. 스토리지 비교표

| 항목 | SharedPreferences | SQLite (sqflite) | Secure Storage | Hive |
|------|-------------------|------------------|----------------|------|
| 사용 목적 | 간단한 설정값 | 복잡한 관계형 데이터 | 민감한 보안 데이터 | 빠른 NoSQL |
| 데이터 형식 | Key-Value | 테이블(관계형) | Key-Value | Key-Value, 객체 |
| 보안 | 낮음 (평문) | 낮음 (평문) | 높음 (암호화) | 선택적 암호화 |
| 성능 | 빠름 | 중간 | 중간 | 매우 빠름 |
| 쿼리 지원 | 없음 | SQL 전체 지원 | 없음 | 제한적 |
| 적합한 데이터 | 테마, 언어 설정 | 사용자 데이터, 캐시 | 토큰, 비밀번호 | 로컬 캐시 |
| 타입 안전성 | 낮음 | 낮음 | 낮음 | 높음 |

---

## 8. REST API 응답 모델 클래스 패턴

### 공통 API 응답 래퍼

```dart
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int? statusCode;

  const ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJson,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool,
      data: json['data'] != null ? fromJson(json['data']) : null,
      message: json['message'] as String?,
      statusCode: json['status_code'] as int?,
    );
  }
}
```

### 페이지네이션 응답 처리

```dart
class PaginatedResponse<T> {
  final List<T> items;
  final int totalCount;
  final int currentPage;
  final int totalPages;
  final bool hasNextPage;

  const PaginatedResponse({
    required this.items,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
    required this.hasNextPage,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonItem,
  ) {
    return PaginatedResponse<T>(
      items: (json['data'] as List)
          .map((item) => fromJsonItem(item as Map<String, dynamic>))
          .toList(),
      totalCount: json['total'] as int,
      currentPage: json['current_page'] as int,
      totalPages: json['total_pages'] as int,
      hasNextPage: json['has_next_page'] as bool,
    );
  }
}

// 사용 예시
Future<PaginatedResponse<Post>> getPosts(int page) async {
  final response = await ApiClient().dio.get(
    '/posts',
    queryParameters: {'page': page, 'limit': 20},
  );

  return PaginatedResponse.fromJson(
    response.data as Map<String, dynamic>,
    Post.fromJson,
  );
}
```

### Repository 패턴

```dart
abstract class UserRepository {
  Future<User> getUser(int id);
  Future<List<User>> getUsers();
  Future<User> createUser(CreateUserRequest request);
  Future<User> updateUser(int id, UpdateUserRequest request);
  Future<void> deleteUser(int id);
}

class RemoteUserRepository implements UserRepository {
  final Dio _dio;
  RemoteUserRepository(this._dio);

  @override
  Future<User> getUser(int id) async {
    final response = await _dio.get('/users/$id');
    return User.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<User>> getUsers() async {
    final response = await _dio.get('/users');
    return (response.data as List)
        .map((json) => User.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<User> createUser(CreateUserRequest request) async {
    final response = await _dio.post('/users', data: request.toJson());
    return User.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<User> updateUser(int id, UpdateUserRequest request) async {
    final response = await _dio.patch('/users/$id', data: request.toJson());
    return User.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteUser(int id) async {
    await _dio.delete('/users/$id');
  }
}
```

---

## 9. 면접 포인트

**Q1. http 패키지와 Dio의 차이점은 무엇인가요?**

http는 Dart 공식 팀의 경량 HTTP 클라이언트로 기본적인 GET/POST 요청에 적합합니다.
Dio는 인터셉터, 요청 취소(CancelToken), FormData 지원, 자동 재시도 등
프로덕션 앱에 필요한 고급 기능을 제공합니다.
대부분의 실무 프로젝트에서는 Dio를 선택합니다.

**Q2. Dio 인터셉터를 사용하는 대표적인 시나리오를 설명해주세요.**

- **인증 토큰 주입**: 모든 요청에 Authorization 헤더 자동 추가
- **토큰 갱신**: 401 응답 시 refresh token으로 새 토큰 발급 후 재시도
- **로깅**: 요청/응답 정보를 로그에 기록하여 디버깅
- **에러 처리**: 서버 공통 에러 형식을 앱 예외로 변환
- **캐싱**: 특정 요청 결과를 로컬에 캐싱

**Q3. SharedPreferences와 Secure Storage의 사용 기준은?**

SharedPreferences는 암호화 없이 평문으로 저장되므로, 테마 설정, 언어 설정,
온보딩 완료 여부 등 보안이 중요하지 않은 데이터에 사용합니다.
반면 액세스 토큰, 리프레시 토큰, 비밀번호 등 민감한 정보는 반드시
Secure Storage를 사용해야 합니다. iOS는 Keychain, Android는 Keystore를 통해
OS 수준에서 암호화됩니다.

**Q4. SQLite에서 트랜잭션을 사용하는 이유는?**

여러 DB 작업이 모두 성공하거나 모두 실패해야 하는 원자성(Atomicity)을 보장하기 위해
사용합니다. 예를 들어, 사용자 생성과 함께 초기 설정값 레코드를 삽입해야 할 때
중간에 오류가 발생하면 전체 롤백이 필요합니다. 트랜잭션 없이는 부분적으로 저장된
불완전한 데이터가 남을 수 있습니다.

**Q5. JSON 파싱 방법(수동, json_serializable, Freezed) 비교를 설명해주세요.**

수동 파싱은 추가 의존성 없이 빠르게 구현 가능하지만, 필드가 많아지면
보일러플레이트가 급증하고 오타 오류가 발생하기 쉽습니다.
json_serializable은 코드 생성으로 반복 코드를 자동화하며 타입 안전성을 제공합니다.
Freezed는 불변 객체, copyWith, 패턴 매칭까지 지원하여 가장 강력하지만
코드 생성 설정이 필요합니다. 실무에서는 Freezed + json_serializable 조합이 권장됩니다.

**Q6. FutureProvider vs StreamProvider 사용 시기는?**

FutureProvider는 한 번 데이터를 가져오고 완료되는 비동기 작업에 사용합니다.
(예: API에서 사용자 정보 한 번 조회)
StreamProvider는 실시간으로 데이터가 변하는 스트림 데이터에 사용합니다.
(예: WebSocket 메시지, Firebase 실시간 업데이트, 위치 정보 스트림)

**Q7. sqflite에서 N+1 쿼리 문제를 어떻게 방지하나요?**

JOIN 쿼리를 사용하거나 rawQuery를 통해 한 번의 쿼리로 필요한 모든 데이터를 조회합니다.
예를 들어 사용자 목록과 각 사용자의 게시글 수를 가져올 때, 사용자마다 별도로
쿼리를 실행하는 것이 아니라 LEFT JOIN + COUNT를 사용한 단일 쿼리로 처리합니다.
