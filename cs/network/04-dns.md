# 4. DNS (Domain Name System)

## 목차
1. DNS란 무엇인가
2. DNS 조회 과정
3. DNS 서버 종류
4. DNS 레코드 타입
5. DNS 캐싱과 TTL
6. DNS 보안 이슈
7. 면접 포인트

---

## 1. DNS란 무엇인가

DNS(Domain Name System)는 사람이 읽기 쉬운 도메인 이름(예: `www.example.com`)을 컴퓨터가 통신에 사용하는 IP 주소(예: `93.184.216.34`)로 변환하는 분산형 계층 네이밍 시스템이다.

인터넷의 "전화번호부"에 비유할 수 있으며, 전 세계 수십억 개의 도메인을 처리하기 위해 계층적·분산적 구조를 채택한다.

### 왜 DNS가 필요한가

- IP 주소는 숫자로만 구성되어 사람이 기억하기 어렵다.
- 서버의 IP 주소는 변경될 수 있지만, 도메인 이름은 그대로 유지할 수 있다.
- 하나의 도메인에 여러 IP를 매핑하여 로드 밸런싱에 활용할 수 있다.

### DNS의 계층 구조

```
.                          ← Root (최상위)
├── com.
│   ├── example.com.
│   │   └── www.example.com.
│   └── google.com.
├── org.
│   └── wikipedia.org.
└── kr.
    └── naver.com.kr.
```

도메인 이름은 오른쪽에서 왼쪽으로 계층이 높아진다.
`www.example.com` = `www` + `example` + `com` + `.`(루트)

---

## 2. DNS 조회 과정

### 전체 흐름 개요

```
클라이언트
   │
   │ 1. 브라우저/OS 캐시 확인
   │
   ▼
Recursive Resolver (ISP 또는 공용 DNS: 8.8.8.8)
   │
   │ 2. 캐시 없으면 Root DNS에 질의
   ▼
Root Name Server (13개 클러스터)
   │
   │ 3. TLD 서버 주소 반환
   ▼
TLD Name Server (.com, .kr 등)
   │
   │ 4. Authoritative 서버 주소 반환
   ▼
Authoritative Name Server (example.com 담당)
   │
   │ 5. 최종 IP 주소 반환
   ▼
Recursive Resolver → 클라이언트
```

### 단계별 상세 설명

**1단계: 로컬 캐시 확인**

브라우저 캐시 → OS 캐시(`/etc/hosts`) → Local DNS Resolver 캐시 순서로 확인한다.

```
# /etc/hosts 예시 (정적 DNS 오버라이드)
127.0.0.1   localhost
192.168.1.10 my-local-server.dev
```

**2단계: Recursive Resolver에 질의**

캐시에 없으면 OS가 설정된 DNS 서버(Recursive Resolver)에 쿼리를 전송한다.

**3단계: Root 서버 질의**

Recursive Resolver가 Root 서버에 `www.example.com`을 질의하면, Root 서버는 `.com` TLD 서버의 주소를 반환한다.

**4단계: TLD 서버 질의**

`.com` TLD 서버에 질의하면 `example.com`의 Authoritative 서버 주소를 반환한다.

**5단계: Authoritative 서버 질의**

`example.com` Authoritative 서버에서 `www.example.com`의 실제 IP 주소를 반환한다.

### 재귀적 쿼리 vs 반복적 쿼리

| 구분 | 재귀적 쿼리 (Recursive Query) | 반복적 쿼리 (Iterative Query) |
|------|-------------------------------|-------------------------------|
| 주체 | Recursive Resolver가 대신 조회 | 클라이언트가 각 서버에 직접 질의 |
| 부하 | Resolver에 부하 집중 | 클라이언트에 부하 분산 |
| 일반적 사용 | 클라이언트 ↔ Resolver 간 | Resolver ↔ Root/TLD/Auth 간 |

```
# 재귀적 쿼리 흐름
클라이언트 → Resolver: "www.example.com의 IP를 알려줘"
Resolver → (알아서 Root → TLD → Auth 순으로 조회)
Resolver → 클라이언트: "93.184.216.34"

# 반복적 쿼리 흐름
Resolver → Root: "www.example.com?"
Root → Resolver: "모름, .com TLD는 a.gtld-servers.net"
Resolver → TLD: "www.example.com?"
TLD → Resolver: "모름, example.com Auth는 ns1.example.com"
Resolver → Auth: "www.example.com?"
Auth → Resolver: "93.184.216.34"
```

### dig 명령어로 DNS 조회 실습

```bash
# 기본 A 레코드 조회
dig www.example.com

# 특정 레코드 타입 조회
dig www.example.com AAAA
dig example.com MX
dig example.com NS
dig example.com TXT

# 특정 DNS 서버를 지정하여 조회
dig @8.8.8.8 www.example.com

# 전체 조회 과정 추적 (+trace)
dig +trace www.example.com

# 간결한 출력
dig +short www.example.com
```

---

## 3. DNS 서버 종류

### Root Name Server

- 인터넷 DNS 계층의 최상위 서버
- 전 세계에 13개의 루트 서버 클러스터가 존재 (A~M)
- 실제로는 anycast를 통해 수백 대의 서버가 분산 운영됨
- TLD 서버의 주소 정보를 보유

```
a.root-servers.net  →  198.41.0.4
b.root-servers.net  →  199.9.14.201
...
m.root-servers.net  →  202.12.27.33
```

### TLD Name Server (Top-Level Domain)

- `.com`, `.org`, `.net`, `.kr` 등 최상위 도메인을 관리
- 해당 TLD 하위 도메인들의 Authoritative 서버 정보를 보유
- ICANN 산하 조직들이 운영

### Authoritative Name Server

- 특정 도메인의 실제 DNS 레코드를 보유하는 최종 권한 서버
- 도메인 소유자(또는 호스팅 업체)가 직접 관리
- 쿼리에 대해 확정적인(authoritative) 응답을 반환

```bash
# example.com의 Authoritative 서버 확인
dig example.com NS

# 결과 예시
;; ANSWER SECTION:
example.com.    86400   IN  NS  a.iana-servers.net.
example.com.    86400   IN  NS  b.iana-servers.net.
```

### Recursive Resolver (Recursor)

- 클라이언트의 DNS 쿼리를 대신 처리해주는 서버
- ISP가 제공하거나 공용 DNS 서비스를 이용
- 캐시를 통해 반복 쿼리의 응답 속도를 향상

```
공용 Recursive Resolver 예시:
- Google:     8.8.8.8, 8.8.4.4
- Cloudflare: 1.1.1.1, 1.0.0.1
- OpenDNS:    208.67.222.222
```

---

## 4. DNS 레코드 타입

### A 레코드 (Address)

도메인 이름을 IPv4 주소에 매핑한다.

```
www.example.com.    300    IN    A    93.184.216.34
```

### AAAA 레코드 (IPv6 Address)

도메인 이름을 IPv6 주소에 매핑한다.

```
www.example.com.    300    IN    AAAA    2606:2800:220:1:248:1893:25c8:1946
```

### CNAME 레코드 (Canonical Name)

도메인을 다른 도메인 이름(별칭)에 매핑한다. IP가 아닌 다른 도메인을 가리킨다.

```
blog.example.com.   300    IN    CNAME    example.com.
shop.example.com.   300    IN    CNAME    myshop.shopify.com.
```

> 주의: CNAME은 Zone Apex(루트 도메인, `example.com`)에 사용할 수 없다.
> 이를 해결하기 위해 Cloudflare의 ALIAS/ANAME 레코드가 등장했다.

### MX 레코드 (Mail Exchange)

도메인으로 수신된 이메일을 처리할 메일 서버를 지정한다. 우선순위(Priority) 값이 낮을수록 먼저 시도된다.

```
example.com.    300    IN    MX    10    mail1.example.com.
example.com.    300    IN    MX    20    mail2.example.com.
```

### NS 레코드 (Name Server)

도메인의 Authoritative Name Server를 지정한다.

```
example.com.    86400    IN    NS    ns1.example.com.
example.com.    86400    IN    NS    ns2.example.com.
```

### TXT 레코드 (Text)

임의의 텍스트 정보를 저장한다. 도메인 소유권 확인, SPF, DKIM 등에 활용된다.

```
example.com.    300    IN    TXT    "v=spf1 include:_spf.google.com ~all"
example.com.    300    IN    TXT    "google-site-verification=abcdef12345"
_dmarc.example.com.  300  IN  TXT  "v=DMARC1; p=reject; rua=mailto:dmarc@example.com"
```

### PTR 레코드 (Pointer)

A 레코드의 역방향 조회(IP → 도메인). 역방향 DNS(Reverse DNS) 조회에 사용된다.

```
34.216.184.93.in-addr.arpa.    300    IN    PTR    www.example.com.
```

```bash
# PTR 레코드 조회 (역방향 DNS)
dig -x 93.184.216.34
nslookup 93.184.216.34
```

### 레코드 타입 요약표

| 레코드 | 용도 | 값의 형식 |
|--------|------|-----------|
| A | 도메인 → IPv4 | `192.0.2.1` |
| AAAA | 도메인 → IPv6 | `2001:db8::1` |
| CNAME | 도메인 → 다른 도메인 | `other.example.com.` |
| MX | 이메일 서버 지정 | `10 mail.example.com.` |
| NS | 네임서버 지정 | `ns1.example.com.` |
| TXT | 텍스트 데이터 | `"v=spf1 ..."` |
| PTR | IP → 도메인 (역방향) | `www.example.com.` |

---

## 5. DNS 캐싱과 TTL

### TTL (Time To Live)

TTL은 DNS 레코드가 캐시에 저장되는 시간(초)을 나타낸다.

```
www.example.com.    300    IN    A    93.184.216.34
                    ^^^
                    TTL = 300초 (5분)
```

- TTL이 만료되면 캐시를 폐기하고 새로 조회한다.
- TTL이 길면 DNS 쿼리가 줄어 성능이 향상되지만, IP 변경 시 반영이 느리다.
- TTL이 짧으면 변경 사항이 빠르게 적용되지만, DNS 조회 부하가 증가한다.

### 캐싱 레이어

```
1. 브라우저 캐시      (Chrome: chrome://net-internals/#dns)
2. OS 캐시           (/etc/hosts, systemd-resolved, nscd)
3. Recursive Resolver 캐시  (ISP 또는 공용 DNS)
4. Authoritative 서버 (캐시 없음, 원본 데이터)
```

### TTL 설계 지침

```
일반 운영 중: 3600 ~ 86400초 (1시간 ~ 1일)
마이그레이션 전: 300 ~ 600초  (5 ~ 10분)로 낮추기
CDN/로드밸런서: 60 ~ 300초   (빠른 장애 전환)
```

### OS DNS 캐시 플러시 방법

```bash
# macOS
sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder

# Windows
ipconfig /flushdns

# Linux (systemd-resolved)
sudo systemd-resolve --flush-caches
```

---

## 6. DNS 보안 이슈

### DNS Spoofing (DNS Cache Poisoning)

공격자가 Recursive Resolver의 캐시에 가짜 DNS 응답을 주입하여, 사용자를 악성 서버로 유도하는 공격이다.

```
정상 흐름:
클라이언트 → Resolver → Auth → "example.com = 93.184.216.34"

DNS Poisoning:
공격자가 Resolver에 가짜 응답 주입
클라이언트 → Resolver → "example.com = 공격자IP"  ← 피싱 사이트
```

**방어 방법:**
- DNSSEC 사용
- DNS over HTTPS(DoH) / DNS over TLS(DoT) 사용
- 랜덤 소스 포트 및 트랜잭션 ID 사용 (Birthday Attack 방어)

### DNSSEC (DNS Security Extensions)

DNS 응답에 디지털 서명을 추가하여 데이터 무결성과 인증을 보장하는 확장 표준이다.

```
DNSSEC 레코드 타입:
- RRSIG: 레코드 집합의 디지털 서명
- DNSKEY: 공개 키
- DS: 위임 서명자 레코드 (부모 → 자식 신뢰 체인)
- NSEC/NSEC3: 존재하지 않는 레코드 증명
```

```bash
# DNSSEC 서명 확인
dig +dnssec www.example.com
dig +sigchase www.example.com  # 신뢰 체인 검증
```

### DNS over HTTPS (DoH)

DNS 쿼리를 HTTPS 프로토콜로 암호화하여 전송하는 방식이다.

```
기존 DNS:  UDP 포트 53 (평문, 도청 가능)
DoH:       HTTPS 포트 443 (암호화, 도청 불가)

DoH 엔드포인트 예시:
- Cloudflare: https://1.1.1.1/dns-query
- Google:     https://dns.google/dns-query
```

### DNS over TLS (DoT)

DNS 쿼리를 TLS로 암호화. TCP 포트 853을 사용한다.

### DNS Hijacking

ISP, 정부, 또는 악성 라우터가 DNS 응답을 가로채거나 변조하는 공격이다.

```
대응책:
- VPN 사용
- DoH/DoT 사용 (암호화된 DNS)
- 하드코딩된 IP 사용 (임시방편)
```

---

## 7. 면접 포인트

### Q1. DNS 조회 과정을 순서대로 설명하세요.

브라우저 캐시 → OS 캐시(`/etc/hosts`) → Recursive Resolver 캐시 → Root DNS → TLD DNS → Authoritative DNS 순서로 조회하며, 각 단계에서 캐시 히트 시 이후 단계를 생략한다.

### Q2. CNAME과 A 레코드의 차이점은 무엇인가요?

A 레코드는 도메인을 IP 주소에 직접 매핑하고, CNAME은 도메인을 다른 도메인 이름에 매핑한다. CNAME은 IP 변경 시 별도 수정이 불필요하다는 장점이 있지만, Zone Apex에는 사용할 수 없다.

### Q3. TTL을 짧게 설정하면 어떤 장단점이 있나요?

장점: IP 변경이나 장애 전환 시 빠른 전파. 단점: DNS 쿼리 빈도 증가로 인한 네트워크 부하 및 응답 지연 가능성 증가. 마이그레이션 전에는 TTL을 낮게 조정하는 것이 일반적이다.

### Q4. DNS Spoofing이란 무엇이며 어떻게 방어하나요?

공격자가 Recursive Resolver의 캐시에 가짜 IP를 주입해 사용자를 악성 서버로 유도하는 공격이다. DNSSEC으로 응답의 무결성을 검증하거나, DoH/DoT로 DNS 쿼리 자체를 암호화하여 방어한다.

### Q5. 재귀적 쿼리와 반복적 쿼리의 차이는 무엇인가요?

재귀적 쿼리는 Recursive Resolver가 클라이언트를 대신해 전체 조회를 완료하고 최종 결과만 반환한다. 반복적 쿼리는 각 DNS 서버가 다음 서버의 주소를 알려주고, Resolver가 직접 다음 서버에 질의하는 방식이다. 일반적으로 클라이언트-Resolver 간은 재귀적 쿼리, Resolver-Root/TLD/Auth 간은 반복적 쿼리를 사용한다.

### Q6. MX 레코드의 우선순위 숫자는 낮을수록 우선순위가 높은가요, 낮은가요?

낮을수록 우선순위가 높다. 이메일 서버는 가장 낮은 숫자의 MX 레코드를 먼저 시도하고, 실패하면 다음 낮은 숫자의 서버로 시도한다.

### 핵심 키워드 정리

| 키워드 | 설명 |
|--------|------|
| Recursive Resolver | 클라이언트 대신 DNS 조회를 수행하는 서버 |
| Authoritative NS | 도메인의 실제 레코드를 보유한 최종 권한 서버 |
| TTL | 캐시 유효 시간 (초 단위) |
| DNSSEC | DNS 응답에 디지털 서명을 추가하는 보안 확장 |
| DoH/DoT | DNS 쿼리를 암호화하는 프로토콜 |
| Zone Apex | 루트 도메인 자체 (CNAME 사용 불가) |
