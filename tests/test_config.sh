test_config_defaults() {
    . "$project_dir/lib/config.sh"

    assert_eq "kewt" "$title" "default title"
    assert_eq "kewt" "$style" "default style"
    assert_eq "en" "$lang" "default lang"
    assert_eq "false" "$draft_by_default" "default draft_by_default"
    assert_eq "true" "$dir_indexes" "default dir_indexes"
    assert_eq "true" "$single_file_index" "default single_file_index"
    assert_eq "false" "$flatten" "default flatten"
    assert_eq "Home" "$home_name" "default home_name"
    assert_eq "true" "$show_home_in_nav" "default show_home_in_nav"
    assert_eq "false" "$generate_feed" "default generate_feed"
    assert_eq "rss.xml" "$feed_file" "default feed_file"
    assert_eq "12" "$posts_per_page" "default posts_per_page"
    assert_eq "false" "$generate_tags" "default generate_tags"
    assert_eq "tags" "$tags_dir" "default tags_dir"
    assert_eq "false" "$generate_search" "default generate_search"
    assert_eq "true" "$enable_header_links" "default enable_header_links"
    assert_eq "true" "$cw_hide_url" "default cw_hide_url"
}

test_config_reset() {
    . "$project_dir/lib/config.sh"
    title="custom"
    style="nord"
    generate_feed="true"
    reset_config

    assert_eq "kewt" "$title" "reset title"
    assert_eq "kewt" "$style" "reset style"
    assert_eq "false" "$generate_feed" "reset generate_feed"
}

test_config_load() {
    . "$project_dir/lib/config.sh"

    tmpdir="${TMPDIR:-/tmp}/kewt_test.$$"
    mkdir -p "$tmpdir"
    cat > "$tmpdir/test.conf" <<EOF
title = "My Site"
style = "nord"
generate_feed = true
base_url = "https://example.com"
posts_per_page = 5
EOF

    reset_config
    load_config "$tmpdir/test.conf"

    assert_eq "My Site" "$title" "load title"
    assert_eq "nord" "$style" "load style"
    assert_eq "true" "$generate_feed" "load generate_feed"
    assert_eq "https://example.com" "$base_url" "load base_url"
    assert_eq "5" "$posts_per_page" "load posts_per_page"

    rm -rf "$tmpdir"
}

test_config_load_quoted() {
    . "$project_dir/lib/config.sh"

    tmpdir="${TMPDIR:-/tmp}/kewt_test.$$"
    mkdir -p "$tmpdir"
    cat > "$tmpdir/test.conf" <<'EOF'
footer = "made with <a href=\"https://kewt.krzak.org\">kewt</a>"
nav_links = "[Docs](/docs), [About](/about)"
EOF

    reset_config
    load_config "$tmpdir/test.conf"

    assert_eq 'made with <a href="https://kewt.krzak.org">kewt</a>' "$footer" "load quoted footer"
    assert_eq "[Docs](/docs), [About](/about)" "$nav_links" "load quoted nav_links"

    rm -rf "$tmpdir"
}

test_config_load_skips_comments() {
    . "$project_dir/lib/config.sh"

    tmpdir="${TMPDIR:-/tmp}/kewt_test.$$"
    mkdir -p "$tmpdir"
    cat > "$tmpdir/test.conf" <<EOF
# This is a comment
title = "Test Site"
# Another comment
style = "kewt"
EOF

    reset_config
    load_config "$tmpdir/test.conf"

    assert_eq "Test Site" "$title" "load with comments title"
    assert_eq "kewt" "$style" "load with comments style"

    rm -rf "$tmpdir"
}

test_config_load_missing_file() {
    . "$project_dir/lib/config.sh"
    reset_config
    load_config "/nonexistent/path/site.conf"

    assert_eq "kewt" "$title" "missing file keeps defaults"
}

test_config_feed_full_content_default() {
    . "$project_dir/lib/config.sh"

    assert_eq "false" "$feed_full_content" "default feed_full_content"
}

test_config_feed_full_content_load() {
    . "$project_dir/lib/config.sh"

    tmpdir="${TMPDIR:-/tmp}/kewt_test.$$"
    mkdir -p "$tmpdir"
    cat > "$tmpdir/test.conf" <<EOF
feed_full_content = true
EOF

    reset_config
    load_config "$tmpdir/test.conf"

    assert_eq "true" "$feed_full_content" "load feed_full_content"

    rm -rf "$tmpdir"
}
