#!/bin/bash

sketchybar --add item calendar right \
  --set calendar \
    icon="" \
    icon.color=0xff7aa2f7 \
    update_freq=300 \
    script="$PLUGIN_DIR/calendar.sh" \
  --subscribe calendar system_woke
