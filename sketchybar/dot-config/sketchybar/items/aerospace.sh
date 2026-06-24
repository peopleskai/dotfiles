#!/bin/bash

WORKSPACES=(1 2 3 4 5 6 7 8 9 10)

for sid in "${WORKSPACES[@]}"; do
  sketchybar --add item space."$sid" left \
    --set space."$sid" \
      icon="$sid" \
      icon.padding_left=8 \
      icon.padding_right=4 \
      icon.highlight_color=0xffff9e64 \
      label="" \
      label.font="sketchybar-app-font:Regular:14.0" \
      label.padding_right=8 \
      label.color=0xff565f89 \
      label.highlight_color=0xffc0caf5 \
      label.y_offset=1 \
      background.color=0xd924283b \
      background.corner_radius=5 \
      background.height=24 \
      background.drawing=off \
      script="$PLUGIN_DIR/aerospace.sh" \
    --subscribe space."$sid" aerospace_workspace_change space_windows_change mouse.clicked
done
