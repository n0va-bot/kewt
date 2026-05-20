{
    lines[NR] = $0
    total = NR

    if (/^\[[^\]]+\]:  */) {
        line = $0
        sub(/^\[/, "", line)
        ref_id = line
        sub(/\].*/, "", ref_id)

        line = $0
        sub(/^\[[^\]]+\]:  */, "", line)
        ref_url = line
        sub(/[ \t].*/, "", ref_url)

        ref_title = $0
        sub(/^\[[^\]]+\]:  *[^\t ]*[ \t]*/, "", ref_title)
        sub(/^"/, "", ref_title)
        sub(/"$/, "", ref_title)
        gsub(/\|/, "!", ref_title)

        refs[ref_id] = ref_url
        if (ref_title != "") titles[ref_id] = ref_title
        is_ref[NR] = 1
    }
}

function resolve_image_ref(alt, id,    url, title) {
    url = refs[id]
    title = (id in titles) ? titles[id] : ""
    if (url == "") return "![" alt "][" id "]"
    return "<img src=\"" url "\" title=\"" title "\" alt=\"" alt "\" />"
}

function resolve_link_ref(text, id,    url, title) {
    url = refs[id]
    title = (id in titles) ? titles[id] : ""
    if (url == "") return "[" text "][" id "]"
    return "<a href=\"" url "\" title=\"" title "\">" text "</a>"
}

function process_refs(line,    result, i, len, ch, j, k, depth, bracket_content, ref_id) {
    result = ""
    len = length(line)
    i = 1

    while (i <= len) {
        ch = substr(line, i, 1)

        if (ch == "!" && i < len && substr(line, i + 1, 1) == "[") {
            bracket_content = ""
            j = i + 2
            while (j <= len && substr(line, j, 1) != "]") {
                bracket_content = bracket_content substr(line, j, 1)
                j++
            }
            if (j <= len && j < len && substr(line, j + 1, 1) == "[") {
                k = j + 2
                ref_id = ""
                while (k <= len && substr(line, k, 1) != "]") {
                    ref_id = ref_id substr(line, k, 1)
                    k++
                }
                if (k <= len) {
                    if (ref_id == "") ref_id = bracket_content
                    if (ref_id in refs) {
                        result = result resolve_image_ref(bracket_content, ref_id)
                        i = k + 1
                        continue
                    }
                }
            }
            result = result substr(line, i, 1)
            i++
        } else if (ch == "[") {
            bracket_content = ""
            j = i + 1
            depth = 1
            while (j <= len && depth > 0) {
                if (substr(line, j, 1) == "[") depth++
                if (substr(line, j, 1) == "]") {
                    depth--
                    if (depth == 0) break
                }
                if (depth > 0) bracket_content = bracket_content substr(line, j, 1)
                j++
            }
            if (j <= len && j < len && substr(line, j + 1, 1) == "[") {
                k = j + 2
                ref_id = ""
                while (k <= len && substr(line, k, 1) != "]") {
                    ref_id = ref_id substr(line, k, 1)
                    k++
                }
                if (k <= len) {
                    if (ref_id == "") ref_id = bracket_content
                    if (ref_id in refs) {
                        result = result resolve_link_ref(bracket_content, ref_id)
                        i = k + 1
                        continue
                    }
                }
            }
            result = result substr(line, i, 1)
            i++
        } else {
            result = result ch
            i++
        }
    }
    return result
}

END {
    for (n = 1; n <= total; n++) {
        if (is_ref[n]) continue
        print process_refs(lines[n])
    }
}
