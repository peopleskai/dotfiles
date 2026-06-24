#!/bin/bash

if ! pgrep -q "Microsoft Outlook"; then
  sketchybar --set "$NAME" label="--" icon.color=0xff565f89
  exit 0
fi

COUNT=$(lsappinfo info -only StatusLabel "Microsoft Outlook" 2>/dev/null | grep -o '"label"="[^"]*"' | grep -o '"[0-9]*"' | tr -d '"')

if [ -z "$COUNT" ]; then
  sketchybar --set "$NAME" label="0" icon.color=0xff9ece6a
else
  sketchybar --set "$NAME" label="$COUNT" icon.color=0xfff7768e
fi
