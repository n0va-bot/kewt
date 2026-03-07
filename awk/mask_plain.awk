function find_unescaped_tag(s, tag,    p, off, pos) {
    p = 1
    while (1) {
        off = index(substr(s, p), tag)
        if (off == 0) return 0
        pos = p + off - 1
        if (pos == 1 || substr(s, pos - 1, 1) != "\\") return pos
        p = pos + 1
    }
}

function mask_plain(s,    t) {
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
    return t
}
BEGIN { in_plain = 0 }
{
    line = $0
    out = ""
    while (1) {
        if (!in_plain) {
            pos = find_unescaped_tag(line, "<plain>")
            if (pos == 0) {
                out = out line
                break
            }
            out = out substr(line, 1, pos - 1) "<mfmplain>"
            line = substr(line, pos + 7)
            in_plain = 1
        } else {
            pos = find_unescaped_tag(line, "</plain>")
            if (pos == 0) {
                out = out mask_plain(line)
                line = ""
                break
            }
            out = out mask_plain(substr(line, 1, pos - 1)) "</mfmplain>"
            line = substr(line, pos + 8)
            in_plain = 0
        }
    }
    print out
}
