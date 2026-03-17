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
       $invoked_as --help

Options:
  --help         Show this help message.
  --new [title]  Create a new site directory (default: site)
  --from <src>   Source directory (default: site)
  --to <out>     Output directory (default: out)
EOF
}

script_dir=$(CDPATH="" cd -- "$(dirname -- "$0")" && pwd)
awk_dir="$script_dir/awk"

KEWT_TMPDIR=$(mktemp -d "/tmp/kewt_run.XXXXXX")
trap 'rm -rf "$KEWT_TMPDIR"' EXIT HUP INT TERM

ensure_root_defaults() {
    if [ ! -f "./site.conf" ]; then
        cat > "./site.conf" <<'EOF'
title = "kewt"
style = "kewt"
dir_indexes = true
single_file_index = true
flatten = false
order = ""
home_name = "Home"
show_home_in_nav = true
nav_links = ""
nav_extra = ""
footer = "made with <a href="https://kewt.krzak.org">kewt</a>"
logo = ""
display_logo = false
display_title = true
logo_as_favicon = true
favicon = ""
generate_page_title = true
error_page = "not_found.html"
versioning = false
EOF
    fi

    if [ ! -f "./template.html" ]; then
        cat > "./template.html" <<'EOF'
<!doctype html>
<html>
    <head>
        <meta charset="UTF-8" />
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
</html>
EOF
    fi
}

create_new_site() {
    new_title="$1"
    new_dir="site"
    [ -n "$new_title" ] && new_dir="$new_title"

    [ -e "$new_dir" ] && die "Target '$new_dir' already exists."

    ensure_root_defaults

    mkdir -p "$new_dir"
    cp "./site.conf" "$new_dir/site.conf"
    printf "# _kewt_ website\n" > "$new_dir/index.md"

    if [ -n "$new_title" ]; then
        awk -v new_title="$new_title" -f "$awk_dir/update_site_conf.awk" "$new_dir/site.conf" > "$new_dir/site.conf.tmp" && mv "$new_dir/site.conf.tmp" "$new_dir/site.conf"
    fi

    echo "Created new site at '$new_dir'."
    exit 0
}



src=""
out=""
new_mode="false"
new_title=""
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

ensure_root_defaults

[ -z "$src" ] && src="site"
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
    dinfo=$(eval "find \"$1\" \( $IGNORE_ARGS -o $HIDE_ARGS -o $PRESERVE_ARGS \) -prune -o -print" | sort | awk -v src="$1" -f "$awk_dir/collect_dir_info.awk")
    eval "find \"$1\" \( $IGNORE_ARGS -o $HIDE_ARGS -o $PRESERVE_ARGS \) -prune -o -name \"*.md\" -print" | sort | awk -v src="$1" -v single_file_index="$single_file_index" -v flatten="$flatten" -v order="$order" -v home_name="$home_name" -v show_home_in_nav="$show_home_in_nav" -v dinfo="$dinfo" -f "$awk_dir/generate_sidebar.awk"
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
            \"*\") val=${val#\"}; val=${val%\"} ;;
            \'*\') val=${val#\'}; val=${val%\'} ;;
        esac

        case "$key" in
            title) title="$val" ;;
            style) style="$val" ;;
            dir_indexes) dir_indexes="$val" ;;
            single_file_index) single_file_index="$val" ;;
            flatten) flatten="$val" ;;
            order) order="$val" ;;
            home_name) home_name="$val" ;;
            show_home_in_nav) show_home_in_nav="$val" ;;
            nav_links) nav_links="$val" ;;
            nav_extra) nav_extra="$val" ;;
            footer) footer="$val" ;;
            logo) logo="$val" ;;
            display_logo) display_logo="$val" ;;
            display_title) display_title="$val" ;;
            logo_as_favicon) logo_as_favicon="$val" ;;
            favicon) favicon="$val" ;;
            generate_page_title) generate_page_title="$val" ;;
            error_page) error_page="$val" ;;
            versioning) versioning="$val" ;;
        esac
    done < "$1"
}

load_config "./site.conf"
load_config "$src/site.conf"

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
[ -f "$template" ] || die "Template '$template' not found."

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
        head_extra="<link rel=\"icon\" href=\"$favicon_src\" />"
    fi

    page_title="$title"
    if [ "$generate_page_title" = "true" ] && [ -n "$file" ] && [ -f "$file" ]; then
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

    MARKDOWN_SITE_ROOT="$src" MARKDOWN_FALLBACK_FILE="$script_dir/styles/$style.css" sh "$script_dir/markdown.sh" "$file" | awk -v title="$page_title" -v nav="$nav" -v footer="$footer" -v style_path="${style_path}${asset_version}" -v header_brand="$header_brand" -v head_extra="$head_extra" -f "$awk_dir/render_template.awk" "$local_template"
}

echo "Building site from '$src' to '$out'..."

eval "find \"$src\" \( $IGNORE_ARGS \) -prune -o -type d -print" | sort | while read -r dir; do
    rel_dir="${dir#"$src"}"
    rel_dir="${rel_dir#/}"
    [ -z "$rel_dir" ] && rel_dir="."
    out_dir="$out/$rel_dir"
    mkdir -p "$out_dir"

    if [ -f "$dir/styles.css" ]; then
        copy_style_with_resolved_vars "$dir/styles.css" "$out_dir/styles.css"
    elif [ -f "$dir/style.css" ]; then
        copy_style_with_resolved_vars "$dir/style.css" "$out_dir/styles.css"
    fi

    [ "$dir_indexes" != "true" ] && continue

    if [ ! -f "$dir/index.md" ]; then
        if [ "$single_file_index" = "true" ]; then
            md_count=$(find "$dir" ! -name "$(basename "$dir")" -prune -name "*.md" | wc -l)
            if [ "$md_count" -eq 1 ]; then
                md_file=$(find "$dir" ! -name "$(basename "$dir")" -prune -name "*.md")
                render_markdown "$md_file" > "$out_dir/index.html"
                continue
            fi
        fi

        temp_index="$KEWT_TMPDIR/index.md"
        display_dir="${rel_dir#.}"
        [ -z "$display_dir" ] && display_dir="/"
        echo "# Index of $display_dir" > "$temp_index"
        echo "" >> "$temp_index"
        find "$dir" ! -name "$(basename "$dir")" -prune ! -name ".*" -print | sort | while read -r entry; do
            name="${entry##*/}"
            case "$name" in
                template.html|site.conf|style.css|index.md) continue ;;
            esac
            if [ -d "$entry" ]; then
                echo "- [${name}/](${name}/index.html)" >> "$temp_index"
            elif [ "${entry%.md}" != "$entry" ]; then
                echo "- [${name%.md}](${name%.md}.html)" >> "$temp_index"
            else
                echo "- [$name]($name)" >> "$temp_index"
            fi
        done
        render_markdown "$temp_index" > "$out_dir/index.html"
        rm "$temp_index"
    fi
done

if [ ! -f "$out/styles.css" ] && [ -f "$script_dir/styles/$style.css" ]; then
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

    is_preserved=0
    if [ -n "$(eval "find \"$file\" \( $PRESERVE_ARGS \) -print")" ]; then
        is_preserved=1
    fi

    if [ "$single_file_index" = "true" ] && [ "${file%.md}" != "$file" ] && [ "$is_preserved" -eq 0 ] && [ ! -f "$(dirname "$file")/index.md" ]; then
        md_count=$(find "$(dirname "$file")" ! -name "$(basename "$(dirname "$file")")" -prune -name "*.md" | wc -l)
        [ "$md_count" -eq 1 ] && continue
    fi

    if [ "${file%.md}" != "$file" ] && [ "$is_preserved" -eq 0 ]; then
        out_file="$out/${rel_path%.md}.html"
        render_markdown "$file" > "$out_file"
    else
        cp "$file" "$out/$rel_path"
    fi
done

if [ -n "$error_page" ] && [ ! -f "$out/$error_page" ]; then
    temp_404="$KEWT_TMPDIR/404_gen.md"
    echo "# 404 - Not Found" > "$temp_404"
    echo "" >> "$temp_404"
    echo "The requested page could not be found." >> "$temp_404"
    render_markdown "$temp_404" > "$out/$error_page"
    rm -f "$temp_404"
fi

echo "Build complete."
