---
title = "Usage"
---
# Usage

```sh
kewt --help
kewt --version
kewt --new [title]
kewt --post [title]
kewt --generate-template [path]
kewt --update [dir]
kewt --from <src> --to <out>
kewt [src] [out]
kewt --watch
kewt --serve [port]
```
- `--new [title]` creates a new site directory with a default `site.conf`, `template.html`, and `index.md`.
- `--post [title]` creates a new markdown file in the configured `posts_dir` with the current date/time as the filename and default frontmatter.
- `--generate-template [path]` writes the default `template.html` to the given path (defaults to `template.html` in the current directory).
- `--update [dir]` adds any missing keys to `site.conf` and checks `template.html` against the latest default.
- `--watch` (`-w`) watches for file changes in the source directory and rebuilds automatically.
- `--serve` (`-s`) starts a local HTTP server (python3 or busybox) in the output directory after building. Use with the port number to specify the port. Composable with `--watch`.
