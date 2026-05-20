test_strip_markdown_bold() {
    . "$project_dir/lib/metadata.sh"
    result=$(strip_markdown_text "**bold text**")
    assert_eq "bold text" "$result" "strip bold"
}

test_strip_markdown_italic() {
    . "$project_dir/lib/metadata.sh"
    result=$(strip_markdown_text "*italic text*")
    assert_eq "italic text" "$result" "strip italic"
}

test_strip_markdown_link() {
    . "$project_dir/lib/metadata.sh"
    result=$(strip_markdown_text "[link](http://example.com)")
    assert_eq "link" "$result" "strip link"
}

test_strip_markdown_code() {
    . "$project_dir/lib/metadata.sh"
    result=$(strip_markdown_text "\`code\`")
    assert_eq "code" "$result" "strip code"
}

test_first_heading() {
    tmpdir="${TMPDIR:-/tmp}/kewt_test.$$"
    mkdir -p "$tmpdir"
    printf '# Hello World\n\nSome content\n' > "$tmpdir/test.md"

    . "$project_dir/lib/metadata.sh"
    result=$(first_heading_from_markdown "$tmpdir/test.md")
    assert_eq "Hello World" "$result" "first heading"

    rm -rf "$tmpdir"
}

test_first_heading_no_heading() {
    tmpdir="${TMPDIR:-/tmp}/kewt_test.$$"
    mkdir -p "$tmpdir"
    printf 'Random content\n' > "$tmpdir/test.md"

    . "$project_dir/lib/metadata.sh"
    result=$(first_heading_from_markdown "$tmpdir/test.md")
    assert_eq "" "$result" "no heading returns empty"

    rm -rf "$tmpdir"
}

test_parse_frontmatter() {
    tmpdir="${TMPDIR:-/tmp}/kewt_test.$$"
    mkdir -p "$tmpdir"
    cat > "$tmpdir/test.md" <<'EOF'
---
title = "My Post"
date = "2026-05-20 10:00"
draft = false
description = "A test post"
tags = "test, example"
---

# Content
EOF

    export KEWT_TMPDIR="$tmpdir"
    export awk_dir="$project_dir/awk"
    . "$project_dir/lib/metadata.sh"
    . "$project_dir/lib/config.sh"

    parse_frontmatter "$tmpdir/test.md"

    assert_eq "My Post" "$fm_title" "parse title"
    assert_eq "2026-05-20 10:00" "$fm_date" "parse date"
    assert_eq "false" "$fm_draft" "parse draft"
    assert_eq "A test post" "$fm_description" "parse description"
    assert_eq "test, example" "$fm_tags" "parse tags"

    rm -rf "$tmpdir"
}

test_set_post_datetime_from_date() {
    . "$project_dir/lib/metadata.sh"
    set_post_datetime "2026-05-20 14:30" "fallback"
    assert_eq "2026-05-20" "$post_date" "post date from date field"
    assert_eq "14:30" "$post_time" "post time from date field"
}

test_set_post_datetime_from_filename() {
    . "$project_dir/lib/metadata.sh"
    set_post_datetime "" "2026-05-20-14-30-slug"
    assert_eq "2026-05-20" "$post_date" "post date from filename"
    assert_eq "14:30" "$post_time" "post time from filename"
}
