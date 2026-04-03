---
title = "Frontmatter"
priority = 4
---
# Frontmatter

You can set metadata for a page using a `site.conf`-style frontmatter block at the very top of `.md` files:

```conf
---
title = "Custom Page Title"
date = "2026-03-23 11:32"
draft = false
description = "A short page summary"
tags = "example, tutorial"
priority = 10
---
```
- `title` - overrides the page title, post name in index links, and RSS `<title>`.
- `date` - overrides the post date and time. Supports `YYYY-MM-DD` and `YYYY-MM-DD HH:MM` (or `HH-MM`).
- `draft` - if `true`, the file is excluded from HTML generation. If not set, uses the `draft_by_default` config value.
- `description` - page description, used for Open Graph `og:description` meta tag.
- `tags` - comma separated list of tags. Used for tag index generation when `generate_tags` is enabled in `site.conf`.
- `content_warning` - if set, creates an interstitial warning page that the user must click through. If set to `true` uses a generic warning, otherwise uses your string.
- `priority` - numeric value for ordering. Lower values sort first in the sidebar and directory indexes. Falls back to alphabetical/date ordering when not set or when items share the same priority.
