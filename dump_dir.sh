#!/usr/bin/env bash
set -euo pipefail

show_help() {
    cat <<EOF
Usage: $(basename "$0") [options]
Options:
  -d, --dir DIRECTORY       Directory to dump (default: .)
  -o, --output FILE         Output file (default: dump.txt)
  -x, --exclude PATTERN     Additional exclude pattern (can be used multiple times)
  -h, --help                Show this help message and exit
EOF
}

# Defaults
DIR="."
OUTPUT="dump.txt"
EXCLUDES=( "__pycache__" ".git" ".venv" "venv" "ENV" "env" \
                         "*.pyc" "*.o" "*.so" "*.dll" "*.exe" \
                         "*.jpg" "*.jpeg" "*.png" "*.gif" \
                         "*.pdf" "*.zip" "*.tar" "*.gz" "*.7z" "*.db" )

# Parse args
while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--dir)      DIR="$2"; shift 2 ;;
        -o|--output)   OUTPUT="$2"; shift 2 ;;
        -x|--exclude)  EXCLUDES+=("$2"); shift 2 ;;
        -h|--help)     show_help; exit 0 ;;
        *) echo "Unknown option: $1"; show_help; exit 1 ;;
    esac
done

# Normalize
DIR="${DIR%/}"
: > "$OUTPUT"

# 1) Header & tree
echo "Directory tree of $DIR" >> "$OUTPUT"
echo "----------------------------------------" >> "$OUTPUT"

if command -v tree >/dev/null; then
    IGNORE_PATTERN=$(IFS="|"; echo "${EXCLUDES[*]}")
    tree -a -I "$IGNORE_PATTERN" "$DIR" >> "$OUTPUT"
else
    find "$DIR" -type f \
         ! -path "*/.git/*" \
         ! -path "*/__pycache__/*" \
         ! -path "*/.venv/*" \
         ! -path "*/venv/*" \
        | sed "s|^$DIR|.|" >> "$OUTPUT"
fi

echo -e "\n" >> "$OUTPUT"

# 2) Dump text files
find "$DIR" -type f | while IFS= read -r file; do
    if [[ "$(file -b --mime-encoding "$file")" != "binary" ]]; then
        rel=${file#$DIR/}
        printf "========== START OF FILE: %s ==========\n" "$rel" >> "$OUTPUT"
        sed 's/\r$//' "$file" >> "$OUTPUT"
        printf "\n========== END OF FILE: %s ==========\n\n" "$rel" >> "$OUTPUT"
    fi
done

echo "Done! Directory dumped to $OUTPUT"
