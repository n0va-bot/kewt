BEGIN {
    slen = length(src)
}

{
    if (length($0) <= slen) {
        next
    }

    rel = substr($0, slen + 2)
    parent = rel
    if (sub(/\/[^\/]+$/, "", parent) == 0) {
        parent = "."
    }

    all[parent]++
    if (is_dir[rel]) {
        dirs[parent]++
    }
    is_dir[parent] = 1
}

END {
    for (parent in all) {
        printf "%s|%d|%d\n", parent, all[parent], dirs[parent]
    }
}
