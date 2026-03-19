# _kewt_
### Pronounced "cute"

***

# [Go to the repo](https://git.krzak.org/N0VA/kewt)

***

_kewt_ is a minimalist ssg inspired by _[werc](http://werc.cat-v.org/)_ and _[kew](https://github.com/uint23/kew)_

It's meant to be a static site generator, like _[kew](https://github.com/uint23/kew)_ but use only default (POSIX) tooling, like _[werc](http://werc.cat-v.org/)_ (and definitely unlike _[kew](https://github.com/uint23/kew)_)

## Features

- No dependencies
- Supports many embed types
- Automatic css variable replacement for older browsers
- Automatic inlining and embedding of many filetypes with `\![link]` or `\![alt](link)`
- Inline html support
- MFM `$font` and `\<plain>` tags
- Admonition support (that's what the blocks like the warning block below are called)
- RSS/Feed generation and Sitemap support
- Post creation via `--post`

If you want to **force** a file to be inlined, use `\!![]` instead of `\![]`

## Installation

You can clone the repository to use `kewt.sh` directly, or you can download the standalone executable, which bundles all dependencies into a single file:

```sh
curl -L -o kewt https://git.krzak.org/N0VA/kewt/releases/download/latest/kewt
chmod +x kewt
```

On Arch Linux, _kewt_ is available on the AUR:

- [kewt-bin](https://aur.archlinux.org/packages/kewt-bin) — prebuilt standalone binary from the latest release
- [kewt-git](https://aur.archlinux.org/packages/kewt-git) — built from the latest git source

## Usage

```sh
./kewt.sh --help
./kewt.sh --new [title]
./kewt.sh --post
./kewt.sh --from <src> --to <out>
./kewt.sh [src] [out]
```

`--new [title]` creates a new site directory with a copied `site.conf` and a default `index.md`.

`--post` creates a new empty markdown file in the configured `posts_dir` with the current date and time as the name.

## site.conf

```conf
title = "kewt"
style = "kewt"
dir_indexes = true
single_file_index = true
flatten = false
order = ""
home_name = "Home"
show_home_in_nav = true
nav_links = ""
nav_extra = ""
footer = "made with <a href=\"https://kewt.krzak.org\">kewt</a>"
logo = ""
display_logo = false
display_title = true
logo_as_favicon = true
favicon = ""
generate_page_title = true
error_page = "not_found.html"
versioning = false
base_url = ""
generate_feed = false
feed_file = "rss.xml"
posts_dir = ""
```

- `title` site title
- `style` style file name from `./styles` (without `.css`)
- `dir_indexes` generate directory index pages when missing `index.md`
- `single_file_index` if a directory has one markdown file and no `index.md`, use that file as `index.html`
- `flatten` flatten sidebar directory levels
- `order` comma separated file/directory name list to order the sidebar (alphabetical by default)
- `home_name` text for the home link in navigation (default: "Home")
- `show_home_in_nav` show home link in navigation (default: true)
- `nav_links` comma separated extra nav links, as bare URLs or Markdown links like `[Label](https://example.com)`
- `nav_extra` raw HTML appended inside the `<nav>` after the generated link list
- `footer` footer html/text shown at the bottom of pages
- `logo` logo image path (used in header if enabled)
- `display_logo` show logo in header
- `display_title` show title text in header
- `logo_as_favicon` use `logo` as favicon
- `favicon` explicit favicon path (used when `logo_as_favicon` is false or no logo is set)
- `generate_page_title` automatically generate title text from the first markdown heading or filename (default: true)
- `error_page` filename for the generated 404 error page (default: "not_found.html", empty to disable)
- `versioning` append a version query parameter (`?v=timestamp`) to css asset urls to bypass cache (default: false)
- `base_url` absolute URL of the site, used for sitemap and RSS feed generation
- `generate_feed` enable RSS feed generation (requires `base_url`)
- `feed_file` filename for the generated RSS feed (default: "rss.xml")
- `posts_dir` directory name containing posts (e.g., "posts"). Enables reverse-chronological sorting, title headings in indexes, and automatic backlinks.

## Ignores

- `.kewtignore`: Files/directories to ignore. If empty, the whole directory gets ignored
- `.kewthide`: Files/directories to hide from navigation but still process. Same empty rules as with ignore
- `.kewtpreserve`: Files/directories to copy but not convert markdown to html. Same empty rules again

## Embeds

- `\![link]`:
  - local image/audio/video files are embedded as media tags
  - local text/code files are inlined directly
  - global image/audio/video links are embedded as media tags
  - other global links are embedded as `<iframe>`
- `\![alt](link)` works the same, with `alt` used for images
- `\!![]` and `\!![alt](link)` force inline local file contents

## Credits

- _kew_ css style adapted from _[kew](https://github.com/uint23/kew)_ by [uint23](https://github.com/uint23)

>[!WARNING]
>The base that all of this is built upon was coded at night, while sleepy and a bit sick, and after walking for about 4 hours around a forest, so...
