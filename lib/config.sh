#!/bin/sh

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
            {{HEADER_SEARCH}}
            <label for="nav-toggle" class="nav-toggle-label" aria-hidden="true">&#9776;</label>
        </header>

        <nav id="side-bar">{{NAV}}</nav>

        <article>{{CONTENT}}</article>
        <footer>{{FOOTER}}</footer>
    </body>
</html>'

_parse_conf_val() {
    _pv_val="$1"
    case "$_pv_val" in
        \"*\")
            _pv_val=${_pv_val#\"}
            _pv_val=${_pv_val%\"}
            printf '%s' "$_pv_val" | sed 's/\\"/\"/g; s/\\\\/\\/g'
            ;;
        \'*\')
            _pv_val=${_pv_val#\'}
            _pv_val=${_pv_val%\'}
            printf '%s' "$_pv_val" | sed "s/\\\\'/'/g; s/\\\\/\\/g"
            ;;
        *)
            printf '%s' "$_pv_val"
            ;;
    esac
}

_load_conf_line() {
    case "$1" in
        ''|'#'*) return ;;
        *=*) ;;
        *) return ;;
    esac

    _lc_key=${1%%=*}
    _lc_val=${1#*=}
    _lc_key=$(printf '%s' "$_lc_key" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
    _lc_val=$(_parse_conf_val "$(printf '%s' "$_lc_val" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')")

    case "$_lc_key" in
        title) title="$_lc_val" ;;
        style) style="${_lc_val#/}" ;;
        dir_indexes) dir_indexes="$_lc_val" ;;
        single_file_index) single_file_index="$_lc_val" ;;
        flatten) flatten="$_lc_val" ;;
        order) order="$_lc_val" ;;
        home_name) home_name="$_lc_val" ;;
        show_home_in_nav) show_home_in_nav="$_lc_val" ;;
        nav_links) nav_links="$_lc_val" ;;
        nav_extra) nav_extra="$_lc_val" ;;
        footer) footer="$_lc_val" ;;
        logo) logo="${_lc_val#/}" ;;
        display_logo) display_logo="$_lc_val" ;;
        display_title) display_title="$_lc_val" ;;
        logo_as_favicon) logo_as_favicon="$_lc_val" ;;
        favicon) favicon="${_lc_val#/}" ;;
        generate_page_title) generate_page_title="$_lc_val" ;;
        error_page) error_page="${_lc_val#/}" ;;
        versioning) versioning="$_lc_val" ;;
        enable_header_links) enable_header_links="$_lc_val" ;;
        base_url) base_url="$_lc_val" ;;
        generate_feed) generate_feed="$_lc_val" ;;
        feed_file) feed_file="${_lc_val#/}" ;;
        posts_dir) posts_dir="${_lc_val#/}" ;;
        posts_per_page) posts_per_page="$_lc_val" ;;
        custom_admonitions) custom_admonitions="$_lc_val" ;;
        cw_hide_url) cw_hide_url="$_lc_val" ;;
        lang) lang="$_lc_val" ;;
        draft_by_default) draft_by_default="$_lc_val" ;;
        generate_tags) generate_tags="$_lc_val" ;;
        tags_dir) tags_dir="${_lc_val#/}" ;;
        generate_search) generate_search="$_lc_val" ;;
        search_in_footer) search_in_footer="$_lc_val" ;;
        search_in_header) search_in_header="$_lc_val" ;;
        include_cw_pages_in_search) include_cw_pages_in_search="$_lc_val" ;;
    esac
}

reset_config() {
    while IFS= read -r _rc_line; do
        _load_conf_line "$_rc_line"
    done <<EOF
$DEFAULT_CONF
EOF
}

load_config() {
    [ -f "$1" ] || return
    while IFS= read -r _lc_line || [ -n "$_lc_line" ]; do
        _load_conf_line "$_lc_line"
    done < "$1"
}

reset_config
