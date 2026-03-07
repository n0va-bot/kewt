function title_from_name(name) {
    gsub(/\.md$/, "", name)
    gsub(/-/, " ", name)
    return name
}

BEGIN {
    n_dlines = split(dinfo, dlines, "\n")
    for (i = 1; i <= n_dlines; i++) {
        if (split(dlines[i], dparts, "|") == 3) {
            d_all[dparts[1]] = dparts[2]
            d_dirs[dparts[1]] = dparts[3]
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
    print "<ul>"
    if ("index.md" in all_paths) {
        print "<li><a href=\"/index.html\">Home</a></li>"
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

            printf "<li><a href=\"/%sindex.html\">%s</a><ul>\n", dir_path, title_from_name(parts[i])
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
            printf "<li><a href=\"%s\">%s</a></li>\n", path, title_from_name(parts[n])
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
