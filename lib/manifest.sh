#!/bin/sh
# shellcheck disable=SC2016,SC2030,SC2031

shell_quote() {
    printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"
}

manifest_meta_path() {
    printf '%s/manifest/meta/%s.meta\n' "$KEWT_TMPDIR" "$1"
}

manifest_dir_meta_path() {
    printf '%s/manifest/dir-meta/%s.meta\n' "$KEWT_TMPDIR" "$1"
}

manifest_dir_hidden_by_draft_index() {
    _manifest_hidden_dir="${1:-.}"
    [ -f "$manifest_hidden_dirs_list" ] || return 1

    while :; do
        awk -v dir="$_manifest_hidden_dir" '$0 == dir { found = 1 } END { exit(found ? 0 : 1) }' "$manifest_hidden_dirs_list" >/dev/null 2>&1 && return 0
        [ "$_manifest_hidden_dir" = "." ] && return 1
        _manifest_hidden_parent=$(dirname "$_manifest_hidden_dir")
        [ "$_manifest_hidden_parent" = "$_manifest_hidden_dir" ] && return 1
        _manifest_hidden_dir="$_manifest_hidden_parent"
    done
}

write_manifest_dir_meta() {
    _dir_meta_rel="$1"
    _dir_meta_count="$2"
    _dir_meta_first="$3"
    _dir_meta_has_index="$4"
    _dir_meta_path=$(manifest_dir_meta_path "$_dir_meta_rel")
    mkdir -p "$(dirname "$_dir_meta_path")"
    {
        printf 'dir_manifest_rel=%s\n' "$(shell_quote "$_dir_meta_rel")"
        printf 'dir_md_count=%s\n' "$(shell_quote "$_dir_meta_count")"
        printf 'dir_first_md=%s\n' "$(shell_quote "$_dir_meta_first")"
        printf 'dir_has_index=%s\n' "$(shell_quote "$_dir_meta_has_index")"
    } > "$_dir_meta_path"
}

load_manifest_dir_entry() {
    _dir_manifest_rel="$1"
    _dir_manifest_meta_path=$(manifest_dir_meta_path "$_dir_manifest_rel")
    [ -f "$_dir_manifest_meta_path" ] || return 1
    # shellcheck disable=SC1090
    . "$_dir_manifest_meta_path"
}

load_manifest_entry() {
    _manifest_rel_path="$1"
    _manifest_meta_path=$(manifest_meta_path "$_manifest_rel_path")
    [ -f "$_manifest_meta_path" ] || return 1
    # shellcheck disable=SC1090
    . "$_manifest_meta_path"
}

extract_search_content() {
    _search_file="$1"
    awk '{
        if (NR == 1 && $0 == "---") { in_fm = 1; next }
        if (in_fm && $0 == "---") { in_fm = 0; next }
        if (in_fm) next
        if ($0 ~ /^```/) { in_code = !in_code; next }
        if (in_code) next
        print
    }' "$_search_file" | sed \
        -e 's/^#\{1,6\} //' \
        -e 's/\*\*\([^*]*\)\*\*/\1/g' \
        -e 's/\*\([^*]*\)\*/\1/g' \
        -e 's/__\([^_]*\)__/\1/g' \
        -e 's/_\([^_]*\)_/\1/g' \
        -e 's/`\([^`]*\)`/\1/g' \
        -e 's/\[\([^]]*\)](\([^)]*\))/\1/g' \
        -e 's/!\[\([^]]*\)](\([^)]*\))//g' \
        -e 's/^[[:space:]]*[-*+] //' \
        -e 's/^[[:space:]]*[0-9]\{1,\}\. //' \
        -e 's/^>[[:space:]]*//' \
        -e 's/<[^>]*>//g' \
        -e '/^[[:space:]]*$/d' \
        -e 's/|//g' \
        -e 's/^[[:space:]]*---[[:space:]]*$//' |
        tr '\n' ' ' |
        sed -e 's/  */ /g' -e 's/\\/\\\\/g' -e 's/"/\\"/g' |
        awk '{ print substr($0, 1, 500) }'
}

build_markdown_manifest() {
    manifest_root="$KEWT_TMPDIR/manifest"
    manifest_meta_root="$manifest_root/meta"
    manifest_dir_meta_root="$manifest_root/dir-meta"
    manifest_all_list="$manifest_root/all.lst"
    manifest_visible_list="$manifest_root/visible.lst"
    manifest_hidden_dirs_list="$manifest_root/hidden-dirs.lst"

    rm -rf "$manifest_root"
    mkdir -p "$manifest_meta_root"
    mkdir -p "$manifest_dir_meta_root"
    : > "$manifest_all_list"
    : > "$manifest_visible_list"
    : > "$manifest_hidden_dirs_list"

    eval "find \"$src\" \( $IGNORE_ARGS \) -prune -o -name \"*.md\" -print" | sort | while IFS= read -r manifest_file; do
        manifest_rel_path="${manifest_file#"$src"/}"
        manifest_dir_rel=$(dirname "$manifest_rel_path")
        manifest_filename=$(basename "$manifest_rel_path")
        manifest_is_index="false"
        [ "$manifest_filename" = "index.md" ] && manifest_is_index="true"

        parse_frontmatter "$manifest_file"
        if [ "$manifest_filename" = "index.md" ] && [ "$fm_draft" = "true" ]; then
            printf '%s\n' "$manifest_dir_rel" >> "$manifest_hidden_dirs_list"
        fi
        markdown_title_from_loaded_file "$manifest_file" "$title - Page"
        manifest_title="$markdown_title"
        set_post_datetime "$fm_date" "$(basename "$manifest_file" .md)"

        manifest_post_date="$post_date"
        manifest_post_time="$post_time"
        manifest_post_slug=$(basename "$manifest_file" .md | sed \
            -e 's/^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}-[0-9]\{2\}[:\-][0-9]\{2\}//' \
            -e 's/^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}//' \
            -e 's/^[_\-]//')

        if [ "$manifest_is_index" = "true" ]; then
            if [ "$manifest_rel_path" = "index.md" ]; then
                manifest_url="/index.html"
            else
                manifest_url=$(directory_index_url "${manifest_rel_path%/index.md}")
            fi
        else
            manifest_url=$(markdown_file_url "$manifest_rel_path")
        fi

        manifest_search_content=""
        if [ "$generate_search" = "true" ]; then
            manifest_search_content=$(extract_search_content "$manifest_file")
        fi

        manifest_meta_file=$(manifest_meta_path "$manifest_rel_path")
        mkdir -p "$(dirname "$manifest_meta_file")"
        {
            printf 'manifest_rel_path=%s\n' "$(shell_quote "$manifest_rel_path")"
            printf 'manifest_dir_rel=%s\n' "$(shell_quote "$manifest_dir_rel")"
            printf 'manifest_filename=%s\n' "$(shell_quote "$manifest_filename")"
            printf 'manifest_is_index=%s\n' "$(shell_quote "$manifest_is_index")"
            printf 'manifest_title=%s\n' "$(shell_quote "$manifest_title")"
            printf 'manifest_date=%s\n' "$(shell_quote "$fm_date")"
            printf 'manifest_draft=%s\n' "$(shell_quote "$fm_draft")"
            printf 'manifest_description=%s\n' "$(shell_quote "$fm_description")"
            printf 'manifest_content_warning=%s\n' "$(shell_quote "$fm_content_warning")"
            printf 'manifest_tags=%s\n' "$(shell_quote "$fm_tags")"
            printf 'manifest_url=%s\n' "$(shell_quote "$manifest_url")"
            printf 'manifest_search_content=%s\n' "$(shell_quote "$manifest_search_content")"
            printf 'manifest_post_date=%s\n' "$(shell_quote "$manifest_post_date")"
            printf 'manifest_post_time=%s\n' "$(shell_quote "$manifest_post_time")"
            printf 'manifest_post_slug=%s\n' "$(shell_quote "$manifest_post_slug")"
        } > "$manifest_meta_file"

        if load_manifest_dir_entry "$manifest_dir_rel"; then
            :
        else
            dir_md_count=0
            dir_first_md=""
            dir_has_index="false"
        fi

        dir_md_count=$((dir_md_count + 1))
        if [ -z "$dir_first_md" ]; then
            dir_first_md="$manifest_rel_path"
        fi
        if [ "$manifest_filename" = "index.md" ]; then
            dir_has_index="true"
        fi
        write_manifest_dir_meta "$manifest_dir_rel" "$dir_md_count" "$dir_first_md" "$dir_has_index"

        printf '%s\n' "$manifest_rel_path" >> "$manifest_all_list"
    done

    if [ -s "$manifest_hidden_dirs_list" ]; then
        LC_ALL=C sort -u "$manifest_hidden_dirs_list" > "$manifest_hidden_dirs_list.sorted"
        mv "$manifest_hidden_dirs_list.sorted" "$manifest_hidden_dirs_list"
    fi

    eval "find \"$src\" \( $IGNORE_ARGS -o $HIDE_ARGS -o $PRESERVE_ARGS \) -prune -o -name \"*.md\" -print" | sort | while IFS= read -r visible_file; do
        visible_rel_path="${visible_file#"$src"/}"
        load_manifest_entry "$visible_rel_path" || continue
        if [ "${draft_mode:-false}" != "true" ]; then
            [ "$manifest_draft" = "true" ] && continue
            manifest_dir_hidden_by_draft_index "$manifest_dir_rel" && continue
        fi
        printf '%s\n' "$visible_rel_path" >> "$manifest_visible_list"
    done
}
