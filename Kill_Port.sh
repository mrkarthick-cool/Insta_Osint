#!/bin/bash

# Kill all processes using TCP ports on localhost
clear
echo ""
echo " ▒█░▄▀ ▀█▀ ▒█░░░ ▒█░░░ 　 ▒█▀▀█ █▀▀█ █▀▀█ ▀▀█▀▀ "
echo " ▒█▀▄░ ▒█░ ▒█░░░ ▒█░░░ 　 ▒█▄▄█ █░░█ █▄▄▀ ░░█░░ "
echo " ▒█░▒█ ▄█▄ ▒█▄▄█ ▒█▄▄█ 　 ▒█░░░ ▀▀▀▀ ▀░▀▀ ░░▀░░ "
echo ""
echo " TOOL Dev :https:/t.me/Drak24Evil"
echo "" 
date 
echo ""
echo "Finding and killing all processes using TCP ports..."

# List all processes using TCP sockets, get the PID, and kill them
lsof -iTCP -sTCP:LISTEN -Pn | awk 'NR>1 {print $2}' | sort -u | while read pid; do
    echo "Killing process with PID: $pid"
    kill -9 $pid 2>/dev/null
done

echo "All listening TCP port processes have been terminated by Drak24Evil."
echo ""

