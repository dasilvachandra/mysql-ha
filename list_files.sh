#!/bin/bash

# Folder atau file yang akan diabaikan (boleh wildcard)
IGNORED_DIRS=(".git" "node_modules" "*.log" "*.tmp")

# File output gabungan
OUTPUT_FILE="all.txt"
> "$OUTPUT_FILE" # kosongkan file output

print_tree_and_collect() {
    local dir="$1"
    local prefix="$2"
    local items=("$dir"/*)
    local count=${#items[@]}
    local index=0

    for item in "${items[@]}"; do
        local basename=$(basename "$item")

        # Lewati jika cocok dengan pola di IGNORED_DIRS (mendukung wildcard)
        for ignored in "${IGNORED_DIRS[@]}"; do
            if [[ "$basename" == $ignored ]]; then
                continue 2
            fi
        done

        index=$((index + 1))
        local connector="├──"
        [[ $index -eq $count ]] && connector="└──"

        if [[ -d "$item" ]]; then
            echo "${prefix}${connector} 📁 $basename/"
            print_tree_and_collect "$item" "${prefix}│   "
        elif [[ -f "$item" ]]; then
            echo "${prefix}${connector} 📄 $basename"

            # Tambahkan isi file ke all.txt
            {
                echo ""
                echo "====================== $item ======================"
                cat "$item"
                echo ""
            } >> "$OUTPUT_FILE"
        fi
    done
}

echo "📁 $(basename "$(pwd)")/"
print_tree_and_collect "." "│   "

echo ""
echo "✅ Semua isi file tersimpan ke: $OUTPUT_FILE"
