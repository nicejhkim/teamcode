# teamcode

팀 공용 Claude Code 하니스 플러그인. 새 프로젝트의 합의(킥오프), PRD를 이슈로 나누기, 요구사항 한 건을 이슈로 남기기, 이슈 하나 구현을 담당한다.

## 설치

```bash
claude plugin marketplace add <이 저장소 git URL>
claude plugin install teamcode
```

로컬에서 시험: `claude --plugin-dir /path/to/teamcode`

## 구성

| 구성 | 종류 | 하는 일 |
|---|---|---|
| `/kickoff` | 스킬 | 대화형 인터뷰 → `docs/PRD.md` → `AGENTS.md`(본문) + `CLAUDE.md`(`@AGENTS.md` 포인터) + `docs/workflow-log.md` + `.claude/protected-paths` + 보호 훅 설치. 기존 PRD가 있으면 인터뷰를 건너뛴다 |
| `/issues` | 스킬 | `docs/PRD.md`를 이슈로 나눈다. 스택이 PRD에 없으면 구현 결정을 먼저 묻는다 |
| `/issue` | 스킬 | 요구사항 한 건을 `docs/issues/NNN-제목.md` 하나로 남긴다. PRD가 없거나 `/issues`를 거치지 않은 프로젝트에서도 쓴다. 구현은 `/work` |
| `/work` | 스킬 | 이슈 하나를 구현하고 수용 조건으로 검증한다. 구현은 `work-implement`, 판정은 읽기 전용 `work-review`. 순서는 [skills/shared/work-loop.md](skills/shared/work-loop.md) |
| `work-implement` | 에이전트 | `/work`가 넘긴 계획만 구현한다. 통과를 선언하지 않는다 |
| `work-review` | 에이전트 | 수용 조건과 불변 규칙으로 판정한다. 파일을 고치지 않는다 |
| `protect-paths` | 훅 (PreToolUse) | `.claude/protected-paths`에 적힌 경로에 대한 Write/Edit, `rm`·`mv`·`cp`·`sed -i`·리다이렉트 등을 차단 |

### 보호 훅은 플러그인이 아니라 프로젝트에 설치된다

```
<프로젝트>/.claude/
├── protected-paths            ← 보호 대상 설명 (커밋)
├── protected-paths.local      ← 각자 머신의 실제 경로 (커밋 안 함, .gitignore)
├── hooks/protect-paths.py     ← skills/kickoff/assets/에서 복사 (커밋)
└── settings.json              ← PreToolUse 훅 등록 (커밋)
```

훅은 `protected-paths`와 `protected-paths.local`을 합쳐 읽는다. 마운트 경로가 사람마다 다를 수 있고
경로 자체를 저장소에 남기고 싶지 않을 수 있으므로, 실제 경로는 각자 `.local`에 적는다.
**팀원은 클론한 뒤 `.claude/protected-paths.local`을 직접 만들어야 보호가 켜진다.**

- 저장소에 커밋되므로 teamcode를 설치하지 않은 팀원도 보호를 받는다.
- Cursor도 `.claude/settings.json`의 훅을 실행한다 (플러그인 훅은 읽지 않는다). Cursor는 셸 도구 이름을 `Shell`로 보낸다.
- 설치·갱신: `python3 skills/kickoff/assets/install-guard.py <프로젝트 루트>` (여러 번 실행해도 결과가 같다.
  스크립트의 `teamcode-protect-paths-version`이 다를 때만 교체). `/kickoff`가 대신 실행한다.
- 훅을 고쳤다면 `protect-paths.py`의 버전 줄을 올린다. 그래야 기존 프로젝트에서 재설치할 때 교체된다.

### protected-paths(.local) 형식

```
# 한 줄에 경로 하나, # 뒤는 주석. ~ 사용 가능
/Volumes/NAS/masters
```

알려진 한계: 명령 단위로 판정하므로 `cp <보호경로>/a /tmp/b`처럼 읽기만 하는 복사도 막힌다.
이런 경우는 사용자가 직접 실행한다.

## 개발

```bash
python3 tests/test_protect_paths.py
```

기능 추가 원칙: 두 번째 프로젝트에서 "또 손으로 하고 있네" 싶은 것이 나올 때 추가한다.
버전은 `.claude-plugin/plugin.json`의 `version`으로 관리한다.

인터뷰 방식은 [grill-me](https://github.com/mattpocock/skills)(한 번에 질문 하나, 추천 답 제시)와
oh-my-claudecode deep-interview(구성요소 확정, 명확도 게이트)를 참고했다.
