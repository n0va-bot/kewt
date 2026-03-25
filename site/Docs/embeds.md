# Embeds

- `\![link]`:
  - local image/audio/video files are embedded as media tags
  - local text/code files are inlined directly
  - global image/audio/video links are embedded as media tags
  - other global links are embedded as `<iframe>`
- `\![alt](link)` works the same, with `alt` used for images
- `\!![link]` and `\!![alt](link)` force inline local file contents

If you want to **force** a file to be inlined, use `\!![]` instead of `\![]`

## Typed Embeds

Force specific output regardless of extension:

- `\!i[link]` or `\!i[alt](link)` - **I**mage
- `\!v[link]` - **V**ideo
- `\!a[link]` - **A**udio
- `\!f[link]` - I**f**rame
- `\!e[link]` - Inline/**e**mbed text/code file directly
