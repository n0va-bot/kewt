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
BEGIN { in_plain = 0; in_script_style = 0 }
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
    tmp_line = out
    out2 = ""
    while (1) {
        if (!in_script_style) {
            pos_script = match(tolower(tmp_line), /<script([ >]|$)/)
            script_start = RSTART; script_len = RLENGTH
            pos_style = match(tolower(tmp_line), /<style([ >]|$)/)
            style_start = RSTART; style_len = RLENGTH

            if (pos_script == 0 && pos_style == 0) {
                out2 = out2 tmp_line
                break
            }
            if (pos_script > 0 && (pos_style == 0 || pos_script < pos_style)) {
                out2 = out2 substr(tmp_line, 1, script_start + script_len - 1)
                tmp_line = substr(tmp_line, script_start + script_len)
                in_script_style = 1
                end_tag = "</script>"
            } else {
                out2 = out2 substr(tmp_line, 1, style_start + style_len - 1)
                tmp_line = substr(tmp_line, style_start + style_len)
                in_script_style = 1
                end_tag = "</style>"
            }
        } else {
            pos_end = match(tolower(tmp_line), end_tag)
            if (pos_end == 0) {
                out2 = out2 mask_plain(tmp_line)
                tmp_line = ""
                break
            }
            out2 = out2 mask_plain(substr(tmp_line, 1, RSTART - 1)) substr(tmp_line, RSTART, RLENGTH)
            tmp_line = substr(tmp_line, RSTART + RLENGTH)
            in_script_style = 0
        }
    }
    print out2
}
