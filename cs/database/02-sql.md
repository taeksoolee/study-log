# 2. SQL

## 목차
1. SELECT 기본 문법
2. JOIN
3. GROUP BY와 집계 함수
4. 서브쿼리(Subquery)
5. 윈도우 함수(Window Function)
6. WITH 절 (CTE)
7. 실용적인 쿼리 예시
8. 면접 포인트

---

## 예시 테이블 정의

이 문서의 예시는 아래 테이블 구조를 기반으로 한다.

```sql
-- 직원 테이블
CREATE TABLE employees (
    id          INT PRIMARY KEY,
    name        VARCHAR(50),
    department  VARCHAR(50),
    salary      INT,
    manager_id  INT,
    hire_date   DATE
);

-- 부서 테이블
CREATE TABLE departments (
    id    INT PRIMARY KEY,
    name  VARCHAR(50),
    city  VARCHAR(50)
);

-- 주문 테이블
CREATE TABLE orders (
    id          INT PRIMARY KEY,
    customer_id INT,
    product_id  INT,
    amount      INT,
    order_date  DATE
);
```

---

## 1. SELECT 기본 문법

SELECT는 데이터베이스에서 데이터를 조회하는 가장 기본적인 명령이다.

### 1-1. 기본 구조

```sql
SELECT 컬럼1, 컬럼2, ...
FROM 테이블명
WHERE 조건
ORDER BY 컬럼 [ASC|DESC]
LIMIT 개수 OFFSET 시작위치;
```

### 1-2. WHERE 조건

```sql
-- 비교 연산자
SELECT * FROM employees WHERE salary > 50000;
SELECT * FROM employees WHERE salary BETWEEN 40000 AND 70000;

-- 문자열 조건
SELECT * FROM employees WHERE name LIKE '김%';      -- 김으로 시작
SELECT * FROM employees WHERE name LIKE '%수';      -- 수로 끝남
SELECT * FROM employees WHERE name LIKE '%철%';     -- 철 포함

-- NULL 처리
SELECT * FROM employees WHERE manager_id IS NULL;
SELECT * FROM employees WHERE manager_id IS NOT NULL;

-- IN 조건
SELECT * FROM employees WHERE department IN ('개발', '기획', '디자인');

-- 복합 조건
SELECT * FROM employees
WHERE department = '개발' AND salary >= 60000;

SELECT * FROM employees
WHERE department = '개발' OR department = '기획';
```

### 1-3. ORDER BY와 LIMIT

```sql
-- 급여 내림차순 정렬
SELECT name, salary
FROM employees
ORDER BY salary DESC;

-- 다중 정렬: 부서 오름차순, 급여 내림차순
SELECT name, department, salary
FROM employees
ORDER BY department ASC, salary DESC;

-- 상위 5명
SELECT name, salary
FROM employees
ORDER BY salary DESC
LIMIT 5;

-- 6번째부터 10번째 (페이지네이션)
SELECT name, salary
FROM employees
ORDER BY salary DESC
LIMIT 5 OFFSET 5;
```

### 1-4. DISTINCT와 별칭(Alias)

```sql
-- 중복 제거
SELECT DISTINCT department FROM employees;

-- 컬럼 별칭
SELECT name AS 이름, salary AS 급여
FROM employees AS e
WHERE e.salary > 50000;

-- 계산식
SELECT name, salary, salary * 1.1 AS 인상후급여
FROM employees;
```

---

## 2. JOIN

JOIN은 두 개 이상의 테이블을 연결하여 데이터를 조회하는 방법이다.

### 2-1. INNER JOIN

두 테이블에서 조건이 일치하는 행만 반환한다.

```sql
-- 직원과 부서 정보 함께 조회
SELECT e.name, e.salary, d.name AS dept_name, d.city
FROM employees e
INNER JOIN departments d ON e.department = d.name;

-- 결과: 부서 정보가 없는 직원은 제외됨
```

### 2-2. LEFT JOIN (LEFT OUTER JOIN)

왼쪽 테이블의 모든 행을 반환하고, 오른쪽 테이블은 일치하는 행만 반환한다.
일치하지 않는 경우 오른쪽 컬럼은 NULL이 된다.

```sql
-- 부서가 없는 직원도 포함하여 조회
SELECT e.name, e.salary, d.name AS dept_name
FROM employees e
LEFT JOIN departments d ON e.department = d.name;

-- 활용: 부서가 배정되지 않은 직원 찾기
SELECT e.name
FROM employees e
LEFT JOIN departments d ON e.department = d.name
WHERE d.id IS NULL;
```

### 2-3. RIGHT JOIN (RIGHT OUTER JOIN)

오른쪽 테이블의 모든 행을 반환하고, 왼쪽 테이블은 일치하는 행만 반환한다.
LEFT JOIN과 반대이며, 대부분 LEFT JOIN으로 대체해서 쓴다.

```sql
-- 직원이 없는 부서도 포함하여 조회
SELECT e.name, d.name AS dept_name
FROM employees e
RIGHT JOIN departments d ON e.department = d.name;
```

### 2-4. FULL OUTER JOIN

두 테이블의 모든 행을 반환한다. 일치하지 않는 쪽은 NULL이 된다.
MySQL은 FULL OUTER JOIN을 직접 지원하지 않으므로 UNION으로 구현한다.

```sql
-- PostgreSQL
SELECT e.name, d.name AS dept_name
FROM employees e
FULL OUTER JOIN departments d ON e.department = d.name;

-- MySQL (UNION으로 구현)
SELECT e.name, d.name AS dept_name
FROM employees e
LEFT JOIN departments d ON e.department = d.name
UNION
SELECT e.name, d.name AS dept_name
FROM employees e
RIGHT JOIN departments d ON e.department = d.name;
```

### 2-5. CROSS JOIN

두 테이블의 모든 행 조합을 반환한다 (카티션 곱).
n행 × m행 = n*m행이 결과로 나온다.

```sql
-- 모든 직원과 부서의 조합
SELECT e.name, d.name AS dept_name
FROM employees e
CROSS JOIN departments d;

-- 날짜 시퀀스 생성 등 특수 목적에 활용
```

### 2-6. Self JOIN

같은 테이블을 두 번 JOIN하는 방법이다. 계층 구조 조회에 자주 사용된다.

```sql
-- 직원과 그 매니저 이름을 함께 조회
SELECT e.name AS 직원명, m.name AS 매니저명
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.id;
```

---

## 3. GROUP BY와 집계 함수

GROUP BY는 특정 컬럼을 기준으로 행을 그룹화하고, 집계 함수로 요약 데이터를 계산한다.

### 3-1. 집계 함수

```sql
-- COUNT: 행 수 세기
SELECT COUNT(*) AS 전체직원수 FROM employees;
SELECT COUNT(manager_id) AS 매니저있는직원수 FROM employees; -- NULL 제외

-- SUM: 합계
SELECT SUM(salary) AS 급여총합 FROM employees;

-- AVG: 평균
SELECT AVG(salary) AS 평균급여 FROM employees;

-- MIN, MAX: 최솟값, 최댓값
SELECT MIN(salary) AS 최소급여, MAX(salary) AS 최대급여 FROM employees;
```

### 3-2. GROUP BY 기본

```sql
-- 부서별 직원 수와 평균 급여
SELECT
    department,
    COUNT(*) AS 직원수,
    AVG(salary) AS 평균급여,
    MAX(salary) AS 최고급여
FROM employees
GROUP BY department;

-- 부서, 입사연도별 그룹화
SELECT
    department,
    YEAR(hire_date) AS 입사년도,
    COUNT(*) AS 직원수
FROM employees
GROUP BY department, YEAR(hire_date)
ORDER BY department, 입사년도;
```

### 3-3. HAVING

GROUP BY 이후 그룹에 대한 조건을 지정한다.
WHERE는 행 단위 필터, HAVING은 그룹 단위 필터다.

```sql
-- 직원이 5명 이상인 부서만 조회
SELECT department, COUNT(*) AS 직원수
FROM employees
GROUP BY department
HAVING COUNT(*) >= 5;

-- 평균 급여가 60000 이상인 부서
SELECT department, AVG(salary) AS 평균급여
FROM employees
GROUP BY department
HAVING AVG(salary) >= 60000
ORDER BY 평균급여 DESC;

-- WHERE와 HAVING 함께 사용
-- 2020년 이후 입사자 중 부서별 집계
SELECT department, COUNT(*) AS 직원수, AVG(salary) AS 평균급여
FROM employees
WHERE hire_date >= '2020-01-01'   -- 행 필터 (GROUP BY 이전)
GROUP BY department
HAVING COUNT(*) >= 3;              -- 그룹 필터 (GROUP BY 이후)
```

---

## 4. 서브쿼리(Subquery)

서브쿼리는 다른 쿼리 안에 포함된 SELECT 문이다.

### 4-1. 스칼라 서브쿼리

단일 값(1행 1열)을 반환하는 서브쿼리로, SELECT 절에 주로 사용된다.

```sql
-- 각 직원의 급여와 전체 평균 급여를 함께 조회
SELECT
    name,
    salary,
    (SELECT AVG(salary) FROM employees) AS 전체평균급여,
    salary - (SELECT AVG(salary) FROM employees) AS 평균과의차이
FROM employees;
```

### 4-2. 인라인 뷰(Inline View)

FROM 절에 사용되는 서브쿼리다. 가상의 테이블로 취급된다.

```sql
-- 부서별 평균 급여보다 높은 급여를 받는 직원 조회
SELECT e.name, e.department, e.salary, dept_avg.평균급여
FROM employees e
JOIN (
    SELECT department, AVG(salary) AS 평균급여
    FROM employees
    GROUP BY department
) AS dept_avg ON e.department = dept_avg.department
WHERE e.salary > dept_avg.평균급여;
```

### 4-3. 중첩 서브쿼리

WHERE 절에 사용되는 서브쿼리다.

```sql
-- 가장 높은 급여를 받는 직원 조회
SELECT name, salary
FROM employees
WHERE salary = (SELECT MAX(salary) FROM employees);

-- IN을 사용한 서브쿼리: 개발 부서 직원의 주문 조회
SELECT *
FROM orders
WHERE customer_id IN (
    SELECT id FROM employees WHERE department = '개발'
);

-- EXISTS: 주문이 있는 직원 조회
SELECT name
FROM employees e
WHERE EXISTS (
    SELECT 1 FROM orders o WHERE o.customer_id = e.id
);

-- NOT EXISTS: 주문이 없는 직원 조회
SELECT name
FROM employees e
WHERE NOT EXISTS (
    SELECT 1 FROM orders o WHERE o.customer_id = e.id
);
```

### 4-4. 상관 서브쿼리(Correlated Subquery)

외부 쿼리의 값을 참조하는 서브쿼리다. 행마다 서브쿼리가 실행되므로 성능에 주의해야 한다.

```sql
-- 같은 부서 내에서 평균 급여보다 높은 급여를 받는 직원
SELECT name, department, salary
FROM employees e1
WHERE salary > (
    SELECT AVG(salary)
    FROM employees e2
    WHERE e2.department = e1.department  -- 외부 쿼리 참조
);
```

---

## 5. 윈도우 함수(Window Function)

윈도우 함수는 현재 행과 관련된 행들의 집합(윈도우)에 대해 계산을 수행한다.
GROUP BY와 달리 행을 그룹화하지 않으므로 원본 행이 그대로 유지된다.

```sql
함수명() OVER (
    [PARTITION BY 컬럼]   -- 그룹 기준
    [ORDER BY 컬럼]       -- 정렬 기준
    [ROWS/RANGE 프레임]   -- 범위 지정 (선택)
)
```

### 5-1. ROW_NUMBER

각 행에 순번을 부여한다. 동일 값이 있어도 고유한 번호를 부여한다.

```sql
-- 부서별로 급여 순위 부여
SELECT
    name,
    department,
    salary,
    ROW_NUMBER() OVER (PARTITION BY department ORDER BY salary DESC) AS 부서내순위
FROM employees;
```

### 5-2. RANK와 DENSE_RANK

동일 값에 같은 순위를 부여한다.
- **RANK**: 동점 처리 후 다음 순위를 건너뜀 (1, 2, 2, 4)
- **DENSE_RANK**: 동점 처리 후 연속된 순위 부여 (1, 2, 2, 3)

```sql
SELECT
    name,
    salary,
    RANK()       OVER (ORDER BY salary DESC) AS rank_순위,
    DENSE_RANK() OVER (ORDER BY salary DESC) AS dense_순위,
    ROW_NUMBER() OVER (ORDER BY salary DESC) AS row_순위
FROM employees;

-- 결과 예시:
-- name    salary  rank_순위  dense_순위  row_순위
-- 홍길동   90000   1          1           1
-- 이순신   80000   2          2           2
-- 강감찬   80000   2          2           3
-- 유관순   70000   4          3           4
```

### 5-3. LAG와 LEAD

현재 행 기준으로 이전(LAG) 또는 다음(LEAD) 행의 값을 가져온다.

```sql
-- 직원의 현재 급여, 이전 입사자 급여, 다음 입사자 급여 조회
SELECT
    name,
    hire_date,
    salary,
    LAG(salary, 1, 0)  OVER (ORDER BY hire_date) AS 이전입사자급여,
    LEAD(salary, 1, 0) OVER (ORDER BY hire_date) AS 다음입사자급여
FROM employees;

-- 월별 주문액과 전월 대비 증감 계산
SELECT
    order_date,
    monthly_amount,
    LAG(monthly_amount) OVER (ORDER BY order_date) AS 전월금액,
    monthly_amount - LAG(monthly_amount) OVER (ORDER BY order_date) AS 전월대비증감
FROM (
    SELECT DATE_FORMAT(order_date, '%Y-%m') AS order_date,
           SUM(amount) AS monthly_amount
    FROM orders
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
) monthly;
```

### 5-4. SUM OVER (누적 합계)

```sql
-- 입사일 순서로 누적 급여 계산
SELECT
    name,
    hire_date,
    salary,
    SUM(salary) OVER (ORDER BY hire_date) AS 누적급여합,
    SUM(salary) OVER (PARTITION BY department ORDER BY hire_date) AS 부서내누적급여
FROM employees;

-- 파티션 전체 합계 (비율 계산에 활용)
SELECT
    name,
    department,
    salary,
    SUM(salary) OVER (PARTITION BY department) AS 부서급여합계,
    ROUND(salary * 100.0 / SUM(salary) OVER (PARTITION BY department), 2) AS 부서내비율
FROM employees;
```

### 5-5. NTILE

행을 N개의 그룹으로 나눈다.

```sql
-- 급여 기준 4분위로 나누기
SELECT
    name,
    salary,
    NTILE(4) OVER (ORDER BY salary DESC) AS 급여분위
FROM employees;
```

---

## 6. WITH 절 (CTE, Common Table Expression)

CTE는 쿼리 내에서 재사용 가능한 임시 결과 집합을 정의한다.
복잡한 쿼리를 가독성 좋게 분리할 수 있다.

### 6-1. 기본 CTE

```sql
-- 부서별 평균 급여를 CTE로 정의
WITH dept_avg AS (
    SELECT department, AVG(salary) AS avg_salary
    FROM employees
    GROUP BY department
)
SELECT e.name, e.department, e.salary, d.avg_salary
FROM employees e
JOIN dept_avg d ON e.department = d.department
WHERE e.salary > d.avg_salary;
```

### 6-2. 여러 CTE 정의

```sql
WITH
high_salary AS (
    SELECT * FROM employees WHERE salary >= 70000
),
dev_dept AS (
    SELECT * FROM employees WHERE department = '개발'
)
-- 고급여 개발자 조회
SELECT name, salary
FROM employees
WHERE id IN (SELECT id FROM high_salary)
  AND id IN (SELECT id FROM dev_dept);
```

### 6-3. 재귀 CTE

계층 구조 데이터를 처리할 때 활용된다.

```sql
-- 조직도 계층 구조 조회 (매니저 -> 직원)
WITH RECURSIVE org_chart AS (
    -- 앵커: 최상위 관리자 (manager_id가 없는 사람)
    SELECT id, name, manager_id, 0 AS depth
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    -- 재귀: 하위 직원 탐색
    SELECT e.id, e.name, e.manager_id, oc.depth + 1
    FROM employees e
    JOIN org_chart oc ON e.manager_id = oc.id
)
SELECT
    REPEAT('  ', depth) || name AS 조직도,
    depth AS 레벨
FROM org_chart
ORDER BY depth, name;
```

---

## 7. 실용적인 쿼리 예시

### 7-1. Top N per Group (그룹별 상위 N개)

```sql
-- 부서별 급여 상위 2명 조회
WITH ranked AS (
    SELECT
        name,
        department,
        salary,
        ROW_NUMBER() OVER (PARTITION BY department ORDER BY salary DESC) AS rn
    FROM employees
)
SELECT name, department, salary
FROM ranked
WHERE rn <= 2;
```

### 7-2. 중복 데이터 제거

```sql
-- 이메일 기준 중복 직원 중 가장 최근 입사자만 남기기
WITH deduped AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY email ORDER BY hire_date DESC) AS rn
    FROM employees
)
SELECT * FROM deduped WHERE rn = 1;
```

### 7-3. 날짜 범위 집계

```sql
-- 최근 30일간 일별 주문 수와 주문액
SELECT
    DATE(order_date) AS 날짜,
    COUNT(*) AS 주문건수,
    SUM(amount) AS 주문금액,
    AVG(amount) AS 평균주문금액
FROM orders
WHERE order_date >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY DATE(order_date)
ORDER BY 날짜;
```

### 7-4. PIVOT (행을 열로 변환)

```sql
-- 부서별, 연도별 직원 수를 열로 나열
SELECT
    department,
    COUNT(CASE WHEN YEAR(hire_date) = 2022 THEN 1 END) AS '2022년',
    COUNT(CASE WHEN YEAR(hire_date) = 2023 THEN 1 END) AS '2023년',
    COUNT(CASE WHEN YEAR(hire_date) = 2024 THEN 1 END) AS '2024년'
FROM employees
GROUP BY department;
```

---

## 8. 면접 포인트

### Q1. INNER JOIN과 LEFT JOIN의 차이는?
> INNER JOIN은 두 테이블에서 조건이 일치하는 행만 반환한다.
> LEFT JOIN은 왼쪽 테이블의 모든 행을 반환하고, 오른쪽에 일치하는 행이 없으면 NULL로 채운다.
> 데이터 누락 없이 전체를 조회해야 할 때는 LEFT JOIN을 사용한다.

### Q2. WHERE와 HAVING의 차이는?
> WHERE는 GROUP BY 이전에 행 단위로 필터링한다.
> HAVING은 GROUP BY 이후에 그룹 단위로 필터링하며, 집계 함수를 조건으로 사용할 수 있다.
> 성능 면에서 WHERE가 먼저 실행되어 처리 데이터 양을 줄이므로, 가능하면 WHERE를 활용하는 것이 좋다.

### Q3. 서브쿼리와 JOIN 중 어느 것을 사용해야 하는가?
> 일반적으로 JOIN이 서브쿼리보다 성능이 좋다. 옵티마이저가 JOIN을 더 효율적으로 최적화하기 때문이다.
> 하지만 EXISTS를 사용하는 서브쿼리는 매칭되는 첫 번째 행을 찾으면 즉시 종료되어 효율적이다.
> 가독성과 상황에 따라 적절히 선택하되, EXPLAIN으로 실행 계획을 확인하는 것이 좋다.

### Q4. RANK와 DENSE_RANK의 차이는?
> 동점이 있을 때 RANK는 그 다음 순위를 건너뛴다 (1, 2, 2, 4).
> DENSE_RANK는 건너뜀 없이 연속된 순위를 부여한다 (1, 2, 2, 3).
> 순위를 이용해 상위 N명을 뽑을 때 RANK를 쓰면 동점자 다음 순위가 달라질 수 있어 주의해야 한다.

### Q5. 윈도우 함수와 GROUP BY의 차이는?
> GROUP BY는 행을 그룹화하여 각 그룹에 하나의 결과 행을 반환한다. 원본 행 정보가 사라진다.
> 윈도우 함수는 행을 그룹화하지 않고 원본 행을 유지하면서, 각 행마다 지정된 범위에 대한 집계값을 계산한다.
> "각 직원의 급여와 그 직원이 속한 부서의 평균 급여를 함께 보여줘"와 같은 요구에 윈도우 함수가 적합하다.

### Q6. CTE(WITH 절)를 사용하는 이점은?
> 복잡한 서브쿼리를 이름 붙여 분리함으로써 쿼리 가독성을 높인다.
> 같은 서브쿼리를 여러 번 참조할 때 재사용할 수 있다.
> 재귀 CTE를 통해 계층 구조 데이터 처리도 가능하다.
> 단, 일부 RDBMS에서 CTE는 인라인 뷰와 달리 최적화가 제한될 수 있어 성능 차이가 있을 수 있다.

### Q7. 쿼리 실행 순서(논리적 처리 순서)는?
> FROM -> JOIN -> WHERE -> GROUP BY -> HAVING -> SELECT -> DISTINCT -> ORDER BY -> LIMIT
> SELECT에서 정의한 별칭(alias)을 WHERE에서 사용할 수 없는 이유가 바로 이 실행 순서 때문이다.
> (SELECT가 WHERE보다 나중에 처리됨)

### Q8. NULL 처리 시 주의할 점은?
> NULL은 비교 연산자(=, !=)로 비교할 수 없고 반드시 IS NULL / IS NOT NULL을 사용해야 한다.
> 집계 함수(COUNT 제외)는 NULL을 무시한다. COUNT(*)는 NULL 포함, COUNT(컬럼)은 NULL 제외다.
> NULL이 포함된 연산의 결과는 항상 NULL이므로 COALESCE나 IFNULL로 기본값을 처리해야 한다.
