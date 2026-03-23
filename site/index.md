# _kewt_
### Pronounced "cute"

***

# [Go to the repo](https://git.krzak.org/N0VA/kewt)

***

_kewt_ is a minimalist ssg inspired by _[werc](http://werc.cat-v.org/)_ and _[kew](https://github.com/uint23/kew)_

It's meant to be a static site generator, like _[kew](https://github.com/uint23/kew)_ but use only default (POSIX) tooling, like _[werc](http://werc.cat-v.org/)_ (and definitely unlike _[kew](https://github.com/uint23/kew)_)

## Features

- No dependencies
- Frontmatter support (title, date, draft)
- Supports many embed types
- Automatic css variable replacement for older browsers
- Automatic inlining and embedding of many filetypes with `\![link]` or `\![alt](link)`
- Typed embeds: `\!i`, `\!v`, `\!a`, `\!f`, `\!e`
- Inline html support
- MFM `$font` and `\<plain>` tags
- GFM Admonition support (that's what the blocks like the warning block below are called)
- Task list support (`- [ ]`, `- [x]`)
- RSS/Feed generation and Sitemap support
- Post creation via `--post`
- Automatic 404 page generation
- `?v=n` support for cache busting
- Code block classes for use with external libraries like highlight.js or prism.js (both tested)
- Clickable markdown header anchors
- Mobile responsive layout

If you want to **force** a file to be inlined, use `\!![]` instead of `\![]`

***

## Installation

### Standalone

```sh
curl -L -o kewt https://git.krzak.org/N0VA/kewt/releases/download/latest/kewt
chmod +x kewt
```

### From source

```sh
git clone https://git.krzak.org/N0VA/kewt.git
cd kewt
```

#### Building

```sh
make
```

#### Installing

```sh
sudo make install
```

### Package Managers

#### AUR

- [kewt-bin](https://aur.archlinux.org/packages/kewt-bin) — prebuilt standalone binary from the latest release
- [kewt-git](https://aur.archlinux.org/packages/kewt-git) — built from the latest git source

#### Homebrew

```sh
brew tap n0va-bot/tap
brew install kewt
```

#### bpkg

```sh
bpkg install n0va-bot/kewt
```

***

## Usage

```sh
./kewt.sh --help
./kewt.sh --version
./kewt.sh --new [title]
./kewt.sh --post
./kewt.sh --from <src> --to <out>
./kewt.sh [src] [out]
```

`--new [title]` creates a new site directory with a copied `site.conf` and a default `index.md`.

`--post [title]` creates a new markdown file in the configured `posts_dir` with the current date/time as the name and creates the default frontmatter.

### site.conf

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
enable_header_links = true
custom_admonitions = ""
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
- `enable_header_links` turns markdown section headings into clickable anchor links (default: true)
- `custom_admonitions` comma separated list of custom admonitions

### Ignores

- `.kewtignore`: Files/directories to ignore. If empty, the whole directory gets ignored
- `.kewthide`: Files/directories to hide from navigation but still process. Same empty rules as with ignore
- `.kewtpreserve`: Files/directories to copy but not convert markdown to html. Same empty rules again

### Embeds

- `\![link]`:
  - local image/audio/video files are embedded as media tags
  - local text/code files are inlined directly
  - global image/audio/video links are embedded as media tags
  - other global links are embedded as `<iframe>`
- `\![alt](link)` works the same, with `alt` used for images
- `\!![]` and `\!![alt](link)` force inline local file contents
- **Typed Embeds**: Force specific output regardless of extension:
  - `\!i[link]` or `\!i[alt](link)`: **I**mage
  - `\!v[link]`: **V**ideo
  - `\!a[link]`: **A**udio
  - `\!f[link]`: I**f**rame
  - `\!e[link]`: Inline/**e**mbed text/code file directly

### Frontmatter

You can set metadata for a page using a `site.conf`-style frontmatter block at the very top of `.md` files:

```conf
---
title = "Custom Page Title"
date = "2026-03-23 11:32"
draft = false
---
```

- `title`: Overrides the page title, post name in index links, and RSS `<title>`.
- `date`: Overrides the post date and time. Supports `YYYY-MM-DD` and `YYYY-MM-DD HH:MM` (or `HH-MM`).
- `draft`: If `true`, the file is excluded from HTML generation

***

>[!WARNING]
>The base that all of this is built upon was coded at night, while sleepy and a bit sick, and after walking for about 4 hours around a forest, so...
