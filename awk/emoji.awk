BEGIN {
    if (emoji_file == "") {
        emoji_file = "emoji.tsv"
    }

    while ((getline line < emoji_file) > 0) {
        split(line, parts, "\t")
        if (length(parts[1]) > 0) {
            map[parts[1]] = parts[2]
        }
    }
    close(emoji_file)
}
{
    if ($0 ~ /<pre>/) in_pre = 1
    if (!in_pre) {
        code_count = 0
        line = $0
        out = ""

        while (match(line, /<code>[^<]*<\/code>/)) {
            code_count++
            code_store[code_count] = substr(line, RSTART, RLENGTH)
            out = out substr(line, 1, RSTART - 1) "\034EC" code_count "\034"
            line = substr(line, RSTART + RLENGTH)
        }
        out = out line

        line = out
        out = ""
        while (match(line, /:[A-Za-z0-9_+\-]+:/)) {
            token = substr(line, RSTART, RLENGTH)
            out = out substr(line, 1, RSTART - 1)
            if (token in map) {
                out = out map[token]
            } else {
                out = out token
            }
            line = substr(line, RSTART + RLENGTH)
        }
        out = out line

        for (i = 1; i <= code_count; i++) {
            gsub("\034EC" i "\034", code_store[i], out)
            delete code_store[i]
        }
        $0 = out
    }
    if ($0 ~ /<\/pre>/) in_pre = 0
    print
}
