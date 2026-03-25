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
```
- `--new [title]` creates a new site directory with a default `site.conf`, `template.html`, and `index.md`.
- `--post [title]` creates a new markdown file in the configured `posts_dir` with the current date/time as the filename and default frontmatter.
- `--generate-template [path]` writes the default `template.html` to the given path (defaults to `template.html` in the current directory).
- `--update [dir]` adds any missing keys to `site.conf` and checks `template.html` against the latest default.

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
enable_header_links = true
base_url = ""
generate_feed = false
feed_file = "rss.xml"
posts_dir = ""
custom_admonitions = ""
```
- `title` - site title
- `style` - style file name from `./styles` (without `.css`)
- `dir_indexes` - generate directory index pages when missing `index.md`
- `single_file_index` - if a directory has one markdown file and no `index.md`, use that file as `index.html`
- `flatten` - flatten sidebar directory levels
- `order` - comma separated file/directory name list to order the sidebar (alphabetical by default)
- `home_name` - text for the home link in navigation (default: "Home")
- `show_home_in_nav` - show home link in navigation (default: true)
- `nav_links` - comma separated extra nav links, as bare URLs or Markdown links like `[Label](https://example.com)`
- `nav_extra` - raw HTML appended inside the `<nav>` after the generated link list
- `footer` - footer html/text shown at the bottom of pages
- `logo` - logo image path (used in header if enabled)
- `display_logo` - show logo in header
- `display_title` - show title text in header
- `logo_as_favicon` - use `logo` as favicon
- `favicon` - explicit favicon path (used when `logo_as_favicon` is false or no logo is set)
- `generate_page_title` - automatically generate title text from the first markdown heading or filename (default: true)
- `error_page` - filename for the generated 404 error page (default: "not_found.html", empty to disable)
- `versioning` - append a version query parameter (`?v=timestamp`) to css asset urls to bypass cache (default: false)
- `base_url` - absolute URL of the site, used for sitemap and RSS feed generation
- `generate_feed` - enable RSS feed generation (requires `base_url`)
- `feed_file` - filename for the generated RSS feed (default: "rss.xml")
- `posts_dir` - directory name containing posts (e.g., "posts"). Enables reverse-chronological sorting, title headings in indexes, and automatic backlinks.
- `enable_header_links` - turns markdown section headings into clickable anchor links (default: true)
- `custom_admonitions` - comma separated list of custom admonitions
