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

VERSION=$(git describe --tags --always --dirty 2>/dev/null || echo "standalone")
tmpbuild=$(mktemp -d)
cp -r "$REPO_ROOT/kewt.sh" "$REPO_ROOT/markdown.sh" "$REPO_ROOT/awk" "$REPO_ROOT/styles" "$tmpbuild/"
sed -e "s/kewt version git/kewt version $VERSION/" "$tmpbuild/kewt.sh" > "$tmpbuild/kewt.sh.tmp" && mv "$tmpbuild/kewt.sh.tmp" "$tmpbuild/kewt.sh"
chmod +x "$tmpbuild/kewt.sh" "$tmpbuild/markdown.sh"
tar -cz -C "$tmpbuild" kewt.sh markdown.sh awk styles >> "$OUT_FILE"
rm -rf "$tmpbuild"

chmod +x "$OUT_FILE"

echo "Generated standalone executable at $OUT_FILE"
