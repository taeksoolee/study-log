# 1. RDBMS 기초

## 목차
1. 트랜잭션(Transaction)
2. ACID 속성
3. 트랜잭션 격리 수준
4. 정규화(Normalization)
5. 역정규화(Denormalization)
6. 인덱스(Index)
7. 복합 인덱스 & 커버링 인덱스
8. 면접 포인트

---

## 1. 트랜잭션(Transaction)

트랜잭션이란 데이터베이스에서 하나의 논리적 작업 단위를 구성하는 일련의 연산 집합이다.
예를 들어 A 계좌에서 B 계좌로 이체할 때, "출금"과 "입금"은 반드시 함께 성공하거나 함께 실패해야 한다.

```sql
-- 트랜잭션 예시: 계좌 이체
BEGIN;

UPDATE accounts SET balance = balance - 10000 WHERE id = 1; -- A 출금
UPDATE accounts SET balance = balance + 10000 WHERE id = 2; -- B 입금

COMMIT; -- 모두 성공하면 확정

-- 오류 발생 시
ROLLBACK; -- 모든 변경을 되돌림
```

트랜잭션의 상태는 다음과 같이 전이된다:
- **Active**: 트랜잭션 실행 중
- **Partially Committed**: 마지막 연산 실행 직후
- **Committed**: 트랜잭션 성공적으로 완료
- **Failed**: 오류 발생으로 중단
- **Aborted**: 롤백 완료

---

## 2. ACID 속성

ACID는 트랜잭션의 신뢰성을 보장하는 4가지 핵심 속성이다.

### 2-1. 원자성 (Atomicity)

트랜잭션 내의 모든 연산은 전부 실행되거나 전부 실행되지 않아야 한다.
"All or Nothing" 원칙이다.

```
이체 트랜잭션 중 시스템 장애 발생 시:
- 출금만 되고 입금이 안 된 상태 -> 불허
- 롤백을 통해 출금도 취소되어야 함
```

### 2-2. 일관성 (Consistency)

트랜잭션이 완료된 후에도 데이터베이스는 일관된 상태를 유지해야 한다.
미리 정의된 규칙(제약 조건, 무결성 등)을 항상 만족해야 한다.

```
잔액은 음수가 될 수 없다는 규칙이 있다면,
트랜잭션 후에도 이 규칙은 반드시 지켜져야 한다.
```

### 2-3. 격리성 (Isolation)

동시에 실행되는 트랜잭션들은 서로 영향을 미치지 않아야 한다.
한 트랜잭션이 완료되기 전까지 다른 트랜잭션은 그 중간 결과를 볼 수 없다.

```
트랜잭션 A가 데이터를 수정하는 중에
트랜잭션 B는 수정 전 혹은 수정 후의 데이터만 볼 수 있어야 한다.
```

### 2-4. 지속성 (Durability)

커밋된 트랜잭션의 결과는 시스템 장애가 발생하더라도 영구적으로 보존되어야 한다.
WAL(Write-Ahead Logging) 등의 메커니즘으로 보장한다.

```
COMMIT 이후 서버가 갑자기 꺼지더라도
재시작 후 데이터는 반드시 반영되어 있어야 한다.
```

---

## 3. 트랜잭션 격리 수준

격리성을 완벽히 보장하면 동시성이 낮아지므로, 4단계의 격리 수준을 제공한다.

| 격리 수준             | Dirty Read | Non-Repeatable Read | Phantom Read |
|----------------------|-----------|--------------------:|-------------|
| Read Uncommitted     | 허용       | 허용                | 허용         |
| Read Committed       | 방지       | 허용                | 허용         |
| Repeatable Read      | 방지       | 방지                | 허용         |
| Serializable         | 방지       | 방지                | 방지         |

### 3-1. Read Uncommitted
커밋되지 않은 데이터도 읽을 수 있다. Dirty Read 문제가 발생한다.

```sql
-- 트랜잭션 A: 아직 커밋 안 함
UPDATE products SET price = 5000 WHERE id = 1;

-- 트랜잭션 B: 커밋 안 된 5000을 읽어버림 (Dirty Read)
SELECT price FROM products WHERE id = 1; -- 5000 반환
```

### 3-2. Read Committed
커밋된 데이터만 읽는다. Non-Repeatable Read 문제가 남는다.
PostgreSQL, Oracle의 기본값이다.

```sql
-- 트랜잭션 A
SELECT price FROM products WHERE id = 1; -- 3000

-- 트랜잭션 B가 price를 5000으로 UPDATE 후 COMMIT

-- 트랜잭션 A 재조회
SELECT price FROM products WHERE id = 1; -- 5000 (값이 바뀜 = Non-Repeatable Read)
```

### 3-3. Repeatable Read
같은 트랜잭션 내에서 같은 행을 다시 읽어도 동일한 값이 보장된다.
MySQL InnoDB의 기본값이다.

```sql
-- 트랜잭션 A
SELECT price FROM products WHERE id = 1; -- 3000

-- 트랜잭션 B가 price를 5000으로 UPDATE 후 COMMIT

-- 트랜잭션 A 재조회
SELECT price FROM products WHERE id = 1; -- 3000 (Repeatable Read 보장)
```

### 3-4. Serializable
모든 트랜잭션을 직렬로 실행한 것과 동일한 결과를 보장한다.
가장 강력한 격리지만 동시성이 가장 낮다.

---

## 4. 정규화(Normalization)

정규화란 데이터 중복을 최소화하고 데이터 무결성을 보장하기 위해
테이블 구조를 체계적으로 분리하는 과정이다.

### 4-1. 제1정규형 (1NF)
각 컬럼은 원자값(atomic value)을 가져야 하며, 반복 그룹이 없어야 한다.

```
[위반 예시]
| 학생ID | 이름  | 수강과목              |
|--------|------|----------------------|
| 1      | 김철수 | 수학, 영어, 과학       |

[1NF 적용 후]
| 학생ID | 이름  | 수강과목 |
|--------|------|---------|
| 1      | 김철수 | 수학     |
| 1      | 김철수 | 영어     |
| 1      | 김철수 | 과학     |
```

### 4-2. 제2정규형 (2NF)
1NF를 만족하며, 부분 함수 종속을 제거해야 한다.
복합 기본키에서 일부 키에만 종속되는 컬럼이 없어야 한다.

```
[위반 예시] PK = (학생ID, 과목ID)
| 학생ID | 과목ID | 학생이름 | 점수 |
|--------|--------|---------|------|
| 1      | 101    | 김철수   | 90   |

학생이름은 학생ID에만 종속 -> 부분 종속 위반

[2NF 적용 후]
학생 테이블: (학생ID, 학생이름)
수강 테이블: (학생ID, 과목ID, 점수)
```

### 4-3. 제3정규형 (3NF)
2NF를 만족하며, 이행 함수 종속을 제거해야 한다.
기본키가 아닌 컬럼이 다른 비기본키 컬럼에 종속되면 안 된다.

```
[위반 예시] PK = 학생ID
| 학생ID | 학과ID | 학과명   |
|--------|--------|---------|
| 1      | 10     | 컴퓨터공학 |

학생ID -> 학과ID -> 학과명 (이행 종속)

[3NF 적용 후]
학생 테이블: (학생ID, 학과ID)
학과 테이블: (학과ID, 학과명)
```

### 4-4. BCNF (Boyce-Codd Normal Form)
3NF를 만족하며, 모든 결정자(Determinant)가 후보키여야 한다.
3NF를 만족해도 이상 현상이 남을 수 있는 경우를 처리한다.

```
[위반 예시] 교수는 하나의 과목만 담당, 학생은 여러 과목 수강
| 학생 | 과목  | 교수  |
|------|------|------|
| 홍길동 | DB   | 김교수 |

교수 -> 과목 (교수가 결정자인데 후보키가 아님)

[BCNF 적용 후]
교수-과목 테이블: (교수, 과목)
학생-교수 테이블: (학생, 교수)
```

---

## 5. 역정규화(Denormalization)

정규화된 테이블을 의도적으로 합치거나 중복을 허용하여 조회 성능을 높이는 기법이다.

**역정규화를 고려하는 경우:**
- JOIN이 너무 많아 쿼리 성능이 저하될 때
- 읽기 작업이 쓰기 작업보다 압도적으로 많을 때
- 통계, 집계 데이터를 자주 조회할 때

```sql
-- 정규화된 구조: 주문마다 고객명을 조회하려면 JOIN 필요
SELECT o.order_id, c.name, o.total_price
FROM orders o
JOIN customers c ON o.customer_id = c.id;

-- 역정규화: orders 테이블에 customer_name 컬럼 추가
-- 데이터 중복이 생기지만 JOIN 없이 바로 조회 가능
SELECT order_id, customer_name, total_price
FROM orders;
```

**역정규화의 단점:**
- 데이터 중복으로 인한 일관성 관리 어려움
- 저장 공간 증가
- 쓰기(INSERT/UPDATE/DELETE) 성능 저하

---

## 6. 인덱스(Index)

인덱스는 테이블의 특정 컬럼에 대한 검색 속도를 높이기 위한 자료구조다.
책의 목차와 같은 역할을 한다.

### 6-1. B-Tree 인덱스

가장 일반적으로 사용되는 인덱스 구조다.
균형 잡힌 트리 구조로 탐색, 삽입, 삭제 모두 O(log n) 시간 복잡도를 가진다.

```
B-Tree 구조 (간략)
          [50]
         /    \
      [20,30]  [70,80]
      /  |  \   /  |  \
    [10][25][35][60][75][90]
```

- **루트 노드**: 트리의 시작점
- **내부 노드**: 키와 자식 포인터를 가짐
- **리프 노드**: 실제 데이터(또는 데이터의 위치)를 가짐

```sql
-- 인덱스 생성
CREATE INDEX idx_users_email ON users(email);

-- 인덱스 확인 (MySQL)
SHOW INDEX FROM users;

-- 인덱스 삭제
DROP INDEX idx_users_email ON users;
```

### 6-2. 인덱스 장단점

**장점:**
- SELECT 쿼리 검색 속도 향상 (O(n) -> O(log n))
- ORDER BY 정렬 성능 개선
- GROUP BY 성능 개선

**단점:**
- INSERT, UPDATE, DELETE 시 인덱스 재구성으로 쓰기 성능 저하
- 추가적인 저장 공간 필요
- 너무 많은 인덱스는 오히려 전체 성능 저하

```sql
-- 인덱스가 없을 때: Full Table Scan
SELECT * FROM users WHERE email = 'test@example.com';
-- 인덱스가 있을 때: Index Scan (훨씬 빠름)

-- EXPLAIN으로 실행 계획 확인
EXPLAIN SELECT * FROM users WHERE email = 'test@example.com';
```

### 6-3. 인덱스가 사용되지 않는 경우

```sql
-- 1. 함수를 사용한 경우
SELECT * FROM users WHERE UPPER(name) = 'HONG'; -- 인덱스 미사용

-- 2. 타입 불일치
SELECT * FROM users WHERE id = '1'; -- id가 INT인데 문자열 비교

-- 3. LIKE에서 앞에 와일드카드 사용
SELECT * FROM users WHERE name LIKE '%홍%'; -- 인덱스 미사용
SELECT * FROM users WHERE name LIKE '홍%';  -- 인덱스 사용 가능

-- 4. OR 조건 (인덱스가 각각 있어도 비효율적일 수 있음)
SELECT * FROM users WHERE name = '홍길동' OR age = 30;
```

---

## 7. 복합 인덱스 & 커버링 인덱스

### 7-1. 복합 인덱스 (Composite Index)

2개 이상의 컬럼을 묶어 생성한 인덱스다.
컬럼 순서가 매우 중요하며, 선두 컬럼부터 순서대로 사용해야 효과적이다.

```sql
-- 복합 인덱스 생성: (last_name, first_name, age) 순서
CREATE INDEX idx_name_age ON users(last_name, first_name, age);

-- 효과적인 사용 (선두 컬럼 포함)
SELECT * FROM users WHERE last_name = '홍';                          -- 사용
SELECT * FROM users WHERE last_name = '홍' AND first_name = '길동';  -- 사용
SELECT * FROM users WHERE last_name = '홍' AND age = 30;             -- 부분 사용

-- 비효율적 사용 (선두 컬럼 미포함)
SELECT * FROM users WHERE first_name = '길동';  -- 인덱스 미사용
SELECT * FROM users WHERE age = 30;             -- 인덱스 미사용
```

### 7-2. 커버링 인덱스 (Covering Index)

쿼리에 필요한 모든 컬럼이 인덱스에 포함되어 있어
실제 테이블 데이터에 접근하지 않고 인덱스만으로 쿼리를 처리할 수 있는 인덱스다.

```sql
-- users 테이블: id, name, email, age, address, ...

-- 커버링 인덱스 생성
CREATE INDEX idx_covering ON users(email, name, age);

-- 다음 쿼리는 인덱스만으로 처리 가능 (테이블 접근 불필요)
SELECT email, name, age FROM users WHERE email = 'test@example.com';

-- EXPLAIN 결과에서 "Using index" 확인 가능 (MySQL)
EXPLAIN SELECT email, name, age FROM users WHERE email = 'test@example.com';
```

---

## 8. 면접 포인트

### Q1. ACID란 무엇인가?
> ACID는 트랜잭션의 신뢰성을 보장하는 4가지 속성이다.
> 원자성(Atomicity)은 모두 성공하거나 모두 실패, 일관성(Consistency)은 규칙 항상 유지,
> 격리성(Isolation)은 트랜잭션 간 독립 실행, 지속성(Durability)은 커밋 후 영구 보존이다.

### Q2. 트랜잭션 격리 수준 4가지를 설명하라.
> Read Uncommitted(미커밋 읽기 허용), Read Committed(커밋 데이터만 읽기, Oracle 기본),
> Repeatable Read(반복 읽기 보장, MySQL 기본), Serializable(완전 직렬화)이며
> 격리 수준이 높을수록 동시성은 낮아진다.

### Q3. Dirty Read, Non-Repeatable Read, Phantom Read의 차이는?
> - **Dirty Read**: 커밋되지 않은 데이터를 읽는 문제
> - **Non-Repeatable Read**: 같은 트랜잭션 내에서 같은 행을 두 번 읽었을 때 값이 달라지는 문제
> - **Phantom Read**: 같은 조건으로 조회 시 없던 행이 생기거나 있던 행이 사라지는 문제

### Q4. 정규화의 목적과 단계를 설명하라.
> 정규화는 데이터 중복 제거와 무결성 보장이 목적이다.
> 1NF는 원자값 보장, 2NF는 부분 함수 종속 제거, 3NF는 이행 함수 종속 제거,
> BCNF는 모든 결정자가 후보키임을 보장한다.

### Q5. 인덱스를 어떤 컬럼에 걸어야 하는가?
> 카디널리티(유니크한 값의 수)가 높은 컬럼, WHERE/JOIN/ORDER BY에 자주 사용되는 컬럼에
> 인덱스를 걸면 효과적이다. 반면 카디널리티가 낮은 컬럼(성별 등)이나 자주 변경되는 컬럼에는
> 인덱스가 오히려 성능을 저하시킬 수 있다.

### Q6. 복합 인덱스에서 컬럼 순서가 중요한 이유는?
> B-Tree 인덱스는 선두 컬럼부터 정렬되어 있기 때문에, 선두 컬럼을 포함하지 않는 조건에서는
> 인덱스를 효과적으로 활용할 수 없다. 따라서 가장 선택도가 높고 자주 사용되는 컬럼을
> 앞에 배치해야 한다.

### Q7. 역정규화는 언제 사용하는가?
> 조회 성능이 중요하고 JOIN이 과도하게 발생하는 경우, 읽기 비율이 압도적으로 높은 경우에
> 역정규화를 고려한다. 단, 데이터 중복과 일관성 유지 비용을 감수해야 한다.
