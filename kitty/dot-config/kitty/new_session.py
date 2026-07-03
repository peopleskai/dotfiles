"""Kitten to create a new named kitty session.

Prompts for a session name, creates a minimal session file if one doesn't
already exist, then switches to it via boss.goto_session(). The session file
is later maintained by auto_save_session.py as tabs are opened/closed.

Bound to: leader %
"""

import sys

from kitty.boss import Boss


def main(args: list[str]) -> str:
    # Runs in an overlay; prompt is visible to the user
    print("Session name: ", end="", flush=True)
    name = sys.stdin.readline().strip()
    return name


def handle_result(args: list[str], name: str, target_window_id: int, boss: Boss) -> None:
    if not name:
        return

    from pathlib import Path

    session_dir = Path("~/.config/kitty/sessions").expanduser()
    safe_name = name.replace("/", "_").replace(" ", "_")
    session_path = session_dir / f"{safe_name}.kitty-session"

    # Bootstrap a minimal session file so goto_session has something to load
    if not session_path.exists():
        session_path.write_text(f"new_tab\nlaunch --cwd=current\n")

    boss.goto_session(str(session_path))
