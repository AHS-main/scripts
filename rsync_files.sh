#!/usr/bin/env bash
set -euo pipefail

show_help() {
    cat <<EOF
Usage: $(basename "$0") [options] <SRC> <DEST>

A thin wrapper around rsync for syncing files between any two endpoints
(local ↔ remote).  Example endpoints:
  /path/to/dir/
  user@host:/other/path/

Options:
  -e, --exclude PATTERN   Add rsync --exclude=PATTERN (repeatable)
  -d, --delete            Delete extraneous files on DEST (--delete)
  -h, --help              Show this help message and exit

Examples:
  # Upload local → remote, excluding tmp files:
  ./rsync_files.sh -e '*.tmp' ./site/ user@server:/var/www/site/

  # Download remote → local, with delete:
  ./rsync_files.sh -d user@server:/var/logs/ ./logs/
EOF
}

EXCLUDES=()
DELETE_FLAG=false

# parse options
while [[ $# -gt 0 ]]; do
    case "$1" in
        -e|--exclude)
            EXCLUDES+=( "--exclude=$2" )
            shift 2
            ;;
        -d|--delete)
            DELETE_FLAG=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        --) shift; break ;;
        -*)
            echo "Unknown option: $1" >&2
            show_help >&2
            exit 1
            ;;
        *) break ;;
    esac
done

# require exactly two positional args
if [[ $# -ne 2 ]]; then
    echo "Error: SRC and DEST required." >&2
    show_help >&2
    exit 1
fi

SRC=$1
DEST=$2

# build rsync opts
RSYNC_OPTS=( -avz )
if $DELETE_FLAG; then
    RSYNC_OPTS+=( --delete )
fi

echo "🔄 Syncing $SRC → $DEST"
rsync "${RSYNC_OPTS[@]}" "${EXCLUDES[@]}" "$SRC" "$DEST"

echo "✅ Done."
