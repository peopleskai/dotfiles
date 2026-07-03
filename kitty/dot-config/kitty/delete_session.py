"""Kitten to delete a saved session.

Lists all saved session files, prompts the user to pick one by number or name,
then removes the session file and closes all tabs belonging to that session.

Bound to: leader d
"""

import sys
from pathlib import Path

from kitty.boss import Boss

SESSION_DIR = Path("~/.config/kitty/sessions").expanduser()


def main(args: list[str]) -> str:
    # Runs in an overlay; show numbered list of sessions
    sessions = sorted(
        f.stem for f in SESSION_DIR.glob("*.kitty-session")
    )
    if not sessions:
        print("No saved sessions to delete.")
        return ""

    for i, name in enumerate(sessions, 1):
        print(f"  {i}. {name}")
    print()
    print("Delete session (number or name): ", end="", flush=True)
    choice = sys.stdin.readline().strip()
    if not choice:
        return ""

    if choice.isdigit():
        idx = int(choice) - 1
        if 0 <= idx < len(sessions):
            return sessions[idx]
        return ""
    if choice in sessions:
        return choice
    return ""


def handle_result(args: list[str], name: str, target_window_id: int, boss: Boss) -> None:
    if not name:
        return

    session_file = SESSION_DIR / f"{name}.kitty-session"
    if session_file.exists():
        session_file.unlink()

    # Closes all tabs that belong to this session
    boss.close_session(name)
