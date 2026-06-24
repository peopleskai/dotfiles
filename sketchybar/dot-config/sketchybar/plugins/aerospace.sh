#!/bin/bash

if [ "$SENDER" = "aerospace_workspace_change" ]; then
  FOCUSED="$FOCUSED_WORKSPACE"
  WORKSPACES=(1 2 3 4 5 6 7 8 9 10)
  for sid in "${WORKSPACES[@]}"; do
    if [ "$sid" = "$FOCUSED" ]; then
      sketchybar --set space."$sid" \
        icon.highlight=on \
        label.highlight=on \
        background.drawing=on
    else
      sketchybar --set space."$sid" \
        icon.highlight=off \
        label.highlight=off \
        background.drawing=off
    fi
  done
fi

if [ "$SENDER" = "space_windows_change" ] || [ "$SENDER" = "aerospace_workspace_change" ]; then
  WORKSPACES=(1 2 3 4 5 6 7 8 9 10)
  for sid in "${WORKSPACES[@]}"; do
    APPS=$(aerospace list-windows --workspace "$sid" --format '%{app-name}' 2>/dev/null)
    ICON_LINE=""
    if [ -n "$APPS" ]; then
      while IFS= read -r APP; do
        ICON=$("$CONFIG_DIR/plugins/app_icons.sh" "$APP")
        ICON_LINE="${ICON_LINE}${ICON} "
      done <<< "$APPS"
    fi
    sketchybar --set space."$sid" label="${ICON_LINE}"
  done
fi

if [ "$SENDER" = "mouse.clicked" ]; then
  SID="${NAME#space.}"
  aerospace workspace "$SID"
fi
