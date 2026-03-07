BEGIN { in_bq = 0 }
/^>[[:space:]]?/ {
    if (!in_bq) { print "<blockquote>"; in_bq = 1 }
    sub(/^>[[:space:]]?/, "", $0)
    print $0
    next
}
{
    if (in_bq) { print "</blockquote>"; in_bq = 0 }
    print
}
END {
    if (in_bq) print "</blockquote>"
}
