# 9. 암호화 알고리즘 기초 (프론트엔드 개발자 관점)

## 목차

1. 암호화 분류
2. 해시 함수
3. 대칭 키 암호화
4. 비대칭 키 암호화
5. JWT와 암호화의 관계
6. HTTPS/TLS 동작 원리
7. 프론트엔드에서 암호화를 직접 사용하는 경우
8. 면접 포인트

---

## 1. 암호화 분류

```
암호화(Cryptography)
├── 단방향 (One-way)
│   └── 해시 함수: MD5, SHA-256, SHA-512, bcrypt, argon2
│       → 원문 복구 불가, 무결성 검증 / 패스워드 저장에 사용
│
└── 양방향 (Two-way)
    ├── 대칭 키 암호화 (Symmetric): AES
    │   → 같은 키로 암호화/복호화. 빠름. 키 공유 문제.
    └── 비대칭 키 암호화 (Asymmetric): RSA, ECC
        → 공개키로 암호화, 개인키로 복호화. 느림. 키 공유 불필요.
```

**핵심 구분**:
- 해시: 암호화가 아님. 복호화 불가. 동일 입력 → 항상 동일 출력.
- 암호화: 복호화 가능. 키가 있어야 원문 복원.
- 서명(Signature): 개인키로 서명, 공개키로 검증. JWT에서 활용.

---

## 2. 해시 함수

### 2-1. MD5

128비트(32자리 hex) 출력. 1992년 설계.

```js
// MD5는 현재 보안 용도로 사용 금지
// 충돌(collision)이 발견됨 → 다른 입력으로 같은 해시 생성 가능
// 사용 가능한 경우: 파일 무결성 체크섬 (보안 불필요 시), 캐시 키

// Web Crypto API는 MD5를 지원하지 않음 (취약하므로 의도적 제외)
// 필요하다면 서드파티 라이브러리 사용 (crypto-js 등)
import CryptoJS from 'crypto-js';
const hash = CryptoJS.MD5('hello').toString();
// → "5d41402abc4b2a76b9719d911017c592"
```

### 2-2. SHA-256, SHA-512

SHA-2 계열. SHA-256은 256비트(64자리 hex), SHA-512는 512비트(128자리 hex) 출력.

```js
// Web Crypto API로 SHA-256 구현 (브라우저 내장, 추가 라이브러리 불필요)
async function sha256(message) {
  const encoder = new TextEncoder();
  const data = encoder.encode(message);
  const hashBuffer = await crypto.subtle.digest('SHA-256', data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
}

// 사용 예시
const hash = await sha256('hello world');
console.log(hash);
// → "b94d27b9934d3e08a52e52d7da7dabfac484efe04294e576e1d7d4d7b2cded10"

// SHA-512
async function sha512(message) {
  const encoder = new TextEncoder();
  const data = encoder.encode(message);
  const hashBuffer = await crypto.subtle.digest('SHA-512', data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
}
```

**용도**:
- 파일 무결성 검증 (다운로드 파일 체크섬).
- 디지털 서명의 기반.
- JWT의 HMAC 서명 (HS256).
- 패스워드 저장에는 부적합 (빠르기 때문에 브루트포스 취약).

### 2-3. bcrypt, argon2 (패스워드 해싱 전용)

패스워드는 SHA-256/SHA-512로 저장하면 안 됨. 이유: 너무 빠르기 때문에 GPU를 이용한 brute-force 공격에 취약.

**bcrypt/argon2의 핵심 개념**:

```
1. Salt: 랜덤 값을 패스워드에 붙여 같은 패스워드도 다른 해시 생성
   → 레인보우 테이블 공격 방지

2. Stretch (Key Stretching): 의도적으로 계산을 느리게 만듦
   → cost factor(bcrypt), iterations(argon2)로 조절
   → 공격자가 초당 시도 횟수를 줄임

3. argon2가 bcrypt보다 최신이며 메모리 경쟁도 활용 (GPU 공격 방어 강화)
```

```js
// Node.js 환경 (프론트에서 직접 패스워드 해싱은 권장하지 않음)
// 서버 측 코드 참고용

import bcrypt from 'bcrypt';

// 해싱 (saltRounds = cost factor, 보통 10~12)
const saltRounds = 12;
const hashedPassword = await bcrypt.hash('myPassword123', saltRounds);
// → "$2b$12$..." (salt 포함된 해시)

// 검증
const isMatch = await bcrypt.compare('myPassword123', hashedPassword);
// → true

// argon2 (더 현대적인 방식)
import argon2 from 'argon2';
const hash = await argon2.hash('myPassword123');
const isValid = await argon2.verify(hash, 'myPassword123');
```

**프론트엔드 개발자로서 알아야 할 것**:
- 패스워드는 반드시 서버에서 bcrypt 또는 argon2로 해싱 후 저장.
- 프론트에서 SHA-256으로 해싱해서 서버에 보내는 것도 잘못된 방식 (서버가 해당 SHA-256 값을 패스워드로 저장하면 동일한 문제).
- HTTPS를 통해 평문 패스워드를 서버로 전송 → 서버에서 bcrypt/argon2 처리.

---

## 3. 대칭 키 암호화

### AES-256 개념

AES(Advanced Encryption Standard). 동일한 키로 암호화/복호화. 256비트 키 = AES-256.

**운용 모드**:
- AES-CBC (Cipher Block Chaining): IV(초기화 벡터) 필요. 블록 단위 처리.
- AES-GCM (Galois/Counter Mode): IV 필요. 인증 태그 포함 → 무결성 검증도 수행. **권장**.

```js
// Web Crypto API로 AES-GCM 암호화/복호화

// 키 생성
async function generateAESKey() {
  return crypto.subtle.generateKey(
    { name: 'AES-GCM', length: 256 },
    true,        // extractable: 키를 내보낼 수 있는지
    ['encrypt', 'decrypt']
  );
}

// 암호화
async function encryptAES(key, plaintext) {
  const encoder = new TextEncoder();
  const data = encoder.encode(plaintext);

  // IV는 매번 새로 생성 (12바이트 권장)
  const iv = crypto.getRandomValues(new Uint8Array(12));

  const encrypted = await crypto.subtle.encrypt(
    { name: 'AES-GCM', iv },
    key,
    data
  );

  return { encrypted, iv };
}

// 복호화
async function decryptAES(key, encrypted, iv) {
  const decrypted = await crypto.subtle.decrypt(
    { name: 'AES-GCM', iv },
    key,
    encrypted
  );
  return new TextDecoder().decode(decrypted);
}

// 사용 예시
const key = await generateAESKey();
const { encrypted, iv } = await encryptAES(key, 'Hello, World!');
const plaintext = await decryptAES(key, encrypted, iv);
console.log(plaintext); // "Hello, World!"
```

**주의사항**:
- IV(Initialization Vector)는 절대 재사용하면 안 됨.
- GCM 모드는 암호문과 함께 인증 태그를 생성 → 변조 감지 가능.
- 키는 안전하게 관리 (하드코딩 금지, 환경 변수 또는 KMS 사용).

---

## 4. 비대칭 키 암호화

### RSA 개념

공개키(Public Key)와 개인키(Private Key) 쌍 사용.
- 공개키: 누구에게나 공개. 암호화 또는 서명 검증에 사용.
- 개인키: 본인만 보관. 복호화 또는 서명에 사용.

```
암호화 흐름: 공개키로 암호화 → 개인키로 복호화
서명 흐름:   개인키로 서명   → 공개키로 검증
```

### HTTPS TLS 핸드셰이크에서의 역할

```
1. 클라이언트 → 서버: ClientHello (지원하는 암호화 방식 목록)
2. 서버 → 클라이언트: ServerHello + 서버 인증서(공개키 포함)
3. 클라이언트: 인증서 검증 (CA 체인 확인)
4. 키 교환:
   - RSA 방식: 클라이언트가 대칭 키를 서버 공개키로 암호화하여 전송
   - ECDHE 방식(현재 주류): 양측이 임시 키쌍 생성 후 Diffie-Hellman 교환
5. 이후 통신: 협상된 대칭 키(AES)로 암호화 → 빠른 통신
```

비대칭 암호화는 느리기 때문에 초기 키 교환에만 사용하고, 실제 데이터 전송은 대칭 키(AES)로 처리.

### Web Crypto API로 RSA-OAEP 예제

```js
// RSA 키 쌍 생성
async function generateRSAKeyPair() {
  return crypto.subtle.generateKey(
    {
      name: 'RSA-OAEP',
      modulusLength: 2048,          // 키 길이 (비트)
      publicExponent: new Uint8Array([1, 0, 1]), // 65537
      hash: 'SHA-256',
    },
    true,
    ['encrypt', 'decrypt']
  );
}

// 공개키로 암호화
async function encryptRSA(publicKey, plaintext) {
  const encoder = new TextEncoder();
  const data = encoder.encode(plaintext);
  return crypto.subtle.encrypt({ name: 'RSA-OAEP' }, publicKey, data);
}

// 개인키로 복호화
async function decryptRSA(privateKey, ciphertext) {
  const decrypted = await crypto.subtle.decrypt(
    { name: 'RSA-OAEP' },
    privateKey,
    ciphertext
  );
  return new TextDecoder().decode(decrypted);
}

// 사용 예시
const { publicKey, privateKey } = await generateRSAKeyPair();
const encrypted = await encryptRSA(publicKey, 'Secret message');
const plaintext = await decryptRSA(privateKey, encrypted);
console.log(plaintext); // "Secret message"
```

**RSA 제한사항**:
- 암호화할 수 있는 데이터 크기 제한 (2048비트 키 = 최대 약 245바이트).
- 큰 데이터는 AES로 암호화하고, AES 키만 RSA로 암호화 (Hybrid Encryption).

---

## 5. JWT와 암호화의 관계

### JWT 구조

```
header.payload.signature

예시:
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9   ← header (Base64URL)
.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkFsaWNlIn0  ← payload (Base64URL)
.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c       ← signature (HMAC 또는 RSA 서명)
```

**중요**: JWT는 암호화가 아닌 서명(Signature)임. Header와 Payload는 Base64URL 인코딩일 뿐 → 누구나 디코딩 가능.

```js
// JWT 디코딩 (서명 검증 없이 내용 확인 — 절대 신뢰 용도로 사용 금지)
function decodeJWT(token) {
  const parts = token.split('.');
  const payload = parts[1];
  // Base64URL → Base64 변환
  const base64 = payload.replace(/-/g, '+').replace(/_/g, '/');
  return JSON.parse(atob(base64));
}

const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkFsaWNlIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';
console.log(decodeJWT(token));
// → { sub: "1234567890", name: "Alice", iat: 1516239022 }
```

### HS256 vs RS256

| 구분 | HS256 (대칭) | RS256 (비대칭) |
|---|---|---|
| 서명 알고리즘 | HMAC-SHA256 | RSA-SHA256 |
| 키 방식 | 하나의 비밀 키 | 개인키(서명) + 공개키(검증) |
| 서명 주체 | 서버 | Auth 서버 |
| 검증 주체 | 동일 서버 | 공개키를 가진 누구나 |
| 적합한 상황 | 단일 서비스 | 마이크로서비스, 서드파티 |

```js
// Node.js jsonwebtoken 라이브러리 사용 예
import jwt from 'jsonwebtoken';

// HS256: 대칭 키 서명
const hs256Token = jwt.sign(
  { sub: 'user123', name: 'Alice' },
  'my-secret-key',    // 서명 키
  { algorithm: 'HS256', expiresIn: '1h' }
);
jwt.verify(hs256Token, 'my-secret-key'); // 같은 키로 검증

// RS256: 비대칭 키 서명
const privateKey = fs.readFileSync('private.pem');
const publicKey = fs.readFileSync('public.pem');

const rs256Token = jwt.sign(
  { sub: 'user123', name: 'Alice' },
  privateKey,
  { algorithm: 'RS256', expiresIn: '1h' }
);
jwt.verify(rs256Token, publicKey); // 공개키로 검증
```

**JWT 보안 주의사항**:
- `alg: "none"` 공격: 서버에서 반드시 알고리즘 명시적 검증 필요.
- Payload에 민감 정보(패스워드, 주민번호 등) 절대 저장 금지 (Base64 디코딩 가능).
- 암호화된 JWT(JWE)는 별도 스펙. 일반적인 JWT(JWS)는 서명만.

---

## 6. HTTPS/TLS 동작 원리 (암호화 관점)

```
TLS 1.3 핸드셰이크 (간략화):

Client                          Server
  |                                |
  |-- ClientHello ---------------→ |  (지원 암호화 스위트, 랜덤값A)
  |                                |
  |← ServerHello + Certificate -- |  (선택된 암호화 스위트, 랜덤값B, 공개키)
  |                                |
  |-- (인증서 검증 중) ----------- |
  |                                |
  | ← 양측 ECDHE 키 교환 →        |  (Diffie-Hellman: Pre-Master Secret)
  |                                |
  | Master Secret 도출:            |
  |   PRF(Pre-Master, A+B) ------  |
  |                                |
  |-- Finished (MAC) ----------→  |
  |← Finished (MAC) ------------ |
  |                                |
  | [이후 AES-256-GCM으로 통신]    |
```

**TLS에서 사용되는 암호화 알고리즘**:
- 키 교환: ECDHE (Elliptic Curve Diffie-Hellman Ephemeral)
- 인증(서버 신원 확인): RSA 또는 ECDSA (인증서 서명)
- 대칭 암호화: AES-256-GCM
- 메시지 인증: SHA-384 (HMAC)
- 인증서 체인: CA(Certificate Authority)의 디지털 서명으로 신뢰 연결

**Perfect Forward Secrecy(PFS)**: ECDHE는 임시(Ephemeral) 키 쌍을 매 세션마다 생성 → 과거 세션 키가 유출돼도 이전 세션 복호화 불가.

---

## 7. 프론트엔드에서 암호화를 직접 사용하는 경우

### 사용해야 하는 경우

```
1. E2E(End-to-End) 암호화 애플리케이션
   → 메시지가 서버에 암호화된 상태로 저장 (WhatsApp, Signal 방식)
   → 서버도 내용을 볼 수 없어야 함

2. 민감 데이터의 클라이언트 측 처리
   → 파일 업로드 전 암호화 (클라이언트 측 암호화 스토리지)
   → 서버에 암호화된 파일만 전달

3. 로컬 스토리지 민감 데이터 보호
   → 토큰 외 추가 민감 정보를 로컬에 저장할 때

4. 디지털 서명 / 무결성 검증
   → 클라이언트에서 데이터에 서명 후 서버 검증
```

```js
// 실용 예: 로컬 스토리지 데이터 AES-GCM 암호화
class SecureStorage {
  constructor(key) {
    this.key = key; // CryptoKey 객체
  }

  async save(storageKey, value) {
    const plaintext = JSON.stringify(value);
    const { encrypted, iv } = await encryptAES(this.key, plaintext);

    // ArrayBuffer → Base64 변환 후 저장
    const encryptedBase64 = btoa(String.fromCharCode(...new Uint8Array(encrypted)));
    const ivBase64 = btoa(String.fromCharCode(...iv));

    localStorage.setItem(storageKey, JSON.stringify({ data: encryptedBase64, iv: ivBase64 }));
  }

  async load(storageKey) {
    const stored = localStorage.getItem(storageKey);
    if (!stored) return null;

    const { data, iv: ivBase64 } = JSON.parse(stored);

    // Base64 → Uint8Array 변환
    const encrypted = Uint8Array.from(atob(data), c => c.charCodeAt(0));
    const iv = Uint8Array.from(atob(ivBase64), c => c.charCodeAt(0));

    return JSON.parse(await decryptAES(this.key, encrypted, iv));
  }
}
```

### 사용하지 말아야 하는 경우

```
1. 패스워드 저장 → 반드시 서버(bcrypt/argon2) 처리
2. 보안 로직을 클라이언트 코드에만 구현 → 소스 공개로 우회 가능
3. 키를 JS 코드에 하드코딩 → 노출 위험
4. "보안을 위해" HTTPS 대신 직접 암호화 → HTTPS가 이미 충분
```

---

## 8. 면접 포인트

**Q. 해시와 암호화의 차이를 설명해주세요.**

해시는 단방향 함수로 복호화가 불가능합니다. 동일 입력에 항상 동일 출력을 냅니다. 무결성 검증, 패스워드 저장에 사용합니다. 암호화는 양방향으로 적절한 키를 가지면 원문을 복원할 수 있습니다. 데이터 기밀성이 필요할 때 사용합니다.

**Q. 패스워드를 SHA-256으로 해싱해서 저장하면 안 되는 이유는?**

SHA-256은 속도가 매우 빠릅니다. GPU를 이용하면 초당 수십억 번 해시 계산이 가능해 brute-force 공격에 취약합니다. 또한 salt가 없으면 레인보우 테이블 공격이 가능합니다. bcrypt와 argon2는 의도적으로 느리고(key stretching) salt를 포함하도록 설계되어 패스워드 저장에 적합합니다.

**Q. JWT는 암호화된 데이터인가요?**

아닙니다. 일반적인 JWT(JWS, JSON Web Signature)는 암호화가 아닌 서명입니다. Header와 Payload는 Base64URL 인코딩일 뿐 누구나 디코딩해서 내용을 볼 수 있습니다. Signature는 내용이 변조되지 않았음을 검증하는 데 사용됩니다. 내용을 숨기려면 JWE(JSON Web Encryption)를 사용해야 합니다.

**Q. 대칭 키와 비대칭 키 암호화의 차이 및 HTTPS에서 어떻게 활용되나요?**

대칭 키는 같은 키로 암호화/복호화합니다. 빠르지만 키를 안전하게 공유하는 것이 문제입니다. 비대칭 키는 공개키/개인키 쌍을 사용합니다. 안전하게 키를 교환할 수 있지만 느립니다. HTTPS/TLS에서는 두 방식을 혼합합니다. 핸드셰이크 시 비대칭 키(RSA/ECDHE)로 안전하게 대칭 키를 교환하고, 실제 데이터 전송은 빠른 대칭 키(AES-256-GCM)로 암호화합니다.

**Q. RS256과 HS256의 차이와 어떤 상황에 각각 사용하나요?**

HS256은 HMAC-SHA256으로 하나의 비밀 키로 서명과 검증을 모두 합니다. 단일 서비스에 적합합니다. RS256은 RSA-SHA256으로 개인키로 서명하고 공개키로 검증합니다. Auth 서버와 리소스 서버가 분리된 마이크로서비스 환경이나 외부 서비스에 토큰을 검증시켜야 할 때 적합합니다. 공개키는 공개해도 안전하므로 검증 서버에 비밀 키를 공유할 필요가 없습니다.

**Q. Web Crypto API는 무엇이고 언제 사용하나요?**

Web Crypto API는 브라우저에 내장된 암호화 기능을 제공하는 표준 API(`crypto.subtle`)입니다. 별도 라이브러리 없이 SHA-256 해시, AES 암호화, RSA 키 생성 등을 수행할 수 있습니다. 안전한 난수 생성(`crypto.getRandomValues`), E2E 암호화, 클라이언트 측 파일 암호화 시 사용합니다. 순수 JS 구현보다 훨씬 빠르고 안전합니다.
