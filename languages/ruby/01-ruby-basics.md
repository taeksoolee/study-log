# 1. Ruby 기초 (프론트엔드 개발자 관점)

## 목차
1. Ruby vs JavaScript 비교
2. 변수 / 상수 / 심볼
3. 문자열
4. 배열 / 해시와 Enumerable
5. 블록 / 프로시저 / 람다
6. 클래스 / 모듈 / 믹스인
7. 예외 처리
8. Ruby 2.7~3.x 최신 문법
9. Gem / Bundler 패키지 관리
10. 면접 포인트

---

## 1. Ruby vs JavaScript 비교

| 항목 | Ruby | JavaScript |
|------|------|------------|
| 타입 시스템 | 동적 타입, 강 타입 | 동적 타입, 약 타입 |
| 실행 환경 | MRI(CRuby), JRuby 등 | 브라우저, Node.js |
| null 표현 | `nil` | `null`, `undefined` |
| 진위값 | `false`, `nil`만 falsy | `0`, `""`, `null` 등도 falsy |
| 클래스 | 모든 것이 객체 (순수 OOP) | 프로토타입 기반, ES6+ class |
| 함수 | 메서드, 블록, 프로시저, 람다 | 함수, 화살표 함수, 클로저 |
| 문자열 보간 | `"Hello, #{name}"` | `` `Hello, ${name}` `` |
| 배열 마지막 요소 | `arr[-1]` | `arr[arr.length - 1]` |
| 해시/객체 | `{ key: value }` (심볼 키) | `{ key: value }` (문자열 키) |
| 패키지 관리 | Gem + Bundler | npm/yarn/pnpm |
| 세미콜론 | 불필요 (관례적으로 생략) | 선택적 (ASI 있음) |
| 반환값 | 마지막 표현식이 자동 반환 | 명시적 `return` 필요 |

```ruby
# Ruby: 모든 것이 객체
1.class          # => Integer
"hello".class    # => String
nil.class        # => NilClass
true.class       # => TrueClass

# JS: 원시값은 객체가 아님 (래퍼 객체 제외)
# typeof 1 => "number"
# typeof null => "object" (버그로 유명)
```

---

## 2. 변수 / 상수 / 심볼

### 변수 종류

```ruby
# 지역 변수 (lowercase 또는 snake_case) — JS의 let과 유사
name = "Alice"
user_age = 30

# 인스턴스 변수 (@) — 클래스 내부 상태
@email = "alice@example.com"

# 클래스 변수 (@@) — 모든 인스턴스가 공유 (JS의 static과 유사)
@@count = 0

# 전역 변수 ($) — 사용 지양
$global = "avoid this"

# 상수 (대문자로 시작) — JS의 const와 유사하지만 경고만 발생 (에러 아님)
MAX_SIZE = 100
PI = 3.14159
```

### 심볼 (Symbol)

```ruby
# 심볼: 불변, 메모리 효율적인 식별자
# JS에는 Symbol이 있지만 Ruby의 심볼이 훨씬 일반적으로 사용됨

status = :active           # 심볼 리터럴
hash = { name: "Alice" }   # 해시 키로 자주 사용 (: 뒤에 오면 심볼)

# 문자열 vs 심볼 비교
"active".object_id == "active".object_id  # => false (매번 새 객체)
:active.object_id == :active.object_id    # => true  (동일 객체, 메모리 절약)

# 변환
:active.to_s   # => "active"
"active".to_sym # => :active
```

---

## 3. 문자열

### 기본 문자열

```ruby
# 큰따옴표: 보간, 이스케이프 시퀀스 지원
name = "World"
greeting = "Hello, #{name}!"   # => "Hello, World!"
escaped = "Line1\nLine2"

# 작은따옴표: 리터럴 그대로 (보간 없음, JS에는 없는 개념)
literal = 'Hello, #{name}!'    # => "Hello, #{name}!" (보간 안 됨)
```

### Heredoc

```ruby
# JS의 템플릿 리터럴과 유사한 멀티라인 문자열
sql = <<~SQL
  SELECT *
  FROM users
  WHERE active = true
SQL

html = <<~HTML
  <div class="container">
    <h1>Hello</h1>
  </div>
HTML
```

### frozen_string_literal

```ruby
# 파일 상단에 추가하면 모든 문자열 리터럴을 불변(frozen)으로 만들어 성능 향상
# frozen_string_literal: true

str = "hello"
str.frozen?  # => true (매직 코멘트 적용 시)
str << " world"  # => FrozenError 발생

# 명시적으로 가변 문자열이 필요할 경우
mutable = +"hello"   # unary + 로 mutable 문자열 생성
mutable << " world"  # => "hello world"
```

### 주요 문자열 메서드

```ruby
"hello world".upcase          # => "HELLO WORLD"
"HELLO".downcase              # => "hello"
"  hello  ".strip             # => "hello"      (JS: trim())
"hello".include?("ell")       # => true         (JS: includes())
"hello world".split(" ")      # => ["hello", "world"]
"hello".gsub("l", "r")        # => "herro"      (JS: replaceAll())
"hello" * 3                   # => "hellohellohello"
```

---

## 4. 배열 / 해시와 Enumerable

### 배열

```ruby
# 생성
arr = [1, 2, 3, 4, 5]
words = %w[apple banana cherry]  # 문자열 배열 단축 표기 (공백 구분)

# 접근
arr[0]    # => 1
arr[-1]   # => 5   (JS: arr[arr.length - 1])
arr[1..3] # => [2, 3, 4]  (범위로 슬라이싱)
arr.first # => 1
arr.last  # => 5

# 조작
arr.push(6)       # arr << 6  도 가능 (JS: push)
arr.pop           # JS: pop
arr.shift         # JS: shift
arr.unshift(0)    # JS: unshift
arr.flatten       # 중첩 배열 평탄화 (JS: flat())
arr.compact       # nil 제거 (JS: filter(x => x != null))
arr.uniq          # 중복 제거 (JS: [...new Set(arr)])
```

### 해시 (Hash)

```ruby
# JS의 Object/Map에 대응
user = { name: "Alice", age: 30 }  # 심볼 키 (일반적)
config = { "host" => "localhost", "port" => 3000 }  # 문자열 키 (구식)

# 접근
user[:name]           # => "Alice"
user.fetch(:name)     # 키가 없으면 KeyError (안전한 접근)
user.fetch(:email, "N/A")  # 기본값 지정

# 조작
user[:email] = "alice@example.com"  # 추가/수정
user.delete(:age)                    # 삭제
user.key?(:name)                     # => true (JS: 'name' in obj)
user.keys                            # => [:name, :email]
user.values                          # => ["Alice", "alice@example.com"]
user.merge({ role: "admin" })        # JS: { ...user, role: "admin" }
```

### Enumerable 메서드

```ruby
numbers = [1, 2, 3, 4, 5]

# map (JS: map)
numbers.map { |n| n * 2 }          # => [2, 4, 6, 8, 10]
numbers.map { _1 * 2 }             # Ruby 2.7+ numbered params

# select / reject (JS: filter)
numbers.select { |n| n.even? }     # => [2, 4]  (filter와 동일)
numbers.reject { |n| n.even? }     # => [1, 3, 5]  (filter 반대)

# reduce / inject (JS: reduce)
numbers.reduce(0) { |sum, n| sum + n }  # => 15
numbers.reduce(:+)                       # => 15  (심볼로 연산자 전달)
numbers.sum                              # => 15  (더 간결한 방법)

# each (JS: forEach)
numbers.each { |n| puts n }

# find (JS: find)
numbers.find { |n| n > 3 }         # => 4

# all? / any? / none? (JS: every/some)
numbers.all? { |n| n > 0 }         # => true
numbers.any? { |n| n > 4 }         # => true
numbers.none? { |n| n > 10 }       # => true

# flat_map (JS: flatMap)
[[1, 2], [3, 4]].flat_map { |a| a.map { |n| n * 2 } }  # => [2, 4, 6, 8]

# group_by (JS: reduce로 구현하는 groupBy)
numbers.group_by { |n| n.even? ? :even : :odd }
# => { odd: [1, 3, 5], even: [2, 4] }

# each_with_object (JS: reduce with accumulator object)
numbers.each_with_object({}) { |n, hash| hash[n] = n ** 2 }
# => { 1=>1, 2=>4, 3=>9, 4=>16, 5=>25 }
```

---

## 5. 블록 / 프로시저 / 람다

### 블록 (Block)

```ruby
# JS의 콜백 함수와 유사하지만 언어 차원의 문법
# do...end 또는 { } 로 표현

# do...end (여러 줄)
[1, 2, 3].each do |n|
  puts n * 2
end

# { } (한 줄)
[1, 2, 3].each { |n| puts n * 2 }

# 메서드에서 블록 받기
def greet
  message = yield("World") if block_given?
  puts message || "No block given"
end

greet { |name| "Hello, #{name}!" }  # => "Hello, World!"
```

### 프로시저 (Proc)

```ruby
# 블록을 객체로 저장
double = Proc.new { |n| n * 2 }
double.call(5)   # => 10
double.(5)       # 짧은 호출 문법
double[5]        # 또한 가능

# JS: const double = (n) => n * 2;
```

### 람다 (Lambda)

```ruby
# Proc과 유사하지만 더 엄격한 인자 체크, return 동작 차이
square = lambda { |n| n ** 2 }
square = ->(n) { n ** 2 }   # 화살표 람다 (JS 화살표 함수와 유사)

square.call(4)  # => 16
square.(4)      # => 16

# Proc vs Lambda 차이
# 1. 인자 수 체크: Lambda는 엄격, Proc은 느슨
# 2. return: Lambda는 람다 내부에서만, Proc은 메서드 자체를 종료
```

### &: 단축 표기

```ruby
# JS: arr.map(n => n.toString())
[1, 2, 3].map { |n| n.to_s }
[1, 2, 3].map(&:to_s)          # & + 심볼로 단축 표기

["hello", "world"].map(&:upcase)    # => ["HELLO", "WORLD"]
[1, nil, 2, nil].compact            # nil 제거
```

---

## 6. 클래스 / 모듈 / 믹스인

### 클래스

```ruby
class Animal
  attr_accessor :name, :age   # getter/setter 자동 생성 (JS: get/set)
  attr_reader :id              # getter만

  @@count = 0  # 클래스 변수

  def initialize(name, age)   # JS의 constructor
    @name = name
    @age = age
    @@count += 1
  end

  def self.count              # 클래스 메서드 (JS의 static)
    @@count
  end

  def speak                   # 인스턴스 메서드
    "..."
  end

  def to_s                    # JS의 toString()
    "Animal(#{@name}, #{@age})"
  end
end

# 상속
class Dog < Animal            # JS: class Dog extends Animal
  def speak
    "Woof!"
  end

  def fetch(item)
    super.speak + " I fetched #{item}!"   # super로 부모 메서드 호출
  end
end

dog = Dog.new("Rex", 3)
dog.name     # => "Rex"
dog.speak    # => "Woof!"
Dog.count    # => 1
```

### 모듈과 믹스인 (include vs extend)

```ruby
module Greetable
  def greet
    "Hello, I'm #{name}"  # 포함하는 클래스의 메서드 사용 가능
  end
end

module ClassMethods
  def description
    "This is #{self.name} class"
  end
end

class Person
  include Greetable      # 인스턴스 메서드로 추가 (JS: mixin 패턴)
  extend ClassMethods    # 클래스 메서드로 추가 (JS: static mixin)

  attr_reader :name
  def initialize(name)
    @name = name
  end
end

alice = Person.new("Alice")
alice.greet        # => "Hello, I'm Alice"  (include: 인스턴스에서 사용)
Person.description # => "This is Person class"  (extend: 클래스에서 사용)
```

---

## 7. 예외 처리

```ruby
# JS의 try/catch/finally와 대응
begin
  result = 10 / 0
rescue ZeroDivisionError => e
  puts "0으로 나눌 수 없습니다: #{e.message}"
rescue ArgumentError, TypeError => e
  puts "인자 오류: #{e.message}"
rescue => e          # StandardError 및 하위 모든 예외 캐치
  puts "예외 발생: #{e.message}"
else
  puts "성공: #{result}"   # 예외가 없을 때 실행 (JS에는 없음)
ensure
  puts "항상 실행"          # JS의 finally와 동일
end

# 예외 발생
raise ArgumentError, "잘못된 인자입니다"
raise "단순 런타임 에러"

# 커스텀 예외
class AppError < StandardError
  def initialize(msg = "앱 에러가 발생했습니다")
    super
  end
end

# 메서드 내 단축 rescue
def parse_number(str)
  Integer(str)
rescue ArgumentError
  nil
end
```

---

## 8. Ruby 2.7~3.x 최신 문법

### Numbered Parameters (2.7+)

```ruby
# _1, _2 ... 으로 블록 파라미터 접근
[1, 2, 3].map { _1 * 2 }            # => [2, 4, 6]
{ a: 1, b: 2 }.map { "#{_1}: #{_2}" }
```

### Pattern Matching (2.7+)

```ruby
# JS의 구조 분해 할당 + switch를 합친 개념
user = { name: "Alice", role: :admin, age: 30 }

case user
in { role: :admin, name: String => name }
  puts "Admin: #{name}"
in { role: :guest }
  puts "Guest user"
end

# Find pattern (3.0+)
case [1, 2, 3, 4, 5]
in [*, 3, *]
  puts "contains 3"
end

# Pin operator (^) — 기존 변수와 매칭
expected = "Alice"
case user
in { name: ^expected }
  puts "Found Alice"
end
```

### Endless Range와 Beginless Range

```ruby
(1..)   # 1부터 무한 (endless)
(..5)   # 처음부터 5 (beginless)

numbers = [1, 2, 3, 4, 5]
numbers.select { |n| (3..).include?(n) }   # => [3, 4, 5]

case age
when (..12)  then "child"
when (13..17) then "teenager"
when (18..)  then "adult"
end
```

### Rightward Assignment (3.0+)

```ruby
# 오른쪽으로 할당 (실험적)
"hello" => greeting
```

### Hash 단축 표기 (3.1+)

```ruby
name = "Alice"
age = 30

# JS: { name, age }  와 동일한 개념
{ name:, age: }  # => { name: "Alice", age: 30 }
```

### endless method (3.0+)

```ruby
def double(x) = x * 2     # 한 줄 메서드 정의
def square(x) = x ** 2
```

---

## 9. Gem / Bundler 패키지 관리

### npm vs Bundler 비교

| npm/yarn | Bundler | 설명 |
|----------|---------|------|
| `package.json` | `Gemfile` | 의존성 선언 파일 |
| `package-lock.json` | `Gemfile.lock` | 고정된 버전 파일 |
| `node_modules/` | `vendor/bundle/` | 설치 경로 |
| `npm install` | `bundle install` | 의존성 설치 |
| `npm install axios` | `bundle add httparty` | 패키지 추가 |
| `npm run start` | `bundle exec rails s` | 스크립트 실행 |
| `npx` | `bundle exec` | 로컬 바이너리 실행 |

### Gemfile 작성

```ruby
# Gemfile
source "https://rubygems.org"

ruby "3.2.0"   # Ruby 버전 고정

gem "rails", "~> 7.1.0"      # ~> : 마이너 버전 호환 (>=7.1.0, <7.2)
gem "pg", ">= 1.1"            # PostgreSQL 어댑터
gem "puma", ">= 5.0"          # 웹 서버

# 환경별 그룹 (JS의 devDependencies와 유사)
group :development, :test do
  gem "rspec-rails"
  gem "factory_bot_rails"
end

group :development do
  gem "rubocop", require: false   # 린터
end
```

### 주요 Gem 목록

```bash
# 설치 및 관리
bundle install              # package.json 기반 설치
bundle update rails         # 특정 gem 업데이트
bundle exec rspec           # 로컬 gem으로 명령 실행
gem list                    # 설치된 gem 목록

# 자주 쓰는 gem
# httparty      — HTTP 클라이언트 (axios 대응)
# kaminari      — 페이지네이션
# devise        — 인증 (passport.js 대응)
# pundit        — 권한 관리
# sidekiq       — 백그라운드 잡 (bull 대응)
# rubocop       — 코드 린터 (ESLint 대응)
```

---

## 10. 면접 포인트

**Q. Ruby에서 `nil`과 `false` 외에 falsy 값이 있나요?**
> 없습니다. Ruby에서는 `nil`과 `false`만이 falsy입니다. `0`, `""`, `[]` 등은 모두 truthy입니다. 이는 JavaScript와 큰 차이점입니다.

**Q. `Proc`과 `Lambda`의 차이점은 무엇인가요?**
> 두 가지 차이가 있습니다. 첫째, 인자 수 검사에서 Lambda는 엄격하게 체크하지만 Proc은 부족한 인자를 nil로 채웁니다. 둘째, `return` 동작에서 Lambda 내의 `return`은 람다만 종료하지만 Proc의 `return`은 메서드 자체를 종료시킵니다.

**Q. `include`와 `extend`의 차이점은?**
> `include`는 모듈의 메서드를 인스턴스 메서드로 추가하고, `extend`는 클래스 메서드(싱글톤 메서드)로 추가합니다.

**Q. Ruby의 `Symbol`을 해시 키로 쓰는 이유는?**
> Symbol은 동일한 이름이면 항상 동일한 객체를 참조합니다(`object_id`가 같음). 따라서 해시 키 비교 시 문자열보다 빠르고 메모리 효율적입니다.

**Q. `frozen_string_literal`은 왜 사용하나요?**
> Ruby에서 문자열 리터럴은 기본적으로 매번 새 객체를 생성합니다. `# frozen_string_literal: true` 주석을 추가하면 동일한 문자열이 같은 객체를 재사용하여 메모리 절약과 성능 향상이 가능합니다.

**Q. Ruby의 블록(Block)과 JS의 콜백 함수 차이는?**
> JS의 콜백은 일반 함수 객체지만, Ruby의 블록은 언어 문법의 일부로 메서드에 단 하나만 전달할 수 있으며 독립적인 객체가 아닙니다. 블록을 객체로 만들려면 Proc이나 Lambda를 사용합니다.
