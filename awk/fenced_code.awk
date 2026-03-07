BEGIN { in_fence = 0; first_line = 0 }
{
    if (!in_fence && $0 ~ /^```/) {
        in_fence = 1
        first_line = 1
        next
    }
    if (in_fence && $0 ~ /^```[[:space:]]*$/) {
        print "</code></pre>"
        in_fence = 0
        next
    }
    if (in_fence) {
        gsub(/&/, "\\&amp;"); gsub(/</, "\\&lt;"); gsub(/>/, "\\&gt;")
        if (first_line) {
            first_line = 0
            if ($0 == "") next
            print "<pre><code>" $0
        } else {
            print
        }
    } else {
        print
    }
}
END {
    if (in_fence) print "</code></pre>"
}
