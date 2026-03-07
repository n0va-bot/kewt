# _kewt_

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

## Credits

- Markdown to html conversion based on [markdown.bash](https://github.com/chadbraunduin/markdown.bash) by [chadbraunduin](https://github.com/chadbraunduin)
- Default css style and html template based on _[kew](https://github.com/uint23/kew)_ by [uint23](https://github.com/uint23)

# Warning
>![WARNING]
>Most of this was coded at night, while sleepy and a bit sick, and after walking for about 4 hours around a forest, so...
