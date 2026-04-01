function is_global_url(src) {
    return (src ~ /^https?:\/\//)
}

function split_src(src, base, qpos, hpos, cutpos) {
    base = src
    qpos = index(base, "?")
    hpos = index(base, "#")
    cutpos = 0
    if (qpos > 0) cutpos = qpos
    if (hpos > 0 && (cutpos == 0 || hpos < cutpos)) cutpos = hpos
    if (cutpos > 0) base = substr(base, 1, cutpos - 1)
    return base
}

function ext_of(src, base, n, parts) {
    base = split_src(src)
    n = split(base, parts, ".")
    if (n < 2) return ""
    return tolower(parts[n])
}

function is_image_ext(ext) {
    return (ext ~ /^(png|jpe?g|gif|bmp|webp|svg|ico)$/)
}

function is_audio_ext(ext) {
    return (ext ~ /^(mp3|wav|ogg|m4a|aac|flac)$/)
}

function is_video_ext(ext) {
    return (ext ~ /^(mp4|webm|ogv|mov|m4v)$/)
}

function is_inline_text_ext(ext) {
    return (ext ~ /^(html|txt|md|css|js|mjs|cjs|json|xml|yml|yaml|toml|ini|conf|c|h|cpp|hpp|rs|go|py|sh|lua|php|java|kt|swift|sql|csv|tsv|log)$/)
}

function dirname_of(path,    p) {
    p = path
    if (sub(/\/[^\/]*$/, "", p)) return p
    return "."
}

function resolve_local_path(src,    rel, candidate) {
    rel = split_src(src)
    if (substr(rel, 1, 1) == "/") {
        rel = substr(rel, 2)
        if (site_root != "") {
            candidate = site_root "/" rel
            if ((getline _tmp < candidate) >= 0) {
                close(candidate)
                return candidate
            }
            close(candidate)
        }
        candidate = rel
        if ((getline _tmp < candidate) >= 0) {
            close(candidate)
            return candidate
        }
        close(candidate)

        if (rel == "styles.css" && fallback_file != "") {
            candidate = fallback_file
            if ((getline _tmp < candidate) >= 0) {
                close(candidate)
                return candidate
            }
            close(candidate)
        }
        return ""
    }

    candidate = input_dir "/" rel
    if ((getline _tmp < candidate) >= 0) {
        close(candidate)
        return candidate
    }
    close(candidate)

    candidate = rel
    if ((getline _tmp < candidate) >= 0) {
        close(candidate)
        return candidate
    }
    close(candidate)
    return ""
}

function read_file(path,    out, line, rc) {
    out = ""
    while ((rc = getline line < path) > 0) {
        out = out line "\n"
    }
    close(path)
    return out
}

function read_file_or_render_md(path, ext,    cmd, content, line, rc) {
    content = ""
    if (ext == "md") {
        cmd = "sh \"" script_dir "/markdown.sh\" \"" path "\""
        while ((cmd | getline line) > 0) {
            content = content line "\n"
        }
        close(cmd)
    } else {
        while ((rc = getline line < path) > 0) {
            content = content line "\n"
        }
        close(path)
    }
    return content
}

function escape_html(s,    t) {
    t = s
    gsub(/&/, "\\&amp;", t)
    gsub(/</, "\\&lt;", t)
    gsub(/>/, "\\&gt;", t)
    return t
}

function css_highlight_line(line,    m, prop, val) {
    if (line ~ /^[[:space:]]*\/\*.*\*\/[[:space:]]*$/) {
        return "<span class=\"tok-com\">" line "</span>"
    }

    if (line ~ /^[[:space:]]*[^{}][^{}]*\{[[:space:]]*$/) {
        sub(/\{[[:space:]]*$/, "", line)
        return "<span class=\"tok-sel\">" line "</span><span class=\"tok-punc\">{</span>"
    }

    if (line ~ /^[[:space:]]*\}[[:space:]]*$/) {
        return "<span class=\"tok-punc\">}</span>"
    }

    if (line ~ /^[[:space:]]*--?[A-Za-z0-9_-]+[[:space:]]*:[[:space:]]*[^;]*;?[[:space:]]*$/) {
        match(line, /:[[:space:]]*/)
        sep_pos = RSTART
        sep_len = RLENGTH

        pre_sep = substr(line, 1, sep_pos - 1)
        sep = substr(line, sep_pos, sep_len)
        post_sep = substr(line, sep_pos + sep_len)

        match(pre_sep, /--?[A-Za-z0-9_-]+/)
        prop_pos = RSTART
        prop_len = RLENGTH

        indent = substr(pre_sep, 1, prop_pos - 1)
        prop_name = substr(pre_sep, prop_pos, prop_len)

        if (match(post_sep, /;[[:space:]]*$/)) {
            val_part = substr(post_sep, 1, RSTART - 1)
            suffix = substr(post_sep, RSTART)
        } else {
            val_part = post_sep
            suffix = ""
        }

        prop = "<span class=\"tok-prop\">" prop_name "</span>"
        gsub(/var\(--[A-Za-z0-9_-]+\)/, "<span class=\"tok-var\">&</span>", val_part)
        val = "<span class=\"tok-val\">" val_part "</span>"

        return indent prop sep val suffix
    }

    return line
}

function highlight_code_block_line(line) {
    return css_highlight_line(line)
}

function highlight_css_block(text,    n, i, lines, out) {
    n = split(text, lines, "\n")
    out = ""
    for (i = 1; i <= n; i++) {
        out = out css_highlight_line(lines[i])
        if (i < n) out = out "\n"
    }
    return out
}

function render_code_include(src, force_inline,    ext, local_path, content) {
    if (is_global_url(src)) return ""

    ext = ext_of(src)
    if (!force_inline && !is_inline_text_ext(ext)) return ""

    local_path = resolve_local_path(src)
    if (local_path == "") return ""

    content = read_file(local_path)
    if (content ~ /\n$/) sub(/\n$/, "", content)
    content = escape_html(content)
    if (ext == "css") {
        content = highlight_css_block(content)
    }
    return content
}

function render_embed(src, alt, has_alt, force_inline,    ext, local_path, content) {
    if (force_inline && !is_global_url(src)) {
        local_path = resolve_local_path(src)
        if (local_path != "") {
            ext = ext_of(src)
            content = read_file_or_render_md(local_path, ext)
            if (content ~ /\n$/) sub(/\n$/, "", content)
            return content
        }
    }

    ext = ext_of(src)

    if (is_global_url(src)) {
        if (is_image_ext(ext)) {
            if (has_alt) return "<img alt=\"" alt "\" src=\"" src "\" />"
            return "<img src=\"" src "\" />"
        }
        if (is_audio_ext(ext)) return "<audio controls src=\"" src "\"></audio>"
        if (is_video_ext(ext)) return "<video controls src=\"" src "\"></video>"
        return "<iframe src=\"" src "\" allowfullscreen></iframe>"
    }

    if (is_image_ext(ext)) {
        if (has_alt) return "<img alt=\"" alt "\" src=\"" src "\" />"
        return "<img src=\"" src "\" />"
    }
    if (is_audio_ext(ext)) return "<audio controls src=\"" src "\"></audio>"
    if (is_video_ext(ext)) return "<video controls src=\"" src "\"></video>"

    if (is_inline_text_ext(ext)) {
        local_path = resolve_local_path(src)
        if (local_path != "") {
            content = read_file_or_render_md(local_path, ext)
            if (content ~ /\n$/) sub(/\n$/, "", content)
            return content
        }
    }

    return "<iframe src=\"" src "\" allowfullscreen></iframe>"
}

function render_typed_embed(etype, src, alt, has_alt,    local_path, content) {
    if (etype == "i") {
        if (has_alt) return "<img alt=\"" alt "\" src=\"" src "\" />"
        return "<img src=\"" src "\" />"
    }
    if (etype == "v") return "<video controls src=\"" src "\"></video>"
    if (etype == "a") return "<audio controls src=\"" src "\"></audio>"
    if (etype == "f") return "<iframe src=\"" src "\" allowfullscreen></iframe>"
    if (etype == "e") {
        if (!is_global_url(src)) {
            local_path = resolve_local_path(src)
            if (local_path != "") {
                content = read_file_or_render_md(local_path, ext_of(src))
                if (content ~ /\n$/) sub(/\n$/, "", content)
                return content
            }
        }
        return render_embed(src, alt, has_alt, 1)
    }
    return render_embed(src, alt, has_alt, 0)
}

function extract_attr(tag, attr,    pat, m, token) {
    pat = attr "=\"[^\"]*\""
    if (match(tag, pat)) {
        token = substr(tag, RSTART, RLENGTH)
        sub(/^[^=]*="/, "", token)
        sub(/"$/, "", token)
        return token
    }
    return ""
}

function trim_ws(s) {
    sub(/^[[:space:]]+/, "", s)
    sub(/[[:space:]]+$/, "", s)
    return s
}

function extract_vertical_align(style,    rest, part, pos, key, val) {
    rest = style
    while (rest != "") {
        pos = index(rest, ";")
        if (pos > 0) {
            part = substr(rest, 1, pos - 1)
            rest = substr(rest, pos + 1)
        } else {
            part = rest
            rest = ""
        }
        part = trim_ws(part)
        if (part == "") continue
        pos = index(part, ":")
        if (pos == 0) continue
        key = tolower(trim_ws(substr(part, 1, pos - 1)))
        val = trim_ws(substr(part, pos + 1))
        if (key == "vertical-align" && val != "") return val
    }
    return ""
}

function td_has_vertical_align(td_tag, style_attr) {
    style_attr = extract_attr(td_tag, "style")
    if (style_attr == "") return 0
    return (extract_vertical_align(style_attr) != "")
}

function add_td_vertical_align(td_tag, align, style_attr, repl) {
    style_attr = extract_attr(td_tag, "style")
    if (style_attr == "") {
        sub(/>$/, " style=\"vertical-align: " align ";\">", td_tag)
        return td_tag
    }
    repl = style_attr
    if (repl !~ /;[[:space:]]*$/) repl = repl ";"
    repl = repl " vertical-align: " align ";"
    gsub(/&/, "\\&amp;", repl)
    gsub(/</, "\\&lt;", repl)
    gsub(/>/, "\\&gt;", repl)
    sub("style=\"" style_attr "\"", "style=\"" repl "\"", td_tag)
    return td_tag
}

function apply_td_vertical_align(line,    out, rest, seg, td_tag, img_tag, after_td, after_img, style_attr, align, new_td) {
    out = ""
    rest = line
    while (match(rest, /<td[^>]*>[[:space:]]*<img[^>]*>/)) {
        out = out substr(rest, 1, RSTART - 1)
        seg = substr(rest, RSTART, RLENGTH)
        rest = substr(rest, RSTART + RLENGTH)

        after_td = index(seg, ">")
        if (after_td == 0) {
            out = out seg
            continue
        }
        td_tag = substr(seg, 1, after_td)
        after_img = index(seg, "<img")
        if (after_img == 0) {
            out = out seg
            continue
        }
        img_tag = substr(seg, after_img)

        style_attr = extract_attr(img_tag, "style")
        align = extract_vertical_align(style_attr)
        if (align != "" && !td_has_vertical_align(td_tag)) {
            new_td = add_td_vertical_align(td_tag, align)
            seg = new_td substr(seg, after_td + 1)
        }
        out = out seg
    }
    return out rest
}

function rewrite_img_tags(line,    out, rest, tag, src, alt, force_inline_tag, embed_type, pre, post, repl) {
    out = ""
    rest = line
    while (match(rest, /<img[^>]*\/?>/)) {
        pre = substr(rest, 1, RSTART - 1)
        tag = substr(rest, RSTART, RLENGTH)
        post = substr(rest, RSTART + RLENGTH)
        src = extract_attr(tag, "src")
        alt = extract_attr(tag, "alt")
        force_inline_tag = extract_attr(tag, "data-force-inline")
        embed_type = extract_attr(tag, "data-embed-type")
        if (embed_type != "") {
            repl = render_typed_embed(embed_type, src, alt, (alt != ""))
        } else if (is_image_ext(ext_of(src)) && force_inline_tag == "") {
            # Preserve hand-written <img> attributes (style/class/etc) for normal images.
            repl = tag
        } else {
            repl = render_embed(src, alt, (alt != ""), (force_inline_tag != ""))
        }
        out = out pre repl
        rest = post
    }
    return out rest
}

function rewrite_double_bang_with_parens(line,    out, rest, token, inside, src, alt, sep, pre, post, repl) {
    out = ""
    rest = line
    while (match(rest, /!!\[[^]]*\]\([^)]*\)/)) {
        pre = substr(rest, 1, RSTART - 1)
        token = substr(rest, RSTART, RLENGTH)
        post = substr(rest, RSTART + RLENGTH)

        inside = token
        sub(/^!!\[/, "", inside)
        sep = index(inside, "](")
        alt = substr(inside, 1, sep - 1)
        src = substr(inside, sep + 2)
        sub(/\)$/, "", src)

        repl = render_embed(src, alt, (alt != ""), 1)
        out = out pre repl
        rest = post
    }
    return out rest
}

function rewrite_double_bang_bare(line,    out, rest, token, src, pre, post, repl) {
    out = ""
    rest = line
    while (match(rest, /!!\[[^]]+\]/)) {
        pre = substr(rest, 1, RSTART - 1)
        token = substr(rest, RSTART, RLENGTH)
        post = substr(rest, RSTART + RLENGTH)
        src = token
        sub(/^!!\[/, "", src)
        sub(/\]$/, "", src)
        repl = render_embed(src, "", 0, 1)
        out = out pre repl
        rest = post
    }
    return out rest
}

function rewrite_bare_bang(line,    out, rest, token, src, pre, post, repl) {
    out = ""
    rest = line
    while (match(rest, /!\[[^]]+\]/)) {
        pre = substr(rest, 1, RSTART - 1)
        token = substr(rest, RSTART, RLENGTH)
        post = substr(rest, RSTART + RLENGTH)
        src = token
        sub(/^!\[/, "", src)
        sub(/\]$/, "", src)
        repl = render_embed(src, "", 0, 0)
        out = out pre repl
        rest = post
    }
    return out rest
}

function rewrite_noncode_line(line,    out, rest, pstart, pend, code_seg, noncode) {
    out = ""
    rest = line
    while (1) {
        pstart = index(rest, "<code>")
        if (pstart == 0) {
            noncode = rest
            noncode = rewrite_img_tags(noncode)
            noncode = rewrite_double_bang_with_parens(noncode)
            noncode = rewrite_double_bang_bare(noncode)
            noncode = rewrite_bare_bang(noncode)
            out = out noncode
            break
        }

        noncode = substr(rest, 1, pstart - 1)
        noncode = rewrite_img_tags(noncode)
        noncode = rewrite_double_bang_with_parens(noncode)
        noncode = rewrite_double_bang_bare(noncode)
        noncode = rewrite_bare_bang(noncode)
        out = out noncode

        rest = substr(rest, pstart)
        pend = index(rest, "</code>")
        if (pend == 0) {
            out = out rest
            break
        }
        code_seg = substr(rest, 1, pend + length("</code>") - 1)
        out = out code_seg
        rest = substr(rest, pend + length("</code>"))
    }
    return out
}

function rewrite_code_double_bang_with_parens(line,    out, rest, token, inside, src, sep, pre, post, repl) {
    out = ""
    rest = line
    while (match(rest, /!!\[[^]]*\]\([^)]*\)/)) {
        pre = substr(rest, 1, RSTART - 1)
        token = substr(rest, RSTART, RLENGTH)
        post = substr(rest, RSTART + RLENGTH)

        inside = token
        sub(/^!!\[/, "", inside)
        sep = index(inside, "](")
        src = substr(inside, sep + 2)
        sub(/\)$/, "", src)

        repl = render_code_include(src, 1)
        if (repl == "") repl = token
        out = out pre repl
        rest = post
    }
    return out rest
}

function rewrite_code_double_bang_bare(line,    out, rest, token, src, pre, post, repl) {
    out = ""
    rest = line
    while (match(rest, /!!\[[^]]+\]/)) {
        pre = substr(rest, 1, RSTART - 1)
        token = substr(rest, RSTART, RLENGTH)
        post = substr(rest, RSTART + RLENGTH)
        src = token
        sub(/^!!\[/, "", src)
        sub(/\]$/, "", src)
        repl = render_code_include(src, 1)
        if (repl == "") repl = token
        out = out pre repl
        rest = post
    }
    return out rest
}

function rewrite_code_bang_with_parens(line,    out, rest, token, inside, src, sep, pre, post, repl) {
    out = ""
    rest = line
    while (match(rest, /!\[[^]]*\]\([^)]*\)/)) {
        pre = substr(rest, 1, RSTART - 1)
        token = substr(rest, RSTART, RLENGTH)
        post = substr(rest, RSTART + RLENGTH)

        inside = token
        sub(/^!\[/, "", inside)
        sep = index(inside, "](")
        src = substr(inside, sep + 2)
        sub(/\)$/, "", src)

        repl = render_code_include(src, 0)
        if (repl == "") repl = token
        out = out pre repl
        rest = post
    }
    return out rest
}

function rewrite_code_bare_bang(line,    out, rest, token, src, pre, post, repl) {
    out = ""
    rest = line
    while (match(rest, /!\[[^]]+\]/)) {
        pre = substr(rest, 1, RSTART - 1)
        token = substr(rest, RSTART, RLENGTH)
        post = substr(rest, RSTART + RLENGTH)
        src = token
        sub(/^!\[/, "", src)
        sub(/\]$/, "", src)
        repl = render_code_include(src, 0)
        if (repl == "") repl = token
        out = out pre repl
        rest = post
    }
    return out rest
}

function restore_plain_markers(line) {
    gsub(/\034P0\034/, "*", line)
    gsub(/\034P1\034/, "_", line)
    gsub(/\034P2\034/, "`", line)
    gsub(/\034P3\034/, "[", line)
    gsub(/\034P4\034/, "]", line)
    gsub(/\034P5\034/, "(", line)
    gsub(/\034P6\034/, ")", line)
    gsub(/\034P7\034/, "!", line)
    gsub(/\034P8\034/, "$", line)
    gsub(/\034P9\034/, "#", line)
    gsub(/\034P10\034/, "+", line)
    gsub(/\034P11\034/, "-", line)
    gsub(/\034P12\034/, "\\\\", line)
    gsub(/\034P13\034/, "\\&lt;", line)
    gsub(/\034P14\034/, "\\&gt;", line)
    gsub(/<mfmplain>/, "<span class=\"mfm-plain\">", line)
    gsub(/<\/mfmplain>/, "</span>", line)
    return line
}

BEGIN {
    input_dir = dirname_of(input_file)
    in_pre_code = 0
}

{
    line = $0

    start_pre = (line ~ /<pre><code>/)
    end_pre = (line ~ /<\/code><\/pre>/)

    if (in_pre_code || start_pre) {
        gsub(/\\!\[/, "\034ESC_BANG_OPEN\034", line)
        line = rewrite_code_double_bang_with_parens(line)
        line = rewrite_code_double_bang_bare(line)
        line = rewrite_code_bang_with_parens(line)
        line = rewrite_code_bare_bang(line)
        gsub(/\034ESC_BANG_OPEN\034/, "![", line)
        line = highlight_code_block_line(line)
    } else {
        line = rewrite_noncode_line(line)
    }

    line = apply_td_vertical_align(line)
    line = restore_plain_markers(line)
    print line

    if (start_pre && !end_pre) {
        in_pre_code = 1
    } else if (in_pre_code && end_pre) {
        in_pre_code = 0
    }
}
