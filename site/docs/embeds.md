---
title = "Embeds"
priority = 5
---
# Embeds

- `\![link]`:
  - local image/audio/video files are embedded as media tags
  - local text/code files are inlined directly
  - global image/audio/video links are embedded as media tags
  - other global links are embedded as `<iframe>`
- `\![alt](link)` works the same, with `alt` used for images
- `\!![link]` and `\!![alt](link)` force inline local file contents

If you want to **force** a file to be inlined, use `\!![]` instead of `\![]`

## Reality-Breaking Embeds

`\!![link]` and `\!![alt](link)` work even inside inline code blocks. If the content between backticks consists only of `\!![]` embeds, the embed triggers and the content is inlined instead of being rendered as code.

```
`!![/file.sh]`
```

## Typed Embeds

Force specific output regardless of extension:

- `\!i[link]` or `\!i[alt](link)` - **I**mage
- `\!v[link]` - **V**ideo
- `\!a[link]` - **A**udio
- `\!f[link]` - I**f**rame
- `\!e[link]` - Inline/**e**mbed text/code file directly
