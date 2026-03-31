function replace_all(text, token, value, pos, token_len, res) {
    token_len = length(token)
    res = ""
    while ((pos = index(text, token)) > 0) {
        res = res substr(text, 1, pos - 1) value
        text = substr(text, pos + token_len)
    }
    return res text
}

BEGIN {
    current_url = ENVIRON["AWK_CURRENT_URL"]
    nav = ENVIRON["AWK_NAV"]
    title = ENVIRON["AWK_TITLE"]
    footer = ENVIRON["AWK_FOOTER"]
    style_path = ENVIRON["AWK_STYLE_PATH"]
    head_extra = ENVIRON["AWK_HEAD_EXTRA"]
    header_brand = ENVIRON["AWK_HEADER_BRAND"]
    lang = ENVIRON["AWK_LANG"]
    version = ENVIRON["AWK_VERSION"]
    content_warning = ENVIRON["AWK_CONTENT_WARNING"]
    if (current_url != "") {
        nav = replace_all(nav, "href=\"" current_url "\"", "href=\"" current_url "\" class=\"current-page\"")
    }
}

{
    line = $0
    line = replace_all(line, "{{TITLE}}", title)
    line = replace_all(line, "{{LANG}}", lang)
    line = replace_all(line, "{{NAV}}", nav)
    line = replace_all(line, "{{FOOTER}}", footer)
    line = replace_all(line, "{{CSS}}", style_path)
    line = replace_all(line, "{{HEAD_EXTRA}}", head_extra)
    line = replace_all(line, "{{HEADER_BRAND}}", header_brand)
    line = replace_all(line, "{{VERSION}}", version)

    pos = index(line, "{{CONTENT}}")
    if (pos > 0) {
        printf "%s", substr(line, 1, pos - 1)
        while ((getline content_line < "-") > 0) {
            gsub(/\.md\)/, ".html)", content_line)
            gsub(/\.md"/, ".html\"", content_line)
            gsub(/\.md\?/, ".html?", content_line)
            gsub(/\.md#/, ".html#", content_line)
            print content_line
        }
        printf "%s\n", substr(line, pos + 11)
    } else {
        print line
    }
}
