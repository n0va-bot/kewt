function trim(s) {
    sub(/^[[:space:]]+/, "", s)
    sub(/[[:space:]]+$/, "", s)
    return s
}

function is_table_row(line, t) {
    t = line
    return (t ~ /^[[:space:]]*\|/ && t ~ /\|[[:space:]]*$/)
}

function is_table_sep(line, t) {
    if (!is_table_row(line)) return 0
    t = line
    gsub(/[|:\-[:space:]]/, "", t)
    return (t == "" && line ~ /-/)
}

function split_row(line, out, n, i, raw) {
    raw = line
    sub(/^[[:space:]]*\|/, "", raw)
    sub(/\|[[:space:]]*$/, "", raw)
    n = split(raw, out, /\|/)
    for (i = 1; i <= n; i++) out[i] = trim(out[i])
    return n
}

function align_for(sep, t) {
    t = trim(sep)
    if (t ~ /^:-+:$/) return "center"
    if (t ~ /^:-+$/) return "left"
    if (t ~ /^-+:$/) return "right"
    return ""
}

function render_cell(cell, inner) {
    inner = trim(cell)
    if (inner ~ /^```.*```$/) {
        sub(/^```[[:space:]]*/, "", inner)
        sub(/[[:space:]]*```$/, "", inner)
        return "<pre><code>" inner "</code></pre>"
    }
    return inner
}

BEGIN { count = 0 }
{ lines[++count] = $0 }

END {
    in_pre = 0
    i = 1
    while (i <= count) {
        if (lines[i] ~ /^<pre><code>/) {
            in_pre = 1
            print lines[i]
            i++
            continue
        }
        if (in_pre) {
            print lines[i]
            if (lines[i] ~ /^<\/code><\/pre>/) in_pre = 0
            i++
            continue
        }

        if (i < count && is_table_row(lines[i]) && is_table_sep(lines[i + 1])) {
            n_header = split_row(lines[i], header)
            n_sep = split_row(lines[i + 1], sep)
            n_cols = (n_header > n_sep ? n_header : n_sep)

            print "<table>"
            print "<thead>"
            print "<tr>"
            for (c = 1; c <= n_cols; c++) {
                cell = (c <= n_header ? render_cell(header[c]) : "")
                a = (c <= n_sep ? align_for(sep[c]) : "")
                if (a != "") print "<th style=\"text-align: " a ";\">" cell "</th>"
                else print "<th>" cell "</th>"
            }
            print "</tr>"
            print "</thead>"

            j = i + 2
            print "<tbody>"
            while (j <= count && is_table_row(lines[j])) {
                n_body = split_row(lines[j], body)
                print "<tr>"
                for (c = 1; c <= n_cols; c++) {
                    cell = (c <= n_body ? render_cell(body[c]) : "")
                    a = (c <= n_sep ? align_for(sep[c]) : "")
                    if (a != "") print "<td style=\"text-align: " a ";\">" cell "</td>"
                    else print "<td>" cell "</td>"
                }
                print "</tr>"
                j++
            }
            print "</tbody>"
            print "</table>"

            i = j
            continue
        }

        if (is_table_sep(lines[i]) && i < count && is_table_row(lines[i + 1])) {
            n_sep = split_row(lines[i], sep)
            n_cols = n_sep

            print "<table>"
            print "<thead>"
            print "<tr>"
            for (c = 1; c <= n_cols; c++) {
                a = align_for(sep[c])
                if (a != "") print "<th style=\"text-align: " a ";\"></th>"
                else print "<th></th>"
            }
            print "</tr>"
            print "</thead>"

            j = i + 1
            print "<tbody>"
            while (j <= count && is_table_row(lines[j])) {
                n_body = split_row(lines[j], body)
                print "<tr>"
                for (c = 1; c <= n_cols; c++) {
                    cell = (c <= n_body ? render_cell(body[c]) : "")
                    a = (c <= n_sep ? align_for(sep[c]) : "")
                    if (a != "") print "<td style=\"text-align: " a ";\">" cell "</td>"
                    else print "<td>" cell "</td>"
                }
                print "</tr>"
                j++
            }
            print "</tbody>"
            print "</table>"

            i = j
            continue
        }

        print lines[i]
        i++
    }
}
