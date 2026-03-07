{
    raw[++n] = $0
    lines[n] = $0
    rest = $0

    while (match(rest, /--[A-Za-z0-9_-]+[[:space:]]*:[[:space:]]*[^;]+;/)) {
        decl = substr(rest, RSTART, RLENGTH)

        name = decl
        sub(/:.*/, "", name)
        gsub(/[[:space:]]/, "", name)

        value = decl
        sub(/^[^:]*:[[:space:]]*/, "", value)
        sub(/;[[:space:]]*$/, "", value)

        vars[name] = value
        rest = substr(rest, RSTART + RLENGTH)
    }
}

END {
    in_root = 0
    for (i = 1; i <= n; i++) {
        line = raw[i]
        if (!in_root && line ~ /:root[[:space:]]*\{/) {
            in_root = 1
            lines[i] = ""
            if (line ~ /\}/) {
                in_root = 0
            }
            continue
        }
        if (in_root) {
            lines[i] = ""
            if (line ~ /\}/) {
                in_root = 0
            }
        }
    }

    for (i = 1; i <= n; i++) {
        line = lines[i]
        if (line == "") {
            continue
        }
        changed = 1
        iter = 0

        while (changed && iter < 10) {
            changed = 0
            iter++
            for (name in vars) {
                token = "var(" name ")"
                while ((pos = index(line, token)) > 0) {
                    line = substr(line, 1, pos - 1) vars[name] substr(line, pos + length(token))
                    changed = 1
                }
            }
        }

        print line
    }
}
