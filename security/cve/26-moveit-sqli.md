# CVE-2023-34362 - MOVEit Transfer SQL Injection

## 개요

| 항목 | 내용 |
|------|------|
| CVE ID | CVE-2023-34362 |
| CVSS | 9.8 (Critical) |
| 영향 소프트웨어 | Progress MOVEit Transfer |
| 영향 버전 | 2021.0 이전 모든 버전, 2021.0.6 이전, 2021.1.4 이전, 2022.0.4 이전, 2022.1.5 이전, 2023.0.1 이전 |
| 수정 버전 | 2023.0.1, 2022.1.5, 2022.0.4, 2021.1.4, 2021.0.6 |
| 공격 유형 | SQL Injection → RCE |
| 발견일 | 2023-05-31 |

## 영향 범위 & 심각성

MOVEit Transfer는 기업용 관리형 파일 전송(MFT) 솔루션으로, 대규모 데이터 유출 사건의 핵심이었다.

- **Cl0p 랜섬웨어 그룹**이 제로데이로 대규모 악용
- 전 세계 2,500개 이상의 조직이 피해 (BBC, Shell, Ernst & Young, 미국 정부 기관 등)
- 약 6,200만 명의 개인정보 유출
- 금융, 헬스케어, 정부 기관에서 널리 사용되는 파일 전송 도구
- 2023년 최대 규모의 사이버 공격 사건 중 하나

## 취약점 기술 분석

### 근본 원인

MOVEit Transfer의 웹 애플리케이션에서 인증 없이 접근 가능한 엔드포인트가 SQL Injection에 취약했다.

```
# 취약한 엔드포인트
/moveitisapi/moveitisapi.dll?action=m2  (IIS 기반)
/guestaccess.aspx  (인증 불필요)
/api/v1/...  (특정 API 엔드포인트)
```

### 공격 체인

1. 인증 없이 접근 가능한 웹 엔드포인트에 조작된 SQL 쿼리 전송
2. SQL Injection을 통해 데이터베이스에서 API 토큰 또는 세션 정보 추출
3. 탈취한 인증 정보로 관리 기능 접근
4. 웹쉘(`human2.aspx`) 업로드를 통해 RCE 달성
5. Azure Blob Storage 또는 로컬 스토리지에서 파일 대량 유출

### 기술적 세부사항

```sql
-- SQL Injection을 통한 sysadmin 세션 탈취 (개념적 예시)
-- MOVEit의 내부 세션 테이블에서 관리자 토큰 추출
SELECT token FROM sessions WHERE username='sysadmin'
```

## 공격 시나리오

```
1단계: 인터넷에 노출된 MOVEit Transfer 인스턴스 스캔
2단계: /guestaccess.aspx 등 인증 불필요 엔드포인트에 SQL Injection
3단계: 데이터베이스에서 관리자 API 키 또는 세션 토큰 추출
4단계: 관리자 권한으로 웹쉘(human2.aspx) 업로드
5단계: 웹쉘을 통해 파일 시스템 접근 및 대량 데이터 유출
6단계: Azure Blob Storage 연결 정보 탈취 → 클라우드 스토리지 직접 접근

Cl0p 그룹의 실제 공격:
- 제로데이 시점에 자동화된 대규모 스캔 및 착취
- 랜섬 요구 대신 데이터 유출 후 공개 협박 전략
```

## 방어 방법

1. **즉시 패치 적용**: Progress 제공 보안 패치 즉시 설치
2. **네트워크 격리**: MOVEit 서버를 인터넷에서 직접 노출하지 않음
3. **IOC 점검**: `human2.aspx` 웹쉘 존재 여부, 비정상 IIS 로그 확인
4. **방화벽 규칙**: 443/80 포트의 인바운드 트래픽을 허용된 IP로 제한
5. **WAF 적용**: SQL Injection 탐지 규칙 활성화
6. **파일 전송 대안 검토**: 제로 트러스트 기반 파일 공유 솔루션 검토
7. **감사 로그 강화**: 파일 다운로드 활동 모니터링 및 이상 탐지

## 교훈

- **MFT 솔루션의 보안 리스크**: 파일 전송 도구는 민감 데이터가 집중되므로 최우선 보호 대상
- **인증 없는 엔드포인트의 위험**: 공개 접근 가능한 모든 엔드포인트에 입력 검증 필수
- **공급망 단일 실패점**: 하나의 MFT 솔루션 취약점으로 수천 개 조직이 동시 피해
- **제로데이 대응 속도**: Cl0p은 패치 전에 이미 대규모 자동 공격을 실행했음
- **Prepared Statement 사용**: SQL Injection은 2023년에도 여전히 크리티컬 위협

## 참고 자료

- [Progress Security Advisory](https://www.progress.com/security/moveit-transfer-and-moveit-cloud-vulnerability)
- [NVD - CVE-2023-34362](https://nvd.nist.gov/vuln/detail/CVE-2023-34362)
- [CISA Advisory AA23-158A](https://www.cisa.gov/news-events/cybersecurity-advisories/aa23-158a)
- [Mandiant - MOVEit Analysis](https://www.mandiant.com/resources/blog/zero-day-moveit-data-theft)
- [Emsisoft MOVEit Impact Tracker](https://www.emsisoft.com/en/blog/44123/unpacking-the-moveit-breach-statistics-and-analysis/)
