#!/usr/bin/env python3
# teamcode-protect-paths-version: 3
"""PreToolUse 훅 — .claude/protected-paths(.local)에 적힌 경로의 수정·삭제를 차단한다.

teamcode /kickoff가 프로젝트의 .claude/hooks/에 복사하고 .claude/settings.json에 등록한다.
Claude Code와 Cursor(Claude 훅 호환, 도구명 Shell) 모두 이 파일을 실행한다.
직접 고치지 말 것 — teamcode에서 고친 뒤 /kickoff로 다시 설치한다.

- .claude/protected-paths        커밋. 보호 대상 설명·팀 공통 경로
- .claude/protected-paths.local  커밋 안 함. 각자 실제 마운트 경로
두 파일을 합쳐 쓴다. 둘 다 없으면 아무것도 하지 않는다. 한 줄에 경로 하나, `#` 뒤는 주석.
차단은 exit 2 + stderr 메시지 (도구가 모델에게 사유를 되돌려준다).
"""
import json
import os
import re
import shlex
import sys

# 경로를 인자로 받아 파일을 바꾸거나 지우는 명령
MUTATING = {"rm", "rmdir", "unlink", "mv", "cp", "rsync", "dd", "truncate",
            "shred", "chmod", "chown", "ln", "tee", "install"}


def load_protected(root):
    out = []
    for name in ("protected-paths", "protected-paths.local"):
        try:
            with open(os.path.join(root, ".claude", name), encoding="utf-8") as f:
                lines = f.read().splitlines()
        except OSError:
            continue
        for line in lines:
            line = line.split("#", 1)[0].strip()
            if line:
                out.append(os.path.normpath(os.path.expanduser(line)))
    return out


def is_under(path, cwd, protected):
    # os.path 기준이라 Windows 구분자(\)와 대소문자 무시도 따른다
    p = os.path.normcase(os.path.normpath(os.path.join(cwd, os.path.expanduser(path))))
    for d in protected:
        d = os.path.normcase(d)
        try:
            if os.path.commonpath([p, d]) == d:
                return True
        except ValueError:  # Windows에서 드라이브가 다르면
            pass
    return False


def mentions(cmd, d):
    # /nas 가 /nas-backup 에 걸리지 않도록 경로 경계까지 확인
    return re.search(re.escape(d) + r"(?=[/\\\s\"';&|)]|$)", cmd) is not None


def check_bash(cmd, cwd, protected):
    cmd = cmd.replace("$HOME", os.path.expanduser("~")).replace("~/", os.path.expanduser("~") + "/")

    # 리다이렉트 대상 (2>/dev/null 같은 읽기 전용 사용은 통과)
    for target in re.findall(r">>?\s*([^\s;&|]+)", cmd):
        if is_under(target.strip("\"'"), cwd, protected):
            return f"보호 경로에 쓰기 리다이렉트: {target}"

    hit = [d for d in protected if mentions(cmd, d)]
    if not hit:
        return None
    try:
        tokens = shlex.split(cmd)
    except ValueError:
        tokens = cmd.split()
    names = {os.path.basename(t) for t in tokens}
    # ponytail: 명령 단위 휴리스틱 — `cp 보호경로/a /tmp/b`처럼 읽기만 하는 복사도 막힌다.
    # 오탐이 잦아지면 cp/rsync는 마지막 인자(목적지)만 검사하도록 좁힐 것.
    mutating = names & MUTATING
    if "sed" in names and any(t.startswith("-i") for t in tokens):
        mutating.add("sed -i")
    if "-delete" in tokens:
        mutating.add("find -delete")
    if mutating:
        return f"보호 경로({', '.join(hit)})에 변경 명령: {', '.join(sorted(mutating))}"
    return None


def main():
    try:
        data = json.load(sys.stdin)
    except ValueError:
        return 0
    cwd = data.get("cwd") or os.getcwd()
    root = os.environ.get("CLAUDE_PROJECT_DIR") or cwd
    protected = load_protected(root)
    if not protected:
        return 0

    tool = data.get("tool_name", "")
    inp = data.get("tool_input", {}) or {}
    reason = None
    if tool in ("Bash", "Shell"):  # Shell = Cursor가 Claude 형식 훅에 보내는 이름
        reason = check_bash(inp.get("command", ""), cwd, protected)
    else:
        path = inp.get("file_path") or inp.get("notebook_path")
        if path and is_under(path, cwd, protected):
            reason = f"보호 경로의 파일 수정: {path}"

    if reason:
        print(f"BLOCKED (teamcode protect-paths): {reason}\n"
              f"이 경로는 .claude/protected-paths에 등록된 원본 보호 영역입니다. "
              f"꼭 필요하면 사용자가 직접 실행해야 합니다.", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
