#!/usr/bin/env bash
#
# Stop the server that tools/run.sh started in this repository, whatever ports it took. Only
# Jekyll processes whose working folder is this repository are stopped, so other programs on
# the same ports, such as an SSH tunnel to the preview of another machine, keep running.

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

# The working folder of a process: /proc on Linux, lsof on macOS
cwd_of() {
  if [ -e "/proc/$1/cwd" ]; then
    readlink "/proc/$1/cwd"
  else
    lsof -a -p "$1" -d cwd -Fn 2>/dev/null | sed -n 's/^n//p'
  fi
}

pids=""
for pid in $(pgrep -f 'jekyll (s|serve)( |$)'); do
  [ "$(cwd_of "$pid")" = "$root" ] && pids="$pids $pid"
done

if [ -z "$pids" ]; then
  echo "> No server is running"
  exit 0
fi

echo "> Stopping$pids"
kill $pids
