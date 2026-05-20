test_draft_mode_includes_drafts_in_manifest() {
    . "$project_dir/lib/config.sh"
    . "$project_dir/lib/runtime.sh"
    . "$project_dir/lib/metadata.sh"
    . "$project_dir/lib/manifest.sh"

    tmpdir="${TMPDIR:-/tmp}/kewt_test.$$"
    mkdir -p "$tmpdir"

    cat > "$tmpdir/site.conf" <<EOF
title = "Test"
dir_indexes = true
EOF

    printf '# Normal Page\n' > "$tmpdir/normal.md"
    printf -- '---\ndraft = true\n---\n# Draft Page\n' > "$tmpdir/draft.md"

    src="$tmpdir"
    out="$tmpdir/out"
    KEWT_TMPDIR="$tmpdir/tmp"
    mkdir -p "$KEWT_TMPDIR"

    awk_dir="$project_dir/awk"
    script_dir="$project_dir"

    reset_config
    load_config "$tmpdir/site.conf"
    IGNORE_ARGS="-name '.kewtignore' -o -path '$src/.*'"
    HIDE_ARGS="-name '.kewtignore' -o -name '.kewthide' -o -name '.kewtpreserve' -o -path '$src/.*'"
    PRESERVE_ARGS="-false"

    draft_mode="false"
    build_markdown_manifest
    visible_count=$(wc -l < "$manifest_visible_list")
    assert_eq "1" "$visible_count" "without draft mode only normal page visible"

    draft_mode="true"
    build_markdown_manifest
    visible_count=$(wc -l < "$manifest_visible_list")
    assert_eq "2" "$visible_count" "with draft mode both pages visible"

    rm -rf "$tmpdir"
}
