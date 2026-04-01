---
title = "Theming"
---
# Theming

*kewt* has a few colour palettes built-in. Set the `style` option in `site.conf` to a theme name to apply it.

## Built-in Themes

| Theme | `style` value | Dark/Light |
|---|---|---|
| Kewt (default) | `kewt` | Light |
| Kewt Light | `kewt-light` | Light |
| Nord | `nord` | Dark |
| Nord Light | `nord-light` | Light |
| Monokai | `mono` | Dark |
| Monokai Light | `mono-light` | Light |
| One Dark | `onedark` | Dark |
| One Light | `onelight` | Light |
| Rose Pine | `rosepine` | Dark |
| Rose Pine Light | `rosepine-light` | Light |
| Solarized | `solarized` | Light |
| Solarized Dark | `solarized-dark` | Dark |

```conf
style = "kewt-light"
```
## How It Works

Each theme is a `.root.css` file containing a `:root` block with CSS custom properties. At build time, *kewt* merges the theme's variables with the base `kewt.css` stylesheet. The base `:root` block is stripped out and replaced with the theme's variables.

## Style Resolution

*kewt* resolves styles in this priority order (highest wins):

1. `site/styles.css` - a full custom stylesheet in your site directory. Overrides everything.
2. `site/styles.root.css` - custom `:root` variables merged with the built-in `kewt.css` base.
3. built-in `<style>.css` - a full stylesheet matching the `style` config value.
4. built-in `<style>.root.css` - `:root` variables merged with `kewt.css`.

If none of these exist, the unmodified `kewt.css` is used

## Custom Themes

To create a custom colour theme, place a `styles.root.css` file in your site directory. The file should contain only a `:root` block with the CSS variables you want to override:

```css
:root {
    --bg: #1a1b26;
    --fg: #c0caf5;
    --fg-link: #7aa2f7;
    --fg-heading: #c0caf5;
    --code-bg: #24283b;
}
```
Any variables not overridden will fall back to the defaults in `kewt.css`. The `:root` block in the base stylesheet is automatically removed to prevent conflicts.

## Per-Directory Styles

Subdirectories can have their own `styles.css` or `styles.root.css` that apply only to pages in that directory. Per-directory styles follow the same priority.
