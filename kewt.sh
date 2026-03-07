#!/bin/sh

die() {
    echo "Error: $1" >&2
    exit 1
}

usage() {
    cat <<EOF
Usage: $0 [--from <src>] [--to <out>]
       $0 [src] [out]
       $0 --new [title]
       $0 --help

Options:
  --help         Show this help message.
  --new [title]  Create a new site directory (default: site)
  --from <src>   Source directory (default: site)
  --to <out>     Output directory (default: out)
EOF
}

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
awk_dir="$script_dir/awk"

ensure_root_defaults() {
    if [ ! -f "./site.conf" ]; then
        cat > "./site.conf" <<'EOF'
title = "kewt"
style = "kewt"
dir_indexes = true
single_file_index = true
flatten = false
footer = "made with <a href="https://git.krzak.org/N0VA/kewt">kewt</a>"
logo = ""
display_logo = false
display_title = true
logo_as_favicon = true
favicon = ""
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
        awk -v new_title="$new_title" '
            BEGIN { done = 0 }
            /^title[[:space:]]*=/ {
                print "title = \"" new_title "\""
                done = 1
                next
            }
            { print }
            END {
                if (!done) print "title = \"" new_title "\""
            }
        ' "$new_dir/site.conf" > "$new_dir/site.conf.tmp" && mv "$new_dir/site.conf.tmp" "$new_dir/site.conf"
    fi

    echo "Created new site at '$new_dir'."
    exit 0
}

generate_nav() {
    dinfo=$(find "$1" -not -path '*/.*' | sort -r | awk -v src="$1" -f "$awk_dir/collect_dir_info.awk")
    find "$1" -name "*.md" | sort | awk -v src="$1" -v single_file_index="$single_file_index" -v flatten="$flatten" -v dinfo="$dinfo" -f "$awk_dir/generate_sidebar.awk"
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
                [ -z "$src" ] && src="$1" || die "Source already set (use either positional or --from)."
            elif [ "$positional_count" -eq 2 ]; then
                [ -z "$out" ] && out="$1" || die "Output already set (use either positional or --to)."
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

[ -d "$src" ] || die "Source directory '$src' does not exist."

title="kewt"
style="kewt"
footer="made with <a href=\"https://kewt.krzak.org\">kewt</a>"
dir_indexes="true"
single_file_index="true"
flatten="false"
logo=""
display_logo="false"
display_title="true"
logo_as_favicon="true"
favicon=""

load_config() {
    [ -f "$1" ] || return
    while IFS='= ' read -r key val; do
        val=$(echo "$val" | tr -d '" ' | tr -d "'")
        case "$key" in
            title) ;;
            style) style="$val" ;;
            dir_indexes) dir_indexes="$val" ;;
            single_file_index) single_file_index="$val" ;;
            flatten) flatten="$val" ;;
            footer) footer="$val" ;;
            logo) logo="$val" ;;
            display_logo) display_logo="$val" ;;
            display_title) display_title="$val" ;;
            logo_as_favicon) logo_as_favicon="$val" ;;
            favicon) favicon="$val" ;;
        esac
    done < "$1"

    t=$(grep "^title" "$1" | cut -d= -f2- | sed 's/^[ "]*//;s/[ "]*$//')
    [ -n "$t" ] && title="$t"
}

load_config "./site.conf"
load_config "$src/site.conf"

template="$src/template.html"
[ -f "$template" ] || template="./template.html"
[ -f "$template" ] || die "Template '$template' not found."

[ -d "$out" ] && rm -rf "$out"
mkdir -p "$out"

nav=$(generate_nav "$src")

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
        style_rel_to_src="${closest_style_src#$src/}"
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

    MARKDOWN_SITE_ROOT="$src" MARKDOWN_FALLBACK_FILE="styles/$style.css" sh "$script_dir/markdown.sh" "$file" | awk -v title="$title" -v nav="$nav" -v footer="$footer" -v style_path="$style_path" -v header_brand="$header_brand" -v head_extra="$head_extra" -f "$awk_dir/render_template.awk" "$local_template"
}

echo "Building site from '$src' to '$out'..."

find "$src" -type d | sort | while read -r dir; do
    rel_dir="${dir#$src/}"
    [ "$dir" = "$src" ] && rel_dir="."
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
            md_count=$(find "$dir" -maxdepth 1 -name "*.md" | wc -l)
            if [ "$md_count" -eq 1 ]; then
                md_file=$(find "$dir" -maxdepth 1 -name "*.md")
                render_markdown "$md_file" > "$out_dir/index.html"
                continue
            fi
        fi

        temp_index="/tmp/kewt_index_$$.md"
        display_dir="${rel_dir#.}"
        [ -z "$display_dir" ] && display_dir="/"
        echo "# Index of $display_dir" > "$temp_index"
        echo "" >> "$temp_index"
        find "$dir" -maxdepth 1 -not -path '*/.*' -not -path "$dir" | sort | while read -r entry; do
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

if [ ! -f "$out/styles.css" ] && [ -f "styles/$style.css" ]; then
    copy_style_with_resolved_vars "styles/$style.css" "$out/styles.css"
fi

find "$src" -type f | sort | while IFS= read -r file; do
    rel_path="${file#$src/}"
    dir_rel=$(dirname "$rel_path")
    out_dir="$out/$dir_rel"

    case "${file##*/}" in
        template.html|site.conf|style.css|styles.css) continue ;;
    esac

    if [ "$single_file_index" = "true" ] && [ "${file%.md}" != "$file" ] && [ ! -f "$(dirname "$file")/index.md" ]; then
        md_count=$(find "$(dirname "$file")" -maxdepth 1 -name "*.md" | wc -l)
        [ "$md_count" -eq 1 ] && continue
    fi

    if [ "${file%.md}" != "$file" ]; then
        out_file="$out/${rel_path%.md}.html"
        render_markdown "$file" > "$out_file"
    else
        cp "$file" "$out/$rel_path"
    fi
done

echo "Build complete."
