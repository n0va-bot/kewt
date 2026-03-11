#!/bin/sh

set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [ ! -f "$REPO_ROOT/kewt.sh" ]; then
    echo "kewt.sh not found. Run from the repository root or tools/."
    exit 1
fi

OUT_FILE="$REPO_ROOT/kewt"

cat << 'EOF' > "$OUT_FILE"
#!/bin/sh
tmpdir=$(mktemp -d "/tmp/kewt.XXXXXX")
trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM

# Extract payload
sed '1,/^#==PAYLOAD==$/d' "$0" | tar -xz -C "$tmpdir"

# Pass control to the extracted script
KEWT_INVOKED_AS="$0" "$tmpdir/kewt.sh" "$@"
exit $?

#==PAYLOAD==
EOF

tar -cz -C "$REPO_ROOT" kewt.sh markdown.sh awk styles >> "$OUT_FILE"

chmod +x "$OUT_FILE"

echo "Generated standalone executable at $OUT_FILE"
