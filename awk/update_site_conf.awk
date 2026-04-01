BEGIN {
    new_title = ENVIRON["AWK_NEW_TITLE"]
    done = 0
}
/^title[[:space:]]*=/ {
    print "title = \"" new_title "\""
    done = 1
    next
}
{ print }
END {
    if (!done) print "title = \"" new_title "\""
}
