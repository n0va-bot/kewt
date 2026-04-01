SEARCH_FORM_FOOTER='<form class="kewt-search-footer" action="/search.html" method="get"><input type="text" name="q" placeholder="Search..." required><button type="submit">Go</button></form>'
SEARCH_FORM_HEADER='<form class="kewt-search-header" action="/search.html" method="get"><input type="text" name="q" placeholder="Search..." required><button type="submit">Go</button></form>'
SEARCH_FORM_NAV='<div class="kewt-search-nav"><form action="/search.html" method="get"><input type="text" name="q" placeholder="Search..." required><button type="submit">Go</button></form></div>'

generate_nav() {
    dinfo=$(eval "find \"$1\" \( $IGNORE_ARGS -o $HIDE_ARGS -o $PRESERVE_ARGS \) -prune -o -print" | sort | AWK_SRC="$1" awk -f "$awk_dir/collect_dir_info.awk")
    find_cmd="find \"$1\" \( $IGNORE_ARGS -o $HIDE_ARGS -o $PRESERVE_ARGS \) -prune -o -name \"*.md\" -print"
    if [ -n "$posts_dir" ] && [ -d "$1/$posts_dir" ]; then
        find_cmd="$find_cmd && echo \"$1/$posts_dir/index.md\""
    fi
    eval "$find_cmd" | sort -u | AWK_SRC="$1" AWK_SINGLE_FILE_INDEX="$single_file_index" AWK_FLATTEN="$flatten" AWK_ORDER="$order" AWK_HOME_NAME="$home_name" AWK_SHOW_HOME_IN_NAV="$show_home_in_nav" AWK_DINFO="$dinfo" awk -f "$awk_dir/generate_sidebar.awk"
}
escape_html_text() {
    printf '%s' "$1" | sed \
        -e 's/&/\&amp;/g' \
        -e 's/</\&lt;/g' \
        -e 's/>/\&gt;/g'
}
escape_html_attr() {
    printf '%s' "$1" | sed \
        -e 's/&/\&amp;/g' \
        -e 's/"/\&quot;/g' \
        -e 's/</\&lt;/g' \
        -e 's/>/\&gt;/g'
}
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
nav_links_html() {
    [ -n "$nav_links" ] || return

    old_ifs=$IFS
    set -f
    IFS=','
    # shellcheck disable=SC2086
    set -- $nav_links
    IFS=$old_ifs
    set +f

    [ $# -gt 0 ] || return

    printf '<ul class="nav-extra-links">\n'
    for raw_link in "$@"; do
        link=$(printf '%s' "$raw_link" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
        [ -n "$link" ] || continue

        case "$link" in
            \[*\]\(*\))
                label=${link#\[}
                label=${label%%\]*}
                link_url=${link#*](}
                link_url=${link_url%)}
                ;;
            *)
                link_url=$link
                label=$(printf '%s' "$link" | sed \
                    -e 's|^[A-Za-z][A-Za-z0-9+.-]*://||' \
                    -e 's|/$||')
                [ -n "$label" ] || label="$link"
                ;;
        esac

        [ -n "$link_url" ] || continue
        [ -n "$label" ] || label="$link_url"

        link_attr=$(escape_html_attr "$link_url")
        label_text=$(escape_html_text "$label")
        printf '<li><a href="%s">%s</a></li>\n' "$link_attr" "$label_text"
    done
    printf '</ul>'
}
find_closest() {
    target="$1"
    start_dir="$2"
    curr="$start_dir"
    while [ "$curr" != "$src" ] && [ "$curr" != "." ] && [ "$curr" != "/" ]; do
        if [ -f "$curr/$target" ]; then
            echo "$curr/$target"
            return
        fi
        curr=$(dirname "$curr")
    done
    if [ -f "$src/$target" ]; then
        echo "$src/$target"
    fi
}
copy_style_with_resolved_vars() {
    src_style="$1"
    out_style="$2"
    awk -f "$awk_dir/replace_variables.awk" "$src_style" > "$out_style"
}
render_markdown() {
    file="$1"
    is_home="$2"
    url_override="$3"

    if [ -n "$url_override" ]; then
        current_url="$url_override"
    else
        rel_path="${file#"$src"}"
        rel_path="${rel_path#/}"
        current_url="/${rel_path%.md}.html"
    fi

    content_file="$file"
    if [ -n "$posts_dir" ] && [ "$file" != "$src/$posts_dir/index.md" ]; then
        rel_dir_of_url=$(dirname "$current_url")
        rel_dir_of_url="${rel_dir_of_url#/}"
        if { [ "$rel_dir_of_url" = "$posts_dir" ] || [ "./$rel_dir_of_url" = "$posts_dir" ]; } && [ "$(basename "$current_url")" != "index.html" ]; then
             temp_post_with_backlink="$KEWT_TMPDIR/post_with_backlink_$$.md"
             printf "[< Back](index.html)\n\n" > "$temp_post_with_backlink"
             awk -f "$awk_dir/frontmatter.awk" "$file" >> "$temp_post_with_backlink"
             
             post_md_name="$(basename "$current_url" .html).md"
             prevnext_file="$KEWT_TMPDIR/prevnext/$post_md_name"
             if [ -f "$prevnext_file" ]; then
                 IFS='|' read -r prev_str next_str < "$prevnext_file"
                 
                 printf "\n\n---\n<div class=\"post-nav\">\n" >> "$temp_post_with_backlink"
                 if [ -n "$prev_str" ]; then
                     printf "<span class=\"prev-post\">%s</span>\n" "$prev_str" >> "$temp_post_with_backlink"
                 fi
                 if [ -n "$next_str" ]; then
                     printf "<span class=\"next-post\">%s</span>\n" "$next_str" >> "$temp_post_with_backlink"
                 fi
                 printf "</div>\n" >> "$temp_post_with_backlink"
             fi
             content_file="$temp_post_with_backlink"
        fi
    fi

    local_template=$(find_closest "template.html" "$(dirname "$file")")
    [ -z "$local_template" ] && local_template="$template"

    closest_style_src=$(find_closest "styles.css" "$(dirname "$file")")
    [ -z "$closest_style_src" ] && closest_style_src=$(find_closest "style.css" "$(dirname "$file")")
    if [ -n "$closest_style_src" ]; then
        style_rel_to_src="${closest_style_src#"$src"/}"
        case "$closest_style_src" in
            "$src/styles.css") style_rel_to_src="styles.css" ;;
            "$src/style.css") style_rel_to_src="style.css" ;;
        esac
        style_path="/${style_rel_to_src%styles.css}"
        style_path="${style_path%style.css}styles.css"
    else
        style_path="/styles.css"
    fi

    logo_html=""
    if [ "$display_logo" = "true" ] && [ -n "$logo" ]; then
        logo_html="<img class=\"site-logo\" src=\"$logo\" alt=\"$title\" />"
    fi

    brand_text=""
    if [ "$display_title" = "true" ]; then
        brand_text="$title"
    fi

    if [ -n "$logo_html" ] && [ -n "$brand_text" ]; then
        header_brand="<a href=\"/index.html\">$logo_html $brand_text</a>"
    elif [ -n "$logo_html" ]; then
        header_brand="<a href=\"/index.html\">$logo_html</a>"
    elif [ -n "$brand_text" ]; then
        header_brand="<a href=\"/index.html\">$brand_text</a>"
    else
        header_brand="<a href=\"/index.html\">$title</a>"
    fi

    favicon_src=""
    if [ "$logo_as_favicon" = "true" ] && [ -n "$logo" ]; then
        favicon_src="$logo"
    elif [ -n "$favicon" ]; then
        favicon_src="$favicon"
    fi
    head_extra=""
    if [ -n "$favicon_src" ]; then
        if echo "$favicon_src" | grep -q "^http"; then
            head_extra="<link rel=\"icon\" href=\"$favicon_src\" />"
        elif echo "$favicon_src" | grep -q "^/"; then
            head_extra="<link rel=\"icon\" href=\"$favicon_src\" />"
        else
            head_extra="<link rel=\"icon\" href=\"/$favicon_src\" />"
        fi
    fi

    parse_frontmatter "$file"

    page_title="$title"
    if [ -n "$fm_title" ]; then
        page_title="$fm_title - $title"
    elif [ "$generate_page_title" = "true" ] && [ -n "$file" ] && [ -f "$file" ]; then
        if [ "$is_home" = "true" ] && [ -n "$home_name" ]; then
            page_title="$home_name - $title"
        else
            first_heading=$(grep -m 1 '^# ' "$file" | sed 's/^# *//; s/ *$//')
            if [ -n "$first_heading" ]; then
                first_heading=$(echo "$first_heading" | sed -e 's/\[//g' -e 's/\]//g' -e 's/!//g' -e 's/\*//g' -e 's/_//g' -e 's/`//g' -e 's/([^)]*)//g' | sed 's/\\//g')
                page_title="$first_heading - $title"
            else
                basename_no_ext=$(basename "$file" .md)
                if [ "$basename_no_ext" != "index" ] && [ "$basename_no_ext" != "404_gen" ]; then
                    cap_basename=$(echo "$basename_no_ext" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')
                    page_title="$cap_basename - $title"
                fi
            fi
        fi
    fi

    head_extra_og="<meta property=\"og:title\" content=\"$(escape_html_attr "$page_title")\" />"
    if [ -n "$fm_description" ]; then
        head_extra_og="$head_extra_og
        <meta property=\"og:description\" content=\"$(escape_html_attr "$fm_description")\" />"
    fi
    og_url="${base_url%/}${current_url}"
    head_extra_og="$head_extra_og
        <meta property=\"og:url\" content=\"$(escape_html_attr "$og_url")\" />"

    if [ -n "$head_extra" ]; then
        head_extra="$head_extra
        $head_extra_og"
    else
        head_extra="$head_extra_og"
    fi
    
    if [ "$is_cw_content_page" = "true" ] && [ "$cw_hide_url" = "true" ]; then
        head_extra="$head_extra
        <script>window.history.replaceState(null, '', '$current_url');</script>"
    fi

    final_footer="$footer"
    if [ "$search_in_footer" = "true" ]; then
        final_footer="$footer $SEARCH_FORM_FOOTER"
    fi

    final_nav="$nav"
    final_header_brand="$header_brand"
    if [ "$search_in_header" = "true" ]; then
        final_header_brand="$header_brand $SEARCH_FORM_HEADER"
        final_nav="$SEARCH_FORM_NAV
$nav"
    fi

    ENABLE_HEADER_LINKS="$enable_header_links" CUSTOM_ADMONITIONS="$custom_admonitions" MARKDOWN_SITE_ROOT="$src" MARKDOWN_FALLBACK_FILE="$script_dir/styles/$style.css" sh "$script_dir/markdown.sh" "$content_file" | AWK_LANG="$lang" AWK_CURRENT_URL="$current_url" AWK_TITLE="$page_title" AWK_NAV="$final_nav" AWK_FOOTER="$final_footer" AWK_STYLE_PATH="${style_path}" AWK_HEADER_BRAND="$final_header_brand" AWK_HEAD_EXTRA="$head_extra" AWK_VERSION="$asset_version" AWK_CONTENT_WARNING="$fm_content_warning" awk -f "$awk_dir/render_template.awk" "$local_template"
}
generate_content_warning_page() {
    _fm_title="$1"
    _fm_content_warning="$2"
    _content_rel_url="$3"
    _target_url="$4"
    _out_file="$5"
    _is_home="$6"
    
    _temp_cw="$KEWT_TMPDIR/cw_$$.md"
    _cw_text="${_fm_content_warning}"
    [ "$_cw_text" = "true" ] && _cw_text="This content may be sensitive."
    
    cat <<EOF > "$_temp_cw"
---
title = "$_fm_title"
---

> [!CAUTION]
> **Content Warning:** $_cw_text

<a href="$(basename "$_content_rel_url")" class="cw-button">Reveal Content</a>
EOF
    render_markdown "$_temp_cw" "$_is_home" "$_target_url" > "$_out_file"
    rm -f "$_temp_cw"
}
