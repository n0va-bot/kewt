BEGIN { in_code = 0; in_html_pre = 0 }
{
    if ($0 ~ /<pre>/) in_html_pre = 1
    if ($0 ~ /<\/pre>/) { in_html_pre = 0; if (in_code) { print "</code></pre>"; in_code = 0 }; print; next }

    if (!in_html_pre && $0 ~ /^(\t|    )/) {
        if (!in_code) { printf "%s", "<pre><code>"; in_code = 1 }
        sub(/^(\t|    )/, "", $0)
        gsub(/&/, "\\&amp;"); gsub(/</, "\\&lt;"); gsub(/>/, "\\&gt;")
        print
        next
    }

    if (in_code) {
        print "</code></pre>"
        in_code = 0
    }
    print
}
END { if (in_code) print "</code></pre>" }
