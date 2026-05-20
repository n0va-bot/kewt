test_needs_rebuild_no_output() {
    . "$project_dir/lib/config.sh"
    . "$project_dir/lib/runtime.sh"
    . "$project_dir/lib/builder.sh"

    tmpdir="${TMPDIR:-/tmp}/kewt_test.$$"
    mkdir -p "$tmpdir"
    echo "test" > "$tmpdir/src.md"

    needs_rebuild "$tmpdir/src.md" "$tmpdir/out.html"
    result=$?
    assert_eq "0" "$result" "rebuild when output missing"

    rm -rf "$tmpdir"
}

test_needs_rebuild_output_newer() {
    . "$project_dir/lib/config.sh"
    . "$project_dir/lib/runtime.sh"
    . "$project_dir/lib/builder.sh"

    tmpdir="${TMPDIR:-/tmp}/kewt_test.$$"
    mkdir -p "$tmpdir"
    echo "test" > "$tmpdir/src.md"
    sleep 1
    echo "test" > "$tmpdir/out.html"

    needs_rebuild "$tmpdir/src.md" "$tmpdir/out.html"
    result=$?
    assert_eq "1" "$result" "no rebuild when output newer"

    rm -rf "$tmpdir"
}

test_needs_rebuild_source_newer() {
    . "$project_dir/lib/config.sh"
    . "$project_dir/lib/runtime.sh"
    . "$project_dir/lib/builder.sh"

    tmpdir="${TMPDIR:-/tmp}/kewt_test.$$"
    mkdir -p "$tmpdir"
    echo "old" > "$tmpdir/out.html"
    sleep 1
    echo "new" > "$tmpdir/src.md"

    needs_rebuild "$tmpdir/src.md" "$tmpdir/out.html"
    result=$?
    assert_eq "0" "$result" "rebuild when source newer"

    rm -rf "$tmpdir"
}

test_escape_html_text() {
    . "$project_dir/lib/generator.sh"

    result=$(escape_html_text "<script>&test>")
    assert_eq "&lt;script&gt;&amp;test&gt;" "$result" "escape html text"
}

test_escape_html_attr() {
    . "$project_dir/lib/generator.sh"

    result=$(escape_html_attr 'value with "quotes" & <tags>')
    assert_eq "value with &quot;quotes&quot; &amp; &lt;tags&gt;" "$result" "escape html attr"
}

test_nav_links_empty() {
    . "$project_dir/lib/config.sh"
    . "$project_dir/lib/generator.sh"

    nav_links=""
    result=$(nav_links_html)
    assert_eq "" "$result" "empty nav links"
}

test_nav_links_markdown() {
    . "$project_dir/lib/config.sh"
    . "$project_dir/lib/generator.sh"

    nav_links="[Docs](/docs), [About](/about)"
    result=$(nav_links_html)
    assert_contains '<li><a href="/docs">Docs</a></li>' "$result" "nav links markdown docs"
    assert_contains '<li><a href="/about">About</a></li>' "$result" "nav links markdown about"
}

test_nav_links_plain() {
    . "$project_dir/lib/config.sh"
    . "$project_dir/lib/generator.sh"

    nav_links="https://example.com"
    result=$(nav_links_html)
    assert_contains '<li><a href="https://example.com">' "$result" "nav links plain url"
}

test_find_closest() {
    . "$project_dir/lib/config.sh"
    . "$project_dir/lib/generator.sh"

    tmpdir="${TMPDIR:-/tmp}/kewt_test.$$"
    mkdir -p "$tmpdir/sub/deep"
    echo "root" > "$tmpdir/template.html"
    echo "sub" > "$tmpdir/sub/template.html"

    src="$tmpdir"
    result=$(find_closest "template.html" "$tmpdir/sub/deep")
    assert_eq "$tmpdir/sub/template.html" "$result" "find closest in parent"

    result=$(find_closest "template.html" "$tmpdir")
    assert_eq "$tmpdir/template.html" "$result" "find closest in current"

    rm -rf "$tmpdir"
}

test_find_closest_fallback_to_src() {
    . "$project_dir/lib/config.sh"
    . "$project_dir/lib/generator.sh"

    tmpdir="${TMPDIR:-/tmp}/kewt_test.$$"
    mkdir -p "$tmpdir/sub"
    echo "root" > "$tmpdir/template.html"

    src="$tmpdir"
    result=$(find_closest "template.html" "$tmpdir/sub")
    assert_eq "$tmpdir/template.html" "$result" "find closest falls back to src"

    rm -rf "$tmpdir"
}

test_custom_404_md() {
    . "$project_dir/lib/config.sh"
    . "$project_dir/lib/runtime.sh"
    . "$project_dir/lib/metadata.sh"
    . "$project_dir/lib/manifest.sh"
    . "$project_dir/lib/generator.sh"
    . "$project_dir/lib/builder.sh"

    tmpdir="${TMPDIR:-/tmp}/kewt_test.$$"
    mkdir -p "$tmpdir"

    cat > "$tmpdir/site.conf" <<EOF
title = "Test"
error_page = "not_found.html"
EOF

    printf '# Custom 404\n\nPage not found, sorry.\n' > "$tmpdir/not_found.md"

    src="$tmpdir"
    out="$tmpdir/out"
    KEWT_TMPDIR="$tmpdir/tmp"
    mkdir -p "$out" "$KEWT_TMPDIR"

    awk_dir="$project_dir/awk"
    script_dir="$project_dir"
    style="kewt"
    template="$KEWT_TMPDIR/default_template.html"
    printf '%s\n' "$DEFAULT_TMPL" > "$template"
    nav=""
    footer=""
    header_brand=""
    head_extra=""
    asset_version=""
    lang="en"
    current_url=""
    fm_title=""
    fm_content_warning=""
    fm_description=""
    generate_page_title="true"
    logo_as_favicon="false"
    favicon=""
    display_logo="false"
    display_title="true"
    logo=""
    search_in_header="false"
    search_in_footer="false"
    cw_hide_url="true"
    enable_header_links="false"
    custom_admonitions=""

    build_error_page

    assert_file_exists "$out/not_found.html" "custom 404 html generated"
    assert_contains "Custom 404" "$(cat "$out/not_found.html")" "custom 404 has custom content"

    rm -rf "$tmpdir"
}
