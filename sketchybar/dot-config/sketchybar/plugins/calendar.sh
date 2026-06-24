#!/bin/bash

NEXT_EVENT=$(osascript -e '
tell application "System Events"
  if not (exists process "Microsoft Outlook") then return ""
end tell
tell application "Microsoft Outlook"
  set now to current date
  set cutoff to now + (12 * hours)
  set minTime to cutoff
  set minLabel to ""
  try
    repeat with cal in calendars
      repeat with evt in (every calendar event of cal)
        set evtStart to start time of evt
        if evtStart >= now and evtStart <= cutoff then
          if evtStart < minTime then
            set minTime to evtStart
            set theHour to hours of evtStart
            set theMin to minutes of evtStart
            set minStr to text -2 thru -1 of ("0" & theMin)
            set minLabel to (theHour as text) & ":" & minStr & " " & subject of evt
          end if
        end if
      end repeat
    end repeat
  end try
  return minLabel
end tell
' 2>/dev/null)

if [ -n "$NEXT_EVENT" ]; then
  TRUNCATED="${NEXT_EVENT:0:30}"
  if [ ${#NEXT_EVENT} -gt 30 ]; then
    TRUNCATED="${TRUNCATED}…"
  fi
  sketchybar --set "$NAME" label="$TRUNCATED" drawing=on
else
  sketchybar --set "$NAME" label="No events" drawing=on
fi
