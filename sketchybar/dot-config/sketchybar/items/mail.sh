#!/bin/bash

sketchybar --add item mail right \
  --set mail \
    icon="󰇮" \
    icon.color=0xff7aa2f7 \
    label="--" \
    update_freq=10 \
    script="$PLUGIN_DIR/mail.sh" \
  --subscribe mail system_woke
