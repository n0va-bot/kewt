---
title = "Configuration"
---
# Configuration

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
posts_per_page = 12
custom_admonitions = ""
cw_hide_url = true
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
- `posts_per_page` - number of posts per page in paginated post indexes (default: 12). Set to 0 to disable pagination.
- `enable_header_links` - turns markdown section headings into clickable anchor links (default: true)
- `custom_admonitions` - comma separated list of custom admonitions
- `cw_hide_url` - embeds non-breaking JS to replace the URL in the browser bar on content warning pages (default: true)

## Dot Files

- `.kewtignore` - files/directories to ignore completely. If the file is empty, the whole directory gets ignored.
- `.kewthide` - files/directories to hide from navigation but still process. Same empty-file rules as `.kewtignore`.
- `.kewtpreserve` - files/directories to copy as-is without converting markdown to HTML. Same empty-file rules again.