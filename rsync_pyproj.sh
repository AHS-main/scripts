#!/usr/bin/env bash
set -euo pipefail

show_help() {
    cat <<EOF
Usage: $(basename "$0") [options] <SRC> <DEST>

Sync a local Python project (or any directory) to/from a remote machine
using sensible defaults.

SRC and DEST follow rsync syntax:
  [USER@]HOST:DIR   for remote
  DIR               for local

Options:
  -u USER           Override remote SSH user
  -k                Keep .git/ (do NOT exclude it)
  -d                Delete extraneous files on destination (--delete)
  -e PATTERN        Extra --exclude=PATTERN (repeatable)
  -h, --help        Show this help and exit

Examples:
  # Local → remote:
  ./rsync_pyproj.sh ./app/ myserver:~/projects/app/

  # Remote → local, delete extras, exclude logs:
  ./rsync_pyproj.sh -d -e 'logs/' myserver:~/projects/app/ ./local_app/
EOF
}

REMOTE_USER_OVERRIDE=""
KEEP_GIT=false
DELETE_FLAG=false
EXTRA_EXCLUDES=()

# parse options
while [[ $# -gt 0 ]]; do
    case "$1" in
        -u) REMOTE_USER_OVERRIDE="$2"; shift 2 ;;
        -k) KEEP_GIT=true; shift ;;
        -d) DELETE_FLAG=true; shift ;;
        -e) EXTRA_EXCLUDES+=("$2"); shift 2 ;;
        -h|--help) show_help; exit 0 ;;
        --) shift; break ;;
        -* )
            echo "Unknown option: $1" >&2
            show_help >&2
            exit 1 ;;
        *) break ;;
    esac
done

if [[ $# -ne 2 ]]; then
    echo "Error: SRC and DEST required" >&2
    show_help >&2
    exit 1
fi

SRC=$1
DEST=$2

# Determine if SRC or DEST is remote
is_remote() {
    [[ "$1" =~ : ]]
}

if is_remote "$SRC"; then
    # pulling from remote
    REMOTE_TARGET="$SRC"
    LOCAL_PATH="$DEST"
elif is_remote "$DEST"; then
    # pushing to remote
    REMOTE_TARGET="$DEST"
    LOCAL_PATH="$SRC"
else
    echo "Error: one of SRC or DEST must be remote (contain a colon)." >&2
    exit 1
fi

# extract host and path
REMOTE_PART="${REMOTE_TARGET%%:*}"
REMOTE_PATH="${REMOTE_TARGET#*:}"

# apply user override if provided
if [[ -n "$REMOTE_USER_OVERRIDE" ]]; then
    HOST_USER="$REMOTE_USER_OVERRIDE@$REMOTE_PART"
else
    HOST_USER="$REMOTE_PART"
fi

SSH_TARGET="$HOST_USER"
RSYNC_TARGET="$SSH_TARGET:$REMOTE_PATH"

# default excludes
EXCLUDES=(
    --exclude='.venv/'
    --exclude='__pycache__/'
    --exclude='*.pyc'
    --exclude='*.pyo'
    --exclude='*.log'
    --exclude='*.tmp'
    --exclude='.mypy_cache/'
    --exclude='.pytest_cache/'
    --exclude='.envrc'
    --exclude='.DS_Store'
)
if [[ "$KEEP_GIT" != true ]]; then
    EXCLUDES+=(--exclude='.git/')
fi
for pat in "${EXTRA_EXCLUDES[@]}"; do
    EXCLUDES+=("--exclude=$pat")
done

# ensure remote directory exists (for push)
if ! is_remote "$SRC"; then
    echo "Ensuring remote directory exists: $REMOTE_PATH"
    ssh "$SSH_TARGET" mkdir -p "$REMOTE_PATH"
fi

# rsync options
RSYNC_OPTS=(-avz)
if [[ "$DELETE_FLAG" == true ]]; then
    RSYNC_OPTS+=(--delete)
fi

echo "Syncing $LOCAL_PATH/ → $RSYNC_TARGET/"
rsync "${RSYNC_OPTS[@]}" "${EXCLUDES[@]}" "$LOCAL_PATH"/ "$RSYNC_TARGET"/

echo "✅ Sync complete."
