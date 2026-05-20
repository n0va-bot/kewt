test_url_encode_spaces() {
    . "$project_dir/lib/runtime.sh"
    result=$(encode_url_path "hello world")
    assert_eq "hello%20world" "$result" "encode spaces"
}

test_url_encode_hash() {
    . "$project_dir/lib/runtime.sh"
    result=$(encode_url_path "file#section")
    assert_eq "file%23section" "$result" "encode hash"
}

test_url_encode_question() {
    . "$project_dir/lib/runtime.sh"
    result=$(encode_url_path "search?q=test")
    assert_eq "search%3Fq=test" "$result" "encode question mark"
}

test_url_encode_percent() {
    . "$project_dir/lib/runtime.sh"
    result=$(encode_url_path "100%")
    assert_eq "100%25" "$result" "encode percent"
}

test_markdown_file_url() {
    . "$project_dir/lib/runtime.sh"
    result=$(markdown_file_url "docs/readme.md")
    assert_eq "/docs/readme.html" "$result" "markdown file url"
}

test_directory_index_url_root() {
    . "$project_dir/lib/runtime.sh"
    result=$(directory_index_url "")
    assert_eq "/index.html" "$result" "root index url"
}

test_directory_index_url_subdir() {
    . "$project_dir/lib/runtime.sh"
    result=$(directory_index_url "docs")
    assert_eq "/docs/index.html" "$result" "subdir index url"
}

test_directory_index_url_dot() {
    . "$project_dir/lib/runtime.sh"
    result=$(directory_index_url ".")
    assert_eq "/index.html" "$result" "dot index url"
}

test_format_rfc2822_utc() {
    . "$project_dir/lib/runtime.sh"
    result=$(format_rfc2822_utc "2026-05-20" "14:30")
    assert_eq "Wed, 20 May 2026 14:30:00 +0000" "$result" "rfc2822 format"
}

test_format_rfc2822_utc_default_time() {
    . "$project_dir/lib/runtime.sh"
    result=$(format_rfc2822_utc "2026-01-01")
    assert_eq "Thu, 01 Jan 2026 00:00:00 +0000" "$result" "rfc2822 default time"
}

test_trim_whitespace() {
    . "$project_dir/lib/runtime.sh"
    result=$(trim_whitespace "  hello  ")
    assert_eq "hello" "$result" "trim whitespace"
}

test_trim_whitespace_tabs() {
    . "$project_dir/lib/runtime.sh"
    result=$(trim_whitespace "	world	")
    assert_eq "world" "$result" "trim tabs"
}
