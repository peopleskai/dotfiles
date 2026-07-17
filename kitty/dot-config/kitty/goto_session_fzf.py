"""Kitten to fuzzy-select a session via fzf.

Lists all .kitty-session files in the sessions directory and pipes them
through fzf for fuzzy selection. Enter selects the highlighted item.

Bound to: leader s
"""

import subprocess
import sys
from pathlib import Path

from kitty.boss import Boss

SESSION_DIR = Path("~/.config/kitty/sessions").expanduser()


def main(args: list[str]) -> str:
    sessions = sorted(f.stem for f in SESSION_DIR.glob("*.kitty-session"))
    if not sessions:
        print("No sessions found.")
        return ""

    input_text = "\n".join(sessions)
    try:
        result = subprocess.run(
            ["/bin/zsh", "-l", "-c", 'fzf --reverse --no-sort --prompt="session> "'],
            input=input_text,
            capture_output=True,
            text=True,
        )
    except FileNotFoundError:
        print("fzf not found. Install fzf via brew.")
        sys.stdin.readline()
        return ""

    return result.stdout.strip()


def handle_result(args: list[str], name: str, target_window_id: int, boss: Boss) -> None:
    if not name:
        return

    session_path = SESSION_DIR / f"{name}.kitty-session"
    if session_path.exists():
        boss.goto_session(str(session_path))
