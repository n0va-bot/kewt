#!/bin/sh

script_dir=$(CDPATH="" cd -- "$(dirname -- "$0")" && pwd)
awk_dir="$script_dir/awk"

sed_inplace() {
    script="$1"
    file="$2"
    tmp="${file}.tmp.$$"
    if sed "$script" "$file" > "$tmp" && mv "$tmp" "$file"; then
        return 0
    else
        rm -f "$tmp"
        return 1
    fi
}

temp_file="/tmp/markdown.$$.md"
cat "$@" > "$temp_file"

trap 'rm -f "$temp_file" "$temp_file.tmp"' EXIT INT TERM

# Mask
awk -f "$awk_dir/mask_inline_code.awk" "$temp_file" > "$temp_file.tmp" && mv "$temp_file.tmp" "$temp_file"
awk -f "$awk_dir/mask_plain.awk" "$temp_file" > "$temp_file.tmp" && mv "$temp_file.tmp" "$temp_file"

# Reference links
refs=$(cat "$@" | awk '/^\[[^\]]+\]:  */')
IFS='
'
for ref in $refs; do
    ref_id=$(echo "$ref" | sed 's/^\[\(.*\)\]: .*/\1/')
    ref_url=$(echo "$ref" | sed 's/^\[.*\]: \([^ ]*\).*/\1/')
    ref_title=$(echo "$ref" | sed -n 's/^\[.*\]: [^ ]* "\(.*\)"/\1/p' | sed 's@|@!@g')
    sed_inplace "s|!\[\([^]]*\)\]\[$ref_id\]|<img src=\"$ref_url\" title=\"$ref_title\" alt=\"\1\" />|g" "$temp_file"
    sed_inplace "s|\[\([^]]*\)\]\[$ref_id\]|<a href=\"$ref_url\" title=\"$ref_title\">\1</a>|g" "$temp_file"
    sed_inplace "s|!\[$ref_id\]\[\]|<img src=\"$ref_url\" title=\"$ref_title\" alt=\"$ref_id\" />|g" "$temp_file"
    sed_inplace "s|\[$ref_id\]\[\]|<a href=\"$ref_url\" title=\"$ref_title\">$ref_id</a>|g" "$temp_file"
done
sed_inplace "/^\[[^\]]*\]:  */d" "$temp_file"

# Blocks
sed_inplace "s/^>!\[/> [!/g" "$temp_file"
sed_inplace "s/^>\[!/> [!/g" "$temp_file"

while grep '^>' "$temp_file" >/dev/null; do
    awk -f "$awk_dir/blockquote.awk" "$temp_file" > "$temp_file.tmp" && mv "$temp_file.tmp" "$temp_file"
done

awk -f "$awk_dir/blockquote_to_admonition.awk" "$temp_file" > "$temp_file.tmp" && mv "$temp_file.tmp" "$temp_file"
awk -f "$awk_dir/fenced_code.awk" "$temp_file" > "$temp_file.tmp" && mv "$temp_file.tmp" "$temp_file"
awk -f "$awk_dir/indented_code.awk" "$temp_file" > "$temp_file.tmp" && mv "$temp_file.tmp" "$temp_file"
awk -f "$awk_dir/pipe_tables.awk" "$temp_file" > "$temp_file.tmp" && mv "$temp_file.tmp" "$temp_file"
awk -f "$awk_dir/headers.awk" "$temp_file" > "$temp_file.tmp" && mv "$temp_file.tmp" "$temp_file"
awk -f "$awk_dir/lists.awk" "$temp_file" > "$temp_file.tmp" && mv "$temp_file.tmp" "$temp_file"

# Spacing
awk -f "$awk_dir/breaks.awk" "$temp_file" > "$temp_file.tmp" && mv "$temp_file.tmp" "$temp_file"
awk -f "$awk_dir/paragraphs.awk" "$temp_file" > "$temp_file.tmp" && mv "$temp_file.tmp" "$temp_file"

# Inline styles
awk -f "$awk_dir/markdown_inline.awk" "$temp_file" > "$temp_file.tmp" && mv "$temp_file.tmp" "$temp_file"
awk -v input_file="$1" -v site_root="$MARKDOWN_SITE_ROOT" -v fallback_file="$MARKDOWN_FALLBACK_FILE" -f "$awk_dir/markdown_embed.awk" "$temp_file"
rm "$temp_file"
