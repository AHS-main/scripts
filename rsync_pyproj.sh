#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<EOF
Usage: $0 -h HOST -r REMOTE_DIR [-l LOCAL_DIR] [-u USER] [-k] [-d] [-e PATTERN]

  -h HOST        remote SSH host or profile (in ~/.ssh/config)
  -r REMOTE_DIR  target directory on the remote machine
  -l LOCAL_DIR   local directory to sync (default: current dir)
  -u USER        remote SSH user (overrides config)
  -k             keep .git/ (do NOT exclude it)
  -d             delete extraneous files on remote (--delete)
  -e PATTERN     additional --exclude=PATTERN (can be used multiple times)

Examples:
  # Basic sync:
  ./rsync_pyproj.sh -h mycluster -r ~/projects/myapp

  # Keep .git/, delete remote extras, and exclude logs:
  ./rsync_pyproj.sh -h mycluster -r ~/projects/myapp -k -d -e 'logs/'

  # Sync a different local folder and add custom excludes:
  ./rsync_pyproj.sh -h mycluster -r ~/projects/myapp -l ../otherproj -e '*.csv' -e 'build/'
EOF
    exit 1
}

# Default values
LOCAL_DIR=""
REMOTE_USER=""
KEEP_GIT=false
DELETE_FLAG=false
EXTRA_EXCLUDES=()

# Parse options
while getopts "h:r:l:u:kde:" opt; do
    case "$opt" in
        h) REMOTE_HOST=$OPTARG ;;
        r) REMOTE_DIR=$OPTARG ;;
        l) LOCAL_DIR=$OPTARG ;;
        u) REMOTE_USER=$OPTARG ;;
        k) KEEP_GIT=true ;;
        d) DELETE_FLAG=true ;;
        e) EXTRA_EXCLUDES+=("$OPTARG") ;;
        *) usage ;;
    esac
done

# Validate required options
if [ -z "${REMOTE_HOST:-}" ] || [ -z "${REMOTE_DIR:-}" ]; then
    echo "Error: -h HOST and -r REMOTE_DIR are required." >&2
    usage
fi

# Default local dir to CWD if not provided
: "${LOCAL_DIR:=$(pwd)}"

# Build exclude-list array
EXCLUDES=(
    --exclude=.venv/
    --exclude=__pycache__/
    --exclude=*.pyc
    --exclude=*.pyo
    --exclude=*.log
    --exclude=*.tmp
    --exclude=.mypy_cache/
    --exclude=.pytest_cache/
    --exclude=.envrc
    --exclude=.DS_Store
)
if [ "$KEEP_GIT" = false ]; then
    EXCLUDES+=(--exclude=.git/)
fi
# Add any extra user-specified excludes
for pattern in "${EXTRA_EXCLUDES[@]}"; do
    EXCLUDES+=(--exclude="$pattern")
done

# Determine SSH target and rsync target
if [ -n "${REMOTE_USER:-}" ]; then
    SSH_TARGET="$REMOTE_USER@$REMOTE_HOST"
else
    SSH_TARGET="$REMOTE_HOST"
fi
RSYNC_TARGET="$SSH_TARGET:$REMOTE_DIR"

# Ensure remote directory exists
echo "Ensuring remote directory exists: $REMOTE_DIR"
ssh "$SSH_TARGET" mkdir -p "$REMOTE_DIR"

# Build rsync options
RSYNC_OPTS=( -avz )
if [ "$DELETE_FLAG" = true ]; then
    RSYNC_OPTS+=(--delete)
fi

# Perform sync
echo "Syncing $LOCAL_DIR/ → $RSYNC_TARGET/"
rsync "${RSYNC_OPTS[@]}" "${EXCLUDES[@]}" "$LOCAL_DIR"/ "$RSYNC_TARGET"/

echo "✅ Sync complete."
