# Git 워크플로우

Git의 핵심 개념부터 다양한 협업 워크플로우까지, 실무와 면접에 필요한 내용을 정리한 학습 자료입니다.

---

## 목차

| 파일 | 주제 | 설명 |
|------|------|------|
| [01-git-basics.md](./01-git-basics.md) | Git 핵심 개념 | Git 내부 구조(Object DB), Branch/HEAD, merge/rebase/squash 차이, cherry-pick, stash, reflog, reset/revert/restore, .gitignore/.gitattributes |
| [02-gitflow.md](./02-gitflow.md) | GitFlow | main/develop/feature/release/hotfix 브랜치 전략, 릴리스 기반 프로젝트에 적합한 엄격한 워크플로우 |
| [03-github-flow.md](./03-github-flow.md) | GitHub Flow | main 브랜치 중심의 단순한 워크플로우, PR 기반 협업, 지속적 배포(CD) 환경에 적합 |
| [04-gitlab-flow.md](./04-gitlab-flow.md) | GitLab Flow | GitHub Flow에 환경 브랜치(production, staging)를 추가한 워크플로우, 배포 환경이 여러 개인 팀에 적합 |
| [05-trunk-based.md](./05-trunk-based.md) | Trunk-Based Development | 모든 개발자가 main(trunk)에 직접 또는 단기 브랜치를 통해 빈번히 통합하는 방식, CI/CD 파이프라인과 궁합이 좋음 |
| [06-commit-convention.md](./06-commit-convention.md) | 커밋 컨벤션 | Conventional Commits 규격, feat/fix/chore 등 타입 정의, 커밋 메시지 작성 가이드, CHANGELOG 자동화 |
| [visualizer/index.html](./visualizer/index.html) | 인터랙티브 시각화 허브 | 각 워크플로우를 브라우저에서 직접 시각화하고 비교할 수 있는 인터랙티브 HTML 도구 |

---

## 학습 순서 추천

처음 Git 워크플로우를 학습하거나 개념을 체계적으로 정리하고 싶다면 아래 순서를 따르세요.

```
1단계 — 기초 다지기
  └─ 01-git-basics.md
       Git 내부 구조와 핵심 명령어를 이해하지 않으면
       워크플로우가 "왜" 그렇게 설계되었는지 파악하기 어렵습니다.

2단계 — 워크플로우 비교
  ├─ 02-gitflow.md         (릴리스 주기가 명확한 팀)
  ├─ 03-github-flow.md     (소규모·웹서비스 팀)
  ├─ 04-gitlab-flow.md     (복수 배포 환경이 있는 팀)
  └─ 05-trunk-based.md     (CI/CD 성숙도가 높은 팀)

3단계 — 협업 품질 향상
  └─ 06-commit-convention.md
       어떤 워크플로우를 선택하든 커밋 컨벤션은 공통으로 적용됩니다.

4단계 — 시각화로 복습
  └─ visualizer/index.html
       브랜치 흐름을 눈으로 확인하며 각 워크플로우를 비교합니다.
```

> 이미 Git 기초가 탄탄하다면 2단계부터 시작해도 무방합니다.

---

## 면접 빈출 주제

Git 관련 기술 면접에서 자주 등장하는 주제와 핵심 키워드입니다. 각 파일의 "면접 포인트" 섹션을 참고하세요.

### Git 명령어 / 내부 동작

- **merge vs rebase의 차이** — 히스토리 보존 vs 선형 히스토리, 공개 브랜치에 rebase 금지 이유
- **reset vs revert** — 로컬 커밋 되돌리기 vs 공개 히스토리에 안전한 되돌리기
- **detached HEAD** — 상태 설명, 복구 방법, 발생 원인
- **cherry-pick 활용 시나리오** — hotfix를 특정 브랜치에만 적용하는 경우 등
- **stash와 WIP 커밋의 차이** — 임시 저장 전략 비교

### 워크플로우

- **GitFlow vs GitHub Flow 선택 기준** — 릴리스 주기, 팀 규모, 배포 빈도
- **Trunk-Based Development가 CI/CD와 어울리는 이유** — 장기 브랜치의 통합 비용, Feature Flag
- **PR(Pull Request) / MR(Merge Request) 리뷰 프로세스** — 코드 품질 게이트, 승인 정책

### 커밋 관리

- **좋은 커밋 메시지의 조건** — Conventional Commits, 원자적 커밋
- **squash merge를 사용하는 이유** — 피처 브랜치 커밋 정리, main 히스토리 가독성
- **git bisect로 버그 도입 커밋 찾기** — 이진 탐색 원리
