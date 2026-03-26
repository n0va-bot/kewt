BEGIN {
    in_dl = 0
    has_prev = 0
    prev_line = ""
    in_pre = 0
}
{
    if ($0 ~ /^<pre>/) {
        if (!in_pre) in_pre = 1
    }
    
    if (!in_pre && $0 ~ /^:[ \t]+[^ \t]/) {
        if (!in_dl) {
            in_dl = 1
            print "<dl>"
            print "<dt>" prev_line "</dt>"
            has_prev = 0
        } else {
            if (has_prev && prev_line != "") {
                print "<dt>" prev_line "</dt>"
                has_prev = 0
            }
        }
        def_text = $0
        sub(/^:[ \t]+/, "", def_text)
        print "<dd>" def_text "</dd>"
        
        if ($0 ~ /<\/pre>/) {
            if (in_pre) in_pre = 0
        }
        next
    } else {
        if (in_dl) {
            if ($0 == "") {
                # End of definition list
                print "</dl>"
                in_dl = 0
                print ""
                has_prev = 0
                next
            }
        }
        if (has_prev) {
            print prev_line
        }
        prev_line = $0
        has_prev = 1
    }
    
    if ($0 ~ /<\/pre>/) {
        if (in_pre) in_pre = 0
    }
}
END {
    if (in_dl) {
        print "</dl>"
    } else {
        if (has_prev) {
            print prev_line
        }
    }
}
