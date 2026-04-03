---
title = "Templates"
priority = 8
---
# Templates

When customizing `template.html`, the placeholders available are:
- `{{CONTENT}}` - the generated content
- `{{TITLE}}` - the generated title
- `{{NAV}}` - the generated navigation
- `{{FOOTER}}` - the configured footer
- `{{VERSION}}` - the cache-busting string from `versioning = true` (e.g. `?v=12345678`). Safe to use even if versioning is **disabled** (it will be empty).
- `{{CSS}}` - the configured CSS file path
- `{{LANG}}` - the configured document language
- `{{HEAD_EXTRA}}` - meta-tags
- `{{HEADER_BRAND}}` - header rendering the name and/or logo

## Search

When `generate_search` is enabled, kewt embeds a search bar into pages based on the `search_in_header` and `search_in_footer` config options. The search uses a `search.json` index generated at build time and a client-side JS script. No external dependencies are required.
