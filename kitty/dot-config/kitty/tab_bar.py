"""Custom tab bar that draws flat tabs with a gap between them.

The gap uses the default background color which inherits background_opacity.
No gradient, no powerline glyphs — just flat colored blocks with spacing.
"""

from kitty.fast_data_types import Screen
from kitty.tab_bar import DrawData, ExtraData, TabBarData, as_rgb, draw_title


def draw_tab(
    draw_data: DrawData,
    screen: Screen,
    tab: TabBarData,
    before: int,
    max_tab_length: int,
    index: int,
    is_last: bool,
    extra_data: ExtraData,
) -> int:
    default_bg = as_rgb(int(draw_data.default_bg))

    if tab.is_active:
        tab_bg = as_rgb(int(draw_data.active_bg))
        tab_fg = as_rgb(int(draw_data.active_fg))
    else:
        tab_bg = as_rgb(int(draw_data.inactive_bg))
        tab_fg = as_rgb(int(draw_data.inactive_fg))

    # Gap before tab (drawn in default bg)
    if index > 1:
        screen.cursor.bg = default_bg
        screen.cursor.fg = default_bg
        screen.draw("  ")

    # Flat tab content
    screen.cursor.bg = tab_bg
    screen.cursor.fg = tab_fg
    screen.draw("  ")
    draw_title(draw_data, screen, tab, index, max_tab_length)
    screen.draw("  ")

    return screen.cursor.x
