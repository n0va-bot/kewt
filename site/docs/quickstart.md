---
title = "Quickstart"
priority = 1
---
# Quickstart

## Creating a site

```sh
kewt --new mysite
cd mysite
```
This creates a directory with a `site.conf`, `template.html`, and `index.md`.

## Writing content

Edit `index.md` (or any `.md` file) and just write markdown as usual. Files in subdirectories are added to the navigation automatically.

## Building

```sh
kewt src out # Replace with the directories you want
```
Reads from `src` and writes static HTML to `out`.

## Previewing

```sh
kewt --serve
```
Builds the site and starts a local HTTP server. Use `--watch` with `--serve` to rebuild automatically on file changes.

## That's it, if you want to do anything more, look at [the documentation](/docs)
