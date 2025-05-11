#!/usr/bin/env bash
set -euo pipefail

show_help() {
  cat <<EOF
Usage: $(basename "$0") [options] <SRC1> [<SRC2> ...] <DEST>

A thin wrapper around rsync for syncing one or more sources to a destination
(local ↔ remote).  Example:
  /path/to/file1 /path/to/dir2 user@host:/dest/path/

Options:
  -e, --exclude PATTERN   Add rsync --exclude=PATTERN (repeatable)
  -d, --delete            Delete extraneous files on DEST (--delete)
  -h, --help              Show this help message and exit

Examples:
  # Upload multiple files to remote:
  ./rsync_files.sh -e '*.tmp' ./a.txt ./b.txt user@server:/path/

  # Download multiple logs:
  ./rsync_files.sh -d user@server:/var/log/foo.log user@server:/var/log/bar.log ~/logs/
EOF
}

EXCLUDES=()
DELETE_FLAG=false

# parse options
while [[ $# -gt 0 ]]; do
  case "$1" in
    -e|--exclude)
      EXCLUDES+=("--exclude=$2")
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
    --)
      shift
      break
      ;;
    -* )
      echo "Unknown option: $1" >&2
      show_help >&2
      exit 1
      ;;
    *)
      break
      ;;
  esac
done

# Collect remaining args
args=( "$@" )
if (( ${#args[@]} < 2 )); then
  echo "Error: need at least one source and one destination." >&2
  show_help >&2
  exit 1
fi

# Separate sources and destination
DEST="${args[-1]}"
SRCs=( "${args[@]:0:${#args[@]}-1}" )

# Build rsync options
RSYNC_OPTS=( -avz )
if $DELETE_FLAG; then
  RSYNC_OPTS+=(--delete)
fi

# Execute
echo "🔄 Syncing ${SRCs[*]} → $DEST"
rsync "${RSYNC_OPTS[@]}" "${EXCLUDES[@]}" "${SRCs[@]}" "$DEST"

echo "✅ Done."
