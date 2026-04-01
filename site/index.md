# _kewt_
### Pronounced "cute"

***

# [Go to the repo](https://git.krzak.org/N0VA/kewt)

***

_kewt_ is a minimalist ssg inspired by _[werc](http://werc.cat-v.org/)_ and _[kew](https://github.com/uint23/kew)_

It's meant to be a static site generator, like _[kew](https://github.com/uint23/kew)_ but use only default (POSIX) tooling, like _[werc](http://werc.cat-v.org/)_ (and definitely unlike _[kew](https://github.com/uint23/kew)_)

## Features

- No dependencies
- Frontmatter support (title, date, draft, description)
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
- Customisable directory index pages with `{{LIST}}`
- Open Graph meta tags from frontmatter
- Auto-generated Table of Contents via `{{TOC}}`
- Footnotes (`[^id]`)
- Definition lists
- Emoji shortcodes (`:smile:`, `:fire:`, etc.)
- Post pagination
- `--watch` and `--serve` modes for development

***

## [Quickstart guide](/docs/quickstart.html)
