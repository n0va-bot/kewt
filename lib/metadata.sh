parse_frontmatter() {
    _fm_file="$1"
    _fm_out="$KEWT_TMPDIR/fm_vals.txt"
    : > "$_fm_out"
    awk -v fm_out="$_fm_out" -f "$awk_dir/frontmatter.awk" "$_fm_file" > /dev/null
    fm_title=""
    fm_date=""
    fm_draft=""
    fm_description=""
    fm_content_warning=""
    fm_tags=""
    while IFS='=' read -r _fk _fv; do
        case "$_fk" in
            title) fm_title="$_fv" ;;
            date) fm_date="$_fv" ;;
            draft) fm_draft="$_fv" ;;
            description) fm_description="$_fv" ;;
            content_warning) fm_content_warning="$_fv" ;;
            tags) fm_tags="$_fv" ;;
        esac
    done < "$_fm_out"
    rm -f "$_fm_out"
}

strip_markdown_text() {
    printf '%s' "$1" | sed \
        -e 's/\[//g' \
        -e 's/\]//g' \
        -e 's/!//g' \
        -e 's/\*//g' \
        -e 's/_//g' \
        -e 's/`//g' \
        -e 's/([^)]*)//g' \
        -e 's/\\//g'
}

first_heading_from_markdown() {
    grep -m 1 '^# ' "$1" | sed 's/^# *//; s/ *$//'
}

markdown_title_from_file() {
    _title_file="$1"
    _title_default="$2"

    parse_frontmatter "$_title_file"
    markdown_title="$fm_title"

    if [ -z "$markdown_title" ]; then
        markdown_title=$(first_heading_from_markdown "$_title_file")
        if [ -n "$markdown_title" ]; then
            markdown_title=$(strip_markdown_text "$markdown_title")
        fi
    fi

    if [ -z "$markdown_title" ]; then
        basename_no_ext=$(basename "$_title_file" .md)
        if [ "$basename_no_ext" != "index" ] && [ "$basename_no_ext" != "404_gen" ]; then
            markdown_title=$(echo "$basename_no_ext" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')
        else
            markdown_title="$_title_default"
        fi
    fi
}

set_post_datetime() {
    _raw_date="$1"
    _fallback_name="$2"

    if [ -n "$_raw_date" ]; then
        post_date=$(echo "$_raw_date" | sed 's/^\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\).*/\1/')
        post_time=""
        if echo "$_raw_date" | grep -q '^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}[ T_-]\?[0-9]\{2\}[:\-][0-9]\{2\}'; then
            post_time=$(echo "$_raw_date" | sed 's/^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}[ T_-]\?\([0-9]\{2\}[:\-][0-9]\{2\}\).*/\1/' | tr '-' ':')
        fi
        return
    fi

    post_date=$(echo "$_fallback_name" | sed 's/^\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\).*/\1/')
    post_time="00:00"
    if echo "$_fallback_name" | grep -q '^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}-[0-9]\{2\}[:\-][0-9]\{2\}'; then
        post_time=$(echo "$_fallback_name" | sed 's/^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}-\([0-9]\{2\}[:\-][0-9]\{2\}\).*/\1/' | tr '-' ':')
    fi
}

set_post_metadata() {
    _post_file="$1"
    _default_title="$2"
    _basename_no_ext=$(basename "$_post_file" .md)

    markdown_title_from_file "$_post_file" "$_default_title"
    post_heading="$markdown_title"
    set_post_datetime "$fm_date" "$_basename_no_ext"

    post_slug=$(echo "$_basename_no_ext" | sed \
        -e 's/^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}-[0-9]\{2\}[:\-][0-9]\{2\}//' \
        -e 's/^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}//' \
        -e 's/^[_\-]//')
}
