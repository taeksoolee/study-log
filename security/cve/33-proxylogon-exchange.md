# CVE-2021-26855 - ProxyLogon (Exchange Server SSRF)

## 개요

| 항목 | 내용 |
|------|------|
| CVE ID | CVE-2021-26855 |
| CVSS | 9.8 (Critical) |
| 영향 소프트웨어 | Microsoft Exchange Server |
| 영향 버전 | 2013 (CU 23 이전), 2016 (CU 19/18 이전), 2019 (CU 8/7 이전) |
| 수정 버전 | 2021년 3월 보안 업데이트 (KB5000871 등) |
| 공격 유형 | SSRF → RCE |
| 발견일 | 2021-03-02 |

## 영향 범위 & 심각성

Microsoft Exchange Server는 전 세계 기업 이메일 인프라의 핵심이다. 온프레미스 Exchange를 운영하는 모든 조직이 영향을 받았다.

**실제 피해:**
- Hafnium(중국 국가지원 APT 그룹) 등 최소 10개 이상의 위협 그룹이 제로데이로 악용
- 전 세계 250,000대 이상의 Exchange 서버가 침해된 것으로 추정
- 미국 정부, 유럽 은행 당국(EBA), 노르웨이 의회 등 주요 기관 피해
- 침해 후 웹쉘 설치, 이메일 전량 유출, 랜섬웨어 배포로 이어짐
- Microsoft가 긴급 패치 외에 원클릭 완화 도구(EOMT)까지 배포한 이례적 대응

## 취약점 기술 분석

### ProxyLogon 체인 구성

ProxyLogon은 두 개의 CVE를 체인으로 연결한 공격이다:
1. **CVE-2021-26855 (SSRF)**: Exchange CAS가 백엔드로 요청 프록시 시 인증 우회
2. **CVE-2021-27065 (임의 파일 쓰기)**: Exchange 관리 기능을 통해 웹쉘 작성

### SSRF 근본 원인

Exchange CAS의 `/ecp/` 엔드포인트에서:
- `X-BEResource` 쿠키를 통해 백엔드 서버를 지정할 수 있음
- SSRF를 통해 백엔드 서비스에 **SYSTEM 권한**으로 인증된 요청 전송 가능
- 백엔드는 프론트엔드로부터 온 요청을 신뢰하므로 추가 인증 없이 처리

### 핵심 문제
- **프론트엔드-백엔드 신뢰 모델의 결함**: CAS가 보내는 요청을 백엔드가 무조건 신뢰
- **쿠키 기반 라우팅 조작**: 사용자가 백엔드 대상을 지정할 수 있는 구조
- **인증 컨텍스트 혼동**: SSRF를 통해 SYSTEM 권한의 세션 획득

## 공격 시나리오

### 공격 체인 흐름

1. **SSRF로 관리자 SID 획득**
```http
POST /ecp/x.js HTTP/1.1
Host: target
Cookie: X-BEResource=admin@target:444/autodiscover/autodiscover.xml?#~1
```

2. **획득한 SID로 관리자 세션 생성** — ECP 엔드포인트에서 관리자 권한 확보

3. **OAB(Offline Address Book) 설정 변경으로 웹쉘 작성** — ExternalUrl을 웹쉘 코드로 설정

4. **웹쉘을 통한 RCE** — `aspx` 웹쉘로 SYSTEM 권한 명령 실행

### 결과
- 전체 이메일 접근 (모든 사용자 메일박스)
- Active Directory 정보 탈취
- 내부 네트워크 침투의 교두보

## 방어 방법

### 즉시 조치
1. **긴급 보안 업데이트 적용** (KB5000871)
2. Microsoft EOMT(Exchange On-Premises Mitigation Tool) 실행
3. IIS 로그에서 ProxyLogon IOC 검색:
```powershell
Get-ChildItem -Path "C:\inetpub\logs\LogFiles" -Recurse |
  Select-String -Pattern "autodiscover\.json.*\/mapi\/nspi|\/ecp\/.*x\.js"
```

### 장기 대책
- Exchange Online(Microsoft 365)으로 마이그레이션 검토
- Exchange 서버에 대한 인터넷 직접 노출 최소화
- 네트워크 세그멘테이션: Exchange를 별도 VLAN에 격리
- EDR 솔루션으로 웹쉘 생성 탐지

## 교훈

1. **온프레미스 인프라의 패치 관리**: 클라우드와 달리 직접 패치해야 하는 부담과 위험. 자동 업데이트가 없으면 방치되기 쉬움
2. **프록시 아키텍처의 신뢰 경계**: 프론트엔드-백엔드 간 암묵적 신뢰는 SSRF로 악용됨. 내부 요청도 인증해야 함
3. **제로데이 대응 속도**: 패치 공개 전 이미 대규모 악용이 진행될 수 있음. 탐지 역량이 핵심
4. **공격 체인 사고**: 단일 SSRF가 RCE 체인의 시작점이 됨. 낮은 심각도의 취약점도 체인에선 치명적
5. **이메일 서버 = 핵심 자산**: 이메일 서버 침해는 조직 전체 기밀 유출과 동일. 최우선 보호 대상으로 분류해야 함
6. **클라우드 마이그레이션 고려**: 보안 인력이 부족한 조직은 관리형 서비스(Microsoft 365)로 전환하는 것이 보안적으로 유리

## 참고 자료

- [NVD - CVE-2021-26855](https://nvd.nist.gov/vuln/detail/CVE-2021-26855)
- [Microsoft HAFNIUM 블로그](https://www.microsoft.com/en-us/security/blog/2021/03/02/hafnium-targeting-exchange-servers/)
- [Volexity 최초 발견 보고서](https://www.volexity.com/blog/2021/03/02/active-exploitation-of-microsoft-exchange-zero-day-vulnerabilities/)
- [CISA Emergency Directive 21-02](https://www.cisa.gov/emergency-directive-21-02)
- [ProxyLogon.com (연구자 공개 사이트)](https://proxylogon.com/)
