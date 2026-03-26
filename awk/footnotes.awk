BEGIN { fn_count = 0 }

# Match [^id]: text
/^\[\^[a-zA-Z0-9_-]+\]:/ {
    id_start = index($0, "[^") + 2
    id_end = index($0, "]:")
    id = substr($0, id_start, id_end - id_start)
    text = substr($0, id_end + 2)
    # Trim leading space
    sub(/^[ \t]+/, "", text)
    
    fn_ids[++fn_count] = id
    fn_texts[id] = text
    next
}

{
    lines[++line_count] = $0
}

END {
    for (i = 1; i <= line_count; i++) {
        line = lines[i]
        
        for (j = 1; j <= fn_count; j++) {
            id = fn_ids[j]
            marker = "[^" id "]"
            repl = "<sup><a href=\"#fn:" id "\" id=\"fnref:" id "\">" id "</a></sup>"
            
            while ((pos = index(line, marker)) > 0) {
                line = substr(line, 1, pos - 1) repl substr(line, pos + length(marker))
            }
        }
        print line
    }
    
    if (fn_count > 0) {
        print "<hr />"
        print "<section class=\"footnotes\">"
        print "<ol>"
        for (j = 1; j <= fn_count; j++) {
            id = fn_ids[j]
            text = fn_texts[id]
            print "<li id=\"fn:" id "\">"
            print "<p>" text " <a href=\"#fnref:" id "\" class=\"reversefootnote\">&#8617;</a></p>"
            print "</li>"
        }
        print "</ol>"
        print "</section>"
    }
}
