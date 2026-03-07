function strip_markdown(s) {
    gsub(/<[^>]+>/, "", s)
    gsub(/[*_`~]/, "", s)
    gsub(/[\[\]]/, "", s)
    gsub(/\([^\)]*\)/, "", s)
    sub(/^[[:space:]]*/, "", s)
    sub(/[[:space:]]*$/, "", s)
    return s
}
BEGIN {
    has_prev = 0
    in_pre = 0
}
{
    if ($0 ~ /^<pre><code>/) {
        in_pre = 1
        if (has_prev && prev != "") { print prev; has_prev = 0 }
        print
        next
    }
    if (in_pre) {
        if ($0 ~ /<\/code><\/pre>/) in_pre = 0
        print
        next
    }

    if ($0 ~ /^=+$/ && has_prev && prev != "" && prev !~ /^<[a-z]/) {
        print "<h1 id=\"" strip_markdown(prev) "\">" prev "</h1>"
        has_prev = 0
    } else if ($0 ~ /^-+$/ && has_prev && prev != "" && prev !~ /^<[a-z]/) {
        print "<h2 id=\"" strip_markdown(prev) "\">" prev "</h2>"
        has_prev = 0
    } else {
        if (has_prev) {
            line = prev
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
                print prev
            }
        }
        prev = $0
        has_prev = 1
    }
}
END {
    if (has_prev) {
        line = prev
        if (line ~ /^# /) {
            sub(/^# /, "", line); print "<h1 id=\"" strip_markdown(line) "\">" line "</h1>"
        } else {
            print prev
        }
    }
}
