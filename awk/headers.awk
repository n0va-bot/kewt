function strip_markdown(s) {
    gsub(/<[^>]+>/, "", s)
    gsub(/[*_`~]/, "", s)
    gsub(/[\[\]]/, "", s)
    gsub(/\([^\)]*\)/, "", s)
    s = tolower(s)
    gsub(/[^a-z0-9 -]/, "", s)
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", s)
    gsub(/[[:space:]]+/, "-", s)
    gsub(/-{2,}/, "-", s)
    gsub(/^-+|-+$/, "", s)
    if (length(s) > 80) s = substr(s, 1, 80)
    gsub(/-+$/, "", s)
    return s
}
function print_header(line) {
    tag = ""
    if (line ~ /^# /) { tag = "h1"; sub(/^# /, "", line) }
    else if (line ~ /^## /) { tag = "h2"; sub(/^## /, "", line) }
    else if (line ~ /^### /) { tag = "h3"; sub(/^### /, "", line) }
    else if (line ~ /^#### /) { tag = "h4"; sub(/^#### /, "", line) }
    else if (line ~ /^##### /) { tag = "h5"; sub(/^##### /, "", line) }
    else if (line ~ /^###### /) { tag = "h6"; sub(/^###### /, "", line) }

    if (tag != "") {
        id = strip_markdown(line)
        if (enable_header_links == "true") {
            print "<" tag " id=\"" id "\"><a href=\"#" id "\" class=\"header-anchor\">" line "</a></" tag ">"
        } else {
            print "<" tag " id=\"" id "\">" line "</" tag ">"
        }
    } else {
        print line
    }
}
BEGIN {
    has_prev = 0
    in_pre = 0
}
{
    if ($0 ~ /^<pre><code/) {
        in_pre = 1
        if (has_prev && prev != "") { print_header(prev); has_prev = 0 }
        print
        next
    }
    if (in_pre) {
        if ($0 ~ /<\/code><\/pre>/) in_pre = 0
        print
        next
    }

    if ($0 ~ /^=+$/) {
        if (has_prev && prev != "" && prev !~ /^<[a-z]/) {
            print "<h1 id=\"" strip_markdown(prev) "\">" prev "</h1>"
            has_prev = 0
        } else {
            if (has_prev) print_header(prev)
            print $0
            has_prev = 0
        }
    } else if ($0 ~ /^-+$/) {
        if (has_prev && prev != "" && prev !~ /^<[a-z]/) {
            print "<h2 id=\"" strip_markdown(prev) "\">" prev "</h2>"
            has_prev = 0
        } else {
            if (has_prev) print_header(prev)
            if (length($0) >= 3) print "<hr />"
            else print $0
            has_prev = 0
        }
    } else if ($0 ~ /^[*_]+$/ && length($0) >= 3) {
        if (has_prev) print_header(prev)
        print "<hr />"
        has_prev = 0
    } else {
        if (has_prev) {
            print_header(prev)
        }
        prev = $0
        has_prev = 1
    }
}
END {
    if (has_prev) {
        print_header(prev)
    }
}
