BEGIN {
    in_pre = 0
}

function mask_html_tags(s,    out, rest, start, len, tag, token) {
    out = ""
    rest = s
    html_tag_count = 0
    while (match(rest, /<[^>]+>/)) {
        out = out substr(rest, 1, RSTART - 1)
        start = RSTART
        len = RLENGTH
        tag = substr(rest, start, len)
        html_tag_count++
        html_tag_token[html_tag_count] = "\034HT" html_tag_count "\034"
        html_tag_value[html_tag_count] = tag
        out = out html_tag_token[html_tag_count]
        rest = substr(rest, start + len)
    }
    return out rest
}

function restore_html_tags(s,    i, val) {
    for (i = 1; i <= html_tag_count; i++) {
        val = html_tag_value[i]
        gsub(/&/, "\\\\&", val)
        gsub(html_tag_token[i], val, s)
    }
    return s
}

{
    if ($0 ~ /<pre>/) {
        in_pre = 1
    }

    if (in_pre) {
        print
        if ($0 ~ /<\/pre>/) {
            in_pre = 0
        }
        next
    }

    line = $0

    # automatic links
    while (match(line, /<https?:\/\/[^>]+>/)) {
        start = RSTART; len = RLENGTH
        url = substr(line, start + 1, len - 2)
        repl = "<a href=\"" url "\">" url "</a>"
        line = substr(line, 1, start - 1) repl substr(line, start + len)
    }

    # automatic email address links
    while (match(line, /<[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}>/)) {
        start = RSTART; len = RLENGTH
        email = substr(line, start + 1, len - 2)
        repl = "<a href=\"mailto:" email "\">" email "</a>"
        line = substr(line, 1, start - 1) repl substr(line, start + len)
    }

    # typed embeds: !i, !v, !a, !f, !e
    while (match(line, /![ivafe]\[[^\]]*\]\([^\)]+ "[^"]*"\)/)) {
        start = RSTART; len = RLENGTH
        token = substr(line, start, len)
        etype = substr(token, 2, 1)
        match(token, /\[[^\]]*\]/); alt = substr(token, RSTART + 1, RLENGTH - 2)
        match(token, /"[^"]*"/); etitle = substr(token, RSTART + 1, RLENGTH - 2)
        match(token, /\([^\)]+/); inner = substr(token, RSTART + 1, RLENGTH - 1)
        sub(/[[:space:]]*"[^"]*"/, "", inner); src = inner
        repl = "<img data-embed-type=\"" etype "\" alt=\"" alt "\" src=\"" src "\" title=\"" etitle "\" />"
        line = substr(line, 1, start - 1) repl substr(line, start + len)
    }
    while (match(line, /![ivafe]\[[^\]]*\]\([^\)]+\)/)) {
        start = RSTART; len = RLENGTH
        token = substr(line, start, len)
        etype = substr(token, 2, 1)
        match(token, /\[[^\]]*\]/); alt = substr(token, RSTART + 1, RLENGTH - 2)
        match(token, /\([^\)]+/); src = substr(token, RSTART + 1, RLENGTH - 1)
        repl = "<img data-embed-type=\"" etype "\" alt=\"" alt "\" src=\"" src "\" />"
        line = substr(line, 1, start - 1) repl substr(line, start + len)
    }
    while (match(line, /![ivafe]\[[^\]]+\]/)) {
        start = RSTART; len = RLENGTH
        token = substr(line, start, len)
        etype = substr(token, 2, 1)
        src = substr(token, 4, len - 4)
        repl = "<img data-embed-type=\"" etype "\" src=\"" src "\" />"
        line = substr(line, 1, start - 1) repl substr(line, start + len)
    }

    # force-inline image syntax (double bang)
    while (match(line, /!!\[[^\]]*\]\([^\)]+ "[^"]*"\)/)) {
        start = RSTART; len = RLENGTH
        token = substr(line, start, len)
        match(token, /\[[^\]]*\]/); alt = substr(token, RSTART + 1, RLENGTH - 2)
        match(token, /"[^"]*"/); title = substr(token, RSTART + 1, RLENGTH - 2)
        match(token, /\([^\)]+/); inner = substr(token, RSTART + 1, RLENGTH - 1)
        sub(/[[:space:]]*"[^"]*"/, "", inner); src = inner
        repl = "<img data-force-inline=\"1\" alt=\"" alt "\" src=\"" src "\" title=\"" title "\" />"
        line = substr(line, 1, start - 1) repl substr(line, start + len)
    }
    while (match(line, /!!\[[^\]]*\]\([^\)]+\)/)) {
        start = RSTART; len = RLENGTH
        token = substr(line, start, len)
        match(token, /\[[^\]]*\]/); alt = substr(token, RSTART + 1, RLENGTH - 2)
        match(token, /\([^\)]+/); src = substr(token, RSTART + 1, RLENGTH - 1)
        repl = "<img data-force-inline=\"1\" alt=\"" alt "\" src=\"" src "\" />"
        line = substr(line, 1, start - 1) repl substr(line, start + len)
    }

    # inline image
    while (match(line, /!\[[^\]]*\]\([^\)]+ "[^"]*"\)/)) {
        start = RSTART; len = RLENGTH
        if (start > 1 && substr(line, start - 1, 1) == "\\") break
        token = substr(line, start, len)
        match(token, /\[[^\]]*\]/); alt = substr(token, RSTART + 1, RLENGTH - 2)
        match(token, /"[^"]*"/); title = substr(token, RSTART + 1, RLENGTH - 2)
        match(token, /\([^\)]+/); inner = substr(token, RSTART + 1, RLENGTH - 1)
        sub(/[[:space:]]*"[^"]*"/, "", inner); src = inner
        repl = "<img alt=\"" alt "\" src=\"" src "\" title=\"" title "\" />"
        line = substr(line, 1, start - 1) repl substr(line, start + len)
    }
    while (match(line, /!\[[^\]]*\]\([^\)]+\)/)) {
        start = RSTART; len = RLENGTH
        if (start > 1 && substr(line, start - 1, 1) == "\\") break
        token = substr(line, start, len)
        match(token, /\[[^\]]*\]/); alt = substr(token, RSTART + 1, RLENGTH - 2)
        match(token, /\([^\)]+/); src = substr(token, RSTART + 1, RLENGTH - 1)
        repl = "<img alt=\"" alt "\" src=\"" src "\" />"
        line = substr(line, 1, start - 1) repl substr(line, start + len)
    }

    # inline link
    while (match(line, /\[[^\]]*\]\([^\)]+ "[^"]*"\)/)) {
        start = RSTART; len = RLENGTH
        if (start > 1 && (substr(line, start - 1, 1) == "\\" || substr(line, start - 1, 1) == "!")) break
        token = substr(line, start, len)
        match(token, /\[[^\]]*\]/); text = substr(token, RSTART + 1, RLENGTH - 2)
        match(token, /"[^"]*"/); title = substr(token, RSTART + 1, RLENGTH - 2)
        match(token, /\([^\)]+/); inner = substr(token, RSTART + 1, RLENGTH - 1)
        sub(/[[:space:]]*"[^"]*"/, "", inner); href = inner
        repl = "<a href=\"" href "\" title=\"" title "\">" text "</a>"
        line = substr(line, 1, start - 1) repl substr(line, start + len)
    }
    while (match(line, /\[[^\]]*\]\([^\)]+\)/)) {
        start = RSTART; len = RLENGTH
        if (start > 1 && (substr(line, start - 1, 1) == "\\" || substr(line, start - 1, 1) == "!")) break
        token = substr(line, start, len)
        match(token, /\[[^\]]*\]/); text = substr(token, RSTART + 1, RLENGTH - 2)
        match(token, /\([^\)]+/); href = substr(token, RSTART + 1, RLENGTH - 1)
        repl = "<a href=\"" href "\">" text "</a>"
        line = substr(line, 1, start - 1) repl substr(line, start + len)
    }

    # MFM font syntax
    while (match(line, /\$\[font\.serif [^\]]+\]/)) {
        start = RSTART; len = RLENGTH
        content = substr(line, start + 13, len - 14)
        line = substr(line, 1, start - 1) "<span style=\"font-family: serif;\">" content "</span>" substr(line, start + len)
    }
    while (match(line, /\$\[font\.monospace [^\]]+\]/)) {
        start = RSTART; len = RLENGTH
        content = substr(line, start + 17, len - 18)
        line = substr(line, 1, start - 1) "<span style=\"font-family: monospace;\">" content "</span>" substr(line, start + len)
    }
    while (match(line, /\$\[font\.sans [^\]]+\]/)) {
        start = RSTART; len = RLENGTH
        content = substr(line, start + 12, len - 13)
        line = substr(line, 1, start - 1) "<span style=\"font-family: sans-serif;\">" content "</span>" substr(line, start + len)
    }

    line = mask_html_tags(line)

    # Bold, Italic, Strikethrough (BRE-like logic in AWK)
    # Strong Bold **
    while (match(line, /\*\*[^*]+\*\*/)) {
        start = RSTART; len = RLENGTH
        content = substr(line, start + 2, len - 4)
        repl = "<strong>" content "</strong>"
        line = substr(line, 1, start - 1) repl substr(line, start + len)
    }
    # Strong Bold __
    while (match(line, /__[^_]+__/)) {
        start = RSTART; len = RLENGTH
        content = substr(line, start + 2, len - 4)
        repl = "<strong>" content "</strong>"
        line = substr(line, 1, start - 1) repl substr(line, start + len)
    }
    # Italic *
    while (match(line, /\*[^*]+\*/)) {
        start = RSTART; len = RLENGTH
        content = substr(line, start + 1, len - 2)
        repl = "<em>" content "</em>"
        line = substr(line, 1, start - 1) repl substr(line, start + len)
    }
    # Italic _
    while (match(line, /_[^_]+_/)) {
        start = RSTART; len = RLENGTH
        if (start > 1 && substr(line, start - 1, 1) == "\\") break
        content = substr(line, start + 1, len - 2)
        repl = "<em>" content "</em>"
        line = substr(line, 1, start - 1) repl substr(line, start + len)
    }
    # Strikethrough ~~
    while (match(line, /~~[^~]+~~/)) {
        start = RSTART; len = RLENGTH
        content = substr(line, start + 2, len - 4)
        repl = "<strike>" content "</strike>"
        line = substr(line, 1, start - 1) repl substr(line, start + len)
    }

    line = restore_html_tags(line)

    # special characters
    if (line !~ /&[A-Za-z0-9#]+;/) {
        gsub(/&/, "&amp;", line)
    }

    p = 1
    while (match(substr(line, p), /</)) {
        start = p + RSTART - 1
        next_char = substr(line, start + 1, 1)
        if (next_char !~ /^[\/A-Za-z]/) {
            line = substr(line, 1, start - 1) "&lt;" substr(line, start + 1)
            p = start + 4
        } else {
            p = start + 1
        }
    }

    gsub(/<a href="https?:\/\/[^"]*"/, "& rel=\"noopener noreferrer\"", line)

    print line
}
