BEGIN {
    depth = 0
    in_pre = 0
}

{
    if ($0 ~ /^<pre>/) in_pre = 1
    if (in_pre) {
        while (depth > 0) { print "</" cur_type[depth] ">"; depth-- }
        print
        if ($0 ~ /<\/pre>/) in_pre = 0
        next
    }

    line = $0
    type = ""
    # match list marker and its preceding spaces
    if (line ~ /^[ \t]*[*+-] /) {
        type = "ul"
        match(line, /^[ \t]*[*+-] /)
        marker_len = RLENGTH
    } else if (line ~ /^[ \t]*[0-9]+\. /) {
        type = "ol"
        match(line, /^[ \t]*[0-9]+\. /)
        marker_len = RLENGTH
    }

    if (type != "") {
        content = substr(line, marker_len + 1)
        # get indentation level
        match(line, /^[ \t]*/)
        indent = RLENGTH
        
        if (depth == 0 || indent > cur_indent[depth]) {
            depth++
            cur_indent[depth] = indent
            cur_type[depth] = type
            print "<" type ">"
        } else {
            while (depth > 1 && indent < cur_indent[depth]) {
                print "</" cur_type[depth] ">"
                depth--
            }
            if (type != cur_type[depth]) {
                print "</" cur_type[depth] ">"
                cur_type[depth] = type
                print "<" type ">"
            }
        }

        has_checkbox = 0
        if (content ~ /^\[[ \t]\] /) {
            has_checkbox = 1
            is_checked = 0
            sub(/^\[[ \t]\] /, "", content)
        } else if (content ~ /^\[[xX]\] /) {
            has_checkbox = 1
            is_checked = 1
            sub(/^\[[xX]\] /, "", content)
        }

        if (has_checkbox) {
            if (is_checked) {
                print "<li class=\"task-list-item\"><input type=\"checkbox\" class=\"task-list-item-checkbox\" checked disabled> " content "</li>"
            } else {
                print "<li class=\"task-list-item\"><input type=\"checkbox\" class=\"task-list-item-checkbox\" disabled> " content "</li>"
            }
        } else {
            print "<li>" content "</li>"
        }
    } else {
        while (depth > 0) {
            print "</" cur_type[depth] ">"
            depth--
        }
        print line
    }
}

END {
    while (depth > 0) {
        print "</" cur_type[depth] ">"
        depth--
    }
}
