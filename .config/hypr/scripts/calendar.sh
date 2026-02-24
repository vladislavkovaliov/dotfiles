#!/usr/bin/env bash

# Get current date
today=$(date +%d)

# Generate calendar with today highlighted in red
cal | awk -v today="$today" '
BEGIN {
    color_start = "<span color=\"red\">"
    color_end = "</span>"
}
{
    line = $0
    # Replace the today date with colored version
    # Match whole word boundaries for the day number
    gsub("\\<(" today ")\\>", color_start today color_end, line)
    print line
}
'
