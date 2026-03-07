function replace_all(text, token, value, pos, token_len) {
    token_len = length(token)
    while ((pos = index(text, token)) > 0) {
        text = substr(text, 1, pos - 1) value substr(text, pos + token_len)
    }
    return text
}

{
    line = $0
    line = replace_all(line, "{{TITLE}}", title)
    line = replace_all(line, "{{NAV}}", nav)
    line = replace_all(line, "{{FOOTER}}", footer)
    line = replace_all(line, "{{CSS}}", style_path)
    line = replace_all(line, "{{HEAD_EXTRA}}", head_extra)
    line = replace_all(line, "{{HEADER_BRAND}}", header_brand)

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
