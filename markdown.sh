#!/bin/sh

script_dir=$(CDPATH="" cd -- "$(dirname -- "$0")" && pwd)
awk_dir="$script_dir/awk"

run_awk() {
    _ra_awk_file="$1"
    shift
    if ! awk -f "$_ra_awk_file" "$@"; then
        echo "Error: AWK failed: $_ra_awk_file" >&2
        return 1
    fi
}

temp_parent="${KEWT_TMPDIR:-${TMPDIR:-/tmp}}"
temp_file="${temp_parent}/markdown.$$.md"
cat "$@" > "$temp_file"

trap 'rm -f "$temp_file" "$temp_file.tmp" "$temp_file.fm"' EXIT INT TERM

fm_file="$temp_file.fm"
: > "$fm_file"

run_awk "$awk_dir/frontmatter.awk" -v fm_out="$fm_file" "$temp_file" > "$temp_file.tmp" && mv "$temp_file.tmp" "$temp_file"

run_awk "$awk_dir/mask_inline_code.awk" "$temp_file" \
    | run_awk "$awk_dir/mask_plain.awk" \
    | run_awk "$awk_dir/reference_links.awk" \
    > "$temp_file.tmp" && mv "$temp_file.tmp" "$temp_file"

loop_count=0
max_iterations=100
while grep -q '^>' "$temp_file"; do
    run_awk "$awk_dir/blockquote.awk" "$temp_file" > "$temp_file.tmp" && mv "$temp_file.tmp" "$temp_file"
    loop_count=$((loop_count + 1))
    if [ "$loop_count" -gt "$max_iterations" ]; then
        echo "Warning: Blockquote processing exceeded $max_iterations iterations on $1. Breaking to prevent infinite loop." >&2
        break
    fi
done

run_awk "$awk_dir/blockquote_to_admonition.awk" -v custom_admonitions="$CUSTOM_ADMONITIONS" "$temp_file" \
    | run_awk "$awk_dir/fenced_code.awk" \
    | run_awk "$awk_dir/indented_code.awk" \
    | run_awk "$awk_dir/pipe_tables.awk" \
    | run_awk "$awk_dir/definition_lists.awk" \
    | run_awk "$awk_dir/lists.awk" \
    | run_awk "$awk_dir/toc.awk" \
    | run_awk "$awk_dir/footnotes.awk" \
    | run_awk "$awk_dir/breaks.awk" \
    | run_awk "$awk_dir/paragraphs.awk" \
    | run_awk "$awk_dir/emoji.awk" -v emoji_file="$awk_dir/emoji.tsv" \
    | run_awk "$awk_dir/markdown_inline.awk" \
    | run_awk "$awk_dir/headers.awk" -v enable_header_links="$ENABLE_HEADER_LINKS" \
    | run_awk "$awk_dir/markdown_embed.awk" -v input_file="$1" -v site_root="$MARKDOWN_SITE_ROOT" -v fallback_file="$MARKDOWN_FALLBACK_FILE" -v script_dir="$script_dir"

rm -f "$temp_file"
