function cap(s) { return toupper(substr(s, 1, 1)) tolower(substr(s, 2)) }
BEGIN { count = 0 }
{ lines[++count] = $0 }
END {
    i = 1
    while (i <= count) {
        if (lines[i] == "<blockquote>") {
            j = i + 1
            while (j <= count && lines[j] != "</blockquote>") j++
            if (j <= count) {
                first = ""
                first_idx = 0
                for (k = i + 1; k < j; k++) {
                    if (lines[k] != "") {
                        first = lines[k]
                        first_idx = k
                        break
                    }
                }
                if (first ~ /^\[![A-Za-z]+\]$/) {
                    kind = first
                    sub(/^\[!/, "", kind)
                    sub(/\]$/, "", kind)
                    lkind = tolower(kind)
                    is_valid = 0
                    if (custom_admonitions != "") {
                        n = split(tolower(custom_admonitions), adms, ",")
                        for (idx = 1; idx <= n; idx++) {
                            adm = adms[idx]
                            sub(/^[ \t]+/, "", adm)
                            sub(/[ \t]+$/, "", adm)
                            if (lkind == adm) { is_valid = 1; break }
                        }
                    } else if (lkind == "note" || lkind == "tip" || lkind == "important" || lkind == "warning" || lkind == "caution") {
                        is_valid = 1
                    }
                    if (is_valid) {
                        print "<div class=\"admonition admonition-" lkind "\">"
                        print "<p class=\"admonition-title\">" cap(lkind) "</p>"
                        has_body = 0
                        for (k = first_idx + 1; k < j; k++) {
                            if (lines[k] != "") {
                                print "<p>" lines[k] "</p>"
                                has_body = 1
                            }
                        }
                        if (!has_body) print "<p></p>"
                        print "</div>"
                        i = j + 1
                        continue
                    }
                }
            }
        }
        print lines[i]
        i++
    }
}
