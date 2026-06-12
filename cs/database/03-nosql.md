# 3. NoSQL

## 목차
1. NoSQL 등장 배경
2. NoSQL 종류
3. CAP 이론
4. MongoDB 개요
5. Redis 개요
6. NoSQL vs RDBMS 비교
7. 선택 기준
8. 면접 포인트

---

## 1. NoSQL 등장 배경

2000년대 중반 이후 웹 서비스 규모가 폭발적으로 성장하면서 전통적인 RDBMS가 직면한 한계가 부각되었다.

### RDBMS의 한계
- **수직 확장(Scale-Up)의 한계**: 단일 서버 성능에 의존하므로 하드웨어 비용이 기하급수적으로 증가
- **스키마 경직성**: 데이터 구조 변경 시 마이그레이션 비용이 큼
- **비정형 데이터 처리 어려움**: JSON, 로그, 센서 데이터 등 다양한 형태의 데이터를 처리하기 부적합
- **수평 확장(Scale-Out) 제약**: 샤딩, 복제 등 분산 처리 구성이 복잡함

### NoSQL이 해결하는 문제
- 대용량 데이터의 수평 확장
- 유연한 스키마로 빠른 개발 사이클 지원
- 다양한 데이터 모델 지원 (문서, 키-값, 컬럼, 그래프)
- 높은 쓰기/읽기 처리량

> **NoSQL = "Not Only SQL"**: 관계형 DB를 완전히 대체하는 것이 아니라, 특정 사용 사례에서 더 적합한 대안을 제공한다는 의미이다.

---

## 2. NoSQL 종류

### 2-1. Document Store (문서형)
데이터를 JSON/BSON 형태의 도큐먼트로 저장한다. 계층 구조와 중첩 데이터를 자연스럽게 표현할 수 있다.

- **대표 제품**: MongoDB, CouchDB, Firestore
- **적합한 사용 사례**: 콘텐츠 관리, 사용자 프로필, 카탈로그

```json
{
  "_id": "user_001",
  "name": "홍길동",
  "email": "hong@example.com",
  "address": {
    "city": "서울",
    "district": "강남구"
  },
  "tags": ["developer", "backend"]
}
```

### 2-2. Key-Value Store (키-값형)
가장 단순한 형태로, 키에 값을 매핑하여 저장한다. 조회 속도가 매우 빠르다.

- **대표 제품**: Redis, DynamoDB, Memcached
- **적합한 사용 사례**: 세션 관리, 캐싱, 장바구니

```
SET user:session:abc123 "userId=1001"
GET user:session:abc123
```

### 2-3. Column-Family Store (컬럼형)
행(Row) 기준이 아닌 컬럼(Column) 단위로 데이터를 저장한다. 집계 쿼리에 유리하다.

- **대표 제품**: Apache Cassandra, HBase, Google Bigtable
- **적합한 사용 사례**: 시계열 데이터, 이벤트 로그, IoT 센서 데이터

### 2-4. Graph DB (그래프형)
노드(Node)와 엣지(Edge)로 데이터 간의 관계를 표현한다. 복잡한 연관 관계 탐색에 특화되어 있다.

- **대표 제품**: Neo4j, Amazon Neptune, JanusGraph
- **적합한 사용 사례**: SNS 친구 관계, 추천 시스템, 사기 탐지

---

## 3. CAP 이론

CAP 이론은 분산 데이터베이스 시스템이 다음 세 가지 속성을 **동시에 모두 보장할 수 없다**는 이론이다 (Eric Brewer, 2000).

```
        C (Consistency)
       /\
      /  \
     /    \
    /      \
   /________\
  A          P
(Availability) (Partition Tolerance)
```

### 세 가지 속성

| 속성 | 설명 |
|------|------|
| **C (Consistency, 일관성)** | 모든 노드가 동시에 같은 데이터를 읽는다. 쓰기 후 읽기는 항상 최신 값을 반환한다. |
| **A (Availability, 가용성)** | 모든 요청에 대해 응답을 반환한다. 일부 노드 장애가 있어도 서비스가 중단되지 않는다. |
| **P (Partition Tolerance, 분단 허용성)** | 네트워크 파티션(노드 간 통신 두절)이 발생해도 시스템이 계속 동작한다. |

### CAP에 따른 분류

분산 시스템에서 네트워크 파티션은 항상 발생할 수 있으므로, 실질적으로 **CP** 또는 **AP** 중 하나를 선택한다.

| 분류 | 설명 | 예시 |
|------|------|------|
| **CP** | 일관성 + 분단 허용성. 파티션 발생 시 가용성 포기(일부 요청 거절) | MongoDB, HBase, Zookeeper |
| **AP** | 가용성 + 분단 허용성. 파티션 발생 시 일관성 포기(오래된 데이터 반환 가능) | Cassandra, DynamoDB, CouchDB |
| **CA** | 일관성 + 가용성. 단일 서버에서만 실현 가능(분산 환경에서는 불가) | 전통적인 RDBMS (단일 노드) |

### PACELC 이론 (CAP의 확장)

CAP 이론의 한계를 보완한 모델이다. 파티션이 없는 정상 상태에서도 지연(Latency)과 일관성(Consistency) 사이의 트레이드오프가 존재함을 명시한다.

```
Partition 발생 시: Availability vs Consistency (CAP의 P/C)
정상 상태 시:      Latency vs Consistency
```

---

## 4. MongoDB 개요

MongoDB는 가장 널리 사용되는 Document Store로, JSON과 유사한 BSON 형식으로 데이터를 저장한다.

### 핵심 개념

| RDBMS | MongoDB |
|-------|---------|
| Database | Database |
| Table | Collection |
| Row | Document |
| Column | Field |
| JOIN | $lookup (Aggregation) |
| Index | Index |

### 4-1. 연결 및 기본 설정

```javascript
// mongoose를 사용한 Node.js 연결
const mongoose = require('mongoose');

mongoose.connect('mongodb://localhost:27017/mydb', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
});

// 스키마 정의
const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, unique: true },
  age: Number,
  createdAt: { type: Date, default: Date.now },
});

const User = mongoose.model('User', userSchema);
```

### 4-2. CRUD 예시

```javascript
// CREATE - 도큐먼트 삽입
const newUser = new User({
  name: '홍길동',
  email: 'hong@example.com',
  age: 30,
});
await newUser.save();

// 또는 insertMany 사용
await User.insertMany([
  { name: '김철수', email: 'kim@example.com', age: 25 },
  { name: '이영희', email: 'lee@example.com', age: 28 },
]);

// READ - 조회
const allUsers = await User.find();
const oneUser = await User.findOne({ email: 'hong@example.com' });
const youngUsers = await User.find({ age: { $lt: 30 } }).sort({ age: 1 });

// UPDATE - 수정
await User.updateOne(
  { email: 'hong@example.com' },
  { $set: { age: 31 } }
);

// $inc: 숫자 증감, $push: 배열에 요소 추가
await User.updateMany(
  { age: { $gte: 25 } },
  { $inc: { age: 1 } }
);

// DELETE - 삭제
await User.deleteOne({ email: 'hong@example.com' });
await User.deleteMany({ age: { $lt: 20 } });
```

### 4-3. Aggregation Pipeline

복잡한 데이터 집계를 파이프라인 형태로 처리한다.

```javascript
// 나이대별 사용자 수 집계
const result = await User.aggregate([
  { $match: { age: { $gte: 20 } } },          // 필터링
  { $group: {                                   // 그룹화
    _id: { $floor: { $divide: ['$age', 10] } },
    count: { $sum: 1 },
    avgAge: { $avg: '$age' },
  }},
  { $sort: { _id: 1 } },                       // 정렬
  { $project: {                                 // 출력 필드 지정
    decade: { $multiply: ['$_id', 10] },
    count: 1,
    avgAge: { $round: ['$avgAge', 1] },
  }},
]);
```

### 4-4. 인덱스

```javascript
// 단일 필드 인덱스
userSchema.index({ email: 1 });        // 오름차순
userSchema.index({ createdAt: -1 });   // 내림차순

// 복합 인덱스
userSchema.index({ name: 1, age: -1 });

// 텍스트 인덱스 (전문 검색)
userSchema.index({ name: 'text', bio: 'text' });

// TTL 인덱스 (자동 만료)
sessionSchema.index({ createdAt: 1 }, { expireAfterSeconds: 3600 });
```

---

## 5. Redis 개요

Redis(Remote Dictionary Server)는 인메모리(In-Memory) 기반의 Key-Value Store로, 캐싱, 세션 관리, 메시지 브로커 등 다양한 용도로 활용된다.

### 핵심 특징
- **인메모리 저장**: 디스크 I/O 없이 RAM에서 처리하여 초고속 응답 (보통 1ms 미만)
- **영속성 지원**: RDB(스냅샷) 또는 AOF(Append Only File) 방식으로 디스크에 저장 가능
- **다양한 자료구조**: String, Hash, List, Set, Sorted Set, Bitmap, HyperLogLog 등
- **Pub/Sub**: 메시지 브로커 기능 내장
- **클러스터 지원**: 수평 확장 가능

### 5-1. String

가장 기본적인 자료구조. 텍스트, 숫자, 직렬화된 객체 등을 저장한다.

```bash
# 기본 SET/GET
SET user:name "홍길동"
GET user:name
# "홍길동"

# 만료 시간 설정 (초 단위)
SET session:abc123 "userId=1001" EX 3600
TTL session:abc123
# 3598

# 숫자 증감 (원자적 연산 - 동시성 안전)
SET visit:count 0
INCR visit:count     # 1
INCRBY visit:count 5 # 6

# NX 옵션: 키가 없을 때만 설정 (분산 락 구현에 활용)
SET lock:resource "locked" EX 10 NX
```

**사용 사례**: 세션 토큰 저장, 캐싱, 카운터(조회수, 좋아요), 분산 락

### 5-2. Hash

필드-값 쌍의 컬렉션. 객체 데이터를 저장하기에 적합하다.

```bash
# 사용자 정보 저장
HSET user:1001 name "홍길동" email "hong@example.com" age 30
HGET user:1001 name        # "홍길동"
HGETALL user:1001          # 모든 필드-값 반환
HMGET user:1001 name email # 여러 필드 한 번에 조회
HINCRBY user:1001 age 1    # 나이 1 증가
HDEL user:1001 email       # 필드 삭제
```

**사용 사례**: 사용자 프로필, 설정 정보, 쇼핑 장바구니 아이템 수량 관리

### 5-3. List

순서가 있는 문자열 컬렉션. 양쪽 끝에서 삽입/삭제가 O(1)이다.

```bash
# 채팅 메시지 저장 (최근 메시지를 앞에 추가)
LPUSH chat:room:1 "안녕하세요"
LPUSH chat:room:1 "반갑습니다"
LRANGE chat:room:1 0 -1   # 전체 조회

# 큐(Queue) 구현: RPUSH로 추가, LPOP으로 꺼내기
RPUSH job:queue "task1"
RPUSH job:queue "task2"
LPOP job:queue    # "task1" (FIFO)

# 블로킹 팝: 데이터가 없으면 대기 (타임아웃: 30초)
BLPOP job:queue 30
```

**사용 사례**: 최근 방문 목록, 알림 피드, 작업 큐(Job Queue)

### 5-4. Set

중복을 허용하지 않는 문자열 집합. 집합 연산(합집합, 교집합, 차집합)을 지원한다.

```bash
# 태그 관리
SADD article:1:tags "tech" "backend" "database"
SMEMBERS article:1:tags       # 모든 태그 조회
SISMEMBER article:1:tags "tech"  # 멤버 여부 확인 (1 또는 0)
SCARD article:1:tags          # 원소 개수

# 집합 연산 (공통 팔로워 찾기)
SADD user:1:followers "a" "b" "c"
SADD user:2:followers "b" "c" "d"
SINTER user:1:followers user:2:followers  # {"b", "c"} 교집합
SUNION user:1:followers user:2:followers  # {"a", "b", "c", "d"} 합집합
SDIFF user:1:followers user:2:followers   # {"a"} 차집합
```

**사용 사례**: 태그 시스템, 좋아요/팔로우 목록, 중복 제거, 공통 관심사 추천

### 5-5. Sorted Set (ZSet)

각 원소에 점수(Score)를 부여하여 자동으로 정렬되는 집합이다.

```bash
# 게임 리더보드
ZADD leaderboard 1500 "player:alice"
ZADD leaderboard 2300 "player:bob"
ZADD leaderboard 1800 "player:charlie"

# 상위 3명 조회 (점수 내림차순)
ZREVRANGE leaderboard 0 2 WITHSCORES
# player:bob 2300, player:charlie 1800, player:alice 1500

# 특정 플레이어 순위 조회 (0-based, 오름차순)
ZREVRANK leaderboard "player:alice"   # 2 (3위)

# 점수 업데이트
ZINCRBY leaderboard 500 "player:alice"

# 점수 범위로 조회
ZRANGEBYSCORE leaderboard 1700 2500 WITHSCORES
```

**사용 사례**: 실시간 랭킹, 우선순위 큐, 만료 시간 기반 정렬

---

## 6. NoSQL vs RDBMS 비교

| 항목 | RDBMS | NoSQL |
|------|-------|-------|
| **데이터 모델** | 테이블(행/열), 고정 스키마 | 문서, 키-값, 컬럼, 그래프 등 유연한 스키마 |
| **확장 방식** | 수직 확장(Scale-Up) 중심 | 수평 확장(Scale-Out) 용이 |
| **일관성** | ACID 트랜잭션 (강한 일관성) | 보통 최종 일관성(Eventual Consistency) |
| **JOIN** | 다중 테이블 JOIN 강력 지원 | JOIN 제한적 (역정규화 필요) |
| **쿼리 언어** | SQL (표준화) | 제품별 고유 쿼리 방식 |
| **스키마 변경** | ALTER TABLE 필요 (비용 큼) | 유연하게 필드 추가/변경 가능 |
| **트랜잭션** | 복잡한 다중 테이블 트랜잭션 지원 | 단일 도큐먼트 수준 또는 제한적 |
| **성숙도** | 수십 년의 검증된 기술 | 상대적으로 신기술, 생태계 성장 중 |
| **사용 사례** | 금융, ERP, 복잡한 관계 데이터 | SNS, 실시간 빅데이터, IoT, 캐싱 |

---

## 7. 선택 기준

### 7-1. RDBMS를 선택해야 할 때
- **강한 일관성이 필수**인 경우: 금융 거래, 재고 관리, 예약 시스템
- **복잡한 JOIN 쿼리**가 빈번한 경우: 다중 테이블 간 연관 분석
- **ACID 트랜잭션**이 반드시 필요한 경우
- 데이터 구조가 **안정적이고 잘 정의**된 경우
- 팀에 SQL 전문성이 충분한 경우

### 7-2. NoSQL을 선택해야 할 때
- **대용량 쓰기/읽기** 처리량이 요구되는 경우 (초당 수만 건 이상)
- **데이터 구조가 자주 변하거나 비정형**인 경우: 로그, 이벤트, 사용자 활동
- **수평 확장**이 필요한 경우: 트래픽 급증에 대응
- **지연 시간(Latency)**이 극도로 낮아야 하는 경우: 캐싱, 실시간 추천
- 각 엔티티마다 **속성이 다양하게 다른** 경우: 상품 카탈로그

### 7-3. 혼용 전략 (Polyglot Persistence)

실제 프로덕션 환경에서는 RDBMS와 NoSQL을 목적에 맞게 함께 사용하는 것이 일반적이다.

```
[서비스 예시]
- 사용자 계정/결제 데이터   → PostgreSQL (ACID 필요)
- 상품 카탈로그/리뷰        → MongoDB (유연한 스키마)
- 세션/인증 토큰            → Redis (인메모리 캐싱)
- 실시간 랭킹/피드          → Redis Sorted Set
- 로그/분석 데이터          → Cassandra (시계열, 대용량 쓰기)
- 친구 추천                 → Neo4j (그래프 관계 탐색)
```

---

## 8. 면접 포인트

### Q1. CAP 이론에서 실제로 CA 시스템이 존재하는가?

분산 시스템에서는 네트워크 파티션이 언제든 발생할 수 있으므로, 실질적으로 CA 시스템은 **단일 노드 환경**에서만 가능하다. 따라서 분산 DB는 반드시 P를 포함해야 하며, CP 또는 AP 중 선택해야 한다. 면접에서는 "분산 환경에서는 P를 포기할 수 없기 때문에 실질적으로 C와 A 사이의 트레이드오프를 선택하는 것"이라고 설명하면 좋다.

### Q2. MongoDB의 트랜잭션 지원은?

MongoDB 4.0부터 **멀티 도큐먼트 ACID 트랜잭션**을 지원한다. 그러나 RDBMS에 비해 성능 오버헤드가 있으므로, 트랜잭션이 반드시 필요한 경우에만 사용하고, 단일 도큐먼트 연산은 원자적으로 처리되므로 도큐먼트 설계를 통해 트랜잭션 필요성을 최소화하는 것이 권장된다.

### Q3. Redis의 데이터 유실 가능성과 대응 방법은?

Redis는 기본적으로 인메모리이므로 서버 재시작 시 데이터가 유실될 수 있다. 이를 방지하기 위해 두 가지 영속성 방법을 제공한다.
- **RDB(Redis Database)**: 주기적으로 스냅샷을 디스크에 저장. 복구 속도가 빠르지만 마지막 스냅샷 이후 데이터 유실 가능
- **AOF(Append Only File)**: 모든 쓰기 명령을 로그로 기록. 데이터 유실이 거의 없지만 파일 크기가 커짐
- **혼용(RDB + AOF)**: 두 방식을 함께 사용하여 장점을 조합

### Q4. NoSQL에서 데이터 정합성은 어떻게 보장하는가?

NoSQL은 보통 **최종 일관성(Eventual Consistency)**을 제공한다. 이는 모든 복제본이 즉시 동기화되지 않더라도, 일정 시간이 지나면 동일한 데이터를 갖게 된다는 의미이다. 애플리케이션 레벨에서 정합성을 보장하려면 멱등성(Idempotency) 설계, 낙관적 잠금(Optimistic Locking), 버전 관리 등의 전략을 활용한다.

### Q5. Redis를 캐시로 사용할 때 캐시 전략은?

- **Cache-Aside(Lazy Loading)**: 캐시 미스 시 DB에서 조회 후 캐시에 저장. 가장 일반적인 패턴
- **Write-Through**: 쓰기 시 캐시와 DB를 동시에 업데이트. 항상 최신 데이터 보장
- **Write-Behind(Write-Back)**: 캐시에만 먼저 쓰고, 나중에 비동기로 DB에 반영. 쓰기 성능 최적화
- **TTL 설정**: 적절한 만료 시간으로 오래된 데이터 자동 제거

### Q6. MongoDB의 샤딩(Sharding)이란?

데이터를 여러 서버(샤드)에 분산 저장하는 수평 확장 기법이다. 샤드 키(Shard Key)를 기준으로 데이터를 분배한다. 좋은 샤드 키는 데이터를 균등하게 분배하고, 자주 사용하는 쿼리 패턴에 부합해야 한다. 샤드 키 선택이 잘못되면 특정 샤드에 데이터가 몰리는 **핫스팟(Hotspot)** 문제가 발생할 수 있다.
