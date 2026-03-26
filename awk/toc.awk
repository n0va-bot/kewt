BEGIN {
    toc_str = "<ol class=\"toc\">\n"
    has_toc = 0
}
{
    lines[++n] = $0
    if ($0 ~ /<pre>/) in_pre = 1
    if (!in_pre && $0 ~ /\{\{TOC\}\}/) {
        has_toc = 1
        toc_lines[n] = 1
    }
    if ($0 ~ /<\/pre>/) in_pre = 0
    if (match($0, /<h[23][^>]*>/)) {
        tag_len = RLENGTH
        title_start = RSTART + tag_len
        title_str = substr($0, title_start)
        title_end = index(title_str, "</h")
        if (title_end > 0) {
            title = substr(title_str, 1, title_end - 1)
            gsub(/<[^>]+>/, "", title)
            
            # extract id
            id_start = match($0, /id="[^"]*"/)
            if (id_start > 0) {
                id_str = substr($0, id_start + 4)
                id_end = index(id_str, "\"")
                id = substr(id_str, 1, id_end - 1)
                
                # what tag? level
                level = substr($0, match($0, /<h[23]/) + 2, 1)
                
                if (level == "2") {
                    toc_str = toc_str "<li class=\"toc-h2\"><a href=\"#" id "\">" title "</a></li>\n"
                } else if (level == "3") {
                    toc_str = toc_str "<li class=\"toc-h3\"><a href=\"#" id "\">" title "</a></li>\n"
                }
            }
        }
    }
}
END {
    toc_str = toc_str "</ol>"
    for (i = 1; i <= n; i++) {
        if (has_toc && toc_lines[i] && lines[i] ~ /^[[:space:]]*\{\{TOC\}\}[[:space:]]*$/) {
            toc_lines[i] = 0 # Mark as processed if we want, but not strictly needed
            sub(/\{\{TOC\}\}/, toc_str, lines[i])
        }
        print lines[i]
    }
}
