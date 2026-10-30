# teamcode

**AI 코딩 하네스 플러그인**

`teamcode`는 AI 코딩 에이전트가 프로젝트의 요구사항을 정리하고, 이슈를 만들고, 구현하고, 결과를 검증하는 과정을 일관되게 수행하도록 돕는 도구입니다.

프로젝트 킥오프부터 요구사항 관리, 이슈 단위 구현과 검증까지 개발 절차를 스킬과 에이전트로 정의합니다. 한 번 정한 프로젝트 규칙을 반복해서 설명하지 않고, 여러 프로젝트와 AI 코딩 도구에서 재사용하는 것이 목적입니다.

- **대화로 합의하고 문서화합니다.** 프로젝트의 방향과 기술적 결정을 정리합니다.
- **작업을 작게 나눕니다.** PRD를 실행 가능한 이슈로 분해합니다.
- **구현과 검증을 분리합니다.** 구현 에이전트와 읽기 전용 리뷰 에이전트가 각각 역할을 맡습니다.
- **중요한 경로를 보호합니다.** 프로젝트별 보호 규칙과 훅으로 실수로 인한 파일 변경을 차단합니다.

현재 Claude Code를 기본 환경으로 설계했으며, Cursor와 Codex에서도 스킬을 재사용할 수 있습니다.

## 1. 왜 프롬프트만으로는 부족할까?

AI 코딩 에이전트에게 자연어로 지시하면 코드를 작성하고 수정할 수 있습니다. 하지만 좋은 프롬프트를 한 번 작성하는 것만으로 개발 절차가 안정적으로 유지되지는 않습니다.

| 프롬프트만으로 작업할 때 | 실제 개발에서 필요한 것 |
|---|---|
| 대화가 바뀌면 같은 규칙을 다시 설명해야 합니다. | 프로젝트 규칙과 결정 사항을 지속적으로 보존합니다. |
| 요구사항을 구현할 때마다 해석이 달라질 수 있습니다. | 합의된 요구사항과 수용 조건을 기준으로 작업합니다. |
| 구현에 집중하다가 기존 기능이나 제약을 놓칠 수 있습니다. | 반드시 지켜야 할 불변 규칙과 보호 경로를 명시합니다. |
| 코드를 작성한 뒤 스스로 잘됐다고 판단하기 쉽습니다. | 구현과 독립적인 검증 절차를 둡니다. |
| 사람마다 지시하는 방식과 작업 순서가 다릅니다. | 팀이 합의한 작업 절차를 반복해서 적용합니다. |

프롬프트는 **무엇을 하라고 지시하는 수단**입니다. 하지만 프로젝트 문서, 작업 순서, 역할 분리, 검증 기준, 파일 변경 제한까지 프롬프트 하나에 의존하면 일관성을 유지하기 어렵습니다.

이 문제를 해결하려면 지시문뿐 아니라 지시를 실행하는 환경과 절차도 함께 설계해야 합니다.

## 2. 하네스(Harness)란?

AI 코딩에서 하네스는 에이전트가 주어진 작업을 안정적으로 수행하도록 둘러싼 **실행 환경, 규칙, 도구, 작업 절차, 검증 장치의 조합**을 뜻합니다.
모델이 코드를 작성하는 능력에 더해, 어떤 맥락에서 어떤 순서로 일하고 무엇을 근거로 결과를 판단할지를 설계합니다.

하네스는 특정 프롬프트나 모델 하나와 같지 않습니다. 예를 들어 다음 요소들이 함께 작동할 수 있습니다.

- **맥락(Context):** `AGENTS.md`, PRD, 이슈, 프로젝트 문서와 기존 코드
- **절차(Workflow):** 요구사항 정리 → 이슈 분해 → 구현 → 검증
- **역할(Agents):** 구현 담당과 검토 담당의 분리
- **도구와 제약(Guardrails):** 파일 변경 권한, 보호 훅, 허용된 작업 범위
- **검증(Verification):** 테스트, 수용 조건, 불변 규칙을 기준으로 한 판정

모든 하네스가 이 요소를 전부 갖춰야 하는 것은 아닙니다. 프로젝트와 작업의 위험도에 맞춰 필요한 장치를 선택하면 됩니다.

`teamcode`는 이 가운데 반복되는 개발 절차와 규칙을 재사용 가능한 스킬, 에이전트, 프로젝트 문서, 보호 훅으로 구성합니다.

## 3. teamcode는 어떻게 동작할까?

`teamcode`는 하나의 거대한 자동화 프로그램이 아닙니다. AI 코딩 도구가 이해하는 스킬과 에이전트, 프로젝트에 남기는 문서, 실제 파일 변경을 통제하는 훅을 조합합니다.

### 전체 작업 흐름

```text
프로젝트 킥오프
    │
    ▼
docs/PRD.md ───────────── 프로젝트 요구사항
    │
    ▼
/issues ──────────────── PRD를 여러 이슈로 분해
    │
    ├── /issue ───────── 개별 요구사항을 이슈로 등록
    │
    ▼
/work <이슈>
    │
    ├── work-implement ─ 계획에 따라 구현
    │
    └── work-review ──── 수용 조건과 불변 규칙 검토
    │
    ▼
검증 결과 확인 및 후속 조치
```

이 흐름은 팀의 작업 방식을 통일하기 위한 기본 경로입니다. 기존 프로젝트에 PRD가 있거나 단일 요구사항만 처리한다면 모든 단계를 처음부터 밟을 필요는 없습니다.

### 3.1. 스킬은 작업 절차를 정의합니다

스킬은 에이전트에게 특정 작업을 어떻게 수행할지 알려주는 지침과 관련 자료입니다. `teamcode`는 스킬을 통해 프로젝트 킥오프, 이슈 분해, 요구사항 등록, 구현과 검증의 절차를 제공합니다.

스킬 자체가 모든 작업을 독립적으로 실행하는 프로그램은 아닙니다. 실제 파일 읽기와 수정, 명령 실행 등은 이를 사용하는 AI 코딩 도구와 에이전트의 기능에 따라 수행됩니다.

### 3.2. 에이전트는 역할을 나눕니다

`/work`는 구현과 검토를 하나의 자기평가에 맡기지 않고, 역할이 다른 두 에이전트를 사용합니다.

- **`work-implement`**: 전달받은 계획에 따라 코드를 구현합니다. 통과를 선언하지 않습니다.
- **`work-review`**: 수용 조건과 불변 규칙을 기준으로 결과를 검토합니다. 파일을 수정할 수 없는 읽기 전용 역할입니다.

`work-review`는 판정을 구현과 다른 AI에게 맡길 수 있습니다. 기본은 `self`(직접 판정)이고, 환경 변수 `TEAMCODE_REVIEWER`를 `cursor`, `codex`, `gemini` 중 하나로 지정하면 해당 CLI에 위임합니다. 리뷰어 CLI는 읽기 전용 모드(`--mode ask`, `--sandbox read-only`, `--approval-mode plan`)로 실행하며, CLI가 없거나 실패하면 `self`로 대체합니다.

```bash
export TEAMCODE_REVIEWER=cursor
```

Windows PowerShell:

```powershell
$env:TEAMCODE_REVIEWER = "cursor"            # 현재 세션만
setx TEAMCODE_REVIEWER cursor                # 영구 설정 (새 터미널부터 적용)
```

구현 에이전트가 작업을 완료했다고 보고하는 것과 검토 에이전트가 수용 조건을 충족했다고 판정하는 것은 별개입니다.

다만 에이전트를 분리한다고 해서 검증이 자동으로 완벽해지는 것은 아닙니다. 테스트와 수용 조건이 구체적이어야 하며, 최종 결과와 필요한 후속 조치는 사람이 확인할 수 있어야 합니다.

### 3.3. 프로젝트 문서가 맥락을 유지합니다

`teamcode`는 프로젝트에 다음과 같은 문서를 남깁니다.

- `docs/PRD.md`: 합의한 요구사항과 프로젝트 방향
- `AGENTS.md`: 에이전트가 따라야 할 프로젝트 공통 지침
- `CLAUDE.md`: Claude Code가 `AGENTS.md`를 참조하도록 하는 포인터
- `docs/workflow-log.md`: 작업 과정과 결정 사항을 기록하는 문서
- `docs/issues/`: 개별 요구사항과 수용 조건

이를 통해 매번 대화에서 프로젝트의 모든 배경과 규칙을 다시 설명하는 부담을 줄입니다. 문서에 남긴 결정 사항은 이후 작업에서도 참조할 수 있습니다.

### 3.4. 보호 훅은 중요한 파일 변경을 차단합니다

프로젝트에 설치되는 `protect-paths` 훅은 지정된 보호 경로에 대한 쓰기 작업을 검사하고, 지원하는 도구 호출에서 위험한 변경을 차단합니다.

예를 들어 외부에서 관리하는 파일이나 원본 데이터가 있는 경로를 보호 대상으로 지정할 수 있습니다.

다만 이는 모든 도구와 모든 실행 경로를 통제하는 완전한 보안 경계가 아닙니다. 보호 대상에 대한 읽기 작업도 일부 명령 형태에서는 차단될 수 있으며, 지원하지 않는 도구나 Codex에서는 같은 보호가 적용되지 않습니다. 구체적인 범위와 한계는 아래 보호 훅 설명을 참고하세요.

## 4. 제공 기능

| 명령 또는 구성 요소 | 종류 | 역할 |
|---|---|---|
| `/kickoff` | 스킬 | 대화형 인터뷰를 통해 프로젝트 요구사항을 정리하고 기본 문서와 보호 훅을 설치합니다. 기존 PRD가 있으면 인터뷰를 건너뜁니다. |
| `/issues` | 스킬 | `docs/PRD.md`를 실행 가능한 이슈로 분해합니다. PRD에 기술 스택이 없으면 구현 결정을 먼저 확인합니다. |
| `/issue` | 스킬 | 요구사항 한 건을 `docs/issues/NNN-제목.md` 형식의 이슈 하나로 작성합니다. PRD가 없거나 `/issues`를 거치지 않은 프로젝트에서도 사용할 수 있습니다. |
| `/work` | 스킬 | 이슈 하나를 구현하고 수용 조건에 따라 검증합니다. `work-implement`와 `work-review`를 활용합니다. |
| `work-implement` | 에이전트 | 전달받은 계획에 따라 구현합니다. 통과를 선언하지 않습니다. |
| `work-review` | 에이전트 | 수용 조건과 불변 규칙을 기준으로 검토합니다. 파일을 수정하지 않습니다. |
| `protect-paths` | PreToolUse 훅 | `.claude/protected-paths` 등에 지정한 경로에 대한 지원되는 쓰기 작업을 차단합니다. |

`/work`의 상세 실행 순서는 [`skills/shared/work-loop.md`](skills/shared/work-loop.md)에 정의되어 있습니다.

## 5. 설치

https://github.com/nicejhkim/teamcode

명령 예시는 macOS·Linux(bash/zsh) 기준이며, 셸 문법이 다른 곳에는 Windows PowerShell 명령을 함께 적었습니다. Windows에서는 다음을 전제로 합니다.

- [Git for Windows](https://git-scm.com/download/win)가 설치되어 있습니다. Claude Code는 Windows에서 Git Bash로 셸 명령과 훅을 실행합니다.
- Python은 [python.org](https://www.python.org/downloads/) 설치본을 쓰며, `python3` 대신 `py`(Python 런처)로 실행합니다.
- `~`는 사용자 폴더(`%USERPROFILE%`, PowerShell의 `$HOME`)를 뜻합니다.

### 5.1. Claude Code

Claude Code에서는 플러그인 마켓플레이스를 통해 설치할 수 있습니다.

```bash
claude plugin marketplace add https://github.com/nicejhkim/teamcode
claude plugin install teamcode
```

로컬에서 개발하거나 시험할 때는 다음과 같이 실행합니다.

```bash
claude --plugin-dir /path/to/teamcode
```

Windows에서는 `claude --plugin-dir C:\path\to\teamcode`처럼 경로를 지정합니다.

설치 후 다음 명령을 사용할 수 있습니다.

```text
/kickoff
/issues
/issue
/work
```

다른 플러그인과 명령 이름이 겹치면 `/teamcode:work`처럼 플러그인 이름을 붙여 호출할 수 있습니다.

### 5.2. Cursor

Cursor에는 Claude Code 플러그인을 그대로 설치하지 않습니다. 스킬과 에이전트 파일을 Cursor가 인식하는 위치에 복사합니다.

```bash
git clone https://github.com/nicejhkim/teamcode ~/teamcode

mkdir -p ~/.cursor/skills ~/.cursor/agents
cp -R ~/teamcode/skills/* ~/.cursor/skills/
cp ~/teamcode/agents/*.md ~/.cursor/agents/
```

Windows PowerShell:

```powershell
git clone https://github.com/nicejhkim/teamcode $HOME\teamcode

New-Item -ItemType Directory -Force $HOME\.cursor\skills, $HOME\.cursor\agents | Out-Null
Copy-Item -Recurse -Force $HOME\teamcode\skills\* $HOME\.cursor\skills\
Copy-Item -Force $HOME\teamcode\agents\*.md $HOME\.cursor\agents\
```

주의 사항:

- 특정 프로젝트에서만 사용하려면 `~/.cursor/` 대신 해당 프로젝트의 `.cursor/` 아래에 복사합니다.
- `skills/shared/`도 함께 복사해야 합니다. `/kickoff`, `/issues`, `/work`가 `../shared/`의 문서를 참조합니다.
- 에이전트 파일은 Claude Code와 같은 형식으로 작성되어 있어 그대로 사용할 수 있습니다.
- Agent 채팅에서 `/work` 등의 명령으로 호출합니다.

보호 훅은 플러그인에 포함된 훅을 설치하는 방식이 아닙니다. 프로젝트에 설치된 `.claude/settings.json`의 훅을 Cursor가 실행하는 방식입니다. Cursor는 셸 도구 이름을 `Shell`로 전달하므로 훅에서 해당 도구 이름을 처리해야 합니다.

### 5.3. Codex

Codex에서는 스킬과 에이전트를 각각 Codex가 인식하는 위치와 형식으로 변환합니다.

먼저 스킬을 복사합니다.

```bash
git clone https://github.com/nicejhkim/teamcode ~/teamcode

mkdir -p ~/.agents/skills
cp -R ~/teamcode/skills/* ~/.agents/skills/
```

Windows PowerShell:

```powershell
git clone https://github.com/nicejhkim/teamcode $HOME\teamcode

New-Item -ItemType Directory -Force $HOME\.agents\skills | Out-Null
Copy-Item -Recurse -Force $HOME\teamcode\skills\* $HOME\.agents\skills\
```

그다음 Markdown 에이전트 정의를 TOML 형식으로 변환합니다.

```bash
cd ~/teamcode

python3 - <<'EOF'
import pathlib

out = pathlib.Path.home() / ".codex/agents"
out.mkdir(parents=True, exist_ok=True)

for f in pathlib.Path("agents").glob("*.md"):
    _, front, body = f.read_text(encoding="utf-8").split("---", 2)
    meta = dict(l.split(": ", 1) for l in front.strip().splitlines())

    sandbox = (
        "read-only"
        if meta["name"] == "work-review"
        else "workspace-write"
    )

    (out / f"{meta['name']}.toml").write_text(
        f'name = "{meta["name"]}"\n'
        f'description = "{meta["description"]}"\n'
        f'sandbox_mode = "{sandbox}"\n'
        f"developer_instructions = '''\n{body.strip()}\n'''\n",
        encoding="utf-8",
    )
EOF
```

Windows PowerShell에서는 같은 스크립트를 here-string으로 감싸 `py`에 넘깁니다. `@'`와 `'@`는 각각 줄의 맨 앞에 있어야 합니다.

```powershell
cd $HOME\teamcode

@'
import pathlib

out = pathlib.Path.home() / ".codex/agents"
out.mkdir(parents=True, exist_ok=True)

for f in pathlib.Path("agents").glob("*.md"):
    _, front, body = f.read_text(encoding="utf-8").split("---", 2)
    meta = dict(l.split(": ", 1) for l in front.strip().splitlines())

    sandbox = (
        "read-only"
        if meta["name"] == "work-review"
        else "workspace-write"
    )

    (out / f"{meta['name']}.toml").write_text(
        f'name = "{meta["name"]}"\n'
        f'description = "{meta["description"]}"\n'
        f'sandbox_mode = "{sandbox}"\n'
        f"developer_instructions = '''\n{body.strip()}\n'''\n",
        encoding="utf-8",
    )
'@ | py -
```

주의 사항:

- 특정 프로젝트에서만 사용하려면 해당 프로젝트의 `.agents/skills/`와 `.codex/agents/`에 둡니다.
- `work-review`는 `sandbox_mode = "read-only"`로 설정하여 파일을 수정할 수 없도록 합니다.
- 에이전트 파일에 한글이 들어 있으므로 읽고 쓸 때 `encoding="utf-8"`을 지정합니다. 지정하지 않으면 Windows의 기본 인코딩(cp949)으로 읽어 오류가 납니다.
- 위 변환 스크립트는 간단한 YAML frontmatter와 본문을 전제로 합니다. 에이전트 메타데이터에 복잡한 YAML 문법이 추가되면 변환 스크립트도 함께 수정해야 합니다.
- Codex의 서브에이전트 기능은 기본적으로 꺼져 있을 수 있습니다. `/work`가 구현과 검토를 별도 에이전트에 위임하려면 [Codex 서브에이전트 문서](https://developers.openai.com/codex/subagents)를 참고해 활성화하세요.
- `.claude/settings.json`의 보호 훅은 Codex가 읽지 않으므로 Codex에서는 프로젝트의 보호 경로가 자동으로 차단되지 않습니다.

호출 예시:

```text
$work
$issue
```

Codex의 스킬 호출 방식과 에이전트 활성화 설정은 사용하는 버전과 환경에 따라 확인이 필요합니다.

## 6. 프로젝트 보호 훅

### 6.1. 설치 위치

보호 훅은 teamcode 플러그인 자체에만 존재하는 것이 아니라, 각 프로젝트에 설치됩니다.

```text
<프로젝트>/
└── .claude/
    ├── protected-paths          # 보호 대상 설명 (커밋)
    ├── protected-paths.local    # 개인별 실제 경로 (커밋하지 않음)
    ├── hooks/
    │   └── protect-paths.py     # 보호 훅 스크립트
    └── settings.json            # PreToolUse 훅 등록
```

- `protected-paths`는 팀이 공유할 보호 규칙을 기록합니다.
- `protected-paths.local`은 각자 머신의 실제 경로를 기록합니다.
- `protect-paths.py`는 `skills/kickoff/assets/`에서 복사됩니다.
- `settings.json`은 프로젝트에서 보호 훅을 등록합니다.

마운트 경로가 팀원마다 다를 수 있고 실제 경로를 저장소에 남기지 않을 수도 있으므로, 개인별 경로는 `.local` 파일에 기록합니다.

**팀원은 프로젝트를 클론한 뒤 `.claude/protected-paths.local`을 직접 만들어야 개인별 보호 경로가 적용됩니다.**

`.local` 파일은 커밋하지 않도록 `.gitignore`에 등록하세요.

### 6.2. 설치 및 갱신

프로젝트 루트에서 실행합니다.

```bash
python3 skills/kickoff/assets/install-guard.py <프로젝트 루트>
```

Windows에서는 `py skills\kickoff\assets\install-guard.py <프로젝트 루트>`로 실행합니다.

여러 번 실행해도 결과가 같도록 설계되어 있습니다. 설치 스크립트는 훅의 `teamcode-protect-paths-version` 버전을 확인하여 버전이 다를 때만 교체합니다. `/kickoff`에서도 설치를 수행합니다.

훅의 동작을 변경했다면 `protect-paths.py`의 버전 줄을 올려야 기존 프로젝트에서 재설치할 때 변경된 파일이 적용됩니다.

### 6.3. 보호 경로 작성

`protected-paths`와 `protected-paths.local`은 한 줄에 경로 하나를 기록합니다. `#` 뒤는 주석이며 `~`를 사용할 수 있습니다.

예시:

```text
# protected-paths.local
/Volumes/NAS/masters
```

### 6.4. 알려진 한계

보호 훅은 명령 단위로 판단하므로, 보호 경로를 읽기만 하는 복사 명령도 차단될 수 있습니다.

예를 들어 다음 명령은 목적지가 보호 경로 밖이어도 차단될 수 있습니다.

```bash
cp /Volumes/NAS/masters/a /tmp/b
```

이러한 경우에는 사용자가 직접 실행해야 합니다.

**Windows에서는 보호 훅이 실제 환경에서 검증되지 않았습니다.** 파일 쓰기 도구(Write, Edit)의 경로 판정은 Windows 구분자(`\`)와 대소문자 무시를 따르도록 테스트되어 있지만, 다음 한계가 있습니다.

- 훅은 `"$CLAUDE_PROJECT_DIR"/.claude/hooks/protect-paths.py`를 직접 실행하고, 스크립트 첫 줄의 `#!/usr/bin/env python3`에 의존합니다. Git Bash에서 `python3`를 찾지 못하면 훅이 실행되지 않습니다.
- 셸 명령 검사는 명령 문자열에 보호 경로가 적힌 그대로 나오는지 봅니다. 보호 경로를 `D:\NAS\masters`로 적었는데 명령에서 `D:/NAS/masters`나 Git Bash 형식인 `/d/NAS/masters`로 쓰면 막지 못합니다.

Windows에서 보호 경로가 중요하다면 훅에만 의존하지 말고 폴더 권한(읽기 전용 속성, NTFS 권한)으로도 보호하세요.

또한 보호 훅의 적용 범위는 도구가 전달하는 호출 형식과 훅이 검사하는 명령에 한정됩니다. 모든 실행 경로나 모든 AI 코딩 도구에서 동일한 보호가 보장되는 것은 아닙니다. 중요한 데이터는 별도의 접근 권한, 백업, 운영 환경의 보안 정책으로도 보호해야 합니다.

## 7. 갱신

Cursor와 Codex는 스킬과 에이전트의 복사본을 사용합니다. 저장소를 갱신한 뒤 각 도구의 설치 절차를 다시 실행하세요.

```bash
cd ~/teamcode
git pull
```

Windows PowerShell에서는 `cd $HOME\teamcode; git pull`입니다.

- Claude Code: 플러그인 설치·갱신 절차를 확인합니다.
- Cursor: 스킬과 에이전트 복사 명령을 다시 실행합니다.
- Codex: 스킬 복사와 에이전트 TOML 변환을 다시 실행합니다.

프로젝트에 설치된 보호 훅도 변경되었다면 해당 프로젝트에서 설치 스크립트를 다시 실행합니다.

```bash
python3 skills/kickoff/assets/install-guard.py <프로젝트 루트>
```

## 8. 개발 및 테스트

보호 훅 테스트:

```bash
python3 tests/test_protect_paths.py
```

Windows에서는 `py tests\test_protect_paths.py`로 실행합니다.

기능 추가 원칙은 단순합니다.

**두 번째 프로젝트에서도 같은 일을 다시 손으로 하고 있다면, 그때 공통 기능으로 만들지 검토합니다.**

특정 프로젝트에만 필요한 기능을 미리 일반화하기보다, 실제 반복되는 작업을 확인한 뒤 teamcode에 반영합니다.

버전은 `.claude-plugin/plugin.json`의 `version`으로 관리합니다.

## 9. 설계 참고

인터뷰 방식은 다음 자료의 아이디어를 참고했습니다.

- [grill-me — Matt Pocock의 skills 저장소](https://github.com/mattpocock/skills): 한 번에 질문 하나를 제시하고 추천 답안을 제공하는 인터뷰 방식
- [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode): deep-interview의 구성 요소 확정과 명확도 게이트 방식

참고한 아이디어를 teamcode의 프로젝트 킥오프 및 작업 절차에 맞게 적용했습니다.

---

## 10. 지향점

teamcode의 목적은 AI가 사람의 판단 없이 모든 일을 처리하도록 만드는 것이 아닙니다.

팀이 합의한 내용을 문서로 남기고, 반복적인 작업 절차를 재사용하며, 구현과 검토의 역할을 분리하고, 실수로부터 중요한 파일을 보호하는 것입니다.

AI 모델이나 코딩 도구가 바뀌더라도 팀의 개발 지식과 작업 절차는 프로젝트에 남아 있어야 합니다.

**좋은 프롬프트를 작성하는 데서 한 걸음 더 나아가, 좋은 결과가 반복해서 나오도록 개발 환경을 설계합니다.**
