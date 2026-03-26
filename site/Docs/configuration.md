# Configuration

## Dot Files

- `.kewtignore` - files/directories to ignore completely. If the file is empty, the whole directory gets ignored.
- `.kewthide` - files/directories to hide from navigation but still process. Same empty-file rules as `.kewtignore`.
- `.kewtpreserve` - files/directories to copy as-is without converting markdown to HTML. Same empty-file rules again.

## Frontmatter

You can set metadata for a page using a `site.conf`-style frontmatter block at the very top of `.md` files:

```conf
---
title = "Custom Page Title"
date = "2026-03-23 11:32"
draft = false
description = "A short page summary"
---
```
- `title` - overrides the page title, post name in index links, and RSS `<title>`.
- `date` - overrides the post date and time. Supports `YYYY-MM-DD` and `YYYY-MM-DD HH:MM` (or `HH-MM`).
- `draft` - if `true`, the file is excluded from HTML generation.
- `description` - page description, used for Open Graph `og:description` meta tag.

## Directory Index Customisation

By default, directories without an `index.md` get an auto-generated index page listing their contents.

If you create your own `index.md` in a directory, you can still include the auto-generated file list by using the `{{LIST}}` placeholder:

```md
# Blog

This is my blog. The posts are below. The top-most one is the most recent.

{{LIST}}
```
The `{{LIST}}` tag will be replaced with the generated list of links to child pages and files, exactly as in case the custom index didn't exist.

## Table of Contents

You can auto-generate a Table of Contents by placing `{{TOC}}` anywhere in your markdown file. It collects all `h2` and `h3` headings and generates an ordered list with anchor links.

## Footnotes

Footnotes use the `[^id]` syntax inline and `[^id]: text` for definitions at the bottom of the file. They are rendered as a numbered `<section>` at the end of the page.

## Definition Lists

Definition lists use the standard syntax:

```md
Term
: Definition
```
This renders as `<dl><dt>Term</dt><dd>Definition</dd></dl>`. Multiple definitions per term are supported.

## Emoji Shortcodes

Standard GitHub/MkDocs emoji shortcodes like `:smile:`, `:fire:`, `:rocket:` are automatically replaced with their Unicode emoji equivalents. Shortcodes inside code blocks are left as-is.