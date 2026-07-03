"""Kitten to open a new tab and attach it to the active session.

Launches a plain shell tab with the current working directory, then assigns
it to the same kitty session as the source window so auto_save_session.py
will persist it across restarts.

Bound to: cmd+shift+t
"""

from kitty.boss import Boss


def main(args: list[str]) -> str:
    return ""


def handle_result(args: list[str], answer: str, target_window_id: int, boss: Boss) -> None:
    window = boss.window_id_map.get(target_window_id)
    if window is None:
        return

    session_name = getattr(window, "created_in_session_name", "")

    tab_ids_before = {tab.id for ow in boss.os_window_map for tab in boss.os_window_map[ow]}
    boss.launch("--type=tab", "--cwd=current")

    if session_name:
        for ow in boss.os_window_map:
            for tab in boss.os_window_map[ow]:
                if tab.id not in tab_ids_before:
                    tab.created_in_session_name = session_name
                    for w in tab:
                        w.created_in_session_name = session_name
