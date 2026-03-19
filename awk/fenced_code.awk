BEGIN { in_fence = 0; first_line = 0; code_tag = "<code>" }
{
    if (!in_fence && $0 ~ /^```/) {
        in_fence = 1
        first_line = 1
        lang = $0
        sub(/^```[[:space:]]*/, "", lang)
        sub(/[[:space:]]*$/, "", lang)
        if (lang != "") {
            code_tag = "<code class=\"language-" lang "\">"
        } else {
            code_tag = "<code>"
        }
        next
    }
    if (in_fence && $0 ~ /^```[[:space:]]*$/) {
        if (first_line) printf "%s", "<pre>" code_tag
        print "</code></pre>"
        in_fence = 0
        next
    }
    if (in_fence) {
        gsub(/&/, "\\&amp;"); gsub(/</, "\\&lt;"); gsub(/>/, "\\&gt;")
        if (first_line) {
            first_line = 0
            printf "%s", "<pre>" code_tag
            if ($0 == "") {
                print ""
                next
            }
            print $0
        } else {
            print
        }
    } else {
        print
    }
}
END {
    if (in_fence) {
        if (first_line) printf "%s", "<pre>" code_tag
        print "</code></pre>"
    }
}
