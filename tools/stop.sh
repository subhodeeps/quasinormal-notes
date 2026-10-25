#!/usr/bin/env bash
#
# Stop the server that tools/run.sh started in this repository, whatever ports it took. Only
# Jekyll processes whose working folder is this repository are stopped, so other programs on
# the same ports, such as an SSH tunnel to the preview of another machine, keep running.

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

pids=""
for pid in $(pgrep -f 'jekyll (s|serve)( |$)'); do
  cwd="$(lsof -a -p "$pid" -d cwd -Fn 2>/dev/null | sed -n 's/^n//p')"
  [ "$cwd" = "$root" ] && pids="$pids $pid"
done

if [ -z "$pids" ]; then
  echo "> No server is running"
  exit 0
fi

echo "> Stopping$pids"
kill $pids
