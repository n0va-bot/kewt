_kewt() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    opts="--help --new --init --clean --no-clean --update --post --generate-template --version --from --to --watch -w --serve -s --draft --dry-run"

    case "$prev" in
        --from|--to)
            COMPREPLY=$(compgen -d -- "$cur")
            return 0
            ;;
        --serve|-s)
            COMPREPLY=()
            return 0
            ;;
        --new|--init|--update)
            COMPREPLY=$(compgen -d -- "$cur")
            return 0
            ;;
        --generate-template)
            COMPREPLY=$(compgen -f -- "$cur")
            return 0
            ;;
    esac

    if [[ "$cur" == -* ]]; then
        COMPREPLY=$(compgen -W "$opts" -- "$cur")
        return 0
    fi

    COMPREPLY=$(compgen -d -- "$cur")
    return 0
}

complete -F _kewt kewt
