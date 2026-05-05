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
function unique_id(raw_id,    candidate) {
    candidate = raw_id
    if (candidate == "") candidate = "section"
    if (!(candidate in seen_ids)) {
        seen_ids[candidate] = 1
        return candidate
    }
    seen_ids[candidate]++
    return candidate "-" seen_ids[candidate]
}
function print_heading(tag, line,    id) {
    id = unique_id(strip_markdown(line))
    if (enable_header_links == "true") {
        print "<" tag " id=\"" id "\">" line " <a href=\"#" id "\" class=\"header-anchor\" aria-label=\"Link to this section\">#</a></" tag ">"
    } else {
        print "<" tag " id=\"" id "\">" line "</" tag ">"
    }
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
        print_heading(tag, line)
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
            print_heading("h1", prev)
            has_prev = 0
        } else {
            if (has_prev) print_header(prev)
            print $0
            has_prev = 0
        }
    } else if ($0 ~ /^-+$/) {
        if (has_prev && prev != "" && prev !~ /^<[a-z]/) {
            print_heading("h2", prev)
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
