#!/bin/sh

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
awk_dir="$script_dir/awk"

sed_ere() {
    if sed -E '' </dev/null >/dev/null 2>&1; then
        sed -E "$@"
    else
        sed -r "$@"
    fi
}

sed_ere_inplace() {
    script="$1"
    file="$2"
    tmp="${file}.tmp.$$"
    sed_ere "$script" "$file" > "$tmp" && mv "$tmp" "$file" || {
        rm -f "$tmp"
        return 1
    }
}

sed_ere_inplace_n() {
    script="$1"
    file="$2"
    tmp="${file}.tmp.$$"
    sed_ere -n "$script" "$file" > "$tmp" && mv "$tmp" "$file" || {
        rm -f "$tmp"
        return 1
    }
}

sed_inplace() {
    script="$1"
    file="$2"
    tmp="${file}.tmp.$$"
    sed "$script" "$file" > "$tmp" && mv "$tmp" "$file" || {
        rm -f "$tmp"
        return 1
    }
}

temp_file="/tmp/markdown.$$"
cat "$@" > "$temp_file"

awk '
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
' "$temp_file" > "$temp_file.plain.$$" && mv "$temp_file.plain.$$" "$temp_file"

IFS='
'
refs=$(sed_ere -n "/^\[.+\]: +/p" "$@")
for ref in $refs
do
    ref_id=$(printf %s "$ref" | sed_ere -n "s/^\[(.+)\]: .*/\1/p" | tr -d '\n')
    ref_url=$(printf %s "$ref" | sed_ere -n "s/^\[.+\]: (.+)/\1/p" | cut -d' ' -f1 | tr -d '\n')
    ref_title=$(printf %s "$ref" | sed_ere -n "s/^\[.+\]: (.+) \"(.+)\"/\2/p" | sed 's@|@!@g' | tr -d '\n')

    # reference-style image using the label
    sed_ere_inplace "s|!\[([^]]+)\]\[($ref_id)\]|<img src=\"$ref_url\" title=\"$ref_title\" alt=\"\1\" />|g" "$temp_file"
    # reference-style link using the label
    sed_ere_inplace "s|\[([^]]+)\]\[($ref_id)\]|<a href=\"$ref_url\" title=\"$ref_title\">\1</a>|g" "$temp_file"

    # implicit reference-style
    sed_ere_inplace "s|!\[($ref_id)\]\[\]|<img src=\"$ref_url\" title=\"$ref_title\" alt=\"\1\" />|g" "$temp_file"
    # implicit reference-style
    sed_ere_inplace "s|\[($ref_id)\]\[\]|<a href=\"$ref_url\" title=\"$ref_title\">\1</a>|g" "$temp_file"
done

# delete the reference lines
sed_ere_inplace "/^\[.+\]: +/d" "$temp_file"

# normalize GitHub admonition shorthand in blockquotes
sed_ere_inplace '
/^>!\[/s/^>!\[/> [!/
/^>\[!/s/^>\[!/> [!/
s/^>([^[:space:]>])/> \1/
' "$temp_file"

# blockquotes
# use grep to find all the nested blockquotes
while grep '^> ' "$temp_file" >/dev/null
do
    sed_ere_inplace_n '
/^$/b blockquote

H
$ b blockquote
b

:blockquote
x
s/(\n+)(> .*)/\1<blockquote>\n\2\n<\/blockquote>/ # wrap the tags in a blockquote
p
' "$temp_file"

    sed_inplace '1 d' "$temp_file" # cleanup superfluous first line

    # cleanup blank lines and remove subsequent blockquote characters
    sed_ere_inplace '
/^> /s/^> (.*)/\1/
' "$temp_file"
done

# convert [!TYPE] blockquotes into admonition blocks
awk '
function cap(s) { return toupper(substr(s, 1, 1)) tolower(substr(s, 2)) }
BEGIN { count = 0 }
{ lines[++count] = $0 }
END {
    i = 1
    while (i <= count) {
        if (lines[i] == "<blockquote>") {
            j = i + 1
            while (j <= count && lines[j] != "</blockquote>") j++
            if (j <= count) {
                first = ""
                first_idx = 0
                for (k = i + 1; k < j; k++) {
                    if (lines[k] != "") {
                        first = lines[k]
                        first_idx = k
                        break
                    }
                }
                if (first ~ /^\[![A-Za-z]+\]$/) {
                    kind = first
                    sub(/^\[!/, "", kind)
                    sub(/\]$/, "", kind)
                    lkind = tolower(kind)
                    if (lkind == "note" || lkind == "tip" || lkind == "important" || lkind == "warning" || lkind == "caution") {
                        print "<div class=\"admonition admonition-" lkind "\">"
                        print "<p class=\"admonition-title\">" cap(lkind) "</p>"
                        has_body = 0
                        for (k = first_idx + 1; k < j; k++) {
                            if (lines[k] != "") {
                                print "<p>" lines[k] "</p>"
                                has_body = 1
                            }
                        }
                        if (!has_body) print "<p></p>"
                        print "</div>"
                        i = j + 1
                        continue
                    }
                }
            }
        }
        print lines[i]
        i++
    }
}
' "$temp_file" > "$temp_file.admon.$$" && mv "$temp_file.admon.$$" "$temp_file"

# Setext-style headers
sed_ere_inplace_n '
# Setext-style headers need to be wrapped around newlines
/^$/ b print

# else, append to holding area
H
$ b print
b

:print
x
/=+$/{
s/\n(.*)\n=+$/\n<h1>\1<\/h1>/
p
b
}
/\-+$/{
s/\n(.*)\n\-+$/\n<h2>\1<\/h2>/
p
b
}
p
' "$temp_file"

sed_inplace '1 d' "$temp_file" # cleanup superfluous first line

# atx-style headers and other block styles
sed_ere_inplace '
/^#+ /s/ #+$// # kill all ending header characters
/^# /s/# ([A-Za-z0-9 ]*)(.*)/<h1 id="\1">\1\2<\/h1>/g # H1
/^#{2} /s/#{2} ([A-Za-z0-9 ]*)(.*)/<h2 id="\1">\1\2<\/h2>/g # H2
/^#{3} /s/#{3} ([A-Za-z0-9 ]*)(.*)/<h3 id="\1">\1\2<\/h3>/g # H3
/^#{4} /s/#{4} ([A-Za-z0-9 ]*)(.*)/<h4 id="\1">\1\2<\/h4>/g # H4
/^#{5} /s/#{5} ([A-Za-z0-9 ]*)(.*)/<h5 id="\1">\1\2<\/h5>/g # H5
/^#{6} /s/#{6} ([A-Za-z0-9 ]*)(.*)/<h6 id="\1">\1\2<\/h6>/g # H6

/^\*\*\*+$/s/\*\*\*+/<hr \/>/ # hr with *
/^---+$/s/---+/<hr \/>/ # hr with -
/^___+$/s/___+/<hr \/>/ # hr with _

' "$temp_file"

# unordered lists
# use grep to find all the nested lists
while grep '^[\*\+\-] ' "$temp_file" >/dev/null
do
sed_ere_inplace_n '
# wrap the list
/^$/b list

# wrap the li tags then add to the hold buffer
# use uli instead of li to avoid collisions when processing nested lists
/^[\*\+\-] /s/[\*\+\-] (.*)/<\/uli>\n<uli>\n\1/

H
$ b list # if at end of file, check for the end of a list
b # else, branch to the end of the script

# this is where a list is checked for the pattern
:list
# exchange the hold space into the pattern space
x
# look for the list items, if there wrap the ul tags
/<uli>/{
s/(.*)/\n<ul>\1\n<\/uli>\n<\/ul>/ # close the ul tags
s/\n<\/uli>// # kill the first superfluous closing tag
p
b
}
p
' "$temp_file"

sed_inplace '1 d' "$temp_file" # cleanup superfluous first line

# convert to the proper li to avoid collisions with nested lists
sed_inplace 's/uli>/li>/g' "$temp_file"

# prepare any nested lists
sed_ere_inplace '/^[\*\+\-] /s/(.*)/\n\1\n/' "$temp_file"
done

# ordered lists
# use grep to find all the nested lists
while grep -E '^[1-9]+\. ' "$temp_file" >/dev/null
do
sed_ere_inplace_n '
# wrap the list
/^$/b list

# wrap the li tags then add to the hold buffer
# use oli instead of li to avoid collisions when processing nested lists
/^[1-9]+\. /s/[1-9]+\. (.*)/<\/oli>\n<oli>\n\1/

H
$ b list # if at end of file, check for the end of a list
b # else, branch to the end of the script

:list
# exchange the hold space into the pattern space
x
# look for the list items, if there wrap the ol tags
/<oli>/{
s/(.*)/\n<ol>\1\n<\/oli>\n<\/ol>/ # close the ol tags
s/\n<\/oli>// # kill the first superfluous closing tag
p
b
}
p
' "$temp_file"

sed_inplace '1 d' "$temp_file" # cleanup superfluous first line

# convert list items into proper list items to avoid collisions with nested lists
sed_inplace 's/oli>/li>/g' "$temp_file"

# prepare any nested lists
sed_ere_inplace '/^[1-9]+\. /s/(.*)/\n\1\n/' "$temp_file"
done

# make escaped periods literal
sed_ere_inplace '/^[1-9]+\\. /s/([1-9]+)\\. /\1\. /' "$temp_file"

# fenced code blocks (triple backticks)
awk '
BEGIN { in_fence = 0 }
{
    if (!in_fence && $0 ~ /^```/) {
        print "<pre><code>"
        in_fence = 1
        next
    }
    if (in_fence && $0 ~ /^```[[:space:]]*$/) {
        print "</code></pre>"
        in_fence = 0
        next
    }
    print
}
END {
    if (in_fence) print "</code></pre>"
}
' "$temp_file" > "$temp_file.fence.$$" && mv "$temp_file.fence.$$" "$temp_file"


# code blocks
sed_ere_inplace_n '
# if at end of file, append the current line to the hold buffer and print it
${
H
b code
}

# wrap the code block on any non code block lines
/^\t| {4}/!b code

# else, append to the holding buffer and do nothing
H
b # else, branch to the end of the script

:code
# exchange the hold space with the pattern space
x
# look for the code items, if there wrap the pre-code tags
/\t| {4}/{
s/(\t| {4})(.*)/<pre><code>\n\1\2\n<\/code><\/pre>/ # wrap the ending tags
p
b
}
p
' "$temp_file"

sed_inplace '1 d' "$temp_file" # cleanup superfluous first line

# convert html characters inside pre-code tags into printable representations
sed_ere_inplace '
# get inside pre-code tags
/^<pre><code>/{
:inside
n
# if you found the end tags, branch out
/^<\/code><\/pre>/!{
s/&/\&amp;/g # ampersand
s/</\&lt;/g # less than
s/>/\&gt;/g # greater than
b inside
}
}
' "$temp_file"

# remove the first tab (or 4 spaces) from the code lines
sed_ere_inplace 's/^\t| {4}(.*)/\1/' "$temp_file"

# markdown pipe tables
awk '
function trim(s) {
    sub(/^[[:space:]]+/, "", s)
    sub(/[[:space:]]+$/, "", s)
    return s
}

function is_table_row(line, t) {
    t = line
    return (t ~ /^[[:space:]]*\|/ && t ~ /\|[[:space:]]*$/)
}

function is_table_sep(line, t) {
    if (!is_table_row(line)) return 0
    t = line
    gsub(/[|:\-[:space:]]/, "", t)
    return (t == "" && line ~ /-/)
}

function split_row(line, out, n, i, raw) {
    raw = line
    sub(/^[[:space:]]*\|/, "", raw)
    sub(/\|[[:space:]]*$/, "", raw)
    n = split(raw, out, /\|/)
    for (i = 1; i <= n; i++) out[i] = trim(out[i])
    return n
}

function align_for(sep, t) {
    t = trim(sep)
    if (t ~ /^:-+:$/) return "center"
    if (t ~ /^:-+$/) return "left"
    if (t ~ /^-+:$/) return "right"
    return ""
}

function render_cell(cell, inner) {
    inner = trim(cell)
    if (inner ~ /^```.*```$/) {
        sub(/^```[[:space:]]*/, "", inner)
        sub(/[[:space:]]*```$/, "", inner)
        return "<pre><code>" inner "</code></pre>"
    }
    return inner
}

BEGIN { count = 0 }
{ lines[++count] = $0 }

END {
    in_pre = 0
    i = 1
    while (i <= count) {
        if (lines[i] ~ /^<pre><code>/) {
            in_pre = 1
            print lines[i]
            i++
            continue
        }
        if (in_pre) {
            print lines[i]
            if (lines[i] ~ /^<\/code><\/pre>/) in_pre = 0
            i++
            continue
        }

        if (i < count && is_table_row(lines[i]) && is_table_sep(lines[i + 1])) {
            n_header = split_row(lines[i], header)
            n_sep = split_row(lines[i + 1], sep)
            n_cols = (n_header > n_sep ? n_header : n_sep)

            print "<table>"
            print "<thead>"
            print "<tr>"
            for (c = 1; c <= n_cols; c++) {
                cell = (c <= n_header ? render_cell(header[c]) : "")
                a = (c <= n_sep ? align_for(sep[c]) : "")
                if (a != "") print "<th style=\"text-align: " a ";\">" cell "</th>"
                else print "<th>" cell "</th>"
            }
            print "</tr>"
            print "</thead>"

            j = i + 2
            print "<tbody>"
            while (j <= count && is_table_row(lines[j])) {
                n_body = split_row(lines[j], body)
                print "<tr>"
                for (c = 1; c <= n_cols; c++) {
                    cell = (c <= n_body ? render_cell(body[c]) : "")
                    a = (c <= n_sep ? align_for(sep[c]) : "")
                    if (a != "") print "<td style=\"text-align: " a ";\">" cell "</td>"
                    else print "<td>" cell "</td>"
                }
                print "</tr>"
                j++
            }
            print "</tbody>"
            print "</table>"

            i = j
            continue
        }

        if (is_table_sep(lines[i]) && i < count && is_table_row(lines[i + 1])) {
            n_sep = split_row(lines[i], sep)
            n_cols = n_sep

            print "<table>"
            print "<thead>"
            print "<tr>"
            for (c = 1; c <= n_cols; c++) {
                a = align_for(sep[c])
                if (a != "") print "<th style=\"text-align: " a ";\"></th>"
                else print "<th></th>"
            }
            print "</tr>"
            print "</thead>"

            j = i + 1
            print "<tbody>"
            while (j <= count && is_table_row(lines[j])) {
                n_body = split_row(lines[j], body)
                print "<tr>"
                for (c = 1; c <= n_cols; c++) {
                    cell = (c <= n_body ? render_cell(body[c]) : "")
                    a = align_for(sep[c])
                    if (a != "") print "<td style=\"text-align: " a ";\">" cell "</td>"
                    else print "<td>" cell "</td>"
                }
                print "</tr>"
                j++
            }
            print "</tbody>"
            print "</table>"

            i = j
            continue
        }

        print lines[i]
        i++
    }
}
' "$temp_file" > "$temp_file.table.$$" && mv "$temp_file.table.$$" "$temp_file"

# br tags
sed_ere_inplace '
# if an empty line, append it to the next line, then check on whether there is two in a row
/^$/ {
N
N
/^\n{2}/s/(.*)/\n<br \/>\1/
}
' "$temp_file"

# emphasis and strong emphasis and strikethrough
sed_ere_inplace_n '
# batch up the entire stream of text until a line break in the action
/^$/b emphasis

H
$ b emphasis
b

:emphasis
x
s/\*\*(.+)\*\*/<strong>\1<\/strong>/g
s/__([^_]+)__/<strong>\1<\/strong>/g
s/\*([^\*]+)\*/<em>\1<\/em>/g
s/([^\\])_([^_]+)_/\1<em>\2<\/em>/g
s/\~\~(.+)\~\~/<strike>\1<\/strike>/g
p
' "$temp_file"

sed_inplace '1 d' "$temp_file" # cleanup superfluous first line

# paragraphs
sed_ere_inplace_n '
# if an empty line, check the paragraph
/^$/ b para
# else append it to the hold buffer
H
# at end of file, check paragraph
$ b para
# now branch to end of script
b
# this is where a paragraph is checked for the pattern
:para
# return the entire paragraph into the pattern space
x
# look for non block-level elements, if there - print the p tags
/\n<(div|table|pre|p|[ou]l|h[1-6]|[bh]r|blockquote|li)/!{
s/(\n+)(.*)/\1<p>\n\2\n<\/p>/
p
b
}
p
' "$temp_file"

sed_inplace '1 d' "$temp_file" # cleanup superfluous first line

# cleanup area where P tags have broken nesting
sed_ere_inplace_n '
# if the line looks like like an end tag
/^<\/(div|table|pre|p|[ou]l|h[1-6]|[bh]r|blockquote)>/{
h
# if EOF, print the line
$ {
x
b done
}
# fetch the next line and check on whether or not it is a P tag
n
/^<\/p>/{
G
b done
}
# else, append the line to the previous line and print them both
H
x
}
:done
p
' "$temp_file"

# inline styles and special characters
sed_ere_inplace '
/^<pre><code>/,/^<\/code><\/pre>/b

s/<(http[s]?:\/\/.*)>/<a href=\"\1\">\1<\/a>/g # automatic links
s/<(.*@.*\..*)>/<a href=\"mailto:\1\">\1<\/a>/g # automatic email address links

# inline code
s/([^\\])``+ *([^ ]*) *``+/\1<code>\2<\/code>/g
s/([^\\])`([^`]*)`/\1<code>\2<\/code>/g

# force-inline image syntax (double bang)
s/!!\[([^]]*)\]\(([^)]*) \"([^\"]*)\"\)/<img data-force-inline=\"1\" alt=\"\1\" src=\"\2\" title=\"\3\" \/>/g
s/!!\[([^]]*)\]\(([^)]*)\)/<img data-force-inline=\"1\" alt=\"\1\" src=\"\2\" \/>/g

s/(^|[^\\])!\[([^]]*)\]\(([^)]*) \"([^\"]*)\"\)/\1<img alt=\"\2\" src=\"\3\" title=\"\4\" \/>/g # inline image with title
s/(^|[^\\])!\[([^]]*)\]\(([^)]*)\)/\1<img alt=\"\2\" src=\"\3\" \/>/g # inline image without title

s/(^|[^\\!])\[([^]]*)\]\(([^)]*) \"([^\"]*)\"\)/\1<a href=\"\3\" title=\"\4\">\2<\/a>/g # inline link with title
s/(^|[^\\!])\[([^]]*)\]\(([^)]*)\)/\1<a href=\"\3\">\2<\/a>/g # inline link

# MFM font syntax
s/\$\[font\.serif ([^]]+)\]/<span style=\"font-family: serif;\">\1<\/span>/g
s/\$\[font\.monospace ([^]]+)\]/<span style=\"font-family: monospace;\">\1<\/span>/g
s/\$\[font\.sans ([^]]+)\]/<span style=\"font-family: sans-serif;\">\1<\/span>/g

# special characters
/&.+;/!s/&/\&amp;/g # ampersand
/<[\/a-zA-Z]/!s/</\&lt;/g# less than bracket

# backslash escapes for literal characters
s/\\\*/\*/g # asterisk
s/\\_/_/g # underscore
s/\\`/`/g # underscore
s/\\!/!/g # exclamation
s/\\#/#/g # pound or hash
s/\\\+/\+/g # plus
s/\\\-/\-/g # minus
s/\\</\&lt;/g # less than bracket
s/\\>/\&gt;/g # greater than bracket
s/\\\\/\\/g # backslash
' "$temp_file"

# display and cleanup
awk -v input_file="$1" -v site_root="$MARKDOWN_SITE_ROOT" -v fallback_file="$MARKDOWN_FALLBACK_FILE" -f "$awk_dir/markdown_embed.awk" "$temp_file"
rm "$temp_file"
