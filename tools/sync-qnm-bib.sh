#!/usr/bin/env bash
#
# Keep the bib file of "Reviews on Quasinormal Modes" in step with the master bibliography.
#
# The entries of the post are the entries of _bibliography/references.bib with a keyword that starts
# with "qnm-" (keywords = "qnm-reviews", "qnm-notes", ...), wherever they stand in the file, and the
# comment that starts "% Reviews, lecture notes" describes them. This script copies the comment and
# these entries, in the order of the file, to _includes/code/reviews-on-quasinormal-modes/qnm.bib,
# the file of the gist that the post links to, and says whether the gist differs from it. With --push it also commits the file in the clone of
# the gist (~/qnm-gist, cloned if it is missing) and pushes it, with the token of the GitHub CLI
# (gh) in place of the credential helper of git, which waits for a password that never comes.
# Nothing in the site repository is committed.
#
# Usage:
#   bash tools/sync-qnm-bib.sh                      copy the block and compare it with the gist
#   bash tools/sync-qnm-bib.sh --push [message]     also commit and push the gist
#
# Environment: QNM_GIST_DIR is the clone of the gist (default ~/qnm-gist).

set -eu

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
SRC="$ROOT/_bibliography/references.bib"
OUT="$ROOT/_includes/code/reviews-on-quasinormal-modes/qnm.bib"
GIST_DIR=${QNM_GIST_DIR:-$HOME/qnm-gist}
GIST_URL=https://gist.github.com/e6cb99d86ec2ccea78bb51e4f7fb6d87.git

push=false
message="Update qnm.bib"
if [ "${1:-}" = "--push" ]; then
    push=true
    [ -n "${2:-}" ] && message=$2
elif [ -n "${1:-}" ]; then
    echo "usage: bash $0 [--push [message]]" >&2
    exit 1
fi

ruby -e '
  text = File.read(ARGV[0])
  header = text[/^% Reviews, lecture notes.*?\n\n/m].to_s
  entries = text.split(/\n(?=@)/).select { |e| e.start_with?("@") && e.match?(/keywords = "[^"]*qnm-/) }
  puts header + entries.map(&:strip).join("\n\n")
' "$SRC" > "$OUT"
[ -s "$OUT" ] || { echo "error: no block of entries found in $SRC" >&2; exit 1; }
echo "qnm.bib: $(grep -c '^@' "$OUT") entries copied from references.bib"

if ! $push; then
    if [ -f "$GIST_DIR/qnm.bib" ] && cmp -s "$OUT" "$GIST_DIR/qnm.bib"; then
        echo "the gist clone in $GIST_DIR has the same file"
    else
        echo "the gist differs from this file; to update it, run: bash $0 --push \"message\""
    fi
    exit 0
fi

[ -d "$GIST_DIR/.git" ] || git clone "$GIST_URL" "$GIST_DIR"
cp "$OUT" "$GIST_DIR/qnm.bib"
cd "$GIST_DIR"
if [ -z "$(git status --porcelain qnm.bib)" ]; then
    echo "the gist is up to date"
    exit 0
fi
git add qnm.bib
git commit -m "$message"
git -c credential.helper= -c 'credential.helper=!gh auth git-credential' push
