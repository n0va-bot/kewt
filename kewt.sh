#!/bin/sh

die() {
    echo "Error: $1" >&2
    exit 1
}

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
  --new [title]              Create a new site directory (default: site)
  --update [dir]             Update site.conf and template.html with latest defaults (defaults to current directory)
  --post                     Create a new empty post file in the configured posts_dir with current date and time as name
  --generate-template [path] Generate a new template file at <path> (default: template.html)
  --version                  Show version information.
  --from <src>               Source directory (default: site)
  --to <out>                 Output directory (default: out)
EOF
}

script_dir=$(CDPATH="" cd -- "$(dirname -- "$0")" && pwd)
awk_dir="$script_dir/awk"

KEWT_TMPDIR=$(mktemp -d "/tmp/kewt_run.XXXXXX")
trap 'rm -rf "$KEWT_TMPDIR"' EXIT HUP INT TERM

DEFAULT_CONF='title = "kewt"
style = "kewt"
dir_indexes = true
single_file_index = true
flatten = false
order = ""
home_name = "Home"
show_home_in_nav = true
nav_links = ""
nav_extra = ""
footer = "made with <a href=\"https://kewt.krzak.org\">kewt</a>"
logo = ""
display_logo = false
display_title = true
logo_as_favicon = true
favicon = ""
generate_page_title = true
error_page = "not_found.html"
versioning = false
enable_header_links = true
base_url = ""
generate_feed = false
feed_file = "rss.xml"
posts_dir = ""
custom_admonitions = ""'

DEFAULT_TMPL='<!doctype html>
<html>
    <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <title>{{TITLE}}</title>

        <link rel="stylesheet" href="{{CSS}}" type="text/css" />
        {{HEAD_EXTRA}}
    </head>

    <body>
        <header>
            <h1>{{HEADER_BRAND}}</h1>
        </header>

        <nav id="side-bar">{{NAV}}</nav>

        <article>{{CONTENT}}</article>
        <footer>{{FOOTER}}</footer>
    </body>
</html>'


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
        printf -- '---\ntitle = "%s"\ndate = "%s"\ndraft = false\n---\n# %s\n' "$post_user_title" "$post_date_val" "$post_user_title" > "$file_path"
    else
        printf -- '---\ndate = "%s"\ndraft = false\n---\n' "$post_date_val" > "$file_path"
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



src=""
out=""
new_mode="false"
new_title=""
post_mode="false"
post_title=""
positional_count=0

while [ $# -gt 0 ]; do
    case "$1" in
        --help|-h)
            usage
            exit 0
            ;;
        --new)
            new_mode="true"
            if [ $# -gt 1 ] && [ "${2#-}" = "$2" ]; then
                new_title="$2"
                shift
            fi
            ;;
        --version|-v)
            echo "kewt version git"
            exit 0
            ;;
        --post)
            post_mode="true"
            if [ $# -gt 1 ] && [ "${2#-}" = "$2" ]; then
                post_title="$2"
                shift
            fi
            ;;
        --generate-template)
            generate_template_path="template.html"
            if [ $# -gt 1 ] && [ "${2#-}" = "$2" ]; then
                generate_template_path="$2"
                shift
            fi
            generate_template "$generate_template_path"
            ;;
        --update)
            update_dir="."
            if [ $# -gt 1 ] && [ "${2#-}" = "$2" ]; then
                update_dir="$2"
                shift
            fi
            update_site "$update_dir"
            ;;
        --from)
            [ $# -lt 2 ] && die "--from requires a value."
            src="$2"
            shift
            ;;
        --to)
            [ $# -lt 2 ] && die "--to requires a value."
            out="$2"
            shift
            ;;
        --*)
            die "Unknown option: $1"
            ;;
        *)
            positional_count=$((positional_count + 1))
            if [ "$positional_count" -eq 1 ]; then
                if [ -z "$src" ]; then src="$1"; else die "Source already set (use either positional or --from)."; fi
            elif [ "$positional_count" -eq 2 ]; then
                if [ -z "$out" ]; then out="$1"; else die "Output already set (use either positional or --to)."; fi
            else
                die "Too many positional arguments."
            fi
            ;;
    esac
    shift
done

[ "$new_mode" = "true" ] && create_new_site "$new_title"



if [ -z "$src" ]; then
    if [ "$post_mode" = "true" ] && [ -f "./site.conf" ]; then
        src="."
    else
        src="site"
    fi
fi
[ -z "$out" ] && out="out"

src="${src%/}"
out="${out%/}"

if [ ! -d "$src" ]; then
    if [ "$src" = "site" ]; then
        usage
        exit 1
    else
        die "Source directory '$src' does not exist."
    fi
fi

IGNORE_ARGS="-name '.kewtignore' -o -path '$src/.*'"

if [ -f "$src/.kewtignore" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in
            ''|'#'*) continue ;;
        esac
        pattern=$(echo "$line" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
        [ -z "$pattern" ] && continue

        pattern_clean="${pattern#/}"
        pattern_clean="${pattern_clean%/}"

        if echo "$pattern" | grep -q "/"; then
             IGNORE_ARGS="$IGNORE_ARGS -o -path '$src/$pattern_clean' -o -path '$src/$pattern_clean/*'"
        else
             IGNORE_ARGS="$IGNORE_ARGS -o -name '$pattern_clean'"
        fi
    done < "$src/.kewtignore"
fi

find "$src" -name .kewtignore > "$KEWT_TMPDIR/kewt_ignore"
while read -r ki; do
    d="${ki%/.kewtignore}"
    if [ "$d" != "$src" ] && [ "$d" != "." ]; then
        IGNORE_ARGS="$IGNORE_ARGS -o -path '$d' -o -path '$d/*'"
    fi
done < "$KEWT_TMPDIR/kewt_ignore"
rm -f "$KEWT_TMPDIR/kewt_ignore"

HIDE_ARGS="-name '.kewtignore' -o -name '.kewthide' -o -name '.kewtpreserve' -o -path '$src/.*'"

if [ -f "$src/.kewthide" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in
            ''|'#'*) continue ;;
        esac
        pattern=$(echo "$line" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
        [ -z "$pattern" ] && continue

        pattern_clean="${pattern#/}"
        pattern_clean="${pattern_clean%/}"

        if echo "$pattern" | grep -q "/"; then
             HIDE_ARGS="$HIDE_ARGS -o -path '$src/$pattern_clean' -o -path '$src/$pattern_clean/*'"
        else
             HIDE_ARGS="$HIDE_ARGS -o -name '$pattern_clean'"
        fi
    done < "$src/.kewthide"
fi

find "$src" -name .kewthide > "$KEWT_TMPDIR/kewt_hide"
while read -r kh; do
    d="${kh%/.kewthide}"
    if [ "$d" != "$src" ] && [ "$d" != "." ]; then
        HIDE_ARGS="$HIDE_ARGS -o -path '$d' -o -path '$d/*'"
    fi
done < "$KEWT_TMPDIR/kewt_hide"
rm -f "$KEWT_TMPDIR/kewt_hide"

PRESERVE_ARGS="-false"

if [ -f "$src/.kewtpreserve" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in
            ''|'#'*) continue ;;
        esac
        pattern=$(echo "$line" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
        [ -z "$pattern" ] && continue

        pattern_clean="${pattern#/}"
        pattern_clean="${pattern_clean%/}"

        if echo "$pattern" | grep -q "/"; then
             PRESERVE_ARGS="$PRESERVE_ARGS -o -path '$src/$pattern_clean' -o -path '$src/$pattern_clean/*'"
        else
             PRESERVE_ARGS="$PRESERVE_ARGS -o -name '$pattern_clean'"
        fi
    done < "$src/.kewtpreserve"
fi

find "$src" -name .kewtpreserve > "$KEWT_TMPDIR/kewt_preserve"
while read -r kp; do
    d="${kp%/.kewtpreserve}"
    if [ "$d" != "$src" ] && [ "$d" != "." ]; then
        PRESERVE_ARGS="$PRESERVE_ARGS -o -path '$d' -o -path '$d/*'"
    fi
done < "$KEWT_TMPDIR/kewt_preserve"
rm -f "$KEWT_TMPDIR/kewt_preserve"

generate_nav() {
    dinfo=$(eval "find \"$1\" \( $IGNORE_ARGS -o $HIDE_ARGS -o $PRESERVE_ARGS \) -prune -o -print" | sort | AWK_SRC="$1" awk -f "$awk_dir/collect_dir_info.awk")
    find_cmd="find \"$1\" \( $IGNORE_ARGS -o $HIDE_ARGS -o $PRESERVE_ARGS \) -prune -o -name \"*.md\" -print"
    if [ -n "$posts_dir" ] && [ -d "$1/$posts_dir" ]; then
        find_cmd="$find_cmd && echo \"$1/$posts_dir/index.md\""
    fi
    eval "$find_cmd" | sort -u | AWK_SRC="$1" AWK_SINGLE_FILE_INDEX="$single_file_index" AWK_FLATTEN="$flatten" AWK_ORDER="$order" AWK_HOME_NAME="$home_name" AWK_SHOW_HOME_IN_NAV="$show_home_in_nav" AWK_DINFO="$dinfo" awk -f "$awk_dir/generate_sidebar.awk"
}

title="kewt"
style="kewt"
footer="made with <a href=\"https://kewt.krzak.org\">kewt</a>"
dir_indexes="true"
single_file_index="true"
flatten="false"
order=""
home_name="Home"
show_home_in_nav="true"
nav_links=""
nav_extra=""
footer="made with <a href=\"https://kewt.krzak.org\">kewt</a>"
logo=""
display_logo="false"
display_title="true"
logo_as_favicon="true"
favicon=""
generate_page_title="true"
error_page="not_found.html"
versioning="false"
enable_header_links="true"
base_url=""
generate_feed="false"
feed_file="rss.xml"
posts_dir=""
custom_admonitions=""

load_config() {
    [ -f "$1" ] || return
    while IFS= read -r line; do
        case "$line" in
            ''|'#'*) continue ;;
            *=*) ;;
            *) continue ;;
        esac

        key=${line%%=*}
        val=${line#*=}

        key=$(printf '%s' "$key" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
        val=$(printf '%s' "$val" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
        case "$val" in
            \"*\")
                val=${val#\"}; val=${val%\"}
                val=$(printf '%s' "$val" | sed 's/\\"/\"/g; s/\\\\/\\/g')
                ;;
            \'*\')
                val=${val#\'}; val=${val%\'}
                val=$(printf '%s' "$val" | sed "s/\\\\'/'/g; s/\\\\/\\/g")
                ;;
        esac

        case "$key" in
            title) title="$val" ;;
            style) style="${val#/}" ;;
            dir_indexes) dir_indexes="$val" ;;
            single_file_index) single_file_index="$val" ;;
            flatten) flatten="$val" ;;
            order) order="$val" ;;
            home_name) home_name="$val" ;;
            show_home_in_nav) show_home_in_nav="$val" ;;
            nav_links) nav_links="$val" ;;
            nav_extra) nav_extra="$val" ;;
            footer) footer="$val" ;;
            logo) logo="${val#/}" ;;
            display_logo) display_logo="$val" ;;
            display_title) display_title="$val" ;;
            logo_as_favicon) logo_as_favicon="$val" ;;
            favicon) favicon="${val#/}" ;;
            generate_page_title) generate_page_title="$val" ;;
            error_page) error_page="${val#/}" ;;
            versioning) versioning="$val" ;;
            enable_header_links) enable_header_links="$val" ;;
            base_url) base_url="$val" ;;
            generate_feed) generate_feed="$val" ;;
            feed_file) feed_file="${val#/}" ;;
            posts_dir) posts_dir="${val#/}" ;;
            custom_admonitions) custom_admonitions="$val" ;;
        esac
    done < "$1"
}

load_config "./site.conf"
load_config "$src/site.conf"

if [ -n "$posts_dir" ]; then
    HIDE_ARGS="$HIDE_ARGS -o -path '$src/$posts_dir/*'"
fi

[ "$post_mode" = "true" ] && create_new_post "$src" "$post_title"

asset_version=""
if [ "$versioning" = "true" ]; then
    asset_version="?v=$(date +%s)"
fi

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
    while IFS='=' read -r _fk _fv; do
        case "$_fk" in
            title) fm_title="$_fv" ;;
            date) fm_date="$_fv" ;;
            draft) fm_draft="$_fv" ;;
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

template="$src/template.html"
[ -f "$template" ] || template="./template.html"
if [ ! -f "$template" ]; then
    template="$KEWT_TMPDIR/default_template.html"
    printf '%s\n' "$DEFAULT_TMPL" > "$template"
fi

[ -d "$out" ] && rm -rf "$out"
mkdir -p "$out"

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
        dir_of_file=$(dirname "$file")
        rel_dir_of_file="${dir_of_file#"$src"}"
        rel_dir_of_file="${rel_dir_of_file#/}"
        if [ "$rel_dir_of_file" = "$posts_dir" ]; then
             temp_post_with_backlink="$KEWT_TMPDIR/post_with_backlink.md"
             printf "[< Back](index.html)\n\n" > "$temp_post_with_backlink"
             awk -f "$awk_dir/frontmatter.awk" "$file" >> "$temp_post_with_backlink"
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

    ENABLE_HEADER_LINKS="$enable_header_links" CUSTOM_ADMONITIONS="$custom_admonitions" MARKDOWN_SITE_ROOT="$src" MARKDOWN_FALLBACK_FILE="$script_dir/styles/$style.css" sh "$script_dir/markdown.sh" "$content_file" | AWK_CURRENT_URL="$current_url" AWK_TITLE="$page_title" AWK_NAV="$nav" AWK_FOOTER="$footer" AWK_STYLE_PATH="${style_path}${asset_version}" AWK_HEADER_BRAND="$header_brand" AWK_HEAD_EXTRA="$head_extra" awk -f "$awk_dir/render_template.awk" "$local_template"
}

needs_rebuild() {
    src_file="$1"
    out_file="$2"
    [ ! -f "$out_file" ] && return 0
    [ "$src_file" -nt "$out_file" ] && return 0
    [ -f "./site.conf" ] && [ "./site.conf" -nt "$out_file" ] && return 0
    [ -f "$src/site.conf" ] && [ "$src/site.conf" -nt "$out_file" ] && return 0
    [ -f "$template" ] && [ "$template" -nt "$out_file" ] && return 0
    [ -f "$script_dir/styles/$style.css" ] && [ "$script_dir/styles/$style.css" -nt "$out_file" ] && return 0
    return 1
}

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
        if grep -q '{{LIST}}' "$dir/index.md" 2>/dev/null; then
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
                    render_markdown "$md_file" "$is_home" "$target_url" > "$out_dir/index.html"
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

        find "$dir" ! -name "$(basename "$dir")" -prune ! -name ".*" -print | LC_ALL=C sort $sort_args | while read -r entry; do
            name="${entry##*/}"
            case "$name" in
                template.html|site.conf|style.css|index.md) continue ;;
            esac
            if [ -d "$entry" ]; then
                echo "- [${name}/](${name}/index.html)" >> "$temp_list"
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
                echo "- [$label](${name%.md}.html)" >> "$temp_list"
            else
                echo "- [$name]($name)" >> "$temp_list"
            fi
        done
        
        if [ "$has_custom_index" = "true" ]; then
            awk '
                /\{\{LIST\}\}/ {
                    while((getline line < "'"$temp_list"'") > 0) print line
                    close("'"$temp_list"'")
                    next
                }
                { print }
            ' "$dir/index.md" > "$temp_index"
        else
            cat "$temp_list" >> "$temp_index"
        fi

        is_home="false"; [ "$dir" = "$src" ] && is_home="true"
        target_url="/$rel_dir/index.html"
        [ "$rel_dir" = "." ] && target_url="/index.html"

        do_rebuild="false"
        needs_rebuild "$dir" "$out_dir/index.html" && do_rebuild="true"
        [ "$has_custom_index" = "true" ] && needs_rebuild "$dir/index.md" "$out_dir/index.html" && do_rebuild="true"

        if [ "$do_rebuild" = "true" ]; then
            render_markdown "$temp_index" "$is_home" "$target_url" > "$out_dir/index.html"
        fi
        rm -f "$temp_index" "$temp_list"
    fi
done

if [ -f "$script_dir/styles/$style.css" ] && needs_rebuild "$script_dir/styles/$style.css" "$out/styles.css"; then
    copy_style_with_resolved_vars "$script_dir/styles/$style.css" "$out/styles.css"
fi

eval "find \"$src\" \( $IGNORE_ARGS \) -prune -o -type f -print" | sort | while IFS= read -r file; do
    rel_path="${file#"$src"}"
    rel_path="${rel_path#/}"
    dir_rel=$(dirname "$rel_path")
    out_dir="$out/$dir_rel"

    case "${file##*/}" in
        template.html|site.conf|style.css|styles.css) continue ;;
    esac

    if [ "${file##*/}" = "index.md" ] && grep -q '{{LIST}}' "$file" 2>/dev/null; then
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
            render_markdown "$file" "$is_home" > "$out_file"
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

    find "$src" -type f -name '*.md' -path "*${posts_dir:-__no_posts__}*" -print | LC_ALL=C sort -r | while IFS= read -r post_file; do
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
        pub_date="${pub_day} ${pub_mon} ${pub_year} ${post_time}:00 +0000"

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

echo "Build complete."
