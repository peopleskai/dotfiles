"""Kitten to open a new kitten ssh tab with a new zmx session.

From the focused ssh tab (e.g. "cloud-merlin.dotfiles"), increments the
trailing number to derive the next host/session (e.g. "cloud-merlin.dotfiles1")
and launches it in a new tab. The new tab is attached to the current kitty
session so it persists across restarts via auto_save_session.py.

The SSH command runs inside a shell (via KITTY_SI_RUN_COMMAND_AT_STARTUP) so
that when the SSH session dies, the tab stays open with a local shell prompt
and the SSH command is in shell history for easy reconnection.

Bound to: cmd+t
Requires: the focused window must be running `kitten ssh` (not plain ssh).
"""

import re
import shlex

from kitty.boss import Boss


def main(args: list[str]) -> str:
    return ""


def handle_result(args: list[str], answer: str, target_window_id: int, boss: Boss) -> None:
    window = boss.window_id_map.get(target_window_id)
    if window is None:
        return

    # Read the session from the source window (target_window_id), not from
    # boss.active_tab.active_session_name: the kitten runs as an overlay
    # window, and while the overlay is closing the tab's active window has
    # an empty created_in_session_name, so that property returns "".
    session_name = getattr(window, "created_in_session_name", "")

    cmdline = window.ssh_kitten_cmdline()
    if not cmdline:
        if not session_name:
            return
        host = f"cloud-merlin.{session_name}"
        cmdline = ["kitten", "ssh", host]

    # Increment trailing number: host -> host1, host1 -> host2, etc.
    host = cmdline[-1]
    match = re.search(r"(\d+)$", host)
    if match:
        num = int(match.group(1)) + 1
        new_host = host[: match.start()] + str(num)
    else:
        new_host = host + "1"

    tab_ids_before = {t.id for ow in boss.os_window_map for t in boss.os_window_map[ow]}
    new_cmdline = cmdline[:-1] + [new_host]
    ssh_cmd = shlex.join(new_cmdline)
    # The startup command is eval'd by the shell integration, which bypasses
    # zsh history. `print -s` pushes it onto history first so the ssh command
    # can be recalled with up-arrow after the ssh session dies.
    startup_cmd = f"print -s -- {shlex.quote(ssh_cmd)}; {ssh_cmd}"
    boss.launch("--type=tab", "--env", f"KITTY_SI_RUN_COMMAND_AT_STARTUP={startup_cmd}")

    # Assign the new tab to the same kitty session,
    # so auto_save_session.py includes it when serializing/restoring.
    if session_name:
        for ow in boss.os_window_map:
            for new_tab in boss.os_window_map[ow]:
                if new_tab.id not in tab_ids_before:
                    new_tab.created_in_session_name = session_name
                    for w in new_tab:
                        w.created_in_session_name = session_name
