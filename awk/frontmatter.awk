BEGIN {
    state = "start"
}
{
    if (state == "start") {
        if ($0 == "---") {
            state = "in_fm"
            next
        } else {
            state = "body"
            print
            next
        }
    }
    if (state == "in_fm") {
        if ($0 == "---") {
            state = "body"
            next
        }
        line = $0
        if (line ~ /^[[:space:]]*$/ || line ~ /^[[:space:]]*#/) next
        if (line !~ /=/) next

        key = line
        val = line
        sub(/=.*/, "", key)
        sub(/[^=]*=/, "", val)

        gsub(/^[[:space:]]+|[[:space:]]+$/, "", key)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", val)

        if (val ~ /^".*"$/) {
            val = substr(val, 2, length(val) - 2)
            gsub(/\\"/, "\"", val)
        } else if (val ~ /^'.*'$/) {
            val = substr(val, 2, length(val) - 2)
            gsub(/\\'/, "'", val)
        }

        if (fm_out != "") {
            print key "=" val >> fm_out
        }
        next
    }
    print
}
