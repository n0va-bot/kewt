test_markdown_heading() {
    tmpdir="${TMPDIR:-/tmp}/kewt_test.$$"
    mkdir -p "$tmpdir"
    printf '# Hello World\n\nSome content.\n' > "$tmpdir/test.md"

    result=$(ENABLE_HEADER_LINKS="false" CUSTOM_ADMONITIONS="" MARKDOWN_SITE_ROOT="$tmpdir" MARKDOWN_FALLBACK_FILE="" sh "$project_dir/markdown.sh" "$tmpdir/test.md")
    assert_contains "<h1" "$result" "markdown heading tag"
    assert_contains "Hello World" "$result" "markdown heading text"

    rm -rf "$tmpdir"
}

test_markdown_paragraph() {
    tmpdir="${TMPDIR:-/tmp}/kewt_test.$$"
    mkdir -p "$tmpdir"
    printf 'This is a paragraph.\n' > "$tmpdir/test.md"

    result=$(ENABLE_HEADER_LINKS="false" CUSTOM_ADMONITIONS="" MARKDOWN_SITE_ROOT="$tmpdir" MARKDOWN_FALLBACK_FILE="" sh "$project_dir/markdown.sh" "$tmpdir/test.md")
    assert_contains "<p>" "$result" "markdown paragraph open"
    assert_contains "This is a paragraph." "$result" "markdown paragraph text"

    rm -rf "$tmpdir"
}

test_markdown_bold() {
    tmpdir="${TMPDIR:-/tmp}/kewt_test.$$"
    mkdir -p "$tmpdir"
    printf 'This is **bold** text.\n' > "$tmpdir/test.md"

    result=$(ENABLE_HEADER_LINKS="false" CUSTOM_ADMONITIONS="" MARKDOWN_SITE_ROOT="$tmpdir" MARKDOWN_FALLBACK_FILE="" sh "$project_dir/markdown.sh" "$tmpdir/test.md")
    assert_contains "<strong>bold</strong>" "$result" "markdown bold"

    rm -rf "$tmpdir"
}

test_markdown_italic() {
    tmpdir="${TMPDIR:-/tmp}/kewt_test.$$"
    mkdir -p "$tmpdir"
    printf 'This is *italic* text.\n' > "$tmpdir/test.md"

    result=$(ENABLE_HEADER_LINKS="false" CUSTOM_ADMONITIONS="" MARKDOWN_SITE_ROOT="$tmpdir" MARKDOWN_FALLBACK_FILE="" sh "$project_dir/markdown.sh" "$tmpdir/test.md")
    assert_contains "<em>italic</em>" "$result" "markdown italic"

    rm -rf "$tmpdir"
}

test_markdown_link() {
    tmpdir="${TMPDIR:-/tmp}/kewt_test.$$"
    mkdir -p "$tmpdir"
    printf '[click here](https://example.com)\n' > "$tmpdir/test.md"

    result=$(ENABLE_HEADER_LINKS="false" CUSTOM_ADMONITIONS="" MARKDOWN_SITE_ROOT="$tmpdir" MARKDOWN_FALLBACK_FILE="" sh "$project_dir/markdown.sh" "$tmpdir/test.md")
    assert_contains 'href="https://example.com"' "$result" "markdown link href"
    assert_contains "click here" "$result" "markdown link text"

    rm -rf "$tmpdir"
}

test_markdown_code_block() {
    tmpdir="${TMPDIR:-/tmp}/kewt_test.$$"
    mkdir -p "$tmpdir"
    cat > "$tmpdir/test.md" <<EOF
\`\`\`
code here
\`\`\`
EOF

    result=$(ENABLE_HEADER_LINKS="false" CUSTOM_ADMONITIONS="" MARKDOWN_SITE_ROOT="$tmpdir" MARKDOWN_FALLBACK_FILE="" sh "$project_dir/markdown.sh" "$tmpdir/test.md")
    assert_contains "<pre>" "$result" "markdown code block pre"
    assert_contains "<code>" "$result" "markdown code block code"

    rm -rf "$tmpdir"
}

test_markdown_unordered_list() {
    tmpdir="${TMPDIR:-/tmp}/kewt_test.$$"
    mkdir -p "$tmpdir"
    printf -- '- item one\n- item two\n' > "$tmpdir/test.md"

    result=$(ENABLE_HEADER_LINKS="false" CUSTOM_ADMONITIONS="" MARKDOWN_SITE_ROOT="$tmpdir" MARKDOWN_FALLBACK_FILE="" sh "$project_dir/markdown.sh" "$tmpdir/test.md")
    assert_contains "<ul>" "$result" "markdown list ul"
    assert_contains "<li>item one</li>" "$result" "markdown list item one"
    assert_contains "<li>item two</li>" "$result" "markdown list item two"

    rm -rf "$tmpdir"
}

test_markdown_blockquote() {
    tmpdir="${TMPDIR:-/tmp}/kewt_test.$$"
    mkdir -p "$tmpdir"
    printf '> This is a quote\n' > "$tmpdir/test.md"

    result=$(ENABLE_HEADER_LINKS="false" CUSTOM_ADMONITIONS="" MARKDOWN_SITE_ROOT="$tmpdir" MARKDOWN_FALLBACK_FILE="" sh "$project_dir/markdown.sh" "$tmpdir/test.md")
    assert_contains "<blockquote>" "$result" "markdown blockquote"

    rm -rf "$tmpdir"
}

test_markdown_frontmatter_stripped() {
    tmpdir="${TMPDIR:-/tmp}/kewt_test.$$"
    mkdir -p "$tmpdir"
    cat > "$tmpdir/test.md" <<EOF
---
title = "Test"
---

# Heading
EOF

    result=$(ENABLE_HEADER_LINKS="false" CUSTOM_ADMONITIONS="" MARKDOWN_SITE_ROOT="$tmpdir" MARKDOWN_FALLBACK_FILE="" sh "$project_dir/markdown.sh" "$tmpdir/test.md")
    assert_contains "<h1" "$result" "markdown frontmatter heading present"
    assert_contains "Heading" "$result" "markdown frontmatter heading text"
    result_not_contains=$(echo "$result" | grep -c 'title = "Test"')
    assert_eq "0" "$result_not_contains" "markdown frontmatter not in output"

    rm -rf "$tmpdir"
}

test_markdown_header_links() {
    tmpdir="${TMPDIR:-/tmp}/kewt_test.$$"
    mkdir -p "$tmpdir"
    printf '# My Heading\n' > "$tmpdir/test.md"

    result=$(ENABLE_HEADER_LINKS="true" CUSTOM_ADMONITIONS="" MARKDOWN_SITE_ROOT="$tmpdir" MARKDOWN_FALLBACK_FILE="" sh "$project_dir/markdown.sh" "$tmpdir/test.md")
    assert_contains 'id="my-heading"' "$result" "markdown header link id"
    assert_contains 'href="#my-heading"' "$result" "markdown header link href"

    rm -rf "$tmpdir"
}

test_markdown_pipe_table() {
    tmpdir="${TMPDIR:-/tmp}/kewt_test.$$"
    mkdir -p "$tmpdir"
    cat > "$tmpdir/test.md" <<EOF
| A | B |
|---|---|
| 1 | 2 |
EOF

    result=$(ENABLE_HEADER_LINKS="false" CUSTOM_ADMONITIONS="" MARKDOWN_SITE_ROOT="$tmpdir" MARKDOWN_FALLBACK_FILE="" sh "$project_dir/markdown.sh" "$tmpdir/test.md")
    assert_contains "<table>" "$result" "markdown table"
    assert_contains "<th>A</th>" "$result" "markdown table header"
    assert_contains "<td>1</td>" "$result" "markdown table cell"

    rm -rf "$tmpdir"
}
