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

build_site() {
echo "Building site from '$src' to '$out'..."

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

    has_custom_index="false"
    has_list="false"
    if [ -f "$dir/index.md" ]; then
        has_custom_index="true"
        if grep -q '^[[:space:]]*{{LIST}}[[:space:]]*$' "$dir/index.md" 2>/dev/null; then
            has_list="true"
        fi
    fi

    if [ "$has_custom_index" = "false" ] || [ "$has_list" = "true" ]; then
        is_posts_dir="false"
        if [ -n "$posts_dir" ] && { [ "$rel_dir" = "$posts_dir" ] || [ "./$rel_dir" = "$posts_dir" ]; }; then
            is_posts_dir="true"
        fi
        if [ "$single_file_index" = "true" ] && [ "$is_posts_dir" = "false" ] && [ "$has_list" = "false" ]; then
            md_count=$(find "$dir" ! -name "$(basename "$dir")" -prune -name "*.md" | wc -l)
            if [ "$md_count" -eq 1 ]; then
                md_file=$(find "$dir" ! -name "$(basename "$dir")" -prune -name "*.md")
                is_home="false"; [ "$dir" = "$src" ] && is_home="true"
                target_url="/$rel_dir/index.html"
                [ "$rel_dir" = "." ] && target_url="/index.html"
                if needs_rebuild "$md_file" "$out_dir/index.html"; then
                    parse_frontmatter "$md_file"
                    if [ -n "$fm_content_warning" ]; then
                        content_out_file="$out_dir/content.html"
                        content_rel_url="/$rel_dir/content.html"
                        [ "$rel_dir" = "." ] && content_rel_url="/content.html"

                        is_cw_content_page="true"
                        render_markdown "$md_file" "$is_home" "$target_url" > "$content_out_file"
                        is_cw_content_page="false"

                        generate_content_warning_page "$fm_title" "$fm_content_warning" "$content_rel_url" "$target_url" "$out_dir/index.html" "false"
                    else
                        render_markdown "$md_file" "$is_home" "$target_url" > "$out_dir/index.html"
                    fi
                fi
                continue
            fi
        fi

        temp_index="$KEWT_TMPDIR/index.md"
        temp_list="$KEWT_TMPDIR/list.md"
        : > "$temp_list"

        if [ "$has_custom_index" = "false" ]; then
            display_dir="${rel_dir#.}"
            [ -z "$display_dir" ] && display_dir="/"
            echo "# Index of $display_dir" > "$temp_index"
            echo "" >> "$temp_index"
        fi


        sort_args=""
        # If this is the posts dir reverse
        if [ "$rel_dir" = "$posts_dir" ] || [ "./$rel_dir" = "$posts_dir" ]; then
            sort_args="-r"
        fi

        temp_entries="$KEWT_TMPDIR/entries_$$.txt"
        : > "$temp_entries"

        find "$dir" ! -name "$(basename "$dir")" -prune ! -name ".*" -print | while read -r entry; do
            name="${entry##*/}"
            case "$name" in
                template.html|site.conf|style.css|styles.root.css|index.md) continue ;;
            esac
            if [ -d "$entry" ]; then
                echo "${name}|- [${name}/](${name}/index.html)" >> "$temp_entries"
            elif [ "${entry%.md}" != "$entry" ]; then
                label="${name%.md}"

                # Parse frontmatter for date/title/draft
                parse_frontmatter "$entry"
                [ "$fm_draft" = "true" ] && continue

                # Try to get first heading
                post_h="$fm_title"
                if [ -z "$post_h" ]; then
                    post_h=$(grep -m 1 '^# ' "$entry" | sed 's/^# *//')
                    if [ -n "$post_h" ]; then
                        post_h=$(echo "$post_h" | sed -e 's/\[//g' -e 's/\]//g' -e 's/!//g' -e 's/\*//g' -e 's/_//g' -e 's/`//g' -e 's/([^)]*)//g' | sed 's/\\//g')
                    fi
                fi

                is_post_entry="false"
                if [ "$rel_dir" = "$posts_dir" ] || [ "./$rel_dir" = "$posts_dir" ]; then
                    is_post_entry="true"
                fi

                if [ -n "$post_h" ]; then
                    if [ "$is_post_entry" = "true" ]; then
                        # Use frontmatter date if available, else parse from filename
                        if [ -n "$fm_date" ]; then
                            p_date=$(echo "$fm_date" | sed 's/^\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\).*/\1/')
                            p_time=""
                            if echo "$fm_date" | grep -q '^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}[ T_-]\?[0-9]\{2\}[:\-][0-9]\{2\}'; then
                                p_time=$(echo "$fm_date" | sed 's/^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}[ T_-]\?\([0-9]\{2\}[:\-][0-9]\{2\}\).*/\1/' | tr '-' ':')
                            fi
                        else
                            p_date=$(echo "${name%.md}" | sed 's/^\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\).*/\1/')
                            p_time="00:00"
                            if echo "${name%.md}" | grep -q '^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}-[0-9]\{2\}[:\-][0-9]\{2\}'; then
                                 p_time=$(echo "${name%.md}" | sed 's/^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}-\([0-9]\{2\}[:\-][0-9]\{2\}\).*/\1/' | tr '-' ':')
                            fi
                        fi
                        if [ -n "$p_time" ]; then
                            label="$post_h - $p_date $p_time"
                        else
                            label="$post_h - $p_date"
                        fi
                    else
                        label="$post_h"
                    fi
                elif [ "$is_post_entry" = "true" ]; then
                    # No heading; use date
                    if [ -n "$fm_date" ]; then
                        p_date=$(echo "$fm_date" | sed 's/^\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\).*/\1/')
                        p_time=""
                        if echo "$fm_date" | grep -q '^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}[ T_-]\?[0-9]\{2\}[:\-][0-9]\{2\}'; then
                            p_time=$(echo "$fm_date" | sed 's/^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}[ T_-]\?\([0-9]\{2\}[:\-][0-9]\{2\}\).*/\1/' | tr '-' ':')
                        fi
                        if [ -n "$p_time" ]; then
                            label="$p_date $p_time"
                        else
                            label="$p_date"
                        fi
                    else
                        p_date=$(echo "${name%.md}" | sed 's/^\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\).*/\1/')
                        p_time="00:00"
                        if echo "${name%.md}" | grep -q '^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}-[0-9]\{2\}[:\-][0-9]\{2\}'; then
                             p_time=$(echo "${name%.md}" | sed 's/^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}-\([0-9]\{2\}[:\-][0-9]\{2\}\).*/\1/' | tr '-' ':')
                        fi
                        label="$p_date $p_time"
                    fi
                fi
                if [ -n "$fm_priority" ]; then
                    prio_val="$fm_priority"
                else
                    prio_val="0"
                fi
                if [ "$is_post_entry" = "true" ]; then
                    prio_key=$(printf '%05d' "$prio_val")
                    sort_key="${prio_key} ${p_date} ${p_time}"
                else
                    prio_key=$(printf '%05d' "$((99999 - prio_val))")
                    sort_key="${prio_key} $name"
                fi
                echo "${sort_key}|- [$label](${name%.md}.html)|$name|${name%.md}.html" >> "$temp_entries"
            else
                echo "${name}|- [$name]($name)|$name|$name" >> "$temp_entries"
            fi
        done

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

        is_home="false"; [ "$dir" = "$src" ] && is_home="true"
        target_url="/$rel_dir/index.html"
        [ "$rel_dir" = "." ] && target_url="/index.html"

        num_items=$(wc -l < "$temp_list")
        if [ "$is_posts_dir" = "true" ] && [ -n "$posts_per_page" ] && [ "$posts_per_page" -gt 0 ] && [ "$num_items" -gt "$posts_per_page" ]; then
            num_pages=$(( (num_items + posts_per_page - 1) / posts_per_page ))
            for p in $(seq 1 $num_pages); do
                chunk_list="$KEWT_TMPDIR/chunk.md"
                start_line=$(( (p - 1) * posts_per_page + 1 ))
                tail -n +$start_line "$temp_list" | head -n "$posts_per_page" > "$chunk_list"

                base_url_dir="$(dirname "$target_url")"
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
                if [ "$has_custom_index" = "false" ]; then
                    display_dir="${rel_dir#.}"
                    [ -z "$display_dir" ] && display_dir="/"
                    echo "# Index of $display_dir" > "$temp_index_p"
                    echo "" >> "$temp_index_p"
                else
                    : > "$temp_index_p"
                fi

                if [ "$has_custom_index" = "true" ]; then
                    awk '
                        /^[[:space:]]*\{\{LIST\}\}[[:space:]]*$/ {
                            while((getline line < "'"$chunk_list"'") > 0) print line
                            close("'"$chunk_list"'")
                            next
                        }
                        { print }
                    ' "$dir/index.md" >> "$temp_index_p"
                else
                    cat "$chunk_list" >> "$temp_index_p"
                fi

                if [ "$p" -eq 1 ]; then
                    out_file="$out_dir/index.html"
                    target_url_p="$target_url"
                else
                    out_file="$out_dir/page/$p/index.html"
                    target_url_p="$base_url_dir/page/$p/index.html"
                    mkdir -p "$(dirname "$out_file")"
                fi

                render_markdown "$temp_index_p" "$is_home" "$target_url_p" > "$out_file"
                rm -f "$temp_index_p" "$chunk_list"
            done
        else
            if [ "$has_custom_index" = "true" ]; then
                awk '
                    /^[[:space:]]*\{\{LIST\}\}[[:space:]]*$/ {
                        while((getline line < "'"$temp_list"'") > 0) print line
                        close("'"$temp_list"'")
                        next
                    }
                    { print }
                ' "$dir/index.md" > "$temp_index"
            else
                cat "$temp_list" >> "$temp_index"
            fi

            do_rebuild="false"
            needs_rebuild "$dir" "$out_dir/index.html" && do_rebuild="true"
            [ "$has_custom_index" = "true" ] && needs_rebuild "$dir/index.md" "$out_dir/index.html" && do_rebuild="true"

            if [ "$do_rebuild" = "false" ] && [ -f "$out_dir/index.html" ]; then
                for _child in "$dir"/*; do
                    [ -e "$_child" ] || continue
                    if [ "$_child" -nt "$out_dir/index.html" ]; then
                        do_rebuild="true"
                        break
                    fi
                done
            fi

            if [ "$do_rebuild" = "true" ]; then
                if [ "$has_custom_index" = "true" ]; then
                    parse_frontmatter "$dir/index.md"
                else
                    fm_content_warning=""
                fi

                if [ -n "$fm_content_warning" ]; then
                    content_out_file="$out_dir/content.html"
                    content_rel_url="/$rel_dir/content.html"
                    [ "$rel_dir" = "." ] && content_rel_url="/content.html"

                    is_cw_content_page="true"
                    render_markdown "$temp_index" "$is_home" "$target_url" > "$content_out_file"
                    is_cw_content_page="false"

                    generate_content_warning_page "$fm_title" "$fm_content_warning" "$content_rel_url" "$target_url" "$out_dir/index.html" "false"
                else
                    render_markdown "$temp_index" "$is_home" "$target_url" > "$out_dir/index.html"
                fi
            fi
        fi
        rm -f "$temp_index" "$temp_list"
    fi
done

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
    if [ -n "$posts_dir" ] && { [ "$dir_rel" = "$posts_dir" ] || [ "./$dir_rel" = "$posts_dir" ]; }; then
        is_posts_dir_2="true"
    fi

    if [ "$single_file_index" = "true" ] && [ "${file%.md}" != "$file" ] && [ "$is_preserved" -eq 0 ] && [ ! -f "$(dirname "$file")/index.md" ] && [ "$is_posts_dir_2" = "false" ]; then
        md_count=$(find "$(dirname "$file")" ! -name "$(basename "$(dirname "$file")")" -prune -name "*.md" | wc -l)
        [ "$md_count" -eq 1 ] && continue
    fi

    if [ "${file%.md}" != "$file" ] && [ "$is_preserved" -eq 0 ]; then
        # Skip draft files
        parse_frontmatter "$file"
        if [ "$fm_draft" = "true" ]; then
            continue
        fi
        is_home="false"; [ "$file" = "$src/index.md" ] && is_home="true"
        out_file="$out/${rel_path%.md}.html"
        if needs_rebuild "$file" "$out_file"; then
            if [ -n "$fm_content_warning" ]; then
                content_out_file="$out/${rel_path%.md}-content.html"
                content_rel_url="/${rel_path%.md}-content.html"
                orig_rel_url="/${rel_path%.md}.html"

                is_cw_content_page="true"
                render_markdown "$file" "$is_home" "$orig_rel_url" > "$content_out_file"
                is_cw_content_page="false"

                generate_content_warning_page "$fm_title" "$fm_content_warning" "$content_rel_url" "$orig_rel_url" "$out_file" "false"
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

if [ -n "$error_page" ] && [ ! -f "$out/$error_page" ]; then
    temp_404="$KEWT_TMPDIR/404_gen.md"
    echo "# 404 - Not Found" > "$temp_404"
    echo "" >> "$temp_404"
    echo "The requested page could not be found." >> "$temp_404"
    render_markdown "$temp_404" "false" "/$error_page" > "$out/$error_page"
    rm -f "$temp_404"
fi

if [ -n "$base_url" ]; then
    sitemap_file="$out/sitemap.xml"
    base_url="${base_url%/}"
    today=$(date +%Y-%m-%d)

    printf '<?xml version="1.0" encoding="UTF-8"?>\n' > "$sitemap_file"
    printf '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n' >> "$sitemap_file"

    find "$out" -type f -name "*.html" -print | sort | while IFS= read -r html_file; do
        rel_url="${html_file#"$out"}"

        # Don't include 404 in the sitemap (duh)
        [ "${rel_url#/}" = "$error_page" ] && continue

        {
            printf '  <url>\n'
            printf '    <loc>%s%s</loc>\n' "$base_url" "$rel_url"
            printf '    <lastmod>%s</lastmod>\n' "$today"
            printf '  </url>\n'
        } >> "$sitemap_file"
    done

    printf '</urlset>\n' >> "$sitemap_file"
fi

if [ "$generate_feed" = "true" ] && [ -n "$base_url" ]; then
    feed_path="$out/$feed_file"
    base_url_feed="${base_url%/}"
    build_date=$(date -u '+%a, %d %b %Y %H:%M:%S +0000')

    printf '<?xml version="1.0" encoding="UTF-8"?>\n' > "$feed_path"
    {
        printf '<rss version="2.0">\n'
        printf '  <channel>\n'
        printf '    <title>%s</title>\n' "$title"
        printf '    <link>%s</link>\n' "$base_url_feed"
        printf '    <description>%s</description>\n' "$title"
        printf '    <lastBuildDate>%s</lastBuildDate>\n' "$build_date"
    } >> "$feed_path"

    temp_feed_files="$KEWT_TMPDIR/feed_files_$$.txt"
    : > "$temp_feed_files"

    find "$src" -type f -name '*.md' -path "*${posts_dir:-__no_posts__}*" -print | while IFS= read -r post_file; do
        post_basename=$(basename "$post_file" .md)
        # Parse frontmatter to get date
        parse_frontmatter "$post_file"
        [ "$fm_draft" = "true" ] && continue
        if [ -n "$fm_date" ]; then
            post_date=$(echo "$fm_date" | sed 's/^\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\).*/\1/')
            post_time="00:00"
            if echo "$fm_date" | grep -q '^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}[ T_-]\?[0-9]\{2\}[:\-][0-9]\{2\}'; then
                post_time=$(echo "$fm_date" | sed 's/^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}[ T_-]\?\([0-9]\{2\}[:\-][0-9]\{2\}\).*/\1/' | tr '-' ':')
            fi
        else
            post_date=$(echo "$post_basename" | sed 's/^\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\).*/\1/')
            post_time="00:00"
            if echo "$post_basename" | grep -q '^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}-[0-9]\{2\}[:\-][0-9]\{2\}'; then
                post_time=$(echo "$post_basename" | sed 's/^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}-\([0-9]\{2\}[:\-][0-9]\{2\}\).*/\1/' | tr '-' ':')
            fi
        fi
        echo "${post_date} ${post_time}|${post_file}" >> "$temp_feed_files"
    done

    LC_ALL=C sort -r "$temp_feed_files" | cut -d'|' -f2- | while IFS= read -r post_file; do
        post_basename=$(basename "$post_file" .md)

        # Parse frontmatter
        parse_frontmatter "$post_file"
        [ "$fm_draft" = "true" ] && continue

        # Use frontmatter date, fallback to filename
        if [ -n "$fm_date" ]; then
            post_date=$(echo "$fm_date" | sed 's/^\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\).*/\1/')
            post_time="00:00"
            if echo "$fm_date" | grep -q '^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}[ T_-]\?[0-9]\{2\}[:\-][0-9]\{2\}'; then
                post_time=$(echo "$fm_date" | sed 's/^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}[ T_-]\?\([0-9]\{2\}[:\-][0-9]\{2\}\).*/\1/' | tr '-' ':')
            fi
        else
            post_date=$(echo "$post_basename" | sed 's/^\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\).*/\1/')
            post_time="00:00"
            if echo "$post_basename" | grep -q '^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}-[0-9]\{2\}[:\-][0-9]\{2\}'; then
                post_time=$(echo "$post_basename" | sed 's/^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}-\([0-9]\{2\}[:\-][0-9]\{2\}\).*/\1/' | tr '-' ':')
            fi
        fi

        post_slug=$(echo "$post_basename" | sed -e 's/^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}-[0-9]\{2\}[:\-][0-9]\{2\}//' -e 's/^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}//' -e 's/^[_\-]//')

        post_heading="$fm_title"
        if [ -z "$post_heading" ]; then
            post_heading=$(grep -m 1 '^# ' "$post_file" | sed 's/^# *//')
        fi
        if [ -z "$post_heading" ]; then
            if [ -n "$post_slug" ] && ! echo "$post_slug" | grep -q '^[0-9]\+$'; then
                post_heading=$(echo "$post_slug" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')
            else
                post_heading="Post"
            fi
        fi
        post_heading=$(echo "$post_heading" | sed -e 's/\[//g' -e 's/\]//g' -e 's/!//g' -e 's/\*//g' -e 's/_//g' -e 's/`//g' -e 's/([^)]*)//g' | sed 's/\\//g')
        feed_post_title="$post_heading - $post_date $post_time"

        rel_path="${post_file#"$src"}"
        rel_path="${rel_path#/}"
        post_url="$base_url_feed/${rel_path%.md}.html"

        if date -u -d "$post_date $post_time" '+%a, %d %b %Y %H:%M:%S +0000' >/dev/null 2>&1; then
            pub_date=$(date -u -d "$post_date $post_time" '+%a, %d %b %Y %H:%M:%S +0000')
        else
            pub_year=$(echo "$post_date" | cut -d- -f1)
            pub_month=$(echo "$post_date" | cut -d- -f2)
            pub_day=$(echo "$post_date" | cut -d- -f3)
            # zero-padded
            pub_day=$(printf '%02d' "${pub_day#0}")
            case "$pub_month" in
                01) pub_mon="Jan" ;; 02) pub_mon="Feb" ;; 03) pub_mon="Mar" ;;
                04) pub_mon="Apr" ;; 05) pub_mon="May" ;; 06) pub_mon="Jun" ;;
                07) pub_mon="Jul" ;; 08) pub_mon="Aug" ;; 09) pub_mon="Sep" ;;
                10) pub_mon="Oct" ;; 11) pub_mon="Nov" ;; 12) pub_mon="Dec" ;;
            esac
            pub_date="Mon, ${pub_day} ${pub_mon} ${pub_year} ${post_time}:00 +0000"
        fi

        {
            printf '    <item>\n'
            printf '      <title>%s</title>\n' "$feed_post_title"
            printf '      <link>%s</link>\n' "$post_url"
            printf '      <guid>%s</guid>\n' "$post_url"
            printf '      <pubDate>%s</pubDate>\n' "$pub_date"
            printf '    </item>\n'
        } >> "$feed_path"
    done

    printf '  </channel>\n' >> "$feed_path"
    printf '</rss>\n' >> "$feed_path"
fi

if [ "$generate_search" = "true" ] || [ "$generate_tags" = "true" ]; then
    if [ "$generate_search" = "true" ]; then
        printf '[\n' > "$out/search.json"
    fi
    first_search_item="true"
    temp_tags="$KEWT_TMPDIR/tags_$$.txt"
    : > "$temp_tags"

    eval "find \"$src\" \( $IGNORE_ARGS -o $HIDE_ARGS -o $PRESERVE_ARGS \) -prune -o -name \"*.md\" -print" | sort | while IFS= read -r md_file; do
        is_index="false"
        [ "$(basename "$md_file")" = "index.md" ] && is_index="true"

        rel_path="${md_file#"$src"}"
        rel_path="${rel_path#/}"
        if [ "$is_index" = "true" ]; then
            if [ "$rel_path" = "index.md" ]; then
                md_url="/index.html"
            else
                md_url="/${rel_path%/index.md}/index.html"
            fi
        else
            md_url="/${rel_path%.md}.html"
            if [ "$single_file_index" = "true" ]; then
                dir_of_file="$(dirname "$md_file")"
                rel_dir_of_file="${dir_of_file#"$src"}"
                rel_dir_of_file="${rel_dir_of_file#/}"
                [ -z "$rel_dir_of_file" ] && rel_dir_of_file="."

                is_posts_dir_search="false"
                if [ -n "$posts_dir" ] && { [ "$rel_dir_of_file" = "$posts_dir" ] || [ "./$rel_dir_of_file" = "$posts_dir" ]; }; then
                    is_posts_dir_search="true"
                fi

                if [ "$is_posts_dir_search" = "false" ] && [ ! -f "$dir_of_file/index.md" ]; then
                    md_count_search=$(find "$dir_of_file" ! -name "$(basename "$dir_of_file")" -prune -name "*.md" | wc -l)
                    if [ "$md_count_search" -eq 1 ]; then
                        if [ "$rel_dir_of_file" = "." ]; then
                            md_url="/index.html"
                        else
                            md_url="/$rel_dir_of_file/index.html"
                        fi
                    fi
                fi
            fi
        fi

        parse_frontmatter "$md_file"
        [ "$fm_draft" = "true" ] && continue

        md_heading="$fm_title"
        if [ -z "$md_heading" ]; then
            md_heading=$(grep -m 1 '^# ' "$md_file" | sed 's/^# *//; s/ *$//')
            if [ -n "$md_heading" ]; then
                md_heading=$(echo "$md_heading" | sed -e 's/\[//g' -e 's/\]//g' -e 's/!//g' -e 's/\*//g' -e 's/_//g' -e 's/`//g' -e 's/([^)]*)//g' | sed 's/\\//g')
            fi
        fi
        if [ -z "$md_heading" ]; then
            basename_no_ext=$(basename "$md_file" .md)
            if [ "$basename_no_ext" != "index" ] && [ "$basename_no_ext" != "404_gen" ]; then
                md_heading=$(echo "$basename_no_ext" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')
            else
                md_heading="$title - Page"
            fi
        fi

        if [ "$generate_search" = "true" ]; then
            if [ -z "$fm_content_warning" ] || [ "$include_cw_pages_in_search" = "true" ]; then
                md_content=$(awk '{
                    if (NR == 1 && $0 == "---") { in_fm = 1; next }
                    if (in_fm && $0 == "---") { in_fm = 0; next }
                    if (in_fm) next
                    if ($0 ~ /^```/) { in_code = !in_code; next }
                    if (in_code) next
                    print
                }' "$md_file" | sed \
                -e 's/^#\{1,6\} //' \
                -e 's/\*\*\([^*]*\)\*\*/\1/g' \
                -e 's/\*\([^*]*\)\*/\1/g' \
                -e 's/__\([^_]*\)__/\1/g' \
                -e 's/_\([^_]*\)_/\1/g' \
                -e 's/`\([^`]*\)`/\1/g' \
                -e 's/\[\([^]]*\)](\([^)]*\))/\1/g' \
                -e 's/!\[\([^]]*\)](\([^)]*\))//g' \
                -e 's/^[[:space:]]*[-*+] //' \
                -e 's/^[[:space:]]*[0-9]\{1,\}\. //' \
                -e 's/^>[[:space:]]*//' \
                -e 's/<[^>]*>//g' \
                -e '/^[[:space:]]*$/d' \
                -e 's/|//g' \
                -e 's/^[[:space:]]*---[[:space:]]*$//' \
                | tr '\n' ' ' | sed -e 's/  */ /g' -e 's/\\/\\\\/g' -e 's/"/\\"/g' | head -c 500)
            if [ "$first_search_item" = "false" ]; then
                printf ',\n' >> "$out/search.json"
            fi
            printf '  {"url": "%s", "title": "%s", "content": "%s"}' "$md_url" "$md_heading" "$md_content" >> "$out/search.json"
            first_search_item="false"
            fi
        fi

        if [ "$generate_tags" = "true" ] && [ -n "$fm_tags" ]; then
            old_ifs=$IFS
            IFS=','
            for tag in $fm_tags; do
                tag=$(echo "$tag" | sed 's/^[ \t]*//;s/[ \t]*$//')
                [ -z "$tag" ] && continue
                printf '%s|%s|%s\n' "$tag" "$md_url" "$md_heading" >> "$temp_tags"
            done
            IFS=$old_ifs
        fi
    done

    if [ "$generate_search" = "true" ]; then
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
    fi

    if [ "$generate_tags" = "true" ]; then
        tags_out_dir="$out/$tags_dir"
        mkdir -p "$tags_out_dir"

        tags_index_md="$KEWT_TMPDIR/tags_index_$$.md"
        echo "# Tags" > "$tags_index_md"
        echo "" >> "$tags_index_md"

        cut -d'|' -f1 "$temp_tags" | sort -u | while IFS= read -r tag; do
            tag_slug=$(echo "$tag" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g')

            echo "- [$tag](/$(echo $tags_dir | sed 's|^\/||; s|\/$||')/$tag_slug.html)" >> "$tags_index_md"

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
        rm -f "$tags_index_md"
    fi
    rm -f "$temp_tags"
fi

echo "Build complete."
}
