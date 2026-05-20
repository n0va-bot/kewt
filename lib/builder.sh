#!/bin/sh
# shellcheck disable=SC2129

needs_rebuild() {
    src_file="$1"
    out_file="$2"
    [ ! -f "$out_file" ] && return 0
    [ "$src_file" -nt "$out_file" ] && return 0
    [ -f "./site.conf" ] && [ "./site.conf" -nt "$out_file" ] && return 0
    [ -f "$src/site.conf" ] && [ "$src/site.conf" -nt "$out_file" ] && return 0
    [ -f "$template" ] && [ "$template" -nt "$out_file" ] && return 0
    [ -f "$script_dir/styles/$style.css" ] && [ "$script_dir/styles/$style.css" -nt "$out_file" ] && return 0
    [ -f "$script_dir/styles/$style.root.css" ] && [ "$script_dir/styles/$style.root.css" -nt "$out_file" ] && return 0
    [ -f "$src/styles.root.css" ] && [ "$src/styles.root.css" -nt "$out_file" ] && return 0
    return 1
}

write_content_warning_outputs() {
    _source_file="$1"
    _content_out_file="$2"
    _content_rel_url="$3"
    _target_url="$4"
    _landing_out_file="$5"
    _is_home="$6"

    is_cw_content_page="true"
    render_markdown "$_source_file" "$_is_home" "$_target_url" > "$_content_out_file"
    is_cw_content_page="false"

    generate_content_warning_page "$fm_title" "$fm_content_warning" "$_content_rel_url" "$_target_url" "$_landing_out_file" "false"
}

build_dir_entries_list() {
    _bde_dir="$1"
    _bde_rel_dir="$2"
    _bde_entries_file="$3"

    find "$_bde_dir" ! -name "$(basename "$_bde_dir")" -prune ! -name ".*" -print | while read -r entry; do
        name="${entry##*/}"
        case "$name" in
            template.html|site.conf|style.css|styles.root.css|index.md) continue ;;
        esac
        if [ -d "$entry" ]; then
            entry_rel_dir="${entry#"$src"/}"
            manifest_dir_hidden_by_draft_index "$entry_rel_dir" && continue
            dir_url="$(encode_url_path "$name")/index.html"
            echo "${name}|- [${name}/](${dir_url})" >> "$_bde_entries_file"
        elif [ "${entry%.md}" != "$entry" ]; then
            entry_rel_path="${entry#"$src"/}"
            load_manifest_entry "$entry_rel_path" || continue
            label="${name%.md}"
            [ "$manifest_draft" = "true" ] && continue

            post_h="$manifest_title"

            is_post_entry="false"
            if is_posts_directory_rel "$_bde_rel_dir"; then
                is_post_entry="true"
            fi

            if [ -n "$post_h" ]; then
                if [ "$is_post_entry" = "true" ]; then
                    if [ -n "$manifest_post_time" ]; then
                        label="$post_h - $manifest_post_date $manifest_post_time"
                    else
                        label="$post_h - $manifest_post_date"
                    fi
                else
                    label="$post_h"
                fi
            elif [ "$is_post_entry" = "true" ]; then
                if [ -n "$manifest_post_time" ]; then
                    label="$manifest_post_date $manifest_post_time"
                else
                    label="$manifest_post_date"
                fi
            fi
            if [ "$is_post_entry" = "true" ]; then
                sort_key="${manifest_post_date} ${manifest_post_time}"
            else
                sort_key="$name"
            fi
            entry_url=$(encode_url_path "${name%.md}.html")
            echo "${sort_key}|- [$label](${entry_url})|$name|${entry_url}" >> "$_bde_entries_file"
        else
            asset_url=$(encode_url_path "$name")
            echo "${name}|- [$name]($asset_url)|$name|$asset_url" >> "$_bde_entries_file"
        fi
    done
}

build_dir_index() {
    _bdi_dir="$1"
    _bdi_rel_dir="$2"
    _bdi_out_dir="$3"

    has_custom_index="false"
    has_list="false"
    if [ -f "$_bdi_dir/index.md" ]; then
        has_custom_index="true"
        if grep -q '^[[:space:]]*{{LIST}}[[:space:]]*$' "$_bdi_dir/index.md" 2>/dev/null; then
            has_list="true"
        fi
    fi

    if [ "$has_custom_index" = "false" ] || [ "$has_list" = "true" ]; then
        is_posts_dir="false"
        if is_posts_directory_rel "$_bdi_rel_dir"; then
            is_posts_dir="true"
        fi
        if [ "$single_file_index" = "true" ] && [ "$is_posts_dir" = "false" ] && [ "$has_list" = "false" ]; then
            if load_manifest_dir_entry "$_bdi_rel_dir" && [ "$dir_md_count" -eq 1 ]; then
                md_file="$src/$dir_first_md"
                is_home="false"; [ "$_bdi_dir" = "$src" ] && is_home="true"
                target_url=$(directory_index_url "$_bdi_rel_dir")
                if needs_rebuild "$md_file" "$_bdi_out_dir/index.html"; then
                    parse_frontmatter "$md_file"
                    if [ -n "$fm_content_warning" ]; then
                        content_out_file="$_bdi_out_dir/content.html"
                        if [ "$_bdi_rel_dir" = "." ]; then
                            content_rel_url="/content.html"
                        else
                            content_rel_url="/$(encode_url_path "$_bdi_rel_dir")/content.html"
                        fi
                        write_content_warning_outputs "$md_file" "$content_out_file" "$content_rel_url" "$target_url" "$_bdi_out_dir/index.html" "$is_home"
                    else
                        render_markdown "$md_file" "$is_home" "$target_url" > "$_bdi_out_dir/index.html"
                    fi
                fi
                return 0
            fi
        fi

        temp_index="$KEWT_TMPDIR/index.md"
        temp_list="$KEWT_TMPDIR/list.md"
        : > "$temp_list"

        if [ "$has_custom_index" = "false" ]; then
            display_dir="${_bdi_rel_dir#.}"
            [ -z "$display_dir" ] && display_dir="/"
            echo "# Index of $display_dir" > "$temp_index"
            echo "" >> "$temp_index"
        fi

        sort_args=""
        if is_posts_directory_rel "$_bdi_rel_dir"; then
            sort_args="-r"
        fi

        temp_entries="$KEWT_TMPDIR/entries_$$.txt"
        : > "$temp_entries"

        build_dir_entries_list "$_bdi_dir" "$_bdi_rel_dir" "$temp_entries"

        if [ "$is_posts_dir" = "true" ]; then
            LC_ALL=C sort $sort_args "$temp_entries" > "$KEWT_TMPDIR/sorted_entries_$$.txt"
            cut -d'|' -f2 "$KEWT_TMPDIR/sorted_entries_$$.txt" >> "$temp_list"
            mkdir -p "$KEWT_TMPDIR/prevnext"
            awk -F'|' '
            {
               name[NR] = $3
               url[NR] = $4
            }
            END {
               for(i=1; i<=NR; i++) {
                  prev_str = ""
                  next_str = ""
                  if(i > 1) {
                     next_str = "[Next >](" url[i-1] ")"
                  }
                  if(i < NR) {
                     prev_str = "[< Previous](" url[i+1] ")"
                  }
                  if (prev_str != "" || next_str != "") {
                      out = "'"$KEWT_TMPDIR"'/prevnext/" name[i]
                      printf "%s|%s\n", prev_str, next_str > out
                  }
               }
            }
            ' "$KEWT_TMPDIR/sorted_entries_$$.txt"
            rm -f "$KEWT_TMPDIR/sorted_entries_$$.txt"
        else
            LC_ALL=C sort $sort_args "$temp_entries" | cut -d'|' -f2 >> "$temp_list"
        fi
        rm -f "$temp_entries"

        is_home="false"; [ "$_bdi_dir" = "$src" ] && is_home="true"
        target_url=$(directory_index_url "$_bdi_rel_dir")

        render_paginated_index "$_bdi_dir" "$_bdi_rel_dir" "$_bdi_out_dir" "$temp_index" "$temp_list" "$target_url" "$is_home" "$has_custom_index" "$is_posts_dir"
        rm -f "$temp_index" "$temp_list"
    fi
}

render_paginated_index() {
    _rpi_dir="$1"
    _rpi_rel_dir="$2"
    _rpi_out_dir="$3"
    _rpi_temp_index="$4"
    _rpi_temp_list="$5"
    _rpi_target_url="$6"
    _rpi_is_home="$7"
    _rpi_has_custom_index="$8"
    _rpi_is_posts_dir="$9"

    num_items=$(wc -l < "$_rpi_temp_list")
    if [ "$_rpi_is_posts_dir" = "true" ] && [ -n "$posts_per_page" ] && [ "$posts_per_page" -gt 0 ] && [ "$num_items" -gt "$posts_per_page" ]; then
        num_pages=$(( (num_items + posts_per_page - 1) / posts_per_page ))
        p=1
        while [ "$p" -le "$num_pages" ]; do
            chunk_list="$KEWT_TMPDIR/chunk.md"
            start_line=$(( (p - 1) * posts_per_page + 1 ))
            tail -n +$start_line "$_rpi_temp_list" | head -n "$posts_per_page" > "$chunk_list"

            base_url_dir="$(dirname "$_rpi_target_url")"
            [ "$base_url_dir" = "/" ] && base_url_dir=""

            nav_html="<div class=\"pagination\">"
            if [ "$p" -gt 1 ]; then
                if [ "$p" -eq 2 ]; then
                    nav_html="$nav_html <a href=\"$base_url_dir/index.html\" class=\"prev-page\">&laquo; Prev</a> "
                else
                    nav_html="$nav_html <a href=\"$base_url_dir/page/$((p-1))/index.html\" class=\"prev-page\">&laquo; Prev</a> "
                fi
            fi
            nav_html="$nav_html <span class=\"page-number\">Page $p of $num_pages</span> "
            if [ "$p" -lt "$num_pages" ]; then
                nav_html="$nav_html <a href=\"$base_url_dir/page/$((p+1))/index.html\" class=\"next-page\">Next &raquo;</a> "
            fi
            nav_html="$nav_html</div>"

            echo "" >> "$chunk_list"
            echo "$nav_html" >> "$chunk_list"

            temp_index_p="$KEWT_TMPDIR/index_p$p.md"
            if [ "$_rpi_has_custom_index" = "false" ]; then
                display_dir="${_rpi_rel_dir#.}"
                [ -z "$display_dir" ] && display_dir="/"
                echo "# Index of $display_dir" > "$temp_index_p"
                echo "" >> "$temp_index_p"
            else
                : > "$temp_index_p"
            fi

            if [ "$_rpi_has_custom_index" = "true" ]; then
                awk '
                    /^[[:space:]]*\{\{LIST\}\}[[:space:]]*$/ {
                        while((getline line < "'"$chunk_list"'") > 0) print line
                        close("'"$chunk_list"'")
                        next
                    }
                    { print }
                ' "$_rpi_dir/index.md" >> "$temp_index_p"
            else
                cat "$chunk_list" >> "$temp_index_p"
            fi

            if [ "$p" -eq 1 ]; then
                out_file="$_rpi_out_dir/index.html"
                target_url_p="$_rpi_target_url"
            else
                out_file="$_rpi_out_dir/page/$p/index.html"
                target_url_p="$base_url_dir/page/$p/index.html"
                mkdir -p "$(dirname "$out_file")"
            fi

            render_markdown "$temp_index_p" "$_rpi_is_home" "$target_url_p" > "$out_file"
            rm -f "$temp_index_p" "$chunk_list"
            p=$((p + 1))
        done
    else
        if [ "$_rpi_has_custom_index" = "true" ]; then
            awk '
                /^[[:space:]]*\{\{LIST\}\}[[:space:]]*$/ {
                    while((getline line < "'"$_rpi_temp_list"'") > 0) print line
                    close("'"$_rpi_temp_list"'")
                    next
                }
                { print }
            ' "$_rpi_dir/index.md" > "$_rpi_temp_index"
        else
            cat "$_rpi_temp_list" >> "$_rpi_temp_index"
        fi

        do_rebuild="false"
        needs_rebuild "$_rpi_dir" "$_rpi_out_dir/index.html" && do_rebuild="true"
        [ "$_rpi_has_custom_index" = "true" ] && needs_rebuild "$_rpi_dir/index.md" "$_rpi_out_dir/index.html" && do_rebuild="true"

        if [ "$do_rebuild" = "false" ] && [ -f "$_rpi_out_dir/index.html" ]; then
            for _child in "$_rpi_dir"/*; do
                [ -e "$_child" ] || continue
                if [ "$_child" -nt "$_rpi_out_dir/index.html" ]; then
                    do_rebuild="true"
                    break
                fi
            done
        fi

        if [ "$do_rebuild" = "true" ]; then
            if [ "$_rpi_has_custom_index" = "true" ]; then
                parse_frontmatter "$_rpi_dir/index.md"
            else
                fm_content_warning=""
            fi

            if [ -n "$fm_content_warning" ]; then
                content_out_file="$_rpi_out_dir/content.html"
                if [ "$_rpi_rel_dir" = "." ]; then
                    content_rel_url="/content.html"
                else
                    content_rel_url="/$(encode_url_path "$_rpi_rel_dir")/content.html"
                fi
                write_content_warning_outputs "$_rpi_temp_index" "$content_out_file" "$content_rel_url" "$_rpi_target_url" "$_rpi_out_dir/index.html" "$_rpi_is_home"
            else
                render_markdown "$_rpi_temp_index" "$_rpi_is_home" "$_rpi_target_url" > "$_rpi_out_dir/index.html"
            fi
        fi
    fi
}

build_directories() {
    eval "find \"$src\" \( $IGNORE_ARGS \) -prune -o -type d -print" | sort | while read -r dir; do
        rel_dir="${dir#"$src"}"
        rel_dir="${rel_dir#/}"
        [ -z "$rel_dir" ] && rel_dir="."
        out_dir="$out/$rel_dir"
        mkdir -p "$out_dir"

        if [ -f "$dir/styles.css" ]; then
            if needs_rebuild "$dir/styles.css" "$out_dir/styles.css"; then
                copy_style_with_resolved_vars "$dir/styles.css" "$out_dir/styles.css"
            fi
        elif [ -f "$dir/style.css" ]; then
            if needs_rebuild "$dir/style.css" "$out_dir/styles.css"; then
                copy_style_with_resolved_vars "$dir/style.css" "$out_dir/styles.css"
            fi
        fi

        [ "$dir_indexes" != "true" ] && continue

        build_dir_index "$dir" "$rel_dir" "$out_dir"
    done
}

build_files() {
    eval "find \"$src\" \( $IGNORE_ARGS \) -prune -o -type f -print" | sort | while IFS= read -r file; do
        rel_path="${file#"$src"}"
        rel_path="${rel_path#/}"
        dir_rel=$(dirname "$rel_path")
        out_dir="$out/$dir_rel"

        case "${file##*/}" in
            template.html|site.conf|style.css|styles.css|styles.root.css) continue ;;
        esac

        if [ "${file##*/}" = "index.md" ] && grep -q '^[[:space:]]*{{LIST}}[[:space:]]*$' "$file" 2>/dev/null; then
            continue
        fi

        is_preserved=0
        if [ -n "$(eval "find \"$file\" \( $PRESERVE_ARGS \) -print")" ]; then
            is_preserved=1
        fi

        is_posts_dir_2="false"
        if is_posts_directory_rel "$dir_rel"; then
            is_posts_dir_2="true"
        fi

        if [ "$single_file_index" = "true" ] && [ "${file%.md}" != "$file" ] && [ "$is_preserved" -eq 0 ] && [ ! -f "$(dirname "$file")/index.md" ] && [ "$is_posts_dir_2" = "false" ]; then
            load_manifest_dir_entry "$dir_rel" && [ "$dir_md_count" -eq 1 ] && continue
        fi

        if [ "${file%.md}" != "$file" ] && [ "$is_preserved" -eq 0 ]; then
            load_manifest_entry "$rel_path" || continue
            [ "$manifest_draft" = "true" ] && continue
            is_home="false"; [ "$file" = "$src/index.md" ] && is_home="true"
            out_file="$out/${rel_path%.md}.html"
            if needs_rebuild "$file" "$out_file"; then
                fm_title="$manifest_title"
                fm_content_warning="$manifest_content_warning"
                if [ -n "$manifest_content_warning" ]; then
                    content_out_file="$out/${rel_path%.md}-content.html"
                    content_rel_url="/$(encode_url_path "${rel_path%.md}")-content.html"
                    orig_rel_url="$manifest_url"
                    write_content_warning_outputs "$file" "$content_out_file" "$content_rel_url" "$orig_rel_url" "$out_file" "$is_home"
                else
                    render_markdown "$file" "$is_home" > "$out_file"
                fi
            fi
        else
            if needs_rebuild "$file" "$out/$rel_path"; then
                cp "$file" "$out/$rel_path"
            fi
        fi
    done
}

build_root_style() {
    if [ ! -f "$src/styles.css" ] && [ ! -f "$src/style.css" ]; then
        if [ -f "$src/styles.root.css" ]; then
            _base_css="$script_dir/styles/$style.css"
            [ ! -f "$_base_css" ] && _base_css="$script_dir/styles/kewt.css"
            if [ ! -f "$out/styles.css" ] || [ "$src/styles.root.css" -nt "$out/styles.css" ] || [ "$_base_css" -nt "$out/styles.css" ]; then
                merge_root_style "$src/styles.root.css" "$_base_css" "$out/styles.css"
            fi
        elif [ -f "$script_dir/styles/$style.css" ]; then
            if needs_rebuild "$script_dir/styles/$style.css" "$out/styles.css"; then
                copy_style_with_resolved_vars "$script_dir/styles/$style.css" "$out/styles.css"
            fi
        elif [ -f "$script_dir/styles/$style.root.css" ]; then
            _base_css="$script_dir/styles/kewt.css"
            if [ ! -f "$out/styles.css" ] || [ "$script_dir/styles/$style.root.css" -nt "$out/styles.css" ] || [ "$_base_css" -nt "$out/styles.css" ]; then
                merge_root_style "$script_dir/styles/$style.root.css" "$_base_css" "$out/styles.css"
            fi
        fi
    fi
}

build_sitemap() {
    [ -n "$base_url" ] || return

    sitemap_file="$out/sitemap.xml"
    base_url="${base_url%/}"
    today=$(date +%Y-%m-%d)

    printf '<?xml version="1.0" encoding="UTF-8"?>\n' > "$sitemap_file"
    printf '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n' >> "$sitemap_file"

    find "$out" -type f -name "*.html" -print | sort | while IFS= read -r html_file; do
        rel_url="${html_file#"$out"}"
        [ "${rel_url#/}" = "$error_page" ] && continue

        printf '  <url>\n    <loc>%s%s</loc>\n    <lastmod>%s</lastmod>\n  </url>\n' "$base_url" "$rel_url" "$today" >> "$sitemap_file"
    done

    printf '</urlset>\n' >> "$sitemap_file"
}

build_feed() {
    [ "$generate_feed" = "true" ] && [ -n "$base_url" ] || return

    feed_path="$out/$feed_file"
    base_url_feed="${base_url%/}"
    build_date=$(date -u '+%a, %d %b %Y %H:%M:%S +0000')

    printf '<?xml version="1.0" encoding="UTF-8"?>\n' > "$feed_path"
    printf '<rss version="2.0">\n  <channel>\n    <title>%s</title>\n    <link>%s</link>\n    <description>%s</description>\n    <lastBuildDate>%s</lastBuildDate>\n' \
        "$title" "$base_url_feed" "$title" "$build_date" >> "$feed_path"

    temp_feed_files="$KEWT_TMPDIR/feed_files_$$.txt"
    : > "$temp_feed_files"

    while IFS= read -r manifest_rel_path; do
        case "$manifest_rel_path" in
            *"${posts_dir:-__no_posts__}"*) ;;
            *) continue ;;
        esac
        load_manifest_entry "$manifest_rel_path" || continue
        [ "$manifest_draft" = "true" ] && continue
        printf '%s %s|%s\n' "$manifest_post_date" "$manifest_post_time" "$manifest_rel_path" >> "$temp_feed_files"
    done < "$manifest_all_list"

    LC_ALL=C sort -r "$temp_feed_files" | cut -d'|' -f2- | while IFS= read -r post_rel_path; do
        load_manifest_entry "$post_rel_path" || continue
        [ "$manifest_draft" = "true" ] && continue

        post_date="$manifest_post_date"
        post_time="$manifest_post_time"
        post_heading="$manifest_title"
        post_slug="$manifest_post_slug"
        if [ -z "$post_heading" ] && [ -n "$post_slug" ] && ! echo "$post_slug" | grep -q '^[0-9]\+$'; then
            post_heading=$(echo "$post_slug" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')
        fi
        feed_post_title="$post_heading - $post_date $post_time"
        post_url="$base_url_feed$manifest_url"
        pub_date=$(format_rfc2822_utc "$post_date" "$post_time")

        printf '    <item>\n      <title>%s</title>\n      <link>%s</link>\n      <guid>%s</guid>\n      <pubDate>%s</pubDate>\n    </item>\n' \
            "$feed_post_title" "$post_url" "$post_url" "$pub_date" >> "$feed_path"
    done

    printf '  </channel>\n</rss>\n' >> "$feed_path"
}

build_search_index() {
    printf '[\n' > "$out/search.json"
    first_search_item="true"

    while IFS= read -r rel_path; do
        load_manifest_entry "$rel_path" || continue

        if [ "$manifest_is_index" = "true" ]; then
            if [ "$rel_path" = "index.md" ]; then
                md_url="/index.html"
            else
                md_url=$(directory_index_url "${rel_path%/index.md}")
            fi
        else
            md_url="$manifest_url"
            if [ "$single_file_index" = "true" ]; then
                rel_dir_of_file="$manifest_dir_rel"
                [ -z "$rel_dir_of_file" ] && rel_dir_of_file="."
                if [ "$rel_dir_of_file" = "." ]; then
                    dir_of_file="$src"
                else
                    dir_of_file="$src/$rel_dir_of_file"
                fi

                is_posts_dir_search="false"
                if [ -n "$posts_dir" ] && { [ "$rel_dir_of_file" = "$posts_dir" ] || [ "./$rel_dir_of_file" = "$posts_dir" ]; }; then
                    is_posts_dir_search="true"
                fi

                if [ "$is_posts_dir_search" = "false" ] && [ ! -f "$dir_of_file/index.md" ]; then
                    if load_manifest_dir_entry "$rel_dir_of_file" && [ "$dir_md_count" -eq 1 ]; then
                        if [ "$rel_dir_of_file" = "." ]; then
                            md_url="/index.html"
                        else
                            md_url=$(directory_index_url "$rel_dir_of_file")
                        fi
                    fi
                fi
            fi
        fi

        [ "$manifest_draft" = "true" ] && continue
        md_heading="$manifest_title"

        if [ -z "$manifest_content_warning" ] || [ "$include_cw_pages_in_search" = "true" ]; then
            md_content="$manifest_search_content"
            if [ "$first_search_item" = "false" ]; then
                printf ',\n' >> "$out/search.json"
            fi
            printf '  {"url": "%s", "title": "%s", "content": "%s"}' "$md_url" "$md_heading" "$md_content" >> "$out/search.json"
            first_search_item="false"
        fi
    done < "$manifest_visible_list"

    printf '\n]\n' >> "$out/search.json"
    cp "$script_dir/lib/search.js" "$out/search.js"

    search_md="$KEWT_TMPDIR/search_$$.md"
    printf '%s\n' '# Search' '' \
        '<form class="kewt-search-page" action="/search.html" method="get">' \
        '  <input type="text" id="search-box" name="q" placeholder="Search..." required>' \
        '  <button type="submit">Search</button>' \
        '</form>' '' \
        '<div id="search-results-list">' \
        '  <p>Loading...</p>' \
        '</div>' '' \
        '<script src="/search.js"></script>' > "$search_md"
    render_markdown "$search_md" "false" "/search.html" > "$out/search.html"
    rm -f "$search_md"
}

build_tags() {
    temp_tags="$KEWT_TMPDIR/tags_$$.txt"
    : > "$temp_tags"

    while IFS= read -r rel_path; do
        load_manifest_entry "$rel_path" || continue
        [ "$manifest_draft" = "true" ] && continue
        md_heading="$manifest_title"

        if [ -n "$manifest_tags" ]; then
            old_ifs=$IFS
            IFS=','
            for tag in $manifest_tags; do
                tag=$(echo "$tag" | sed 's/^[ \t]*//;s/[ \t]*$//')
                [ -z "$tag" ] && continue
                printf '%s|%s|%s\n' "$tag" "$manifest_url" "$md_heading" >> "$temp_tags"
            done
            IFS=$old_ifs
        fi
    done < "$manifest_visible_list"

    tags_out_dir="$out/$tags_dir"
    mkdir -p "$tags_out_dir"

    tags_index_md="$KEWT_TMPDIR/tags_index_$$.md"
    echo "# Tags" > "$tags_index_md"
    echo "" >> "$tags_index_md"

    cut -d'|' -f1 "$temp_tags" | sort -u | while IFS= read -r tag; do
        tag_slug=$(echo "$tag" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g')

        echo "- [$tag](/$(echo "$tags_dir" | sed 's|^\/||; s|\/$||')/$tag_slug.html)" >> "$tags_index_md"

        tag_page_md="$KEWT_TMPDIR/tag_page_$$.md"
        echo "# Tag: $tag" > "$tag_page_md"
        echo "" >> "$tag_page_md"
        echo "Posts tagged with **$tag**:" >> "$tag_page_md"
        echo "" >> "$tag_page_md"

        grep "^${tag}|" "$temp_tags" | while IFS='|' read -r _t t_url t_title; do
            echo "- [$t_title]($t_url)" >> "$tag_page_md"
        done

        render_markdown "$tag_page_md" "false" "/$tags_dir/$tag_slug.html" > "$tags_out_dir/$tag_slug.html"
        rm -f "$tag_page_md"
    done

    render_markdown "$tags_index_md" "false" "/$tags_dir/index.html" > "$tags_out_dir/index.html"
    rm -f "$tags_index_md" "$temp_tags"
}

build_error_page() {
    [ -n "$error_page" ] && [ ! -f "$out/$error_page" ] || return

    temp_404="$KEWT_TMPDIR/404_gen.md"
    printf '# 404 - Not Found\n\nThe requested page could not be found.\n' > "$temp_404"
    render_markdown "$temp_404" "false" "/$error_page" > "$out/$error_page"
    rm -f "$temp_404"
}

build_site() {
    echo "Building site from '$src' to '$out'..."

    build_markdown_manifest
    build_full_nav

    build_directories
    build_root_style
    build_files
    build_error_page
    build_sitemap
    build_feed

    if [ "$generate_search" = "true" ]; then
        build_search_index
    fi

    if [ "$generate_tags" = "true" ]; then
        build_tags
    fi

    echo "Build complete."
}
