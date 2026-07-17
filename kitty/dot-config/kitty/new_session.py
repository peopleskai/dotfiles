"""Kitten to create a new named kitty session.

Prompts for a session name. If a session file already exists, switches to it
via boss.goto_session(). Otherwise launches a new tab tagged with the session
name (launch --add-to-session) and focuses it; auto_save_session.py writes the
session file on the resulting tab-bar-dirty event. The current window stays in
its own session untouched.

Bound to: ctrl+shift+5
"""

import sys

from kitty.boss import Boss


def main(args: list[str]) -> str:
    print("Session name: ", end="", flush=True)
    name = sys.stdin.readline().strip()
    return name


def handle_result(args: list[str], name: str, target_window_id: int, boss: Boss) -> None:
    if not name:
        return

    from pathlib import Path

    from kitty.session import append_to_session_history

    session_dir = Path("~/.config/kitty/sessions").expanduser()
    safe_name = name.replace("/", "_").replace(" ", "_")
    session_path = session_dir / f"{safe_name}.kitty-session"

    if session_path.exists():
        boss.goto_session(str(session_path))
        return

    boss.launch("--type=tab", f"--add-to-session={safe_name}", "--cwd=current")
    # The tab bar filter (session:~) also shows the most recently visited
    # session; record the new one so only its tabs are displayed.
    append_to_session_history(safe_name)
