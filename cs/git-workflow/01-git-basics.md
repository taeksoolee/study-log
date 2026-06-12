# 1. Git 핵심 개념

## 목차

1. [Git 내부 구조 (Object DB)](#1-git-내부-구조-object-db)
2. [Branch, HEAD, Detached HEAD](#2-branch-head-detached-head)
3. [merge vs rebase vs squash](#3-merge-vs-rebase-vs-squash)
4. [cherry-pick, stash, reflog](#4-cherry-pick-stash-reflog)
5. [reset vs revert vs restore](#5-reset-vs-revert-vs-restore)
6. [.gitignore, .gitattributes](#6-gitignore-gitattributes)
7. [면접 포인트](#7-면접-포인트)

---

## 1. Git 내부 구조 (Object DB)

Git은 **콘텐츠 주소 지정 파일 시스템(content-addressable filesystem)** 위에 구축된 버전 관리 도구입니다.
모든 데이터는 `.git/objects/` 디렉터리에 네 가지 오브젝트 타입으로 저장됩니다.

### 오브젝트 타입

| 타입 | 설명 | 저장 내용 |
|------|------|-----------|
| **blob** | 파일의 내용 스냅샷 | 파일 데이터 (파일명 미포함) |
| **tree** | 디렉터리 스냅샷 | blob/tree 참조 + 파일명 + 권한 |
| **commit** | 특정 시점의 프로젝트 상태 | tree 참조 + 부모 커밋 + 메타데이터(작성자, 시각, 메시지) |
| **tag** | 특정 커밋에 대한 고정 참조 | commit 참조 + 태그 메시지 + 서명 정보 |

### SHA-1 해시

모든 오브젝트는 **SHA-1 해시(40자 16진수)** 로 식별됩니다.
동일한 내용이면 항상 같은 해시값이 생성되므로, 중복 저장이 방지됩니다.

```
해시 예시: a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2
디스크 경로: .git/objects/a1/b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2
```

### git cat-file 명령어 예제

```bash
# 오브젝트 타입 확인
git cat-file -t HEAD          # commit

# 오브젝트 내용 출력
git cat-file -p HEAD          # 최신 커밋 내용 출력
git cat-file -p HEAD^{tree}   # 커밋이 가리키는 tree 출력
git cat-file -p <blob-hash>   # 파일 내용 출력

# 예: 커밋 내용 확인
# tree 4b825dc642cb6eb9a060e54bf8d69288fbee4904
# parent 1a2b3c4d5e6f...
# author 홍길동 <gildong@example.com> 1700000000 +0900
# committer 홍길동 <gildong@example.com> 1700000000 +0900
#
# feat: 사용자 인증 기능 추가
```

---

## 2. Branch, HEAD, Detached HEAD

### Branch는 커밋 포인터

Git의 브랜치는 특정 커밋을 가리키는 **가변 포인터(40바이트 파일)** 에 불과합니다.
새 커밋이 생성될 때마다 현재 브랜치 포인터가 자동으로 앞으로 이동합니다.

```bash
# 브랜치 파일 실제 위치와 내용
cat .git/refs/heads/main
# a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2
```

### HEAD

`HEAD`는 **현재 작업 중인 위치**를 가리키는 특수 포인터입니다.
일반적으로 HEAD는 브랜치 이름을 가리키고, 브랜치가 커밋을 가리킵니다.

```
HEAD → main → 커밋 A

# .git/HEAD 파일 내용 (일반 상태)
ref: refs/heads/main
```

### Detached HEAD 상태

HEAD가 브랜치가 아닌 **특정 커밋을 직접 가리키는 상태**입니다.
이 상태에서 커밋을 해도 브랜치에 연결되지 않아 나중에 접근하기 어려워질 수 있습니다.

**발생 원인**
- `git checkout <커밋 해시>` 실행
- `git checkout <태그>` 실행
- `git rebase` 진행 중

```bash
# Detached HEAD 진입
git checkout a1b2c3d

# .git/HEAD 파일 내용 (detached 상태)
a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2

# 복구 방법 1: 기존 브랜치로 돌아가기
git checkout main

# 복구 방법 2: 현재 위치에서 새 브랜치 생성
git checkout -b new-branch

# 복구 방법 3: 이미 커밋했다면 브랜치에 연결
git branch new-branch HEAD
git checkout new-branch
```

---

## 3. merge vs rebase vs squash

### merge

두 브랜치의 변경 사항을 합치는 **병합 커밋(merge commit)** 을 생성합니다.
히스토리에 브랜치 분기와 합류 지점이 그대로 남습니다.

```bash
git checkout main
git merge feature/login
# Merge commit: "Merge branch 'feature/login'"
```

### rebase

피처 브랜치의 커밋들을 대상 브랜치의 끝으로 **재배치(replay)** 합니다.
선형 히스토리를 유지하지만, 커밋 해시가 변경됩니다.

```bash
git checkout feature/login
git rebase main
# feature/login의 커밋들이 main 끝에 재생성됨

# 이후 main에 fast-forward merge
git checkout main
git merge feature/login
```

### squash

여러 커밋을 **하나의 커밋으로 압축**합니다. 피처 브랜치의 지저분한 WIP 커밋들을 정리할 때 유용합니다.

```bash
# merge --squash: 피처 브랜치의 모든 커밋을 staged 상태로 가져옴
git checkout main
git merge --squash feature/login
git commit -m "feat: 로그인 기능 구현"

# 인터랙티브 rebase로 squash
git rebase -i HEAD~3
# pick → squash(s)로 변경하여 커밋 합치기
```

### 언제 사용하는가

| 상황 | 추천 방법 | 이유 |
|------|-----------|------|
| 팀 협업, 히스토리 보존이 중요한 경우 | merge | 분기 맥락이 그대로 보존됨 |
| 공개되지 않은 로컬 브랜치 정리 | rebase | 선형 히스토리로 가독성 향상 |
| 피처 브랜치를 main에 합칠 때 커밋 정리 | squash merge | main 히스토리를 깔끔하게 유지 |
| **절대 금지** | 공개 브랜치에 rebase | 팀원의 히스토리와 충돌 발생 |

---

## 4. cherry-pick, stash, reflog

### cherry-pick

다른 브랜치의 **특정 커밋 하나(또는 여러 개)를 현재 브랜치에 복사**합니다.

```bash
# 특정 커밋 적용
git cherry-pick a1b2c3d

# 범위 지정 (a 미포함, b 포함)
git cherry-pick a1b2c3d..e4f5g6h

# 충돌 발생 시
git cherry-pick --continue   # 충돌 해결 후 계속
git cherry-pick --abort      # 취소
```

**실용 시나리오**: develop 브랜치에서 발견된 긴급 버그 수정 커밋을 main 또는 release 브랜치에 선별 적용할 때

### stash

작업 중인 변경 사항을 **임시 스택에 저장**하고 워킹 디렉터리를 깨끗하게 만듭니다.

```bash
# 현재 변경 사항 저장 (추적된 파일만)
git stash

# 이름을 붙여 저장
git stash save "WIP: 결제 모듈 리팩터링"

# 추적되지 않은 파일(-u)까지 저장
git stash -u

# stash 목록 확인
git stash list
# stash@{0}: WIP: 결제 모듈 리팩터링
# stash@{1}: On main: 임시 수정

# 최신 stash 적용 후 목록에서 제거
git stash pop

# 특정 stash 적용 (목록에 유지)
git stash apply stash@{1}

# stash 삭제
git stash drop stash@{0}
git stash clear   # 전체 삭제
```

### reflog

HEAD의 **이동 기록(reference log)** 을 보여줍니다.
reset --hard, 잘못된 rebase 등으로 커밋을 잃었을 때 복구에 사용합니다.

```bash
# reflog 확인
git reflog
# a1b2c3d HEAD@{0}: reset: moving to HEAD~1
# e4f5g6h HEAD@{1}: commit: feat: 결제 기능 추가   ← 잃어버린 커밋
# ...

# 잃어버린 커밋 복구
git checkout e4f5g6h           # detached HEAD로 확인
git branch recovered-branch    # 브랜치로 고정

# 또는 reset으로 직접 복구
git reset --hard HEAD@{1}
```

---

## 5. reset vs revert vs restore

### reset

현재 브랜치 포인터를 **이전 커밋으로 이동**시킵니다. 로컬 히스토리를 실제로 변경하므로, 공개 브랜치에는 사용하지 않습니다.

```bash
# --soft: 커밋만 취소, 변경 사항은 staged 상태로 유지
git reset --soft HEAD~1

# --mixed (기본값): 커밋 취소 + unstaged 상태로 변경 사항 유지
git reset HEAD~1
git reset --mixed HEAD~1

# --hard: 커밋 취소 + 변경 사항 완전 삭제 (주의!)
git reset --hard HEAD~1
```

| 옵션 | 커밋 히스토리 | Staged 영역 | 워킹 디렉터리 |
|------|--------------|-------------|--------------|
| --soft | 이전으로 | 변경 유지 (staged) | 변경 유지 |
| --mixed | 이전으로 | 초기화 | 변경 유지 |
| --hard | 이전으로 | 초기화 | 초기화 (삭제) |

### revert

지정한 커밋의 변경 사항을 **되돌리는 새 커밋을 생성**합니다.
히스토리를 보존하므로 공개 브랜치에서 안전하게 사용할 수 있습니다.

```bash
# 특정 커밋 되돌리기
git revert a1b2c3d

# 커밋 메시지 편집 없이 바로 실행
git revert --no-edit a1b2c3d

# 여러 커밋 되돌리기 (역순으로)
git revert HEAD~3..HEAD
```

### restore

**워킹 디렉터리 또는 staging 영역의 파일을 복원**합니다.
커밋 히스토리에는 영향을 주지 않습니다. (Git 2.23+)

```bash
# 워킹 디렉터리의 파일을 최근 커밋 상태로 복원
git restore src/app.js

# staged 파일을 unstage (git reset HEAD <file> 대체)
git restore --staged src/app.js

# 특정 커밋 시점으로 파일 복원
git restore --source=HEAD~2 src/app.js
```

### 용도 비교 요약

| 명령어 | 목적 | 히스토리 변경 | 공개 브랜치 사용 |
|--------|------|--------------|----------------|
| reset | 로컬 커밋 취소 / 되돌리기 | 변경됨 | 금지 |
| revert | 안전하게 변경 사항 취소 | 추가됨 | 권장 |
| restore | 파일 단위 복원 | 없음 | 가능 |

---

## 6. .gitignore, .gitattributes

### .gitignore

Git이 추적하지 않을 파일/디렉터리 패턴을 정의합니다.

```gitignore
# 특정 파일
.env
.env.local

# 특정 확장자
*.log
*.tmp
*.pyc

# 디렉터리 전체
node_modules/
dist/
build/
.cache/

# 예외 (앞에 ! 사용)
!important.log

# 루트 기준 경로 (앞에 / 사용)
/config/local.json

# 특정 디렉터리 내 패턴
docs/**/*.pdf
```

**주의 사항**
- 이미 추적 중인 파일은 .gitignore 추가만으로 무시되지 않습니다.
  이 경우 `git rm --cached <파일>` 로 추적 해제가 필요합니다.
- 전역 gitignore는 `~/.gitignore_global` 에 설정하고
  `git config --global core.excludesfile ~/.gitignore_global` 으로 등록합니다.

### .gitattributes

파일별 Git 동작을 세밀하게 제어합니다.

```gitattributes
# 줄바꿈 문자 통일 (Windows/Mac 혼용 팀에서 중요)
* text=auto
*.sh text eol=lf
*.bat text eol=crlf

# 이진 파일 명시 (diff/merge 비활성화)
*.png binary
*.jpg binary
*.pdf binary

# diff 드라이버 지정 (Word 문서 등)
*.docx diff=word

# merge 전략 지정
package-lock.json merge=ours

# export-ignore: git archive 시 제외
.github export-ignore
tests/ export-ignore
```

**주요 용도**
- `text=auto` / `eol`: OS 간 줄바꿈 문제(CRLF vs LF) 해결
- `binary`: 이진 파일에 diff/merge 시도를 방지하여 성능 향상
- `merge=ours`: 자동 생성 파일(lock 파일 등)의 충돌 방지
- `export-ignore`: 배포 아카이브에 불필요한 파일 제외

---

## 7. 면접 포인트

### Q1. merge와 rebase의 차이는 무엇인가요? 언제 rebase를 사용하면 안 되나요?

> **merge**: 두 브랜치를 합치는 병합 커밋을 생성하여 분기 히스토리를 보존합니다.
> **rebase**: 커밋들을 대상 브랜치 끝으로 재배치하여 선형 히스토리를 만듭니다.
> 이미 원격에 푸시된 공개 브랜치에는 rebase를 사용하면 안 됩니다. 커밋 해시가 바뀌어
> 다른 팀원의 로컬 히스토리와 충돌이 발생하기 때문입니다("황금률: 공개 커밋은 rebase하지 않는다").

### Q2. git reset --hard와 git revert의 차이는 무엇인가요?

> **reset --hard**: 브랜치 포인터를 직접 이동시켜 커밋 히스토리를 삭제합니다. 로컬 전용.
> **revert**: 취소 내용을 담은 새 커밋을 추가합니다. 히스토리가 보존되므로 main 같은 공개
> 브랜치에서 이전 버전으로 돌아갈 때 사용합니다.

### Q3. detached HEAD가 무엇이며 어떻게 복구하나요?

> HEAD가 브랜치가 아닌 특정 커밋 해시를 직접 가리키는 상태입니다.
> 이 상태에서 커밋하면 어떤 브랜치에도 속하지 않아 나중에 garbage collect될 수 있습니다.
> 복구: `git branch new-branch` 로 브랜치를 만들거나, `git reflog` 로 해시를 확인하여
> `git checkout -b new-branch <해시>` 로 복구합니다.

### Q4. git stash와 WIP 커밋 중 어느 것을 선호하나요?

> 상황에 따라 다릅니다. **stash**는 임시 작업 보관에 간편하지만 팀원과 공유가 불가능합니다.
> **WIP 커밋**은 원격에 푸시하여 다른 기기나 팀원과 공유할 수 있고, reflog에서 명확히
> 추적됩니다. 단기 보관은 stash, 장기 보관이나 공유가 필요하면 WIP 커밋을 사용합니다.

### Q5. cherry-pick은 언제 사용하나요?

> 특정 브랜치의 커밋 하나만 다른 브랜치에 적용해야 할 때 사용합니다.
> 대표적인 예: develop에서 발견한 버그를 수정한 커밋을 main(또는 release) 브랜치에만
> 선별 적용하는 핫픽스 시나리오. 단, cherry-pick은 동일한 변경을 복사하므로 히스토리상
> 중복 커밋이 생길 수 있어 남용은 금물입니다.

### Q6. .gitignore에 파일을 추가했는데 여전히 추적된다면 어떻게 해야 하나요?

> Git이 이미 해당 파일을 추적(tracked)하고 있기 때문입니다. .gitignore는 처음부터
> 추적하지 않을 파일에만 적용됩니다. 해결책: `git rm --cached <파일>` 로 인덱스에서
> 제거한 뒤 커밋합니다. 워킹 디렉터리의 실제 파일은 유지됩니다.

### Q7. git reflog는 언제 사용하나요?

> `reset --hard`, 잘못된 `rebase`, 브랜치 삭제 등으로 커밋을 잃어버렸을 때 사용합니다.
> reflog는 HEAD의 모든 이동 기록을 로컬에 30일간 보관하므로, 해당 해시를 찾아
> `git checkout` 또는 `git reset` 으로 복구할 수 있습니다. 원격에는 존재하지 않는
> 로컬 전용 안전망입니다.
