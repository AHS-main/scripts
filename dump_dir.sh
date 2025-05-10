#!/usr/bin/env bash
set -euo pipefail

# Usage: dump_dir.sh <directory> [output_file]
DIR=${1:?Usage: $0 directory [output_file]}
OUTPUT=${2:-dump.txt}

# Strip any trailing slash
DIR=${DIR%/}

# Overwrite/create the output file
: > "$OUTPUT"

# 1) Print a header and the tree of files (ignoring common binary/cache dirs)
echo "Directory tree of $DIR" >> "$OUTPUT"
echo "----------------------------------------" >> "$OUTPUT"
if command -v tree >/dev/null; then
    tree -a -I "__pycache__|.git|.venv|venv|ENV|env|*.pyc|*.o|*.so|*.dll|*.exe|*.jpg|*.jpeg|*.png|*.gif|*.pdf|*.zip|*.tar|*.gz|*.7z|*.db" "$DIR" >> "$OUTPUT"
else
    # Fallback if `tree` is not installed
    find "$DIR" \
         \( -path "*/.git" -o -path "*/__pycache__" -o -path "*/.venv" -o -path "*/venv" -o -path "*/ENV" -o -path "*/env" \) -prune -false -o -print \
        | sed "s|^$DIR|.|" \
              >> "$OUTPUT"
fi

echo -e "\n" >> "$OUTPUT"

# 2) Walk all files (excluding cache dirs + pyc), detect text vs binary, and dump
find "$DIR" -type f \
     ! -path "*/.git/*" \
     ! -path "*/__pycache__/*" \
     ! -path "*/.venv/*" \
     ! -path "*/venv/*" \
     ! -name "*.pyc" \
    | while IFS= read -r file; do
    # Check if file is binary or not
    encoding=$(file -b --mime-encoding "$file")
    if [[ "$encoding" != "binary" ]]; then
        # Compute a relative path for readability
        rel=${file#$DIR/}
        # Delimit start
        printf "========== START OF FILE: %s ==========\n" "$rel" >> "$OUTPUT"
        # Strip any Windows CRs and append content
        sed 's/\r$//' "$file" >> "$OUTPUT"
        # Delimit end
        printf "\n========== END OF FILE: %s ==========\n\n" "$rel" >> "$OUTPUT"
    fi
done

echo "Done! Directory dumped to $OUTPUT"
