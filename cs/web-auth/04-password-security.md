# 4. 패스워드 보안

## 목차
1. 평문 저장이 왜 위험한가
2. 해시 함수와 그 한계
3. Salt: 레인보우 테이블 방어
4. bcrypt: 적응형 해시
5. Argon2: 현재 권장 표준
6. PBKDF2: NIST 표준
7. 알고리즘 비교
8. 비밀번호 정책
9. 면접 포인트

---

## 1. 평문 저장이 왜 위험한가

```
DB에 평문 저장:
  users 테이블
  ┌──────────┬──────────────────┐
  │ email    │ password         │
  ├──────────┼──────────────────┤
  │ a@a.com  │ mypassword123    │  ← DB 유출 즉시 전체 노출
  │ b@b.com  │ qwerty           │
  └──────────┴──────────────────┘
```

DB가 유출되면:
- 모든 사용자의 비밀번호가 즉시 공격자에게 노출
- 사람들은 여러 서비스에 같은 비밀번호를 사용 → **크리덴셜 스터핑** 공격으로 다른 서비스도 침해
- 서비스 신뢰도 완전 파괴

실제 사례: 2012년 LinkedIn 유출 (SHA-1 unsalted), 2019년 Collection #1 (21억 계정)

---

## 2. 해시 함수와 그 한계

### 단순 해시 (SHA-256)

```javascript
// SHA-256으로 해시
const hash = crypto.createHash('sha256').update('mypassword123').digest('hex');
// → "65e84be33532fb784c48129675f9eff3a682b27168c0ea744b2cf58ee02337c5"
```

```
users 테이블
┌──────────┬──────────────────────────────────────────────────────────────┐
│ email    │ password_hash                                                │
├──────────┼──────────────────────────────────────────────────────────────┤
│ a@a.com  │ 65e84be33532fb784c48129675f9eff3a682b27168c0ea744b2cf58ee... │
└──────────┴──────────────────────────────────────────────────────────────┘
```

### 레인보우 테이블 공격

SHA-256은 **결정론적(deterministic)**입니다. 같은 입력은 항상 같은 출력을 냅니다.

```
공격자가 미리 계산한 레인보우 테이블:
  "password"    → "5e884898da28047151d0e56f8dc6292773603d0d6aabbdd..."
  "123456"      → "8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12..."
  "qwerty"      → "65e84be33532fb784c48129675f9eff3a682b27168c0ea..."  ← 일치!
  ...

→ DB 유출 후 해시 값으로 테이블을 역조회 → 원문 즉시 획득
```

또한 SHA-256은 **매우 빠릅니다**. GPU로 초당 수십억 회 연산 가능 → 브루트포스(무차별 대입) 공격에 취약.

---

## 3. Salt: 레인보우 테이블 방어

Salt는 비밀번호마다 추가하는 **랜덤 문자열**입니다.

```
Salt 없이:
  hash("password") → "5e884898..."
  어떤 사용자든 "password" 해시는 동일

Salt 있이:
  hash("password" + "xK9mN2pQ") → "a3f7c8..."  (사용자 A)
  hash("password" + "tR4hJ7kL") → "9b2e4f..."  (사용자 B)
  → 같은 비밀번호도 Salt가 다르면 완전히 다른 해시
```

```
users 테이블
┌──────────┬─────────────────┬──────────────────────┐
│ email    │ salt            │ password_hash         │
├──────────┼─────────────────┼──────────────────────┤
│ a@a.com  │ xK9mN2pQ...     │ a3f7c8...            │
│ b@b.com  │ tR4hJ7kL...     │ 9b2e4f...            │
└──────────┴─────────────────┴──────────────────────┘
```

Salt로 레인보우 테이블을 무력화할 수 있지만, SHA-256 자체의 빠른 속도 문제는 여전히 남습니다.

---

## 4. bcrypt: 적응형 해시

bcrypt는 1999년 설계된 비밀번호 해시 전용 알고리즘입니다.

### 특징

- **Salt 자동 생성 및 포함**: Salt를 별도로 저장할 필요 없음
- **느린 해시**: 의도적으로 연산 비용이 높음 → 브루트포스 방어
- **work factor (cost factor)**: 연산 횟수를 조절하는 파라미터. 하드웨어 성능 향상에 맞춰 증가 가능

```javascript
const bcrypt = require('bcrypt');

// 비밀번호 해시 생성
const saltRounds = 12; // work factor: 2^12 = 4096번 반복
const hashedPassword = await bcrypt.hash('mypassword123', saltRounds);
// → "$2b$12$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36WQoeG6Lruj3vjPGga31lW"

// 비밀번호 검증
const isMatch = await bcrypt.compare('mypassword123', hashedPassword);
// → true
```

### bcrypt 해시 구조

```
$2b$12$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36WQoeG6Lruj3vjPGga31lW
 │   │  │                    │
 │   │  └─ Salt (22자)       └─ 해시 (31자)
 │   └── work factor (12 = 2^12 반복)
 └── 알고리즘 버전 ($2b$)
```

Salt가 해시 내에 포함되어 있어 DB에 해시 값 하나만 저장하면 됩니다.

### work factor 권장값

| work factor | 일반 CPU 소요 시간 | 권장 여부 |
|-------------|-------------------|-----------|
| 10 | ~100ms | 최소 |
| 12 | ~400ms | 권장 (2024년 기준) |
| 14 | ~1.5초 | 보안 중요 서비스 |

사용자 로그인에 0.4초 정도는 허용 범위이며, 공격자는 수십억 번을 시도해야 하므로 효과적입니다.

---

## 5. Argon2: 현재 권장 표준

Argon2는 2015년 **Password Hashing Competition** 우승 알고리즘으로, 현재 가장 강력한 비밀번호 해시 알고리즘입니다.

### 세 가지 변형

| 변형 | 특징 | 용도 |
|------|------|------|
| **Argon2id** | Argon2i + Argon2d 혼합 | **범용 권장** |
| Argon2i | 사이드채널 공격 방어 | 비밀번호 해시 |
| Argon2d | GPU 공격 방어 | 암호화폐 PoW |

### 특징: 메모리 하드(Memory-Hard)

bcrypt는 CPU 연산이 비싸지만, Argon2는 **대량의 메모리**도 필요합니다. GPU/ASIC의 병렬 처리를 어렵게 만드는 방어 메커니즘입니다.

```javascript
const argon2 = require('argon2');

// 해시 생성
const hash = await argon2.hash('mypassword123', {
  type: argon2.argon2id,
  memoryCost: 65536,  // 64 MB
  timeCost: 3,        // 반복 횟수
  parallelism: 4,     // 병렬 스레드 수
});
// → "$argon2id$v=19$m=65536,t=3,p=4$..."

// 검증
const isValid = await argon2.verify(hash, 'mypassword123');
```

---

## 6. PBKDF2: NIST 표준

PBKDF2(Password-Based Key Derivation Function 2)는 NIST에서 표준화한 알고리즘입니다. FIPS 인증이 필요한 정부/금융 시스템에서 주로 사용합니다.

```javascript
const crypto = require('crypto');
const { promisify } = require('util');
const pbkdf2 = promisify(crypto.pbkdf2);

async function hashPassword(password) {
  const salt = crypto.randomBytes(32).toString('hex');
  const iterations = 600000; // NIST 2023 권장: HMAC-SHA256 기준 600,000회
  const keylen = 64;
  const digest = 'sha256';

  const derivedKey = await pbkdf2(password, salt, iterations, keylen, digest);
  return `${salt}:${derivedKey.toString('hex')}`;
}
```

---

## 7. 알고리즘 비교

| 항목 | SHA-256 | bcrypt | Argon2id | PBKDF2 |
|------|---------|--------|----------|--------|
| 비밀번호 해시 목적 | X | O | O | O |
| Salt 자동 처리 | X | O | O | X (수동) |
| 메모리 하드 | X | X | O | X |
| 속도 조절 | X | O (work factor) | O (파라미터) | O (반복 횟수) |
| 표준 | NIST | 업계 표준 | **현재 권장** | NIST FIPS |
| 주요 사용처 | 데이터 무결성 | 기존 시스템 | 신규 시스템 | 금융/정부 |

**신규 시스템 권장 순서**: Argon2id > bcrypt > PBKDF2

---

## 8. 비밀번호 정책

### 8-1. 길이와 복잡도

```
NIST SP 800-63B (2024) 권장:
  - 최소 8자, 최대 64자 이상 허용
  - 복잡도 규칙(대문자/소문자/숫자/특수문자 강제)보다 길이가 더 중요
  - 사용자가 긴 비밀번호를 선택하도록 유도
  - 주기적 강제 변경 불필요 (유출 시에만 변경)
```

### 8-2. 유출 비밀번호 확인: Have I Been Pwned API

```javascript
async function isPasswordPwned(password) {
  // k-Anonymity 방식: 비밀번호 전체를 전송하지 않음
  const sha1Hash = crypto.createHash('sha1').update(password).digest('hex').toUpperCase();
  const prefix = sha1Hash.slice(0, 5);    // 앞 5자리만 전송
  const suffix = sha1Hash.slice(5);       // 나머지로 클라이언트에서 대조

  const response = await fetch(`https://api.pwnedpasswords.com/range/${prefix}`);
  const text = await response.text();

  // 응답: "SUFFIX1:횟수\nSUFFIX2:횟수\n..."
  return text.split('\n').some((line) => {
    const [hashSuffix] = line.split(':');
    return hashSuffix === suffix;
  });
}

// 사용
if (await isPasswordPwned(newPassword)) {
  throw new Error('이 비밀번호는 이미 유출된 비밀번호입니다. 다른 비밀번호를 사용하세요.');
}
```

### 8-3. 비밀번호 정책 체크리스트

```javascript
function validatePassword(password) {
  const errors = [];

  if (password.length < 8)
    errors.push('최소 8자 이상이어야 합니다');

  if (password.length > 128)
    errors.push('128자를 초과할 수 없습니다');

  // 연속된 문자 방지 (aaa, 123 등)
  if (/(.)\1{2,}/.test(password))
    errors.push('같은 문자를 3번 이상 연속 사용할 수 없습니다');

  // 공백 포함 금지 (선택)
  if (/\s/.test(password))
    errors.push('공백을 포함할 수 없습니다');

  return errors;
}
```

---

## 9. 면접 포인트

**Q. 비밀번호를 해시할 때 SHA-256을 사용하면 안 되는 이유는?**

> SHA-256은 빠른 연산이 목적인 범용 해시 함수로, GPU로 초당 수십억 회 계산이 가능합니다. 또한 결정론적이어서 레인보우 테이블 공격에 취약합니다. 비밀번호 해시에는 의도적으로 느리게 설계된 bcrypt, Argon2와 같은 전용 알고리즘을 사용해야 합니다.

**Q. Salt가 무엇이고 왜 필요한가요?**

> Salt는 비밀번호마다 추가하는 랜덤 문자열입니다. 같은 비밀번호도 Salt가 다르면 다른 해시가 생성되어 레인보우 테이블 공격을 무력화합니다. bcrypt, Argon2는 Salt를 자동으로 생성하고 해시에 포함합니다.

**Q. bcrypt의 work factor를 높이면 좋은 점과 트레이드오프는?**

> work factor가 높을수록 해시 생성에 더 많은 시간이 걸려 브루트포스 공격이 어려워집니다. 하지만 로그인 시 사용자가 기다리는 시간이 길어집니다. 일반적으로 100~400ms 범위에서 하드웨어 성능에 맞게 설정합니다.

**Q. Argon2가 bcrypt보다 나은 이유는?**

> bcrypt는 CPU 비용만 높이지만, Argon2는 대량의 메모리도 필요한 메모리 하드(Memory-Hard) 알고리즘입니다. GPU와 ASIC은 메모리가 제한적이므로 대규모 병렬 공격이 어렵습니다. 또한 CPU/메모리/병렬성 파라미터를 독립적으로 조절할 수 있어 더 세밀한 조정이 가능합니다.

**Q. Have I Been Pwned API를 사용할 때 비밀번호가 외부에 노출되지 않는 이유는?**

> k-Anonymity 기법을 사용합니다. 비밀번호 SHA-1 해시의 앞 5자리만 API에 전송하고, 서버는 해당 접두사로 시작하는 모든 해시 목록을 반환합니다. 클라이언트에서 나머지 부분을 대조해 일치 여부를 확인하므로, 실제 비밀번호나 전체 해시가 외부에 전송되지 않습니다.
