# CVE-2023-44487 - HTTP/2 Rapid Reset DDoS

## 개요

| 항목 | 내용 |
|------|------|
| CVE ID | CVE-2023-44487 |
| CVSS | 7.5 (High) |
| 영향 소프트웨어 | HTTP/2 프로토콜을 구현한 모든 서버 |
| 영향 버전 | Nginx, Apache, Node.js, Go net/http, Envoy, HAProxy 등 거의 모든 HTTP/2 구현 |
| 수정 버전 | Nginx 1.25.3, Apache 2.4.58, Node.js 20.8.1, Go 1.21.3 등 |
| 공격 유형 | DDoS (Denial of Service) |
| 발견일 | 2023-10-10 |

## 영향 범위 & 심각성

HTTP/2 프로토콜 자체의 설계 결함을 악용한 공격으로, 사실상 인터넷의 모든 HTTP/2 서버가 영향을 받았다.

- Google Cloud에서 초당 **3억 9,800만 건**의 요청(398M RPS)을 기록한 역대 최대 DDoS
- Cloudflare, AWS, Google이 동시에 공격을 탐지하고 공동 대응
- 단일 머신에서도 대규모 서버에 유의미한 영향을 줄 수 있는 비대칭 공격
- CDN, 로드밸런서, API Gateway, 리버스 프록시 등 모든 HTTP/2 인프라가 대상
- 공격 도구가 단순하여 스크립트 키디도 악용 가능

## 취약점 기술 분석

### 근본 원인

HTTP/2의 **스트림 멀티플렉싱** 기능과 **RST_STREAM** 프레임의 상호작용에서 발생한 설계 결함이다.

```
HTTP/2 정상 동작:
Client → HEADERS (Stream 1) → Server
Client → HEADERS (Stream 3) → Server
Server → HEADERS + DATA (Stream 1) → Client
Server → HEADERS + DATA (Stream 3) → Client

Rapid Reset 공격:
Client → HEADERS (Stream 1) → Server  [요청 시작]
Client → RST_STREAM (Stream 1) → Server  [즉시 취소]
Client → HEADERS (Stream 3) → Server  [새 요청]
Client → RST_STREAM (Stream 3) → Server  [즉시 취소]
... (초당 수백만 회 반복)
```

### 공격 메커니즘

1. 클라이언트가 HTTP/2 스트림을 열고 즉시 RST_STREAM으로 취소
2. 서버는 요청 처리를 시작하지만, RST_STREAM 수신 후 응답을 폐기
3. **서버는 이미 리소스를 소비**했지만, 클라이언트는 응답을 받지 않으므로 bandwidth 비용 없음
4. HTTP/2 `MAX_CONCURRENT_STREAMS` 제한을 우회: 취소된 스트림은 활성 스트림으로 카운트되지 않음
5. 결과적으로 단일 연결에서 무한에 가까운 요청을 생성 가능

## 공격 시나리오

```
1단계: 대상 서버와 HTTP/2 연결 수립
2단계: HEADERS 프레임으로 요청 시작 (Stream ID 증가)
3단계: 즉시 RST_STREAM 프레임으로 해당 스트림 취소
4단계: 2-3단계를 초당 수십만~수백만 회 반복
5단계: 서버의 CPU/메모리 고갈 → 정상 트래픽 처리 불가
```

```python
# 공격 개념 (교육 목적 의사코드)
import h2.connection

conn = h2.connection.H2Connection()
conn.initiate_connection()

stream_id = 1
while True:
    conn.send_headers(stream_id, headers=[...])  # 요청 시작
    conn.reset_stream(stream_id)                  # 즉시 취소
    stream_id += 2  # HTTP/2 클라이언트 스트림은 홀수
```

## 방어 방법

1. **서버 소프트웨어 업데이트**: 각 서버 벤더의 패치 적용
2. **RST_STREAM Rate Limiting**: 단일 연결의 RST_STREAM 빈도 제한
   ```nginx
   # Nginx 설정 예시
   http2_max_concurrent_streams 100;
   limit_req_zone $binary_remote_addr zone=http2:10m rate=100r/s;
   ```
3. **연결 수준 제한**: RST_STREAM이 임계값을 초과하면 연결 종료(GOAWAY)
4. **CDN/DDoS 방어 서비스**: Cloudflare, AWS Shield, Google Cloud Armor 활용
5. **HTTP/2 비활성화**: 긴급 상황에서 HTTP/1.1로 일시 전환 (기능 저하 감수)
6. **모니터링**: RST_STREAM 비율, 연결당 스트림 생성 속도 모니터링

## 교훈

- **프로토콜 설계의 보안 검증**: HTTP/2 표준 자체의 설계가 악용 가능한 비대칭성을 내포
- **리소스 소비의 비대칭성**: 공격자는 적은 비용으로, 서버는 큰 비용을 지불하는 구조 주의
- **업계 협력의 중요성**: Google, Cloudflare, AWS가 동시 탐지 후 coordinated disclosure
- **DDoS 방어는 다층 구조로**: 프로토콜 패치 + CDN + Rate Limiting + 모니터링
- **새 프로토콜 도입 시 공격 표면 확대**: HTTP/2의 멀티플렉싱이 새로운 공격 벡터 생성

## 참고 자료

- [Google Blog - HTTP/2 Rapid Reset](https://cloud.google.com/blog/products/identity-security/how-it-works-the-novel-http2-rapid-reset-ddos-attack)
- [Cloudflare Blog - HTTP/2 Zero-Day](https://blog.cloudflare.com/technical-breakdown-http2-rapid-reset-ddos-attack/)
- [NVD - CVE-2023-44487](https://nvd.nist.gov/vuln/detail/CVE-2023-44487)
- [Nginx Advisory](https://www.nginx.com/blog/http-2-rapid-reset-attack-impacting-f5-nginx-products/)
- [CISA Advisory](https://www.cisa.gov/news-events/alerts/2023/10/10/http2-rapid-reset-vulnerability-cve-2023-44487)
