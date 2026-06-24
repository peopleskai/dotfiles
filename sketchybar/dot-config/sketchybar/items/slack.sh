#!/bin/bash

sketchybar --add item slack right \
  --set slack \
    icon="󰒱" \
    icon.color=0xff9ece6a \
    label="" \
    update_freq=10 \
    script="$PLUGIN_DIR/slack.sh" \
  --subscribe slack system_woke mouse.clicked
