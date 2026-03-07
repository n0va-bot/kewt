# _kewt_
### Pronounced "cute"

# [Go to the website](https://kewt.krzak.org)

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

If you want to **force** a file to be inlined, use `\!![]` instead of `\![]`

## Usage

```sh
./kewt.sh --help
./kewt.sh --new [title]
./kewt.sh --from <src> --to <out>
./kewt.sh [src] [out]
```

`--new [title]` creates a new site directory with a copied `site.conf` and a default `index.md`.

## site.conf

```conf
title = "kewt"
style = "kewt"
dir_indexes = true
single_file_index = true
flatten = false
order = ""
footer = "made with <a href="https://kewt.krzak.org">kewt</a>"
logo = ""
display_logo = false
display_title = true
logo_as_favicon = true
favicon = ""
```

- `title` site title
- `style` style file name from `./styles` (without `.css`)
- `dir_indexes` generate directory index pages when missing `index.md`
- `single_file_index` if a directory has one markdown file and no `index.md`, use that file as `index.html`
- `flatten` flatten sidebar directory levels
- `order` comma separated file/directory name list to order the sidebar (alphabetical by default)
- `footer` footer html/text shown at the bottom of pages
- `logo` logo image path (used in header if enabled)
- `display_logo` show logo in header
- `display_title` show title text in header
- `logo_as_favicon` use `logo` as favicon
- `favicon` explicit favicon path (used when `logo_as_favicon` is false or no logo is set)

## Embeds

- `\![link]`:
  - local image/audio/video files are embedded as media tags
  - local text/code files are inlined directly
  - global image/audio/video links are embedded as media tags
  - other global links are embedded as `<iframe>`
- `\![alt](link)` works the same, with `alt` used for images
- `\!![]` and `\!![alt](link)` force inline local file contents

## Credits

- Markdown to html conversion based on [markdown.bash](https://github.com/chadbraunduin/markdown.bash) by [chadbraunduin](https://github.com/chadbraunduin)
- Default css style and html template based on _[kew](https://github.com/uint23/kew)_ by [uint23](https://github.com/uint23)

>[!WARNING]
>Most of this was coded at night, while sleepy and a bit sick, and after walking for about 4 hours around a forest, so...
