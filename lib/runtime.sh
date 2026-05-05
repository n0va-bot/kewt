trim_whitespace() {
    printf '%s' "$1" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
}

append_find_rule() {
    _expr="$1"
    _rule="$2"

    if [ -n "$_expr" ]; then
        printf '%s -o %s\n' "$_expr" "$_rule"
    else
        printf '%s\n' "$_rule"
    fi
}

append_pattern_rules_from_file() {
    _expr="$1"
    _root="$2"
    _file="$3"

    while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in
            ''|'#'*) continue ;;
        esac

        pattern=$(trim_whitespace "$line")
        [ -z "$pattern" ] && continue

        pattern_clean="${pattern#/}"
        pattern_clean="${pattern_clean%/}"

        if echo "$pattern" | grep -q "/"; then
            _expr=$(append_find_rule "$_expr" "-path '$_root/$pattern_clean'")
            _expr=$(append_find_rule "$_expr" "-path '$_root/$pattern_clean/*'")
        else
            _expr=$(append_find_rule "$_expr" "-name '$pattern_clean'")
        fi
    done < "$_file"

    printf '%s\n' "$_expr"
}

append_nested_marker_rules() {
    _expr="$1"
    _root="$2"
    _marker="$3"
    _tmp_file="$KEWT_TMPDIR/${_marker#*.}_paths"

    find "$_root" -name "$_marker" > "$_tmp_file"
    while IFS= read -r marker_path; do
        marker_dir="${marker_path%/$marker}"
        if [ "$marker_dir" != "$_root" ] && [ "$marker_dir" != "." ]; then
            _expr=$(append_find_rule "$_expr" "-path '$marker_dir'")
            _expr=$(append_find_rule "$_expr" "-path '$marker_dir/*'")
        fi
    done < "$_tmp_file"
    rm -f "$_tmp_file"

    printf '%s\n' "$_expr"
}

build_rule_args() {
    _root="$1"
    _marker="$2"
    _base_expr="$3"

    _expr="$_base_expr"
    if [ -f "$_root/$_marker" ]; then
        _expr=$(append_pattern_rules_from_file "$_expr" "$_root" "$_root/$_marker")
    fi
    _expr=$(append_nested_marker_rules "$_expr" "$_root" "$_marker")
    printf '%s\n' "$_expr"
}

resolve_template_path() {
    template="$src/template.html"
    [ -f "$template" ] || template="./template.html"
    if [ ! -f "$template" ]; then
        template="$KEWT_TMPDIR/default_template.html"
        printf '%s\n' "$DEFAULT_TMPL" > "$template"
    fi
}

build_full_nav() {
    nav=$(generate_nav "$src")
    extra_links=$(nav_links_html)
    if [ -n "$extra_links" ]; then
        nav="$nav
$extra_links"
    fi
    if [ -n "$nav_extra" ]; then
        nav="$nav
$nav_extra"
    fi
}

refresh_build_context() {
    reset_config
    load_config "./site.conf"
    load_config "$src/site.conf"

    HIDE_ARGS="$BASE_HIDE_ARGS"
    if [ -n "$posts_dir" ]; then
        HIDE_ARGS=$(append_find_rule "$HIDE_ARGS" "-path '$src/$posts_dir/*'")
    fi

    asset_version=""
    if [ "$versioning" = "true" ]; then
        asset_version="?v=$(date +%s)"
    fi

    resolve_template_path
    build_full_nav
}

watch_for_changes() {
    _mark_file="$1"

    changed="$(find "$src" -type f -newer "$_mark_file" 2>/dev/null | head -n 1)"
    [ -z "$changed" ] && [ -f "site.conf" ] && [ "site.conf" -nt "$_mark_file" ] && changed="site.conf"
    [ -z "$changed" ] && [ -f "$src/site.conf" ] && [ "$src/site.conf" -nt "$_mark_file" ] && changed="$src/site.conf"
    [ -z "$changed" ] && [ -f "$template" ] && [ "$template" -nt "$_mark_file" ] && changed="$template"
    [ -z "$changed" ] && [ -d "$script_dir/styles" ] && changed="$(find "$script_dir/styles" -type f -newer "$_mark_file" 2>/dev/null | head -n 1)"

    printf '%s\n' "$changed"
}

is_posts_directory_rel() {
    _rel_dir="$1"
    [ -n "$posts_dir" ] && { [ "$_rel_dir" = "$posts_dir" ] || [ "./$_rel_dir" = "$posts_dir" ]; }
}
