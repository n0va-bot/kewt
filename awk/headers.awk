function strip_markdown(s) {
    gsub(/<[^>]+>/, "", s)
    gsub(/[*_`~]/, "", s)
    gsub(/[\[\]]/, "", s)
    gsub(/\([^\)]*\)/, "", s)
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", s)
    gsub(/[[:space:]]+/, "-", s)
    return s
}
function print_header(line) {
    if (line ~ /^# /) {
        sub(/^# /, "", line); print "<h1 id=\"" strip_markdown(line) "\">" line "</h1>"
    } else if (line ~ /^## /) {
        sub(/^## /, "", line); print "<h2 id=\"" strip_markdown(line) "\">" line "</h2>"
    } else if (line ~ /^### /) {
        sub(/^### /, "", line); print "<h3 id=\"" strip_markdown(line) "\">" line "</h3>"
    } else if (line ~ /^#### /) {
        sub(/^#### /, "", line); print "<h4 id=\"" strip_markdown(line) "\">" line "</h4>"
    } else if (line ~ /^##### /) {
        sub(/^##### /, "", line); print "<h5 id=\"" strip_markdown(line) "\">" line "</h5>"
    } else if (line ~ /^###### /) {
        sub(/^###### /, "", line); print "<h6 id=\"" strip_markdown(line) "\">" line "</h6>"
    } else {
        print line
    }
}
BEGIN {
    has_prev = 0
    in_pre = 0
}
{
    if ($0 ~ /^<pre><code>/) {
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
