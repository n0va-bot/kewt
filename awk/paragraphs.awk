BEGIN {
    in_p = 0
    in_pre = 0
}

{
    if ($0 ~ /^<pre>/) in_pre = 1
    
    if (in_pre) {
        if (in_p) { print "</p>"; in_p = 0 }
        print
        if ($0 ~ /<\/pre>/) in_pre = 0
        next
    }

    if ($0 ~ /^<\/?(div|table|p|[ou]l|h[1-6]|[bh]r|blockquote|li|hr|section|article|nav|aside|header|footer|dl|dt|dd)/) {
        if (in_p) {
            print "</p>"
            in_p = 0
        }
        print
        next
    }

    if ($0 == "") {
        if (in_p) {
            print "</p>"
            in_p = 0
        }
        print
        next
    }

    if (!in_p) {
        print "<p>"
        in_p = 1
    }
    print
}

END {
    if (in_p) print "</p>"
}
