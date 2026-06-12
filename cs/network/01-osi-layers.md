# 1. OSI 7계층 모델

## 목차
1. OSI 모델 개요
2. OSI 7계층 각 역할과 프로토콜
3. 데이터 단위 (PDU)
4. TCP/IP 4계층과 비교
5. 실제 데이터 전송 흐름
6. 면접 포인트

---

## 1. OSI 모델 개요

OSI(Open Systems Interconnection) 모델은 ISO에서 1984년에 제정한 네트워크 통신 표준 참조 모델입니다. 서로 다른 시스템 간의 통신을 7개의 계층으로 추상화합니다.

```
발신측                                          수신측
─────────────────────────────────────────────────────
7. 응용 계층  (Application)  ←──────────→  7. 응용 계층
6. 표현 계층  (Presentation) ←──────────→  6. 표현 계층
5. 세션 계층  (Session)      ←──────────→  5. 세션 계층
4. 전송 계층  (Transport)    ←──────────→  4. 전송 계층
3. 네트워크 계층(Network)    ←──────────→  3. 네트워크 계층
2. 데이터링크계층(Data Link)  ←──────────→  2. 데이터링크계층
1. 물리 계층  (Physical)     ←──────────→  1. 물리 계층
─────────────────────────────────────────────────────
```

각 계층은 아래 계층의 서비스를 이용하고 위 계층에 서비스를 제공합니다.

---

## 2. OSI 7계층 각 역할과 프로토콜

### 7계층 - 응용 계층 (Application Layer)

```
역할: 사용자가 직접 상호작용하는 네트워크 서비스 제공
     파일 전송, 이메일, 웹 브라우징, DNS 등

프로토콜:
  HTTP/HTTPS  - 웹 통신
  FTP/SFTP    - 파일 전송
  SMTP/POP3/IMAP - 이메일
  DNS         - 도메인 이름 해석
  SSH         - 보안 원격 접속
  DHCP        - IP 주소 자동 할당
  SNMP        - 네트워크 관리
  WebSocket   - 양방향 실시간 통신

PDU: Data (메시지)
장치: 게이트웨이, 프록시 서버
```

### 6계층 - 표현 계층 (Presentation Layer)

```
역할: 데이터 형식 변환, 인코딩/디코딩, 압축, 암호화

기능:
  - 문자 인코딩: ASCII ↔ Unicode 변환
  - 데이터 압축: gzip, deflate
  - 암호화/복호화: SSL/TLS (현재는 Transport 계층으로 분류하기도 함)
  - 데이터 직렬화: JSON, XML, Protobuf

예시:
  - JPEG, PNG, GIF (이미지 포맷 변환)
  - MP3, MPEG (미디어 인코딩)
  - MIME (이메일 첨부 파일)

PDU: Data
```

### 5계층 - 세션 계층 (Session Layer)

```
역할: 통신 세션 수립, 유지, 종료 및 동기화

기능:
  - 세션 설정/관리/종료
  - 체크포인트(동기화 지점): 긴 파일 전송 중 실패 시 재개 지점
  - 전이중(Full-Duplex) / 반이중(Half-Duplex) 통신 제어
  - 인증(Authentication)

프로토콜:
  NetBIOS     - 윈도우 네트워크 세션
  RPC         - 원격 프로시저 호출
  SQL 세션    - 데이터베이스 세션

PDU: Data
```

### 4계층 - 전송 계층 (Transport Layer)

```
역할: 종단간(end-to-end) 신뢰성 있는 데이터 전송
     프로세스 간 통신 (포트 번호로 식별)

핵심 프로토콜:
  TCP (Transmission Control Protocol)
    - 신뢰성: 3-way handshake, 오류 감지/복구
    - 순서 보장: 시퀀스 번호
    - 흐름 제어: 슬라이딩 윈도우
    - 혼잡 제어: 느린 시작, 혼잡 회피
    - 연결 지향: 연결 수립 후 데이터 전송

  UDP (User Datagram Protocol)
    - 비연결형, 순서 미보장
    - 속도 우선: 스트리밍, 게임, DNS 쿼리
    - 오버헤드 낮음

잘 알려진 포트:
  20/21 FTP    22 SSH     23 Telnet
  25 SMTP      53 DNS     80 HTTP
  443 HTTPS    3306 MySQL 5432 PostgreSQL
  6379 Redis   27017 MongoDB

PDU: 세그먼트(TCP) / 데이터그램(UDP)
장치: 방화벽(4계층), 로드 밸런서
```

### 3계층 - 네트워크 계층 (Network Layer)

```
역할: 서로 다른 네트워크 간 패킷 라우팅
     논리 주소(IP) 지정

핵심 프로토콜:
  IP (Internet Protocol)
    IPv4: 32비트 주소 (예: 192.168.1.1)
    IPv6: 128비트 주소 (예: 2001:db8::1)

  ICMP  - 오류 보고 및 진단 (ping, traceroute)
  ARP   - IP → MAC 주소 변환 (엄밀히는 2/3 경계)
  IGMP  - 멀티캐스트 그룹 관리
  OSPF, BGP - 라우팅 프로토콜

PDU: 패킷(Packet)
장치: 라우터, L3 스위치
```

### 2계층 - 데이터 링크 계층 (Data Link Layer)

```
역할: 같은 네트워크(LAN) 내 노드 간 데이터 전송
     오류 감지(FCS/CRC), 물리 주소(MAC) 지정

구성:
  MAC (Media Access Control): 하드웨어 주소 (48비트)
  LLC (Logical Link Control): 상위 프로토콜 식별

프로토콜:
  Ethernet   - 가장 일반적인 LAN 프로토콜
  Wi-Fi(IEEE 802.11) - 무선 LAN
  PPP        - 점대점 연결
  VLAN       - 가상 LAN 분리

PDU: 프레임(Frame)
장치: 스위치(L2), 브릿지, NIC(네트워크 카드)
```

### 1계층 - 물리 계층 (Physical Layer)

```
역할: 비트(0과 1)를 전기 신호, 광 신호, 전파로 변환하여 물리 매체로 전송

내용:
  - 전압 레벨, 신호 타이밍
  - 케이블 사양: 이더넷(Cat5e, Cat6), 광케이블
  - 무선 주파수: 2.4GHz, 5GHz (Wi-Fi)
  - 데이터 전송 속도(bps), 최대 거리

프로토콜/표준:
  USB, Bluetooth, 802.11 (Wi-Fi 물리 계층)
  DSL, ISDN, RS-232

PDU: 비트(Bit)
장치: 허브(Hub), 리피터, 케이블, 모뎀
```

---

## 3. 데이터 단위 (PDU)

PDU(Protocol Data Unit)는 각 계층에서 사용하는 데이터 묶음 단위입니다.

```
7 Application  │ Data (Message)
6 Presentation │ Data
5 Session      │ Data
────────────────│─────────────────────────────────────
4 Transport    │ Segment (TCP) / Datagram (UDP)
               │ [TCP Header][Data]
               │  Port, Seq, Ack, Flags, Window
────────────────│─────────────────────────────────────
3 Network      │ Packet
               │ [IP Header][Segment]
               │  src IP, dst IP, TTL, Protocol
────────────────│─────────────────────────────────────
2 Data Link    │ Frame
               │ [Frame Header][Packet][FCS]
               │  src MAC, dst MAC, Type, CRC
────────────────│─────────────────────────────────────
1 Physical     │ Bit (0/1 전기 신호)
```

### 캡슐화와 역캡슐화

```
송신 (캡슐화):    7→1: 각 계층이 헤더/트레일러 추가
수신 (역캡슐화): 1→7: 각 계층이 자신의 헤더 제거 후 상위로 전달

Data
  → [TCP Header|Data]                     (전송 계층)
  → [IP Header|TCP Header|Data]           (네트워크 계층)
  → [MAC Header|IP|TCP|Data|FCS]          (데이터링크 계층)
  → 전기 신호                              (물리 계층)
```

---

## 4. TCP/IP 4계층과 비교

TCP/IP 모델은 인터넷의 실제 구현 모델입니다. OSI는 이론적 참조 모델입니다.

| OSI 7계층 | TCP/IP 4계층 | 주요 프로토콜 |
|-----------|-------------|---------------|
| 7. 응용   | 4. 응용 계층 | HTTP, FTP, DNS, SMTP |
| 6. 표현   | ↑ (응용에 통합) | TLS, MIME |
| 5. 세션   | ↑ (응용에 통합) | TLS, RPC |
| 4. 전송   | 3. 전송 계층 | TCP, UDP |
| 3. 네트워크 | 2. 인터넷 계층 | IP, ICMP, ARP |
| 2. 데이터링크 | 1. 네트워크 접근 계층 | Ethernet, Wi-Fi |
| 1. 물리   | ↑ (네트워크 접근에 통합) | 물리 매체 |

---

## 5. 실제 데이터 전송 흐름

```
시나리오: 브라우저에서 https://www.example.com 요청

[클라이언트]
  7. HTTP GET 요청 생성 (응용)
  6. TLS 암호화 (표현)
  5. TLS 세션 유지 (세션)
  4. TCP 세그먼트로 분할, 포트(443) 추가 (전송)
  3. IP 패킷 포장, 출발/도착 IP 추가 (네트워크)
  2. 이더넷 프레임 포장, MAC 주소 추가 (데이터링크)
  1. 전기 신호로 변환 → 케이블/공기 전파 (물리)

[라우터 1, 2, 3 ... (3계층까지만 처리)]
  1-3계층에서 목적지 IP를 보고 다음 홉으로 전달

[서버]
  1-7 역순으로 역캡슐화
  7. HTTP 요청 수신 → 응답 생성
```

---

## 6. 면접 포인트

### Q1. OSI 7계층을 외우는 좋은 방법은?

"**물 데 네 전 세 표 응**" (물리 데이터링크 네트워크 전송 세션 표현 응용) 또는 영어로는 "Please Do Not Throw Sausage Pizza Away" (Physical, Data Link, Network, Transport, Session, Presentation, Application).

### Q2. OSI 모델과 TCP/IP 모델의 차이는?

OSI는 ISO에서 만든 7계층 이론적 참조 모델로, 각 계층의 역할을 명확히 분리하여 표준화했습니다. TCP/IP는 인터넷이 실제로 구현된 4계층 모델입니다. OSI의 5~7계층을 TCP/IP에서는 응용 계층 하나로 통합하고, OSI의 1~2계층을 네트워크 접근 계층 하나로 통합했습니다. 실무에서는 TCP/IP 모델을 사용하지만, 개념 이해와 문제 진단에는 OSI 모델이 유용합니다.

### Q3. 각 계층에서 사용하는 주소 체계의 차이는?

- 2계층: MAC 주소 (48비트, 하드웨어 고유 주소, 같은 네트워크 내 통신)
- 3계층: IP 주소 (32/128비트, 논리 주소, 서로 다른 네트워크 간 라우팅)
- 4계층: 포트 번호 (16비트, 프로세스 식별, 0~65535)

ARP는 IP 주소로 같은 네트워크 내의 MAC 주소를 얻어냅니다.

### Q4. 라우터는 몇 계층 장치인가요?

라우터는 3계층(네트워크 계층)까지 처리합니다. IP 헤더를 읽어 목적지를 확인하고 다음 홉으로 전달합니다. 스위치는 2계층(데이터링크)까지 처리해 MAC 주소 테이블로 프레임을 전달합니다. 허브는 1계층으로, 들어온 신호를 모든 포트에 그냥 복사해서 내보냅니다.
