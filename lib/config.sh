DEFAULT_CONF='title = "kewt"
style = "kewt"
lang = "en"
draft_by_default = false
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
posts_per_page = 12
custom_admonitions = ""
cw_hide_url = true
generate_tags = false
tags_dir = "tags"
generate_search = false
search_in_footer = false
search_in_header = false
include_cw_pages_in_search = false'

DEFAULT_TMPL='<!doctype html>
<html lang="{{LANG}}">
    <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <title>{{TITLE}}</title>

        <link rel="stylesheet" href="{{CSS}}{{VERSION}}" type="text/css" />
        {{HEAD_EXTRA}}
    </head>

    <body>
        <input type="checkbox" id="nav-toggle" class="nav-toggle" aria-hidden="true" />
        <header>
            <h1>{{HEADER_BRAND}}</h1>
            <label for="nav-toggle" class="nav-toggle-label" aria-hidden="true">&#9776;</label>
        </header>

        <nav id="side-bar">{{NAV}}</nav>

        <article>{{CONTENT}}</article>
        <footer>{{FOOTER}}</footer>
    </body>
</html>'

title="kewt"
style="kewt"
lang="en"
draft_by_default="false"
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
posts_per_page="12"
custom_admonitions=""
cw_hide_url="true"
generate_tags="false"
tags_dir="tags"
generate_search="false"
search_in_footer="false"
search_in_header="false"
include_cw_pages_in_search="false"

load_config() {
    [ -f "$1" ] || return
    while IFS= read -r line || [ -n "$line" ]; do
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
            posts_per_page) posts_per_page="$val" ;;
            custom_admonitions) custom_admonitions="$val" ;;
            cw_hide_url) cw_hide_url="$val" ;;
            lang) lang="$val" ;;
            draft_by_default) draft_by_default="$val" ;;
            generate_tags) generate_tags="$val" ;;
            tags_dir) tags_dir="${val#/}" ;;
            generate_search) generate_search="$val" ;;
            search_in_footer) search_in_footer="$val" ;;
            search_in_header) search_in_header="$val" ;;
            include_cw_pages_in_search) include_cw_pages_in_search="$val" ;;
        esac
    done < "$1"
}
