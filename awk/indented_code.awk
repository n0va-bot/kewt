BEGIN { in_code = 0 }
/^	|    / {
    if (!in_code) { print "<pre><code>"; in_code = 1 }
    sub(/^	|    /, "", $0)
    gsub(/&/, "&amp;"); gsub(/</, "&lt;"); gsub(/>/, "&gt;")
    print; next
}
{ if (in_code) { print "</code></pre>"; in_code = 0 } print }
END { if (in_code) print "</code></pre>" }
