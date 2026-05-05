#!/bin/sh

trim_whitespace() {
    printf '%s' "$1" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
}

encode_url_path() {
    printf '%s' "$1" | sed \
        -e 's/%/%25/g' \
        -e 's/ /%20/g' \
        -e 's/#/%23/g' \
        -e 's/?/%3F/g' \
        -e 's/"/%22/g' \
        -e "s/'/%27/g"
}

markdown_file_url() {
    _rel_path="$1"
    printf '/%s.html\n' "$(encode_url_path "${_rel_path%.md}")"
}

directory_index_url() {
    _rel_dir="$1"
    if [ -z "$_rel_dir" ] || [ "$_rel_dir" = "." ]; then
        printf '/index.html\n'
    else
        printf '/%s/index.html\n' "$(encode_url_path "$_rel_dir")"
    fi
}

format_rfc2822_utc() {
    _rfc_date="$1"
    _rfc_time="${2:-00:00}"
    [ -n "$_rfc_time" ] || _rfc_time="00:00"
    awk -v d="$_rfc_date" -v t="$_rfc_time" '
        function weekday(y, m, day,    k, j, h) {
            if (m < 3) {
                m += 12
                y--
            }
            k = y % 100
            j = int(y / 100)
            h = (day + int((13 * (m + 1)) / 5) + k + int(k / 4) + int(j / 4) + 5 * j) % 7
            return (h + 6) % 7
        }
        BEGIN {
            split(d, da, "-")
            split(t, ti, ":")
            year = da[1] + 0
            month = da[2] + 0
            day = da[3] + 0
            hour = (ti[1] == "" ? 0 : ti[1]) + 0
            minute = (ti[2] == "" ? 0 : ti[2]) + 0

            months[1] = "Jan"; months[2] = "Feb"; months[3] = "Mar"; months[4] = "Apr"
            months[5] = "May"; months[6] = "Jun"; months[7] = "Jul"; months[8] = "Aug"
            months[9] = "Sep"; months[10] = "Oct"; months[11] = "Nov"; months[12] = "Dec"

            days[0] = "Sun"; days[1] = "Mon"; days[2] = "Tue"; days[3] = "Wed"
            days[4] = "Thu"; days[5] = "Fri"; days[6] = "Sat"

            printf "%s, %02d %s %04d %02d:%02d:00 +0000\n",
                days[weekday(year, month, day)], day, months[month], year, hour, minute
        }
    '
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
        marker_dir="${marker_path%/"$marker"}"
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
        asset_version="?v=$(date '+%Y%m%d%H%M%S')"
    fi

    resolve_template_path
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
