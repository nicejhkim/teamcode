#!/usr/bin/env python3
"""protect-paths 훅 자체 점검. 실행: python3 tests/test_protect_paths.py"""
import json
import os
import subprocess
import sys
import tempfile

HOOK = os.path.join(os.path.dirname(__file__), "..", "skills", "kickoff", "assets", "protect-paths.py")


def run(root, tool, tool_input):
    payload = json.dumps({"tool_name": tool, "tool_input": tool_input, "cwd": root})
    env = dict(os.environ, CLAUDE_PROJECT_DIR=root)
    return subprocess.run([sys.executable, HOOK], input=payload, text=True,
                          capture_output=True, env=env).returncode


def main():
    with tempfile.TemporaryDirectory() as root:
        nas = os.path.join(root, "nas")
        # 설정 없음 → 전부 통과
        assert run(root, "Bash", {"command": f"rm -rf {nas}"}) == 0

        os.makedirs(os.path.join(root, ".claude"))
        with open(os.path.join(root, ".claude", "protected-paths"), "w") as f:
            f.write(f"# 원본 마스터\n{nas}\n")

        cases = [
            ("Write", {"file_path": f"{nas}/a.mov"}, 2),
            ("Edit", {"file_path": f"{root}/src/app.ts"}, 0),
            ("Write", {"file_path": f"{nas}-backup/a.mov"}, 0),   # 경로 경계
            ("Write", {"file_path": "nas/a.mov"}, 2),              # 상대 경로
            ("Bash", {"command": f"rm -rf {nas}/title1"}, 2),
            ("Bash", {"command": f"mv '{nas}/a.mov' /tmp/"}, 2),
            ("Bash", {"command": f"echo x > {nas}/a.txt"}, 2),
            ("Bash", {"command": f"sed -i '' s/a/b/ {nas}/sub.srt"}, 2),
            ("Bash", {"command": f"find {nas} -name '*.tmp' -delete"}, 2),
            ("Bash", {"command": f"ffprobe {nas}/a.mov 2>/dev/null"}, 0),
            ("Bash", {"command": f"ls -la {nas}"}, 0),
            ("Bash", {"command": f"rm -rf {root}/build"}, 0),
            ("Shell", {"command": f"rm -rf {nas}/title1", "cwd": ""}, 2),  # Cursor
            ("Shell", {"command": f"ls {nas}", "cwd": ""}, 0),
        ]
        for tool, inp, want in cases:
            got = run(root, tool, inp)
            assert got == want, f"{tool} {inp}: expected {want}, got {got}"

    # 공용 파일엔 주석만, 실제 경로는 .local에만 있어도 막혀야 한다
    with tempfile.TemporaryDirectory() as root:
        nas = os.path.join(root, "mnt-nas")
        os.makedirs(os.path.join(root, ".claude"))
        with open(os.path.join(root, ".claude", "protected-paths"), "w") as f:
            f.write("# 원본 마스터 — 실제 경로는 protected-paths.local에\n")
        assert run(root, "Bash", {"command": f"rm -rf {nas}"}) == 0
        with open(os.path.join(root, ".claude", "protected-paths.local"), "w") as f:
            f.write(f"{nas}\n")
        assert run(root, "Bash", {"command": f"rm -rf {nas}/a"}) == 2
        assert run(root, "Write", {"file_path": f"{nas}/a.srt"}) == 2
        assert run(root, "Write", {"file_path": f"{root}/src/a.ts"}) == 0
    print(f"hook ok ({len(cases) + 5} cases)")


def test_install():
    installer = os.path.join(os.path.dirname(HOOK), "install-guard.py")
    with tempfile.TemporaryDirectory() as root:
        os.makedirs(os.path.join(root, ".claude"))
        settings_path = os.path.join(root, ".claude", "settings.json")
        existing = {"permissions": {"allow": ["Bash(ls:*)"]},
                    "hooks": {"PreToolUse": [{"matcher": "Bash", "hooks": [{"type": "command", "command": "other.sh"}]}]}}
        with open(settings_path, "w") as f:
            json.dump(existing, f)

        for _ in range(2):  # 두 번 실행해도 결과가 같아야 한다
            subprocess.run([sys.executable, installer, root], check=True, capture_output=True)

        with open(settings_path) as f:
            s = json.load(f)
        assert s["permissions"] == existing["permissions"]
        pre = s["hooks"]["PreToolUse"]
        assert pre[0]["hooks"][0]["command"] == "other.sh"
        assert sum("protect-paths.py" in h["command"] for e in pre for h in e["hooks"]) == 1

        dst = os.path.join(root, ".claude", "hooks", "protect-paths.py")
        assert os.access(dst, os.X_OK)

        with open(os.path.join(root, ".gitignore")) as f:
            lines = f.read().splitlines()
        assert lines.count(".claude/protected-paths.local") == 1, lines
        assert lines.count(".claude/settings.local.json") == 1, lines

        # 구버전이 깔려 있으면 교체
        with open(dst, "w") as f:
            f.write("# teamcode-protect-paths-version: 0\n")
        out = subprocess.run([sys.executable, installer, root], check=True,
                             capture_output=True, text=True).stdout
        assert "교체" in out, out
        with open(dst) as f, open(HOOK) as g:
            assert f.read() == g.read()
    print("install ok")


if __name__ == "__main__":
    main()
    test_install()
