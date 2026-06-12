# 5. 그리디 알고리즘 (Greedy Algorithm)

## 목차
1. 그리디 개념과 조건
2. 그리디 vs DP 선택 기준
3. 그리디 정당성 증명 (교환 논증)
4. 예제 문제
   - 동전 거스름돈 (단순 그리디)
   - 회의실 배정 (Activity Selection)
   - 허프만 코딩 개념
   - Jump Game (점프 게임)
5. 면접 포인트

---

## 1. 그리디 개념과 조건

그리디(탐욕) 알고리즘은 매 순간 **현재 시점에서 가장 좋아 보이는 선택**을 반복하여 전체 최적해를 구하는 방법입니다. 미래 결과를 고려하지 않고 지역 최적(local optimum)을 선택하지만, 특정 조건을 만족하면 전역 최적(global optimum)으로 이어집니다.

### 그리디 적용 필수 조건

**1. 탐욕적 선택 속성 (Greedy Choice Property)**
> 현재의 최적 선택이 이후의 선택에 영향을 주지 않으며, 매 단계의 탐욕적 선택이 전역 최적해에 포함된다.

**2. 최적 부분 구조 (Optimal Substructure)**
> 문제의 최적해가 하위 문제의 최적해로 구성된다. (DP와 공유하는 조건)

### 그리디가 실패하는 경우

```
동전 단위: [1, 3, 4], 목표: 6
그리디: 4 → 1 → 1 = 3개  (잘못된 답)
최적:   3 → 3     = 2개  (올바른 답)

→ 이 경우 탐욕적 선택 속성이 성립하지 않으므로 DP 사용
```

---

## 2. 그리디 vs DP 선택 기준

| 구분 | 그리디 | DP |
|------|--------|----|
| 선택 방식 | 현재 최적만 고려 | 모든 가능성 고려 |
| 구현 난이도 | 단순 | 복잡 |
| 시간복잡도 | 일반적으로 빠름 | 느릴 수 있음 |
| 정확성 | 조건 만족 시만 | 항상 최적 보장 |
| 증명 필요 여부 | 필수 | 점화식으로 자동 보장 |

### 판단 플로우차트

```
문제를 분석
    ↓
탐욕적 선택 속성 성립?
    ├─ YES → 그리디 적용 (증명 필수)
    └─ NO  → DP 또는 완전 탐색 고려

탐욕적 선택 속성 확인법:
  1. "매 단계 최선의 선택이 전체 최선으로 이어지는가?"
  2. 반례 찾기: 특수 케이스에서 그리디가 실패하는가?
  3. 교환 논증으로 수학적 증명
```

### 대표 그리디 문제 패턴

- **정렬 기반:** 어떤 기준으로 정렬 후 순서대로 처리
- **우선순위 큐:** 항상 최솟값/최댓값을 선택
- **구간 문제:** 끝 시간 기준 정렬 후 겹치지 않는 최대 선택

---

## 3. 그리디 정당성 증명 (교환 논증, Exchange Argument)

교환 논증은 그리디 알고리즘의 정당성을 증명하는 가장 일반적인 방법입니다.

### 증명 방법

1. 임의의 최적해 OPT가 존재한다고 가정
2. OPT에서 그리디의 첫 선택과 다른 부분을 찾음
3. 그 부분을 그리디의 선택으로 교환해도 해의 품질이 나빠지지 않음을 보임
4. 이를 반복하면 OPT를 그리디 해로 변환 가능 → 그리디 해도 최적

### 예시: Activity Selection (회의실 배정)

```
증명: "종료 시간이 가장 빠른 활동을 먼저 선택"의 정당성

최적해 OPT = [a1, a2, ..., ak] (종료 시간순 정렬됨)
그리디해  G  = [g1, g2, ..., gm]

가정: g1 ≠ a1 (그리디 첫 선택 ≠ 최적해 첫 선택)

교환: OPT에서 a1을 g1으로 교환
  - g1의 종료 시간 ≤ a1의 종료 시간 (그리디가 가장 빠른 종료 선택)
  - g1이 a1 자리에 들어가도 이후 활동들과 충돌 없음
  - 교환 후 활동 수는 동일 → 교환된 해도 최적해

이 과정을 반복하면 OPT를 G로 변환 가능
→ G도 최적해 (QED)
```

---

## 4. 예제 문제

### 4-1. 동전 거스름돈 (단순 그리디)

**전제:** 동전 단위가 배수 관계일 때 (예: 한국 동전 10, 50, 100, 500원)

```javascript
/**
 * 최소 동전 개수로 거스름돈 만들기 (배수 관계 단위)
 * @param {number[]} coins - 내림차순 정렬된 동전 단위
 * @param {number} amount  - 목표 금액
 * @return {number}        - 최소 동전 개수
 *
 * 시간복잡도: O(coins.length)
 * 공간복잡도: O(1)
 */
function minCoinsGreedy(coins, amount) {
  let count = 0;
  let remaining = amount;

  // 큰 단위 동전부터 가능한 많이 사용
  for (const coin of coins) {
    const use = Math.floor(remaining / coin);
    count += use;
    remaining -= use * coin;

    if (remaining === 0) break;
  }

  return remaining === 0 ? count : -1; // 정확히 나누어 떨어지지 않으면 -1
}

// 한국 동전 체계 (배수 관계 → 그리디 정당)
console.log(minCoinsGreedy([500, 100, 50, 10], 1260)); // 6 (500*2 + 100*2 + 50*1 + 10*1)
console.log(minCoinsGreedy([500, 100, 50, 10], 370));  // 5 (100*3 + 50*1 + 10*2)

// 주의: 임의 단위에서는 그리디 실패
// coinChange([1, 3, 4], 6) → 그리디: 3개, 최적: 2개 (DP 필요)
```

---

### 4-2. 회의실 배정 (Activity Selection Problem)

**문제:** 여러 회의의 시작/종료 시간이 주어질 때, 겹치지 않게 선택할 수 있는 최대 회의 수를 반환하라.

**핵심 아이디어:** 종료 시간이 빠른 회의를 먼저 선택 → 다음 회의를 위한 시간을 최대로 확보

```javascript
/**
 * @param {number[][]} meetings - [시작시간, 종료시간] 배열
 * @return {number}
 * 시간복잡도: O(n log n) - 정렬 지배
 * 공간복잡도: O(1)
 */
function maxMeetings(meetings) {
  // 종료 시간 기준 오름차순 정렬
  meetings.sort((a, b) => a[1] - b[1]);

  let count = 0;
  let lastEnd = -Infinity; // 마지막으로 선택한 회의의 종료 시간

  for (const [start, end] of meetings) {
    if (start >= lastEnd) { // 이전 회의가 끝난 후 시작
      count++;
      lastEnd = end;
    }
  }

  return count;
}

/**
 * 선택된 회의 목록도 반환하는 버전
 */
function activitySelection(meetings) {
  meetings.sort((a, b) => a[1] - b[1]);

  const selected = [];
  let lastEnd = -Infinity;

  for (const meeting of meetings) {
    const [start, end] = meeting;
    if (start >= lastEnd) {
      selected.push(meeting);
      lastEnd = end;
    }
  }

  return selected;
}

const meetings = [[0,6], [1,4], [3,5], [5,7], [6,9], [8,9]];
console.log(maxMeetings(meetings)); // 3

const selected = activitySelection(meetings);
console.log(selected); // [[1,4], [5,7], [8,9]]
```

---

### 4-3. 허프만 코딩 (Huffman Coding) - 개념

허프만 코딩은 빈도가 높은 문자에 짧은 비트열, 낮은 문자에 긴 비트열을 할당하여 데이터를 압축하는 그리디 알고리즘입니다.

```javascript
/**
 * 허프만 코딩 - 최소 힙 기반 구현
 * 실제 구현에서는 우선순위 큐(Min-Heap) 필요
 * 여기서는 개념 이해를 위한 단순화 버전
 *
 * 알고리즘:
 * 1. 각 문자의 빈도수로 리프 노드 생성
 * 2. 빈도가 낮은 두 노드를 꺼내 병합 (그리디 선택)
 * 3. 병합된 노드의 빈도 = 두 노드 빈도 합
 * 4. 노드가 하나 남을 때까지 반복
 */
class HuffmanNode {
  constructor(char, freq, left = null, right = null) {
    this.char = char;
    this.freq = freq;
    this.left = left;
    this.right = right;
  }
}

function buildHuffmanTree(freqMap) {
  // 우선순위 큐 시뮬레이션 (실제로는 Min-Heap 사용)
  let nodes = Object.entries(freqMap)
    .map(([char, freq]) => new HuffmanNode(char, freq));

  while (nodes.length > 1) {
    // 빈도 오름차순 정렬 (Min-Heap 역할)
    nodes.sort((a, b) => a.freq - b.freq);

    const left = nodes.shift();  // 최솟값 1
    const right = nodes.shift(); // 최솟값 2

    // 두 노드 병합 (그리디 선택)
    const merged = new HuffmanNode(null, left.freq + right.freq, left, right);
    nodes.push(merged);
  }

  return nodes[0]; // 루트 노드
}

function buildCodes(node, prefix = '', codes = {}) {
  if (!node) return;
  if (node.char !== null) {
    codes[node.char] = prefix || '0'; // 단일 문자 예외 처리
    return;
  }
  buildCodes(node.left, prefix + '0', codes);
  buildCodes(node.right, prefix + '1', codes);
  return codes;
}

// 사용 예시
const freqMap = { 'a': 5, 'b': 9, 'c': 12, 'd': 13, 'e': 16, 'f': 45 };
const root = buildHuffmanTree(freqMap);
const codes = buildCodes(root);
console.log(codes);
// f: '0', c: '100', d: '101', a: '1100', b: '1101', e: '111'
// 빈도 높은 'f'(45)에 가장 짧은 코드 '0' 할당
```

**그리디 정당성:** 빈도가 낮은 두 노드를 먼저 합치면 해당 노드들의 깊이가 깊어지므로, 긴 코드를 적게 사용하는 방향으로 최적화됩니다. 교환 논증으로 증명 가능합니다.

---

### 4-4. Jump Game (점프 게임)

**문제:** 정수 배열 `nums`에서 각 위치의 값은 최대 점프 거리를 나타낸다.
인덱스 0에서 시작하여 마지막 인덱스에 도달할 수 있는지 반환하라.

**핵심 아이디어:** 도달 가능한 최대 인덱스(`maxReach`)를 계속 갱신. 현재 위치가 maxReach를 넘으면 불가능.

```javascript
/**
 * Jump Game I - 도달 가능 여부
 * @param {number[]} nums
 * @return {boolean}
 * 시간복잡도: O(n)
 * 공간복잡도: O(1)
 */
function canJump(nums) {
  let maxReach = 0; // 현재까지 도달 가능한 최대 인덱스

  for (let i = 0; i < nums.length; i++) {
    if (i > maxReach) return false; // 현재 위치에 도달 불가

    // 현재 위치에서 점프 시 도달 가능한 최대 인덱스 갱신
    maxReach = Math.max(maxReach, i + nums[i]);

    if (maxReach >= nums.length - 1) return true; // 이미 목표 도달 가능
  }

  return true;
}

/**
 * Jump Game II - 최소 점프 횟수
 * @param {number[]} nums
 * @return {number}
 * 시간복잡도: O(n)
 * 공간복잡도: O(1)
 */
function jump(nums) {
  let jumps = 0;     // 점프 횟수
  let curEnd = 0;    // 현재 점프로 도달 가능한 범위의 끝
  let farthest = 0;  // 다음 점프로 도달 가능한 최대 인덱스

  // 마지막 인덱스는 이미 도달했으므로 제외
  for (let i = 0; i < nums.length - 1; i++) {
    farthest = Math.max(farthest, i + nums[i]);

    if (i === curEnd) {
      // 현재 범위의 끝에 도달 → 점프 실행
      jumps++;
      curEnd = farthest;

      if (curEnd >= nums.length - 1) break;
    }
  }

  return jumps;
}

// 테스트
console.log(canJump([2, 3, 1, 1, 4])); // true
console.log(canJump([3, 2, 1, 0, 4])); // false (인덱스 3에서 멈춤)

console.log(jump([2, 3, 1, 1, 4])); // 2 (0→1→4 또는 0→2→4)
console.log(jump([2, 3, 0, 1, 4])); // 2

// 시뮬레이션 (nums = [2,3,1,1,4]):
// i=0: farthest=2, i===curEnd(0) → jumps=1, curEnd=2
// i=1: farthest=max(2,4)=4
// i=2: farthest=max(4,3)=4, i===curEnd(2) → jumps=2, curEnd=4
// curEnd(4) >= 4 → break, return 2
```

---

## 5. 면접 포인트

### Q1. 그리디 알고리즘의 정당성을 어떻게 확인하나요?

두 가지 방법을 사용합니다.

1. **교환 논증(Exchange Argument):** 최적해의 일부를 그리디 선택으로 교환했을 때 해가 나빠지지 않음을 증명합니다.
2. **귀류법:** 그리디 해가 최적해가 아니라고 가정하면 모순이 발생함을 보입니다.

실무/코딩 테스트에서는 반례를 적극적으로 찾는 것이 중요합니다.

### Q2. Activity Selection에서 종료 시간으로 정렬하는 이유는?

시작 시간이 아닌 종료 시간으로 정렬해야 합니다. 이유는 종료가 빠를수록 다음 활동을 위한 **가용 시간이 최대화**되기 때문입니다. 시작 시간 기준으로 정렬하면 긴 활동이 선택되어 이후 많은 활동을 놓칠 수 있습니다.

```javascript
// 반례: 시작 시간 정렬의 실패
const meetings = [[0, 100], [1, 2], [3, 4]];
// 시작 시간 정렬: [0,100] 선택 → 1개만 가능
// 종료 시간 정렬: [1,2], [3,4] 선택 → 2개 가능 (최적)
```

### Q3. 허프만 코딩이 왜 최적 접두사 코드인가요?

허프만 코딩은 빈도가 낮은 문자를 트리의 깊은 곳(긴 코드)에, 높은 문자를 얕은 곳(짧은 코드)에 배치합니다. 어떤 다른 접두사 코드도 이보다 평균 코드 길이를 줄일 수 없음이 교환 논증으로 증명됩니다. 시간복잡도는 Min-Heap 사용 시 O(n log n)입니다.

### Q4. Jump Game에서 그리디가 성립하는 이유는?

각 위치에서 도달 가능한 최대 범위를 탐욕적으로 확장하면, 어떤 경로를 택하든 결국 도달 가능한 최대 인덱스는 동일합니다. 즉, "어디서 점프하느냐"가 아니라 "얼마나 멀리 갈 수 있느냐"만 중요하므로 탐욕적 선택이 최적해를 보장합니다.

### Q5. 코딩 테스트에서 그리디 문제를 인식하는 방법은?

다음 키워드나 패턴이 보이면 그리디를 고려합니다.
- **"최소/최대 개수"**, **"최소/최대 비용"**
- 정렬 후 순서대로 처리하면 될 것 같은 느낌
- **구간 겹침**, **회의실 배정**, **작업 스케줄링** 유형
- 항상 가장 크거나 가장 작은 것을 선택하는 패턴

반례가 떠오르지 않는다면 그리디를 시도하고, 실패하면 DP로 전환합니다.

### 핵심 그리디 문제 목록

| 문제 | 정렬 기준 | 선택 전략 |
|------|----------|----------|
| Activity Selection | 종료 시간 ↑ | 겹치지 않는 가장 빠른 것 |
| Fractional Knapsack | 단위 가치(v/w) ↓ | 가치 높은 것부터 채움 |
| Huffman Coding | 빈도수 ↑ | 가장 작은 두 노드 병합 |
| Jump Game | - | 도달 범위 최대화 |
| Task Scheduler | 빈도수 ↓ | 남은 빈도 많은 것 먼저 |
| Minimum Spanning Tree | 가중치 ↑ | 사이클 없는 최소 간선 선택 (크루스칼) |
