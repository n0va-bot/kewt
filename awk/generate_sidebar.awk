function title_from_name(name) {
    gsub(/\.md$/, "", name)
    gsub(/-/, " ", name)
    return name
}

function get_title(path, default_title,   full_path, line, title, in_fm) {
    full_path = src "/" path
    if (path !~ /\.md$/) {
        full_path = full_path "/index.md"
    }

    title = ""
    in_fm = 0
    while ((getline line < full_path) > 0) {
        if (line ~ /^---[[:space:]]*$/) {
            if (in_fm == 0) {
                in_fm = 1
                continue
            } else {
                break
            }
        }
        if (in_fm) {
            if (line ~ /^[[:space:]]*title[[:space:]]*=/) {
                sub(/^[[:space:]]*title[[:space:]]*=[[:space:]]*/, "", line)
                if (line ~ /^".*"$/) {
                    title = substr(line, 2, length(line) - 2)
                } else if (line ~ /^'.*'$/) {
                    title = substr(line, 2, length(line) - 2)
                } else {
                    title = line
                }
                break
            }
        } else {
            break
        }
    }
    close(full_path)

    if (title != "") return title
    return default_title
}


function compare_paths(p1, p2,    parts1, parts2, n1, n2, i, name1, name2, lname1, lname2, w1, w2) {
    n1 = split(p1, parts1, "/")
    n2 = split(p2, parts2, "/")
    for (i = 1; i <= n1 && i <= n2; i++) {
        name1 = parts1[i]
        name2 = parts2[i]
        if (i == n1) gsub(/\.md$/, "", name1)
        if (i == n2) gsub(/\.md$/, "", name2)
        lname1 = tolower(name1)
        lname2 = tolower(name2)

        if (lname1 == "index" && i == n1 && lname2 != "index") return -1
        if (lname2 == "index" && i == n2 && lname1 != "index") return 1

        w1 = (lname1 in custom_order ? custom_order[lname1] : 999999)
        w2 = (lname2 in custom_order ? custom_order[lname2] : 999999)

        if (w1 < w2) return -1
        if (w1 > w2) return 1

        if (lname1 < lname2) return -1
        if (lname1 > lname2) return 1
    }
    if (n1 < n2) return -1
    if (n1 > n2) return 1
    return 0
}

BEGIN {
    src = ENVIRON["AWK_SRC"]
    single_file_index = ENVIRON["AWK_SINGLE_FILE_INDEX"]
    flatten = ENVIRON["AWK_FLATTEN"]
    order = ENVIRON["AWK_ORDER"]
    home_name = ENVIRON["AWK_HOME_NAME"]
    show_home_in_nav = ENVIRON["AWK_SHOW_HOME_IN_NAV"]
    dinfo = ENVIRON["AWK_DINFO"]
    n_dlines = split(dinfo, dlines, "\n")
    for (i = 1; i <= n_dlines; i++) {
        if (split(dlines[i], dparts, "|") == 3) {
            d_all[dparts[1]] = dparts[2]
            d_dirs[dparts[1]] = dparts[3]
        }
    }

    n_order = split(order, oparts, ",")
    for (i = 1; i <= n_order; i++) {
        name = oparts[i]
        sub(/^[[:space:]]*/, "", name)
        sub(/[[:space:]]*$/, "", name)
        if (name != "") {
            custom_order[tolower(name)] = i
        }
    }
}

{
    rel = substr($0, length(src) + 2)
    all_paths[rel] = 1
    ordered_paths[count++] = rel

    dir = rel
    if (sub(/\/[^\/]+$/, "", dir) == 0) {
        dir = "."
    }

    md_count[dir]++
    if (rel ~ /index\.md$/) {
        has_index[dir] = 1
    }
}

END {
    for (i = 0; i < count - 1; i++) {
        for (j = 0; j < count - i - 1; j++) {
            if (compare_paths(ordered_paths[j], ordered_paths[j+1]) > 0) {
                tmp = ordered_paths[j]
                ordered_paths[j] = ordered_paths[j+1]
                ordered_paths[j+1] = tmp
            }
        }
    }

    print "<ul>"
    if (show_home_in_nav == "true" && "index.md" in all_paths) {
        if (home_name == "") home_name = "Home"
        print "<li><a href=\"/index.html\">" home_name "</a></li>"
    }

    depth = 0
    prev_n = 0

    for (idx = 0; idx < count; idx++) {
        rel = ordered_paths[idx]
        if (rel == "index.md") {
            continue
        }

        n = split(rel, parts, "/")
        common = 0
        for (i = 1; i < n && i < prev_n; i++) {
            if (parts[i] == prev_parts[i]) {
                common = i
            } else {
                break
            }
        }

        while (depth > 0 && opened_levels[depth] > common) {
            print "</ul></li>"
            delete opened_levels[depth]
            depth--
        }

        for (i = common + 1; i < n; i++) {
            dir_path = ""
            for (j = 1; j <= i; j++) {
                dir_path = dir_path parts[j] "/"
            }

            this_d = ""
            for (j = 1; j <= i; j++) {
                this_d = (this_d == "" ? parts[j] : this_d "/" parts[j])
            }

            if (flatten == "true" && d_all[this_d] == 1 && d_dirs[this_d] == 1) {
                continue
            }

            printf "<li><a href=\"/%sindex.html\">%s</a><ul>\n", dir_path, get_title(this_d, title_from_name(parts[i]))
            opened_levels[++depth] = i
        }

        curr_dir = rel
        if (sub(/\/[^\/]+$/, "", curr_dir) == 0) {
            curr_dir = "."
        }
        is_single = (single_file_index == "true" && md_count[curr_dir] == 1 && !has_index[curr_dir])

        if (parts[n] != "index.md" && !is_single) {
            path = "/" rel
            gsub(/\.md$/, ".html", path)
            printf "<li><a href=\"%s\">%s</a></li>\n", path, get_title(rel, title_from_name(parts[n]))
        }

        prev_n = n
        split(rel, prev_parts, "/")
    }

    while (depth > 0) {
        print "</ul></li>"
        depth--
    }
    print "</ul>"
}
