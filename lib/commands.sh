usage() {
    invoked_as=$(basename "${KEWT_INVOKED_AS:-$0}")
    cat <<EOF
Usage: $invoked_as [--from <src>] [--to <out>]
       $invoked_as [src] [out]
       $invoked_as --new [title]
       $invoked_as --update [dir]
       $invoked_as --post
       $invoked_as --generate-template
       $invoked_as --version
       $invoked_as --help

Options:
  --help                     Show this help message.
  --new, --init [title]      Create a new site directory (default: site)
  --clean                    Clean the output directory before building (default).
  --no-clean                 Do not clean the output directory before building.
  --update [dir]             Update site.conf and template.html with latest defaults (defaults to current directory)
  --post                     Create a new empty post file in the configured posts_dir with current date and time as name
  --generate-template [path] Generate a new template file at <path> (default: template.html)
  --version                  Show version information.
  --from <src>               Source directory (default: site)
  --to <out>                 Output directory (default: out)
  --watch, -w                Watch for file changes and rebuild automatically.
  --serve, -s [port]         Start a local HTTP server after building (default port: 8000).
EOF
}
generate_template() {
    _gt_path="$1"
    [ -e "$_gt_path" ] && die "File '$_gt_path' already exists."
    _gt_dir=$(dirname "$_gt_path")
    [ -d "$_gt_dir" ] || mkdir -p "$_gt_dir"
    printf '%s\n' "$DEFAULT_TMPL" > "$_gt_path"
    echo "Generated template at '$_gt_path'."
    exit 0
}

create_new_site() {
    new_title="$1"
    new_dir="site"
    [ -n "$new_title" ] && new_dir="$new_title"

    [ -e "$new_dir" ] && die "Target '$new_dir' already exists."

    mkdir -p "$new_dir"
    printf '%s\n' "$DEFAULT_CONF" > "$new_dir/site.conf"
    printf '%s\n' "$DEFAULT_TMPL" > "$new_dir/template.html"
    printf "# _kewt_ website\n" > "$new_dir/index.md"

    if [ -n "$new_title" ]; then
        AWK_NEW_TITLE="$new_title" awk -f "$awk_dir/update_site_conf.awk" "$new_dir/site.conf" > "$new_dir/site.conf.tmp" && mv "$new_dir/site.conf.tmp" "$new_dir/site.conf"
    fi

    echo "Created new site at '$new_dir'."
    exit 0
}

create_new_post() {
    post_src_dir="$1"
    post_user_title="$2"

    target_dir="$post_src_dir"
    if [ -n "$posts_dir" ]; then
        target_dir="$post_src_dir/$posts_dir"
    fi

    mkdir -p "$target_dir"

    base_filename="$(date +%Y-%m-%d-%H-%M)"
    filename="${base_filename}.md"
    file_path="$target_dir/$filename"

    counter=1
    while [ -e "$file_path" ]; do
        filename="${base_filename}_${counter}.md"
        file_path="$target_dir/$filename"
        counter=$((counter + 1))
    done

    post_date_val="$(date "+%Y-%m-%d %H:%M")"
    if [ -n "$post_user_title" ]; then
        printf -- '---\ntitle = "%s"\ndate = "%s"\ndraft = %s\n---\n# %s\n' "$post_user_title" "$post_date_val" "$draft_by_default" "$post_user_title" > "$file_path"
    else
        printf -- '---\ndate = "%s"\ndraft = %s\n---\n' "$post_date_val" "$draft_by_default" > "$file_path"
    fi

    echo "Created new post at '$file_path'."
    exit 0
}

update_site() {
    update_dir="${1:-.}"
    [ -d "$update_dir" ] || die "Directory '$update_dir' does not exist."

    target_conf="$update_dir/site.conf"
    target_tmpl="$update_dir/template.html"

    # Generate default site.conf
    default_conf="$KEWT_TMPDIR/default_site.conf"
    printf '%s\n' "$DEFAULT_CONF" > "$default_conf"

    # Update site.conf
    if [ ! -f "$target_conf" ]; then
        echo "No site.conf found in '$update_dir'; nothing to update."
    else
        added=0
        while IFS= read -r line; do
            case "$line" in
                ''|'#'*) continue ;;
                *=*) ;;
                *) continue ;;
            esac
            key=$(printf '%s' "${line%%=*}" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
            if ! grep -q "^[[:space:]]*${key}[[:space:]]*=" "$target_conf"; then
                printf '%s\n' "$line" >> "$target_conf"
                echo "  Added: $key"
                added=$((added + 1))
            fi
        done < "$default_conf"
        if [ "$added" -eq 0 ]; then
            echo "site.conf is already up to date."
        else
            echo "Added $added new key(s) to '$target_conf'."
        fi
    fi

    # Update template.html
    if [ -f "$target_tmpl" ]; then
        default_tmpl="$KEWT_TMPDIR/default_template.html"
        printf '%s\n' "$DEFAULT_TMPL" > "$default_tmpl"
        if cmp -s "$default_tmpl" "$target_tmpl" 2>/dev/null; then
            echo "template.html is already up to date."
        else
            cp "$default_tmpl" "${target_tmpl}.default"
            echo "template.html has local changes; saved latest default as '${target_tmpl}.default'."
            echo ""
            diff "$target_tmpl" "${target_tmpl}.default" || true
        fi
    fi

    exit 0
}
