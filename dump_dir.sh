#!/usr/bin/env bash
set -euo pipefail

show_help() {
  cat <<EOF
Usage: $(basename "$0") [options] <DIR> [OUTPUT_FILE]

Dumps a directory tree and all text file contents into a single output file.

Options:
  -e, --exclude PATTERN    Additional exclude pattern (repeatable)
  -h, --help               Show this help message and exit
EOF
}

# Default exclude patterns
EXCLUDES=(
  "__pycache__" ".git" ".venv" "venv" "ENV" "env"
  "*.pyc" "*.o" "*.so" "*.dll" "*.exe"
  "*.jpg" "*.jpeg" "*.png" "*.gif"
  "*.pdf" "*.zip" "*.tar" "*.gz" "*.7z" "*.db"
)

# Parse options
while [[ $# -gt 0 ]]; do
  case "$1" in
    -e|--exclude)
      EXCLUDES+=("$2")
      shift 2
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    -* )
      echo "Unknown option: $1" >&2
      show_help >&2
      exit 1
      ;;
    *) break ;;  # end of options
  esac
done

# Positional arguments
DIR="${1:-.}"
OUTPUT_PARAM="${2:-}"

# Prepare default output directory
dump_root="$HOME/dumps"
mkdir -p "$dump_root"

# Resolve DIR full path and compute base name
full_dir="$(realpath "$DIR")"
dir_base="$(basename "$full_dir")"

# Determine output path
if [[ -n "$OUTPUT_PARAM" ]]; then
  OUTPUT="$OUTPUT_PARAM"
else
  OUTPUT="$dump_root/${dir_base}_dump.txt"
fi

# Prevent writing output inside DIR
full_out="$(realpath -m "$OUTPUT")"
if [[ "$full_out" == "$full_dir"* ]]; then
  echo "Error: output file must not be inside the directory being dumped." >&2
  exit 1
fi

# Initialize output
: > "$OUTPUT"

echo "Directory tree of $DIR" >> "$OUTPUT"
echo "----------------------------------------" >> "$OUTPUT"

if command -v tree >/dev/null; then
  IGNORE_PATTERN=$(IFS="|"; echo "${EXCLUDES[*]}")
  tree -a -I "$IGNORE_PATTERN" "$DIR" >> "$OUTPUT"
else
  # build find ignore arguments
  ignore_args=()
  for pat in "${EXCLUDES[@]}"; do
    ignore_args+=( ! -path "*/$pat/*" )
  done
  find "$DIR" -type f "${ignore_args[@]}" | sed "s|^$DIR|.|" >> "$OUTPUT"
fi

echo -e "\n" >> "$OUTPUT"

# Dump text files
ignore_args=()
for pat in "${EXCLUDES[@]}"; do
  ignore_args+=( ! -path "*/$pat/*" )
done

find "$DIR" -type f "${ignore_args[@]}" | while IFS= read -r file; do
  if [[ "$(file -b --mime-encoding "$file")" != "binary" ]]; then
    rel="${file#$DIR/}"
    {
      printf "========== START OF FILE: %s ==========
" "$rel"
      sed 's/\r$//' "$file"
      printf "\n========== END OF FILE: %s ==========
\n" "$rel"
    } >> "$OUTPUT"
  fi
done

echo "Done! Directory dumped to $OUTPUT"
