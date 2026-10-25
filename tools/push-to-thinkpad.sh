#!/usr/bin/env bash
#
# Send the committed work of this Mac to the preview on the ThinkPad.
#
# The site and its drafts are two repositories, and a push to main of
# the site repository deploys the public site. This script therefore
# pushes to the ThinkPad over SSH and leaves GitHub alone. The
# ThinkPad's checkouts accept the push and update their files
# (receive.denyCurrentBranch = updateInstead), and the preview there
# rebuilds the changed pages. The script restarts the preview only
# when a plugin, a configuration file or the Gemfile changed, since
# Jekyll reads those at start-up only.
#
# Usage:
#   bash tools/push-to-thinkpad.sh [--restart] [--publish] [--dry-run]
#   bash tools/push-to-thinkpad.sh --setup [--dry-run]     (once)
#
#   --setup    add the remote "thinkpad" to both repositories and let
#              the ThinkPad accept pushes
#   --restart  restart the preview, whatever changed
#   --publish  afterwards, push both repositories to GitHub as well;
#              this deploys the public site
#   --dry-run  say what would happen, and change nothing
#
# The settings below can be overridden with environment variables.

set -u

HOST=${THINKPAD_HOST:-thinkpad}
SITE_DIR=${THINKPAD_SITE_DIR:-/mnt/nvme0/Docs/Notes/just-the-notes}
SERVERS=${THINKPAD_SERVERS:-scripts/thinkpad-servers.sh}
REMOTE=thinkpad

# A change of these files needs a restart of the preview
RESTART_FILES='^(_plugins/|_config[^/]*\.ya?ml$|Gemfile|\.ruby-version)'

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
REPOS=("$ROOT" "$ROOT/_drafts")
NAMES=(site drafts)
DIRS=("$SITE_DIR" "$SITE_DIR/_drafts")

setup=false
restart=false
publish=false
dry=false
for arg in "$@"; do
    case $arg in
        --setup)    setup=true ;;
        --restart)  restart=true ;;
        --publish)  publish=true ;;
        --dry-run)  dry=true ;;
        -h|--help)  sed -n '3,/^$/p' "$0" | sed 's/^# \{0,1\}//'
                    exit 0 ;;
        *)          echo "unknown option: $arg (see --help)"; exit 1 ;;
    esac
done

say()  { printf '%s\n' "$*"; }
fail() { printf 'error: %s\n' "$*" >&2; exit 1; }
run()  { if $dry; then say "[dry run] $*"; else "$@"; fi; }
tp()   { ssh -o BatchMode=yes -o ConnectTimeout=10 "$HOST" "$@"; }

tp true >/dev/null 2>&1 || fail "cannot reach $HOST over SSH"

# Once: the remote of each repository, and the ThinkPad's permission
if $setup; then
    for i in 0 1; do
        repo=${REPOS[$i]}
        url="$HOST:${DIRS[$i]}"
        if git -C "$repo" remote get-url "$REMOTE" >/dev/null 2>&1; then
            run git -C "$repo" remote set-url "$REMOTE" "$url"
        else
            run git -C "$repo" remote add "$REMOTE" "$url"
        fi
        run tp git -C "${DIRS[$i]}" config \
            receive.denyCurrentBranch updateInstead
        say "${NAMES[$i]}: remote $REMOTE is $url"
    done
    exit 0
fi

# Both repositories on main, with the remote, and a warning for
# changes that were not committed
for i in 0 1; do
    repo=${REPOS[$i]}
    name=${NAMES[$i]}
    [ -d "$repo/.git" ] || fail "$name: no repository at $repo"
    [ "$(git -C "$repo" branch --show-current)" = main ] \
        || fail "$name is not on the branch main"
    git -C "$repo" remote get-url "$REMOTE" >/dev/null 2>&1 \
        || fail "$name has no remote $REMOTE; run: bash $0 --setup"
    if [ -n "$(git -C "$repo" status --porcelain)" ]; then
        say "warning: $name has uncommitted changes; they are not sent"
    fi
done

# What each repository would send: the commit that the ThinkPad has,
# and the files that changed since then ("?" if that commit is unknown)
OLD=("" "")
NEW=("" "")
FILES=("" "")
for i in 0 1; do
    repo=${REPOS[$i]}
    old=$(tp git -C "${DIRS[$i]}" rev-parse HEAD 2>/dev/null) \
        || fail "${NAMES[$i]}: no repository at ${DIRS[$i]} on $HOST"
    new=$(git -C "$repo" rev-parse HEAD)
    files=""
    if [ "$old" != "$new" ]; then
        if git -C "$repo" cat-file -e "$old^{commit}" 2>/dev/null; then
            files=$(git -C "$repo" diff --name-only "$old" "$new")
        else
            files="?"
        fi
    fi
    OLD[$i]=$old
    NEW[$i]=$new
    FILES[$i]=$files
done

# The push: fast-forward only, and the ThinkPad refuses it if its
# files have been edited there
for i in 0 1; do
    repo=${REPOS[$i]}
    name=${NAMES[$i]}
    if [ "${OLD[$i]}" = "${NEW[$i]}" ]; then
        say "$name: up to date on $HOST"
        continue
    fi
    n=$(git -C "$repo" rev-list --count "${OLD[$i]}..${NEW[$i]}" \
        2>/dev/null || echo "some")
    say "$name: sending $n commit(s) to $HOST"
    run git -C "$repo" push "$REMOTE" main \
        || fail "the push of $name failed; nothing else was done"
done

# The preview rebuilds changed pages by itself. A plugin, a
# configuration file or the Gemfile is read at start-up only.
files=${FILES[0]}
need=false
why=""
if [ "$files" = "?" ]; then
    need=true
    why="the commit on the ThinkPad is unknown here"
elif printf '%s\n' "$files" | grep -Eq "$RESTART_FILES"; then
    need=true
    why=$(printf '%s\n' "$files" | grep -E "$RESTART_FILES" \
        | head -3 | paste -sd, -)
fi
if $restart; then
    need=true
    why="--restart"
fi
if printf '%s\n' "$files" | grep -q '^Gemfile'; then
    say "note: the Gemfile changed; run bundle install on the ThinkPad:"
    say "  ssh $HOST 'cd $SITE_DIR && . .venv/bin/activate &&" \
        "bundle install'"
fi

if ! $need; then
    say "no restart needed: the preview rebuilds the changes itself"
elif $restart || tp "$SERVERS" status site 2>/dev/null \
        | grep -q '^site: running'; then
    say "restarting the preview ($why)"
    run tp "$SERVERS" restart site
else
    say "the preview is not running, so it is not restarted ($why)"
    say "  start it with: ssh $HOST $SERVERS start site"
fi

tp "$SERVERS" status site
if curl -sI --max-time 3 http://127.0.0.1:4000 >/dev/null 2>&1; then
    say "preview: http://127.0.0.1:4000"
else
    say "nothing answers at http://127.0.0.1:4000: the preview is down,"
    say "or the tunnel is closed (open it with: thinkpad-web)"
fi

if $publish; then
    say "publishing: a push of the site repository deploys the site"
    for i in 0 1; do
        run git -C "${REPOS[$i]}" push \
            || fail "the push of ${NAMES[$i]} to GitHub failed"
    done
fi
