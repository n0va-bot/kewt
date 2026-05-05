#!/bin/sh

die() {
    echo "Error: $1" >&2
    exit 1
}

script_dir=$(CDPATH="" cd -- "$(dirname -- "$0")" && pwd)
awk_dir="$script_dir/awk"

KEWT_TMPDIR=$(mktemp -d "/tmp/kewt_run.XXXXXX")
trap 'rm -rf "$KEWT_TMPDIR"' EXIT
trap 'exit 0' HUP INT TERM

. "$script_dir/lib/config.sh"
. "$script_dir/lib/metadata.sh"
. "$script_dir/lib/commands.sh"
. "$script_dir/lib/generator.sh"
. "$script_dir/lib/builder.sh"
. "$script_dir/lib/runtime.sh"

src=""
out=""
new_mode="false"
new_title=""
clean_mode="true"
post_mode="false"
post_title=""
positional_count=0
watch_mode="false"
serve_mode="false"
serve_port=""

while [ $# -gt 0 ]; do
    case "$1" in
        --help|-h)
            usage
            exit 0
            ;;
        --new|--init)
            new_mode="true"
            if [ $# -gt 1 ] && [ "${2#-}" = "$2" ]; then
                new_title="$2"
                shift
            fi
            ;;
        --no-clean)
            clean_mode="false"
            ;;
        --clean)
            clean_mode="true"
            ;;
        --version|-v)
            echo "kewt version git"
            exit 0
            ;;
        --dump-zsh-completions)
            cat <<'EOFCOMPS'
#compdef kewt
_kewt() {
    local -a args
    args=(
        '--help[Show help message]'
        '(-h)--help[Show help message]'
        '(-)--new[Create a new site directory]'
        '(-)--init[Create a new site directory (alias for --new)]'
        '(-)--clean[Clean the output directory before building]'
        '(-)--no-clean[Do not clean the output directory before building]'
        '(-)--update[Update site.conf and template.html with latest defaults]'
        '(-)--post[Create a new empty post file in the configured posts_dir]'
        '(-)--generate-template[Generate a new template file]'
        '(-v --version)'{-v,--version}'[Show version information]'
        '--from[Source directory]:directory:_directories'
        '--to[Output directory]:directory:_directories'
        '(-w --watch)'{-w,--watch}'[Watch for file changes and rebuild automatically]'
        '(-s --serve)'{-s,--serve}'[Start a local HTTP server after building]::port:'
    )

    _arguments -S -C $args '*: :_directories'
}

_kewt "$@"
EOFCOMPS
            exit 0
            ;;
        --post)
            post_mode="true"
            if [ $# -gt 1 ] && [ "${2#-}" = "$2" ]; then
                post_title="$2"
                shift
            fi
            ;;
        --generate-template)
            generate_template_path="template.html"
            if [ $# -gt 1 ] && [ "${2#-}" = "$2" ]; then
                generate_template_path="$2"
                shift
            fi
            generate_template "$generate_template_path"
            ;;
        --update)
            update_dir="."
            if [ $# -gt 1 ] && [ "${2#-}" = "$2" ]; then
                update_dir="$2"
                shift
            fi
            update_site "$update_dir"
            ;;
        --from)
            [ $# -lt 2 ] && die "--from requires a value."
            src="$2"
            shift
            ;;
        --to)
            [ $# -lt 2 ] && die "--to requires a value."
            out="$2"
            shift
            ;;
        --watch|-w)
            watch_mode="true"
            ;;
        --serve|-s)
            serve_mode="true"
            if [ $# -ge 2 ] && echo "$2" | grep -qE '^[0-9]+$'; then
                serve_port="$2"
                shift
            fi
            ;;
        --*)
            die "Unknown option: $1"
            ;;
        *)
            positional_count=$((positional_count + 1))
            if [ "$positional_count" -eq 1 ]; then
                if [ -z "$src" ]; then
                    src="$1"
                else
                    die "Source already set (use either positional or --from)."
                fi
            elif [ "$positional_count" -eq 2 ]; then
                if [ -z "$out" ]; then
                    out="$1"
                else
                    die "Output already set (use either positional or --to)."
                fi
            else
                die "Too many positional arguments."
            fi
            ;;
    esac
    shift
done

[ "$new_mode" = "true" ] && create_new_site "$new_title"

if [ -z "$src" ]; then
    if [ "$post_mode" = "true" ] && [ -f "./site.conf" ]; then
        src="."
    else
        src="site"
    fi
fi
[ -z "$out" ] && out="out"

src="${src%/}"
out="${out%/}"

if [ ! -d "$src" ]; then
    if [ "$src" = "site" ]; then
        usage
        exit 1
    fi
    die "Source directory '$src' does not exist."
fi

BASE_IGNORE_ARGS=$(build_rule_args "$src" ".kewtignore" "-name '.kewtignore' -o -path '$src/.*'")
BASE_HIDE_ARGS=$(build_rule_args "$src" ".kewthide" "-name '.kewtignore' -o -name '.kewthide' -o -name '.kewtpreserve' -o -path '$src/.*'")
PRESERVE_ARGS=$(build_rule_args "$src" ".kewtpreserve" "-false")
IGNORE_ARGS="$BASE_IGNORE_ARGS"
HIDE_ARGS="$BASE_HIDE_ARGS"

refresh_build_context

[ "$post_mode" = "true" ] && create_new_post "$src" "$post_title"

if [ "$clean_mode" = "true" ]; then
    [ -d "$out" ] && rm -rf "$out"
fi
mkdir -p "$out"

build_site

if [ "$serve_mode" = "true" ]; then
    port="${serve_port:-8000}"
    if command -v python3 >/dev/null 2>&1; then
        python3 -m http.server "$port" -d "$out" >/dev/null 2>&1 &
        server_pid=$!
        echo "Serving '$out' on http://localhost:$port (python3)"
    elif command -v busybox >/dev/null 2>&1; then
        busybox httpd -f -p "$port" -h "$out" >/dev/null 2>&1 &
        server_pid=$!
        echo "Serving '$out' on http://localhost:$port (busybox)"
    else
        die "Neither python3 nor busybox httpd is available to serve."
    fi

    trap 'kill $server_pid 2>/dev/null; rm -rf "$KEWT_TMPDIR"' EXIT
    trap 'kill $server_pid 2>/dev/null; exit 0' HUP INT TERM
fi

if [ "$watch_mode" = "true" ]; then
    echo "Watching for changes in '$src'..."
    touch "$KEWT_TMPDIR/watch_mark"
    while true; do
        sleep 1
        changed=$(watch_for_changes "$KEWT_TMPDIR/watch_mark")

        if [ -n "$changed" ]; then
            echo ""
            echo "Change detected, rebuilding..."

            if [ "$clean_mode" = "true" ]; then
                find "$out" -mindepth 1 -delete 2>/dev/null
            fi

            refresh_build_context
            build_site
            touch "$KEWT_TMPDIR/watch_mark"
        fi
    done
elif [ "$serve_mode" = "true" ]; then
    wait "$server_pid"
fi
