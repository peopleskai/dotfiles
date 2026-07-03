"""Watcher that auto-saves kitty sessions to disk.

Registered as a global watcher in kitty.conf. On every tab-bar-dirty event
(tab opened/closed/reordered) and on quit, serializes each named session to
its own file in ~/.config/kitty/sessions/ and writes a combined
_startup.kitty-session used by kitty's startup_session directive.

Config: watcher auto_save_session.py
"""

import threading

from pathlib import Path
from typing import Any

from kitty.boss import Boss
from kitty.fast_data_types import add_timer
from kitty.session import parse_save_as_options_spec_args
from kitty.window import Window

SESSION_DIR = Path("~/.config/kitty/sessions").expanduser()
lock = threading.Lock()
_save_pending = False


def _get_session_names(boss: Boss) -> set[str]:
    names = set()
    for os_window_id in boss.os_window_map:
        tm = boss.os_window_map[os_window_id]
        for tab in tm:
            name = getattr(tab, "active_session_name", "")
            if name:
                names.add(name)
    return names


def _save_all_sessions(boss: Boss):
    names = _get_session_names(boss)
    all_lines = []

    if not names:
        all_lines = list(boss.serialize_state_as_session())
    else:
        # Serialize each session independently, writing per-session files
        for name in names:
            opts = parse_save_as_options_spec_args([])[0]
            opts.match = f"session:{name}"
            opts.use_foreground_process = True
            lines = list(boss.serialize_state_as_session("", opts))
            if lines:
                safe_name = name.replace("/", "_").replace(" ", "_")
                session_path = SESSION_DIR / f"{safe_name}.kitty-session"
                with open(session_path, "w") as f:
                    f.write("\n".join(lines))
                all_lines.extend(lines)
                all_lines.append("")

    # Combined file used by startup_session to restore everything at launch
    startup_path = SESSION_DIR / "_startup.kitty-session"
    with open(startup_path, "w") as f:
        f.write("\n".join(all_lines))


def write_sessions(boss: Boss, blocking: bool = False):
    locked = lock.acquire(blocking=blocking)
    if not locked:
        return
    try:
        _save_all_sessions(boss)
    finally:
        lock.release()


def on_tab_bar_dirty(boss: Boss, window: Window, data: dict[str, Any]) -> None:
    # Deferred via timer: this callback fires synchronously mid-tab-creation,
    # before the new window is fully registered in boss's weakref maps.
    # Serializing here would raise KeyError and abort the launch.
    global _save_pending
    if _save_pending:
        return
    _save_pending = True

    def _deferred(timer_id: int) -> None:
        global _save_pending
        _save_pending = False
        write_sessions(boss)

    add_timer(_deferred, 0, False)


def on_quit(boss: Boss, window: Window, data: dict[str, Any]) -> None:
    if data.get("confirmed") and not data.get("aborted"):
        write_sessions(boss, blocking=True)
