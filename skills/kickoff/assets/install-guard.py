#!/usr/bin/env python3
"""protect-paths 훅을 프로젝트에 설치한다. 여러 번 실행해도 결과가 같다.

사용: python3 install-guard.py <프로젝트 루트>

1. 이 디렉터리의 protect-paths.py를 <루트>/.claude/hooks/로 복사 (버전이 다를 때만 교체)
2. <루트>/.claude/settings.json에 PreToolUse 훅 항목 병합 (기존 설정·훅은 보존)
3. <루트>/.gitignore에 개인 파일(protected-paths.local, settings.local.json) 추가
.claude/protected-paths(.local) 내용은 건드리지 않는다 — 그건 /kickoff와 사용자가 쓴다.
"""
import json
import os
import re
import shutil
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "protect-paths.py")
REL = ".claude/hooks/protect-paths.py"
COMMAND = f'"$CLAUDE_PROJECT_DIR"/{REL}'
MATCHER = "Bash|Write|Edit|MultiEdit|NotebookEdit"
IGNORE = [".claude/protected-paths.local", ".claude/settings.local.json"]


def version(path):
    try:
        with open(path, encoding="utf-8") as f:
            m = re.search(r"teamcode-protect-paths-version:\s*(\S+)", f.read())
    except OSError:
        return None
    return m.group(1) if m else "unknown"


def install_script(root):
    dst = os.path.join(root, REL)
    old, new = version(dst), version(SRC)
    if old == new:
        return f"script: 최신 (v{new})"
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    shutil.copyfile(SRC, dst)
    os.chmod(dst, 0o755)
    return f"script: {'설치' if old is None else f'v{old} → 교체'} (v{new})"


def merge_settings(root):
    path = os.path.join(root, ".claude", "settings.json")
    try:
        with open(path, encoding="utf-8") as f:
            settings = json.load(f)
    except FileNotFoundError:
        settings = {}
    # 파싱 실패(JSONDecodeError)는 그대로 터뜨린다 — 사용자 설정을 덮어쓰지 않기 위해

    pre = settings.setdefault("hooks", {}).setdefault("PreToolUse", [])
    for entry in pre:
        if any(REL in h.get("command", "") for h in entry.get("hooks", [])):
            return "settings.json: 이미 등록됨"
    pre.append({"matcher": MATCHER, "hooks": [{"type": "command", "command": COMMAND}]})
    with open(path, "w", encoding="utf-8") as f:
        json.dump(settings, f, ensure_ascii=False, indent=2)
        f.write("\n")
    return "settings.json: 훅 등록"


def update_gitignore(root):
    path = os.path.join(root, ".gitignore")
    try:
        with open(path, encoding="utf-8") as f:
            text = f.read()
    except FileNotFoundError:
        text = ""
    present = {line.strip() for line in text.splitlines()}
    missing = [p for p in IGNORE if p not in present]
    if not missing:
        return ".gitignore: 이미 등록됨"
    with open(path, "a", encoding="utf-8") as f:
        if text and not text.endswith("\n"):
            f.write("\n")
        f.write("\n# teamcode: 개인별 파일 (커밋하지 않음)\n" + "\n".join(missing) + "\n")
    return f".gitignore: {', '.join(missing)} 추가"


def main():
    if len(sys.argv) != 2 or not os.path.isdir(sys.argv[1]):
        sys.exit("사용: install-guard.py <프로젝트 루트>")
    root = os.path.abspath(sys.argv[1])
    print(install_script(root))
    print(merge_settings(root))
    print(update_gitignore(root))


if __name__ == "__main__":
    main()
