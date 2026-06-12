# 7. 백트래킹 (Backtracking)

## 목차
1. 백트래킹 개념
2. 백트래킹 vs DFS 차이
3. 백트래킹 템플릿
4. 순열 (Permutations)
5. 조합 (Combinations)
6. 부분 집합 (Subsets)
7. N-Queens 문제
8. 시간복잡도 분석
9. 면접 포인트

---

## 1. 백트래킹 개념

백트래킹(Backtracking)은 결정 트리(Decision Tree)를 탐색하면서 해를 구성해 나가되, **유망하지 않은(promising) 경로는 일찍 포기**하고 되돌아오는 탐색 기법이다.

### 핵심 아이디어

```
선택 → 탐색 → 실패 시 선택 취소(Undo) → 다른 선택 시도
```

### 결정 트리 예시 (순열 [1,2,3])

```
                  []
         /         |         \
       [1]        [2]        [3]
      /   \      /   \      /   \
   [1,2] [1,3] [2,1] [2,3] [3,1] [3,2]
    |      |     |     |     |     |
[1,2,3] [1,3,2] ... ... ... ...
```

### 가지치기 (Pruning)

백트래킹의 핵심은 **유망 함수(Promising Function)**다.

- 유망(Promising): 현재 경로에서 해가 존재할 가능성이 있음
- 비유망(Non-promising): 현재 경로에서 절대 해가 나올 수 없음 → **즉시 가지치기**

```
가지치기 없는 완전 탐색:  모든 경우의 수 탐색 (Brute Force)
가지치기 있는 백트래킹:   불필요한 경로 조기 차단 → 실질적으로 훨씬 빠름
```

---

## 2. 백트래킹 vs DFS 차이

백트래킹은 DFS를 기반으로 하지만 목적과 사용 방식이 다르다.

| 항목 | DFS | 백트래킹 |
|------|-----|---------|
| 목적 | 그래프/트리의 모든 노드 방문 | 조건을 만족하는 해 탐색 |
| 탐색 공간 | 명시적 그래프/트리 | 암묵적 상태 공간 트리 |
| 가지치기 | 없음 | 있음 (유망 함수) |
| 상태 복원 | 방문 여부만 관리 | 선택을 취소(Undo)하며 상태 복원 |
| 사용 예 | 연결 요소, 경로 탐색 | 순열, 조합, 제약 만족 문제 |

```javascript
// DFS - 방문 여부만 체크, 상태 복원 없음
function dfs(graph, node, visited) {
  visited.add(node);
  for (const neighbor of graph[node]) {
    if (!visited.has(neighbor)) {
      dfs(graph, neighbor, visited);
    }
  }
}

// 백트래킹 - 선택 후 복원, 유망 함수 포함
function backtrack(state) {
  if (isGoal(state)) {
    recordSolution(state);
    return;
  }
  for (const choice of getChoices(state)) {
    if (isPromising(state, choice)) {   // 가지치기
      makeChoice(state, choice);        // 선택
      backtrack(state);                 // 탐색
      undoChoice(state, choice);        // 복원 (핵심!)
    }
  }
}
```

---

## 3. 백트래킹 템플릿

모든 백트래킹 문제에 적용할 수 있는 범용 템플릿이다.

```javascript
/**
 * 백트래킹 범용 템플릿
 *
 * @param {Array} result      - 최종 결과를 저장하는 배열
 * @param {Array} current     - 현재 구성 중인 해 (경로)
 * @param {*}     startOrState - 탐색 시작 위치 또는 현재 상태
 * @param {Array} candidates  - 선택 가능한 후보들
 */
function backtrack(result, current, startOrState, candidates) {
  // ① 종료 조건 (기저 사례): 해를 완성했으면 결과에 추가
  if (isComplete(current)) {
    result.push([...current]); // 복사본 저장 (참조 주의!)
    return;
  }

  // ② 선택 목록 순회
  for (let i = startOrState; i < candidates.length; i++) {
    const choice = candidates[i];

    // ③ 가지치기: 유망하지 않으면 건너뜀
    if (!isPromising(current, choice)) continue;

    // ④ 선택: 현재 후보를 경로에 추가
    current.push(choice);

    // ⑤ 재귀 탐색
    backtrack(result, current, i + 1, candidates);

    // ⑥ 복원: 선택 취소 (Undo)
    current.pop();
  }
}

// 사용 예시
const result = [];
backtrack(result, [], 0, [1, 2, 3, 4]);
```

### 상태 복원 패턴

```javascript
// 배열 원소 추가/제거
current.push(choice);   // 선택
backtrack(...);
current.pop();          // 복원

// 방문 여부 토글
visited[i] = true;      // 선택
backtrack(...);
visited[i] = false;     // 복원

// 집합에 추가/제거
set.add(choice);        // 선택
backtrack(...);
set.delete(choice);     // 복원

// 숫자 누적
sum += choice;          // 선택
backtrack(...);
sum -= choice;          // 복원
```

---

## 4. 순열 (Permutations)

n개의 원소에서 모든 순열을 구한다. 순서가 중요하며, 각 원소는 한 번만 사용한다.

### JavaScript 구현

```javascript
/**
 * 전체 순열 생성
 * @param {number[]} nums
 * @returns {number[][]}
 */
function permutations(nums) {
  const result = [];
  const visited = new Array(nums.length).fill(false);

  function backtrack(current) {
    // 종료 조건: 모든 원소를 선택했으면 결과에 추가
    if (current.length === nums.length) {
      result.push([...current]);
      return;
    }

    for (let i = 0; i < nums.length; i++) {
      // 가지치기: 이미 사용한 원소는 건너뜀
      if (visited[i]) continue;

      // 선택
      visited[i] = true;
      current.push(nums[i]);

      // 재귀
      backtrack(current);

      // 복원
      current.pop();
      visited[i] = false;
    }
  }

  backtrack([]);
  return result;
}

console.log(permutations([1, 2, 3]));
/*
[
  [1,2,3], [1,3,2],
  [2,1,3], [2,3,1],
  [3,1,2], [3,2,1]
]
*/
```

### 중복 원소가 있는 순열

```javascript
/**
 * 중복 원소가 있는 배열의 고유 순열
 * @param {number[]} nums
 * @returns {number[][]}
 */
function permutationsUnique(nums) {
  const result = [];
  const visited = new Array(nums.length).fill(false);
  nums.sort((a, b) => a - b); // 중복 처리를 위해 정렬

  function backtrack(current) {
    if (current.length === nums.length) {
      result.push([...current]);
      return;
    }

    for (let i = 0; i < nums.length; i++) {
      if (visited[i]) continue;
      // 핵심 가지치기: 같은 값의 원소는 이전 원소가 사용된 경우에만 사용
      if (i > 0 && nums[i] === nums[i - 1] && !visited[i - 1]) continue;

      visited[i] = true;
      current.push(nums[i]);
      backtrack(current);
      current.pop();
      visited[i] = false;
    }
  }

  backtrack([]);
  return result;
}

console.log(permutationsUnique([1, 1, 2]).length); // 3 ([1,1,2], [1,2,1], [2,1,1])
```

- **시간복잡도**: O(n * n!) — n!개의 순열, 각 복사에 O(n)
- **공간복잡도**: O(n) — 재귀 스택 깊이

---

## 5. 조합 (Combinations)

n개의 원소에서 k개를 선택하는 모든 조합을 구한다. 순서는 무관하다.

### JavaScript 구현

```javascript
/**
 * nCk 조합 생성
 * @param {number} n - 전체 원소 수 (1~n)
 * @param {number} k - 선택할 원소 수
 * @returns {number[][]}
 */
function combinations(n, k) {
  const result = [];

  function backtrack(start, current) {
    // 종료 조건: k개를 선택했으면 결과에 추가
    if (current.length === k) {
      result.push([...current]);
      return;
    }

    // 남은 원소 수가 부족하면 탐색 불필요 (가지치기)
    // current.length + (n - i + 1) >= k 를 만족해야 함
    for (let i = start; i <= n - (k - current.length) + 1; i++) {
      current.push(i);
      backtrack(i + 1, current);
      current.pop();
    }
  }

  backtrack(1, []);
  return result;
}

console.log(combinations(4, 2));
// [[1,2],[1,3],[1,4],[2,3],[2,4],[3,4]]
```

### 배열 원소로 조합 생성

```javascript
/**
 * 배열에서 k개를 선택하는 조합
 * @param {any[]} arr
 * @param {number} k
 * @returns {any[][]}
 */
function combinationsFromArray(arr, k) {
  const result = [];

  function backtrack(start, current) {
    if (current.length === k) {
      result.push([...current]);
      return;
    }

    for (let i = start; i < arr.length; i++) {
      current.push(arr[i]);
      backtrack(i + 1, current);
      current.pop();
    }
  }

  backtrack(0, []);
  return result;
}

console.log(combinationsFromArray(['a', 'b', 'c', 'd'], 2));
// [['a','b'],['a','c'],['a','d'],['b','c'],['b','d'],['c','d']]
```

### 조합 합 (Combination Sum) - 중복 선택 허용

```javascript
/**
 * 합이 target이 되는 조합 (원소 중복 사용 가능)
 * @param {number[]} candidates
 * @param {number} target
 * @returns {number[][]}
 */
function combinationSum(candidates, target) {
  const result = [];
  candidates.sort((a, b) => a - b);

  function backtrack(start, current, remaining) {
    if (remaining === 0) {
      result.push([...current]);
      return;
    }

    for (let i = start; i < candidates.length; i++) {
      // 가지치기: 현재 원소가 남은 합보다 크면 이후 원소도 불필요
      if (candidates[i] > remaining) break;

      current.push(candidates[i]);
      backtrack(i, current, remaining - candidates[i]); // i+1이 아닌 i (중복 허용)
      current.pop();
    }
  }

  backtrack(0, [], target);
  return result;
}

console.log(combinationSum([2, 3, 6, 7], 7));
// [[2,2,3],[7]]
```

- **시간복잡도**: O(C(n,k)) — 조합의 수
- **공간복잡도**: O(k) — 재귀 스택 깊이

---

## 6. 부분 집합 (Subsets)

n개의 원소로 만들 수 있는 모든 부분집합(멱집합)을 구한다.

### JavaScript 구현

```javascript
/**
 * 모든 부분집합 생성
 * @param {number[]} nums
 * @returns {number[][]}
 */
function subsets(nums) {
  const result = [];

  function backtrack(start, current) {
    // 매 단계에서 현재 상태를 결과에 추가 (종료 조건이 별도 없음)
    result.push([...current]);

    for (let i = start; i < nums.length; i++) {
      current.push(nums[i]);
      backtrack(i + 1, current);
      current.pop();
    }
  }

  backtrack(0, []);
  return result;
}

console.log(subsets([1, 2, 3]));
/*
[
  [],      // 공집합
  [1], [1,2], [1,2,3], [1,3],
  [2], [2,3],
  [3]
]
총 2^3 = 8개
*/
```

### 탐색 트리 시각화

```
backtrack(0, [])  → result에 [] 추가
  i=0: push(1)
  backtrack(1, [1])  → result에 [1] 추가
    i=1: push(2)
    backtrack(2, [1,2])  → result에 [1,2] 추가
      i=2: push(3)
      backtrack(3, [1,2,3])  → result에 [1,2,3] 추가
      pop(3)
    pop(2)
    i=2: push(3)
    backtrack(3, [1,3])  → result에 [1,3] 추가
    pop(3)
  pop(1)
  i=1: push(2)
  ...
```

### 중복 원소가 있는 부분집합

```javascript
/**
 * 중복 원소가 있는 배열의 고유 부분집합
 * @param {number[]} nums
 * @returns {number[][]}
 */
function subsetsUnique(nums) {
  const result = [];
  nums.sort((a, b) => a - b); // 중복 처리를 위해 정렬

  function backtrack(start, current) {
    result.push([...current]);

    for (let i = start; i < nums.length; i++) {
      // 핵심 가지치기: 같은 레벨에서 같은 값은 한 번만 선택
      if (i > start && nums[i] === nums[i - 1]) continue;

      current.push(nums[i]);
      backtrack(i + 1, current);
      current.pop();
    }
  }

  backtrack(0, []);
  return result;
}

console.log(subsetsUnique([1, 2, 2]).length); // 6 (중복 제거 후)
```

- **시간복잡도**: O(n * 2^n) — 2^n개의 부분집합, 각 복사에 O(n)
- **공간복잡도**: O(n) — 재귀 스택 깊이

---

## 7. N-Queens 문제

N×N 체스판에 N개의 퀸을 서로 공격하지 못하도록 배치하는 모든 경우를 구한다.

### 유망 함수 (Promising Function)

퀸은 같은 행, 열, 대각선에 있으면 서로 공격할 수 있다.

```
같은 열:     col[i] === col[j]
같은 대각선:  |row[i] - row[j]| === |col[i] - col[j]|
같은 행:     한 행에 하나씩 배치하므로 자동으로 해결됨
```

### JavaScript 구현

```javascript
/**
 * N-Queens 문제 풀이
 * @param {number} n
 * @returns {string[][]} 체스판 배열 목록
 */
function solveNQueens(n) {
  const result = [];
  const queens = []; // queens[row] = col: row행에 퀸이 배치된 열

  /**
   * 유망 함수: 현재 행(row)에 col열로 퀸을 놓을 수 있는지 확인
   */
  function isPromising(row, col) {
    for (let prevRow = 0; prevRow < row; prevRow++) {
      const prevCol = queens[prevRow];
      // 같은 열 또는 같은 대각선인지 확인
      if (prevCol === col || Math.abs(prevRow - row) === Math.abs(prevCol - col)) {
        return false;
      }
    }
    return true;
  }

  /**
   * 현재 queens 배열로 체스판 문자열 생성
   */
  function buildBoard() {
    return queens.map(col => {
      const row = '.'.repeat(n).split('');
      row[col] = 'Q';
      return row.join('');
    });
  }

  function backtrack(row) {
    // 종료 조건: 모든 행에 퀸을 배치했으면 결과 추가
    if (row === n) {
      result.push(buildBoard());
      return;
    }

    // 현재 행의 각 열에 퀸을 놓아보기
    for (let col = 0; col < n; col++) {
      // 가지치기: 유망하지 않으면 건너뜀
      if (!isPromising(row, col)) continue;

      // 선택: row행 col열에 퀸 배치
      queens.push(col);

      // 재귀: 다음 행 탐색
      backtrack(row + 1);

      // 복원: 퀸 제거
      queens.pop();
    }
  }

  backtrack(0);
  return result;
}

// 4-Queens 실행
const solutions = solveNQueens(4);
console.log(`4-Queens 해의 수: ${solutions.length}`); // 2
solutions.forEach(board => {
  console.log(board.join('\n'));
  console.log('---');
});
/*
.Q..
...Q
Q...
..Q.
---
..Q.
Q...
...Q
.Q..
*/
```

### 최적화: 비트마스크 활용

```javascript
/**
 * 비트마스크를 활용한 N-Queens (빠른 버전)
 * @param {number} n
 * @returns {number} 해의 개수
 */
function totalNQueens(n) {
  let count = 0;
  const fullMask = (1 << n) - 1; // n개의 비트가 모두 1인 마스크

  /**
   * @param {number} cols      - 이미 퀸이 있는 열 비트마스크
   * @param {number} diag1     - 우하향 대각선 비트마스크 (\방향)
   * @param {number} diag2     - 좌하향 대각선 비트마스크 (/방향)
   */
  function backtrack(cols, diag1, diag2) {
    if (cols === fullMask) {
      count++;
      return;
    }

    // 놓을 수 있는 위치: 세 마스크의 합집합의 여집합
    let available = fullMask & ~(cols | diag1 | diag2);

    while (available) {
      const pos = available & (-available); // 가장 낮은 비트 추출
      available &= available - 1;           // 해당 비트 제거

      backtrack(
        cols | pos,
        (diag1 | pos) << 1,  // 우하향 대각선은 오른쪽으로 이동
        (diag2 | pos) >> 1   // 좌하향 대각선은 왼쪽으로 이동
      );
    }
  }

  backtrack(0, 0, 0);
  return count;
}

console.log(totalNQueens(8)); // 92
```

### N-Queens 해의 수

| N | 해의 수 |
|---|--------|
| 1 | 1 |
| 4 | 2 |
| 5 | 10 |
| 6 | 4 |
| 8 | 92 |
| 12 | 14200 |

---

## 8. 시간복잡도 분석

| 문제 | 시간복잡도 | 공간복잡도 | 설명 |
|------|-----------|-----------|------|
| 순열 | O(n * n!) | O(n) | n!개의 순열 * 복사 비용 O(n) |
| 조합 nCk | O(k * C(n,k)) | O(k) | C(n,k)개의 조합 * 복사 비용 O(k) |
| 부분집합 | O(n * 2^n) | O(n) | 2^n개의 집합 * 복사 비용 O(n) |
| N-Queens | O(n!) 상한 | O(n) | 가지치기로 실제로는 훨씬 빠름 |

### 가지치기 효과

```
N=8 Queens:
- 완전 탐색: 8^8 = 16,777,216
- 기본 가지치기(열만): 8! / 평균 = 훨씬 적음
- 대각선까지 가지치기: 실제로 15720번의 재귀 호출
- 비트마스크 최적화: 더욱 빠름

가지치기는 점근적 복잡도는 동일해도
실제 상수 계수를 크게 줄임
```

---

## 9. 면접 포인트

### Q1. 백트래킹의 핵심 원리는 무엇인가요?

> 백트래킹은 가능성이 있는 경로를 DFS로 탐색하면서, **유망하지 않다고 판단되면 즉시 탐색을 중단**하고 이전 상태로 돌아가는 기법입니다. "선택 → 탐색 → 선택 취소"의 패턴을 반복하며, 핵심은 상태를 온전히 **복원(Undo)**하는 것입니다.

### Q2. 백트래킹과 DFS의 차이는 무엇인가요?

> DFS는 그래프/트리에서 **모든 노드를 방문**하는 것이 목적이고, 가지치기가 없습니다. 백트래킹은 **조건을 만족하는 해를 탐색**하는 것이 목적이며, 유망 함수로 불필요한 경로를 가지치기합니다. 또한 백트래킹은 선택을 취소하는 "복원" 단계가 필수입니다.

### Q3. 순열과 조합 구현의 핵심 차이는 무엇인가요?

> - **순열**: `visited` 배열로 이미 사용한 원소를 추적. 매 재귀에서 인덱스 0부터 시작 → 순서 고려
> - **조합**: `start` 변수로 이미 고려한 원소 이전으로 돌아가지 않음 → 순서 무관, 중복 방지
>
> 핵심: 조합은 `backtrack(i+1, ...)`처럼 다음 시작 인덱스를 넘겨 순서가 정해진 선택만 허용합니다.

### Q4. `result.push([...current])`에서 왜 스프레드 연산자를 사용하나요?

> `current`는 탐색 과정에서 계속 변경되는 **단일 배열 참조**입니다. 참조를 그대로 저장하면 나중에 `pop()`으로 내용이 바뀔 때 result에 이미 저장된 항목도 함께 변경됩니다. `[...current]`는 **얕은 복사본**을 만들어 그 시점의 상태를 보존합니다.

```javascript
// 버그 있는 코드
result.push(current);    // current의 참조를 저장 → 나중에 변경됨

// 올바른 코드
result.push([...current]); // 현재 상태의 복사본 저장
```

### Q5. 중복 원소가 있을 때 고유한 조합/순열을 구하는 방법은?

> 1. 배열을 **정렬**하여 같은 값을 인접하게 만든다
> 2. 같은 재귀 레벨에서 이전 원소와 같은 값이면 건너뛴다
>
> ```javascript
> // 조합/부분집합에서
> if (i > start && nums[i] === nums[i - 1]) continue;
>
> // 순열에서
> if (i > 0 && nums[i] === nums[i - 1] && !visited[i - 1]) continue;
> ```

### Q6. N-Queens에서 유망 함수를 어떻게 최적화할 수 있나요?

> 기본 구현은 매번 이전 모든 행을 검사하여 O(n)이 걸립니다. 비트마스크를 사용하면 열, 두 대각선 방향을 각각 하나의 정수로 표현하고, 비트 연산으로 O(1)에 가능 위치를 계산할 수 있습니다.
>
> ```javascript
> // 놓을 수 있는 위치를 O(1)로 계산
> let available = fullMask & ~(cols | diag1 | diag2);
> ```

### Q7. 백트래킹 문제를 풀 때 체크리스트는?

> 1. **상태 정의**: 현재 구성 중인 해를 어떻게 표현할지
> 2. **종료 조건**: 언제 결과를 저장하고 리턴할지
> 3. **선택 목록**: 현재 상태에서 고려할 후보는 무엇인지
> 4. **유망 함수**: 어떤 조건이면 가지치기할지
> 5. **복원**: 선택 후 어떤 상태를 되돌려야 하는지

---

## 핵심 정리

```
백트래킹 = DFS + 가지치기 + 상태 복원

템플릿:
  backtrack(state):
    if 종료조건: result.push(...); return
    for choice in 선택목록:
      if not 유망: continue       ← 가지치기
      makeChoice(state, choice)   ← 선택
      backtrack(state)            ← 재귀
      undoChoice(state, choice)   ← 복원 (핵심!)

문제별 핵심 차이:
  순열: visited 배열 + 매번 0부터 탐색
  조합: start 인덱스 + 앞 원소 재선택 금지
  부분집합: 매 단계 결과 저장 + 종료 조건 없음
  N-Queens: 유망 함수가 핵심 (열 + 대각선 충돌 검사)
```
