#!/bin/bash

sketchybar --add item caffeinate right \
  --set caffeinate \
    icon="󰛊" \
    icon.color=0xff565f89 \
    label="" \
    update_freq=3 \
    script="$PLUGIN_DIR/caffeinate.sh" \
    click_script="$PLUGIN_DIR/caffeinate_click.sh" \
    popup.drawing=off \
    popup.background.drawing=on \
    popup.background.color=0xd91a1b26 \
    popup.background.border_color=0xff33467c \
    popup.background.border_width=1 \
    popup.background.corner_radius=8 \
    popup.background.padding_left=4 \
    popup.background.padding_right=4 \
  --subscribe caffeinate mouse.exited.global system_woke
