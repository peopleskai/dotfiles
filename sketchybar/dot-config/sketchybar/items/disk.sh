#!/bin/bash

sketchybar --add item disk right \
  --set disk \
    icon="󰋊" \
    icon.color=0xff7aa2f7 \
    update_freq=120 \
    script="$PLUGIN_DIR/disk.sh"
