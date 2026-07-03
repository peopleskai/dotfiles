"""Kitten to open a new kitten ssh tab with a new zmx session.

From the focused ssh tab (e.g. "cloud-merlin.dotfiles"), increments the
trailing number to derive the next host/session (e.g. "cloud-merlin.dotfiles1")
and launches it in a new tab. The new tab is attached to the current kitty
session so it persists across restarts via auto_save_session.py.

Bound to: cmd+t
Requires: the focused window must be running `kitten ssh` (not plain ssh).
"""

import re

from kitty.boss import Boss


def main(args: list[str]) -> str:
    return ""


def handle_result(args: list[str], answer: str, target_window_id: int, boss: Boss) -> None:
    window = boss.window_id_map.get(target_window_id)
    if window is None:
        return

    # Only works when the focused window is running the kitty ssh kitten
    cmdline = window.ssh_kitten_cmdline()
    if not cmdline:
        return

    session_name = getattr(window, "created_in_session_name", "")

    # Increment trailing number: host -> host1, host1 -> host2, etc.
    host = cmdline[-1]
    match = re.search(r"(\d+)$", host)
    if match:
        num = int(match.group(1)) + 1
        new_host = host[: match.start()] + str(num)
    else:
        new_host = host + "1"

    tab_ids_before = {tab.id for ow in boss.os_window_map for tab in boss.os_window_map[ow]}
    new_cmdline = cmdline[:-1] + [new_host]
    boss.launch("--type=tab", *new_cmdline)

    # Assign the new tab to the same kitty session as the source window,
    # so auto_save_session.py includes it when serializing/restoring.
    if session_name:
        for ow in boss.os_window_map:
            for tab in boss.os_window_map[ow]:
                if tab.id not in tab_ids_before:
                    tab.created_in_session_name = session_name
                    for w in tab:
                        w.created_in_session_name = session_name
