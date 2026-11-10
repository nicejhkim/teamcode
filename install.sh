#!/usr/bin/env bash
# 이 저장소의 teamcode를 현재 사용자 계정에 설치한다.
# 사용: ./install.sh [cursor|codex|claude|agy]
# 인자가 없으면 이 컴퓨터에 명령이 있는 도구만 설치한다.
set -euo pipefail

root="$(cd "$(dirname "$0")" && pwd)"

# 스킬 디렉터리만 갈아끼운다. 목적지에 있는 다른 스킬은 남긴다.
copy_skills() {
  local dest="$1"
  local skill name
  mkdir -p "$dest"
  for skill in "$root"/skills/*; do
    name="$(basename "$skill")"
    rm -rf "$dest/$name"
    cp -R "$skill" "$dest/$name"
  done
}

# Cursor가 읽는 스킬과 에이전트 위치로 복사한다.
install_cursor() {
  copy_skills "$HOME/.cursor/skills"
  mkdir -p "$HOME/.cursor/agents"
  cp "$root"/agents/*.md "$HOME/.cursor/agents/"
  echo "cursor: $HOME/.cursor/skills $HOME/.cursor/agents"
}

# Codex 스킬을 복사하고, 에이전트 마크다운을 toml로 바꿔 둔다.
install_codex() {
  copy_skills "$HOME/.agents/skills"
  python3 - "$root" "$HOME/.codex/agents" <<'PY'
import pathlib, sys

def write_agent(src: pathlib.Path, out_dir: pathlib.Path) -> None:
    """에이전트 마크다운의 frontmatter와 본문을 Codex toml로 저장한다."""
    _, front, body = src.read_text(encoding="utf-8").split("---", 2)
    meta = dict(line.split(": ", 1) for line in front.strip().splitlines())
    sandbox = "read-only" if meta["name"] == "work-review" else "workspace-write"
    desc = meta["description"].replace("\\", "\\\\").replace('"', '\\"')
    text = body.strip().replace("'''", "'' '")
    (out_dir / f"{meta['name']}.toml").write_text(
        f'name = "{meta["name"]}"\n'
        f'description = "{desc}"\n'
        f'sandbox_mode = "{sandbox}"\n'
        f"developer_instructions = '''\n{text}\n'''\n",
        encoding="utf-8",
    )

out = pathlib.Path(sys.argv[2])
out.mkdir(parents=True, exist_ok=True)
for path in pathlib.Path(sys.argv[1], "agents").glob("*.md"):
    write_agent(path, out)
PY
  echo "codex: $HOME/.agents/skills $HOME/.codex/agents"
}

# agy가 이 저장소를 Claude 플러그인에서 변환해 설치한다. 다시 실행하면 기존 설치를 교체한다.
install_agy() {
  agy plugin install "$root"
  echo "agy: $HOME/.gemini/config/plugins/teamcode"
}

# Claude Code 마켓플레이스에 등록하고 사용자 스코프에 설치한다.
# 이미 등록된 마켓플레이스는 지우지 않는다.
install_claude() {
  if ! claude plugin marketplace list 2>/dev/null | grep -Eq '^[[:space:]]*❯ teamcode$'; then
    claude plugin marketplace add "$root"
  fi
  if claude plugin list 2>/dev/null | grep -Eq '^[[:space:]]*❯ teamcode@teamcode$'; then
    claude plugin update teamcode@teamcode
  else
    claude plugin install teamcode@teamcode -s user -y
  fi
  echo "claude: teamcode@teamcode"
}

# 요청한 대상만 설치한다. 인자가 없으면 설치된 도구를 골라 설치한다.
main() {
  local target="${1:-}"
  case "$target" in
    cursor) install_cursor ;;
    codex) install_codex ;;
    claude) install_claude ;;
    agy) install_agy ;;
    "")
      command -v cursor >/dev/null && install_cursor
      command -v codex >/dev/null && install_codex
      command -v claude >/dev/null && install_claude
      command -v agy >/dev/null && install_agy
      ;;
    *)
      echo "usage: $0 [cursor|codex|claude|agy]" >&2
      exit 1
      ;;
  esac
}

main "$@"
