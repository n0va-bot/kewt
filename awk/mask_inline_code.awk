function mask(s,    t) {
    t = s
    gsub(/\*/, "\034P0\034", t)
    gsub(/_/, "\034P1\034", t)
    gsub(/`/, "\034P2\034", t)
    gsub(/\[/, "\034P3\034", t)
    gsub(/\]/, "\034P4\034", t)
    gsub(/\(/, "\034P5\034", t)
    gsub(/\)/, "\034P6\034", t)
    gsub(/!/, "\034P7\034", t)
    gsub(/\$/, "\034P8\034", t)
    gsub(/#/, "\034P9\034", t)
    gsub(/\+/, "\034P10\034", t)
    gsub(/-/, "\034P11\034", t)
    gsub(/\\/, "\034P12\034", t)
    gsub(/</, "\034P13\034", t)
    gsub(/>/, "\034P14\034", t)
    return t
}
{
    # backslash escapes
    gsub(/\\\*/, "\034P0\034")
    gsub(/\\_/, "\034P1\034")
    gsub(/\\`/, "\034P2\034")
    gsub(/\\\[/, "\034P3\034")
    gsub(/\\\]/, "\034P4\034")
    gsub(/\\\(/, "\034P5\034")
    gsub(/\\\)/, "\034P6\034")
    gsub(/\\!/, "\034P7\034")
    gsub(/\\\$/, "\034P8\034")
    gsub(/\\#/, "\034P9\034")
    gsub(/\\\+/, "\034P10\034")
    gsub(/\\\-/, "\034P11\034")
    gsub(/\\\\/, "\034P12\034")
    gsub(/\\</, "\034P13\034")
    gsub(/\\>/, "\034P14\034")

    # inline code (1 or 2 backticks)
    line = $0
    if (line ~ /^```/) {
        print line
        next
    }
    out = ""
    p = 1
    while (match(substr(line, p), /`+/)) {
        pstart = p + RSTART - 1
        plen = RLENGTH

        # Found backtick sequence at pstart
        # Search for closing marker of same length
        marker = substr(line, pstart, plen)
        tail = substr(line, pstart + plen)
        mpos = index(tail, marker)
        if (mpos > 0) {
            # Check if it is followed by more backticks
            if (substr(tail, mpos + plen, 1) == "`") {
                # Not a match, treat as literal
                out = out substr(line, p, pstart - p + plen)
                p = pstart + plen
                continue
            }

            # Found match!
            content = substr(tail, 1, mpos - 1)
            out = out substr(line, p, pstart - p)
            if (plen >= 2 && substr(content, 1, 1) == " " && substr(content, length(content), 1) == " ") {
                content = substr(content, 2, length(content) - 2)
            }
            if (content ~ /!!\[/) {
                _rb_test = content
                gsub(/!!\[[^\]]*\]\([^)]*\)/, "", _rb_test)
                gsub(/!!\[[^\]]+\]/, "", _rb_test)
                gsub(/[[:space:]]+/, "", _rb_test)
                if (_rb_test == "") {
                    out = out content
                    p = pstart + plen + mpos + plen - 1
                    continue
                }
            }
            out = out "<code>" mask(content) "</code>"
            p = pstart + plen + mpos + plen - 1
        } else {
            # No closing marker, treat as literal
            out = out substr(line, p, pstart - p + plen)
            p = pstart + plen
        }
    }
    out = out substr(line, p)
    print out
}
