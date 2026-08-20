# theme-css

Review of the DevTools token sheets: how they layer, what CSS actually reads, and how this fork overlays them.

Source: extracted frontend at `~/.local/share/chromium/front_end`.
Counted exact `var(--token)` in `*.css` and `*.css.js`. Definitions in `design_system_tokens.css` are excluded. Prefix matches are excluded.

Related: `theme-usage.md` (blast radius of `theme.css` sys overrides, older overlay), `theme-tokens.md` (per-token consumers of those overrides).

## Files

| File                                      | Role                                                                              |
| ----------------------------------------- | --------------------------------------------------------------------------------- |
| `front_end/design_system_tokens.css`      | Palette + sys tokens. HTML `<link>`. Overlay is concatenated here                 |
| `front_end/application_tokens.css`        | Icons, app, legacy `--color-*`. HTML `<link>`                                     |
| `front_end/ui/legacy/inspectorCommon.css` | Global chrome. Injected as `inspectorCommon.css.js`                               |
| `inspector.css` (this repo)               | Overlay for `inspectorCommon.css.js`. Checkbox fill                               |
| `config.css` (this repo)                  | Input numbers (`--hue`, `--sat-in`, `--spread`, `--hue-*`). Concatenated first    |
| `theme.css` (this repo)                   | Overlay for `design_system_tokens.css`. Palette re tint from knob vars            |
| `ui/components/buttons/textButton.css`    | `.text-button`. Also a `.css.js` module                                           |
| `entrypoints/greendev_floaty/floaty.css`  | Gemini floaty. Tokens disabled (`stylelint plugin/use_theme_colors`)              |

The built frontend ships **5** raw `.css` files and **383** `.css.js` modules. Almost every panel stylesheet is a JS string injected into a shadow root. Token _definitions_ stay in the two HTML-linked sheets so every root inherits them.

## Overlay pipeline

`scripts/overlay.sh` is the only CSS writer. `scripts/build.sh` and `apply` both call it.

1. Extract `front_end/` from the release tar (`apply`) or overlay Chromium source before ninja (`build.sh`).
2. Strip any previous `/* === knobs.css === */`, `/* === config.css === */`, or `/* === theme.css === */` block from `design_system_tokens.css`.
3. `overlay.sh` reprints config (merge `config.css` with numeric env) then concatenates `theme.css`.
4. `overlay.sh inspector.css` is appended onto `inspectorCommon.css.js` locally, or onto `inspectorCommon.css` at compile time. The leftover `.css` file is unused by DevTools itself; only `floaty.html` links it.

No `@import`. Chrome never loads `config.css` as a file.

Later `:root` in the same file wins. `theme.css` therefore overrides upstream `--ref-palette-*` and the few `--sys-color-*` it sets.

HTML load order (`devtools_app.html` and the other `*_app.html`):

```
application_tokens.css
design_system_tokens.css   (includes theme overlay)
```

Custom properties resolve at computed-value time, so a `--sys-*` defined in the second sheet is visible to aliases in the first. Same-name properties: later stylesheet wins.

## Token layers

```
Chrome  --color-ref-*     (devtools://theme/colors.css, optional)
   |
   v
--ref-palette-*           palette / "base". Do not read in component CSS.
   |
   v
--sys-color-*             semantic. What panels should use.
--sys-size-* --sys-typescale-* --sys-elevation-* --sys-shape-* --sys-motion-*
   |
   v
--app-color-* --icon-* --text-* --color-* --legacy-*
                          exceptions, icons, leftover pre-token colors
```

Chrome Desktop Design System (goo.gle/devtools-ux-style-guide). Three color kinds:

| Prefix            | Sheet                      | Use                                                            |
| ----------------- | -------------------------- | -------------------------------------------------------------- |
| `--ref-palette-*` | `design_system_tokens.css` | Raw ramps. Sys and app may alias them. Component CSS must not. |
| `--sys-color-*`   | `design_system_tokens.css` | Semantic. Light/dark and baseline variants live here.          |
| `--app-color-*`   | `application_tokens.css`   | One-off panel colors when sys is not enough.                   |

`theme.css` retints `--ref-palette-*`. Most `--sys-color-*` follow automatically because they are `var(--ref-palette-...)`.

## Classes on `<html>`

`ThemeSupport` toggles these on `documentElement`:

| Class                                              | When                                                            |
| -------------------------------------------------- | --------------------------------------------------------------- |
| `theme-with-dark-background`                       | DevTools theme is dark (setting or `prefers-color-scheme`)      |
| `baseline-default`                                 | Chrome theme colors on, `--user-color-source: baseline-default` |
| `baseline-grayscale`                               | Incognito, or Chrome theme off, or Chrome grayscale baseline    |
| `platform-linux` `platform-mac` `platform-windows` | Fonts                                                           |
| `platform-screenshot-test`                         | Tests force Roboto                                              |

Without a baseline class, surfaces are `color-mix` of `--ref-palette-primary*` on `--ref-palette-neutral*`.
`baseline-default` upstream hardcodes `#6991d6` / `#d1e1ff`. `theme.css` overrides those mixes to use the retinted palette.
`baseline-grayscale` mixes `--ref-palette-neutral40` on white/near-black, so it still follows the hue.

Chrome may also inject `devtools://theme/colors.css?sets=ui,chrome`, which sets `--color-ref-*`. Upstream palette is `var(--color-ref-primary0, rgb(...fallback))`. `theme.css` assigns `--ref-palette-*` to `hsl(...)` directly, so Chrome's `--color-ref-*` no longer feeds the palette.

## `design_system_tokens.css`

One `:root` with nested `&` selectors. Sections in order:

1. Chrome Desktop sys colors (surfaces, containers, primary/error, states, surface1-5)
2. DevTools extras (bright accents, syntax `--sys-color-token-*`, cdt-base)
3. `&.baseline-default` / `&.baseline-grayscale` surface overrides
4. `&.theme-with-dark-background` (full sys remap)
5. Sizes `--sys-size-1` to `--sys-size-41`
6. Typography (platform fonts + `--sys-typescale-*`)
7. Elevation, shape, motion
8. `--ref-palette-*` (the actual base ramp)

Unique tokens defined:

| Family                                             | Count |
| -------------------------------------------------- | ----: |
| `--ref-palette-*`                                  |   190 |
| `--sys-color-*`                                    |   121 |
| `--sys-typescale-*`                                |    44 |
| `--sys-size-*`                                     |    41 |
| `--sys-shape-*`                                    |     6 |
| `--sys-elevation-*`                                |     5 |
| `--sys-motion-*`                                   |     5 |
| `--ref-typeface-*`                                 |     3 |
| fonts (`--default-font-family`, mono, source-code) |     5 |

### Palette (the base ramp)

`--ref-palette-{family}{step}` with Material steps `0 10 20 30 40 50 60 70 80 90 95 99 100`. Extra steps: secondary `15 25 35`, neutral `15 25 94 98`, pink `55`.

Two kinds of family:

| Kind    | Families                                                             | Chrome `--color-ref-*` |
| ------- | -------------------------------------------------------------------- | ---------------------- |
| Dynamic | `primary` `secondary` `tertiary` `error` `neutral` `neutral-variant` | yes, with rgb fallback |
| Fixed   | `blue` `green` `orange` `yellow` `cyan` `purple` `pink` `indigo`     | no, rgb only           |

`theme.css` rewrites **both** kinds to HSL from `--hue`, `--hue-*`, `--spread`, `--sat`. Fixed families keep their own hue knobs in `config.css` (`--hue-blue`, `--hue-error`, ...) so syntax and file icons stay distinct from chrome.

Upstream comment: do not change and do not use `--ref-palette-*` in component CSS. FlameChart still reads `--ref-palette-neutral10` via `getComputedValue` in JS.

### Sys color ranked by CSS blast radius

| Token                                        | Files | Hits | Paints                                 |
| -------------------------------------------- | ----: | ---: | -------------------------------------- |
| `--sys-color-divider`                        |   142 |  281 | Borders, splitters, list rules         |
| `--sys-color-cdt-base-container`             |   115 |  228 | Default panel / page background        |
| `--sys-color-on-surface`                     |   102 |  183 | Default text                           |
| `--sys-color-primary`                        |    98 |  173 | Links, filled buttons, selected chrome |
| `--sys-color-token-subtle`                   |    73 |  122 | Muted syntax, secondary labels         |
| `--sys-color-state-hover-on-subtle`          |    79 |  121 | Hover wash                             |
| `--sys-color-state-focus-ring`               |    62 |   94 | Focus outlines                         |
| `--sys-color-on-surface-subtle`              |    57 |   91 | Secondary text, default icons          |
| `--sys-color-tonal-container`                |    60 |   85 | Selected row / chip / tab fill         |
| `--sys-color-error`                          |    48 |   73 | Error text                             |
| `--sys-color-state-disabled`                 |    45 |   66 | Disabled text / icons                  |
| `--sys-color-neutral-outline`                |    41 |   56 | Quiet borders                          |
| `--sys-color-on-tonal-container`             |    27 |   38 | Text on tonal fill                     |
| `--sys-color-state-ripple-neutral-on-subtle` |    16 |   33 | Pressed wash                           |
| `--sys-color-neutral-container`              |    29 |   31 | Inactive chips                         |
| `--sys-color-primary-bright`                 |    14 |   30 | Icon accent                            |
| `--sys-color-on-primary`                     |    15 |   29 | Text on filled primary                 |
| `--sys-color-surface3`                       |    14 |   24 | Cards, insight panels (dark menus)     |
| `--sys-color-surface1`                       |    18 |   23 | Grid stripes                           |
| `--sys-color-state-focus-highlight`          |    17 |   21 | Focus fill                             |

`body` in `inspectorCommon` is `color: var(--sys-color-on-surface); background: var(--sys-color-cdt-base-container)`. Those two plus `divider` and `primary` are the chrome.

### Light vs dark aliases (chrome fill)

| Token                | Light                         | Dark                           |
| -------------------- | ----------------------------- | ------------------------------ |
| `cdt-base-container` | `neutral99`                   | `base-container` (`neutral15`) |
| `cdt-base`           | `base-container` (`surface4`) | `base` (`secondary25`)         |
| `base`               | `neutral98`                   | `secondary25`                  |
| `surface`            | `neutral99`                   | `neutral10`                    |
| `primary`            | `primary40`                   | `primary80`                    |
| `tonal-container`    | `primary90`                   | `secondary30`                  |
| `divider`            | `primary90`                   | `secondary35`                  |
| `token-variable`     | `on-surface`                  | `neutral80`                    |
| `token-property`     | `on-surface`                  | `yellow70`                     |

Dark `cdt-base` follows `base`. Dark `cdt-base-container` follows `base-container`, which is `neutral15`, not `surface4`.

### Sys colors with 0 CSS `var()`

| Token                                                                                                     | Note                                                |
| --------------------------------------------------------------------------------------------------------- | --------------------------------------------------- |
| `divider-prominent`                                                                                       | Dead in CSS. `theme.css` still sets it.             |
| `omnibox-container`                                                                                       | Alias of `surface4` / dark `neutral15`. Never read. |
| `on-base-divider`                                                                                         | Defined, unused.                                    |
| `on-blue` `on-cyan` `on-green` `on-orange` `on-pink` `on-purple` `on-secondary` `on-tertiary` `on-yellow` | Pair tokens with no CSS consumer.                   |
| `on-surface-green` `on-surface-primary` `on-surface-secondary` `on-tertiary-container`                    | Same.                                               |
| `state-hover-bright-blend-protection` `state-hover-dim-blend-protection`                                  | Defined, unused in CSS.                             |
| `state-on-header-hover`                                                                                   | 0 CSS hits. FlameChart canvas reads it in JS.       |

Highlighter-only tokens (`token-keyword` `token-number` `token-string` `token-atom` `token-builtin` `token-definition` `token-deleted` `token-inserted` `token-type` `token-string-special`) live in one stylesheet (`codeHighlighter`) so they show 1 file / 1 hit.

### Hardcoded sys values (do not follow palette)

These stay rgb even after `theme.css` retints `--ref-palette-*`:

| Token                                 | Light                 | Dark                     |
| ------------------------------------- | --------------------- | ------------------------ |
| `state-hover-dim-blend-protection`    | `rgb(6 46 111 / 18%)` | `rgb(31 31 31 / 10%)`    |
| `state-hover-bright-blend-protection` | `rgb(31 31 31 / 6%)`  | `rgb(31 31 31 / 16%)`    |
| `state-focus-highlight`               | `rgb(31 31 31 / 6%)`  | `rgb(253 252 251 / 10%)` |
| `state-disabled`                      | `rgb(31 31 31 / 38%)` | `rgb(227 227 227 / 38%)` |
| `state-disabled-container`            | `rgb(31 31 31 / 12%)` | `rgb(227 227 227 / 12%)` |
| `state-scrim`                         | `rgb(0 0 0 / 60%)`    | (not remapped)           |
| `surface-yellow`                      | `rgb(254 246 213)`    | `rgb(65 60 38)`          |
| `surface-yellow-high`                 | `rgb(253 240 185)`    | `rgb(76 68 37)`          |
| `surface-error`                       | `rgb(252 235 235)`    | `rgb(78 53 52)`          |
| `surface-green`                       | `rgb(219 243 226)`    | `rgb(43 70 51)`          |
| elevation shadows                     | `rgb(0 0 0 / 15-30%)` | same                     |

`baseline-default` surfaces upstream use `#6991d6` / `#d1e1ff`. `theme.css` replaces those under `&.baseline-default`.

## `application_tokens.css`

152 unique tokens. Groups:

| Prefix          | Count | Follows sys/palette?                          |
| --------------- | ----: | --------------------------------------------- |
| `--app-color-*` |    55 | mixed                                         |
| `--icon-*`      |    35 | yes, mostly `--sys-color-*-bright`            |
| `--color-*`     |    37 | mostly hardcoded rgb                          |
| `--legacy-*`    |     6 | hardcoded + one sys focus ring                |
| `--text-*`      |     4 | yes (`on-surface`, `primary`, `token-subtle`) |

Icons are the cleanest layer. `--icon-default` is 23 files / 33 hits, alias of `--sys-color-on-surface-subtle`. `--icon-action` `--icon-request` `--icon-request-response` have 0 CSS hits; they still exist for SVG/JS.

`--app-color-*` splits:

- Aliases of sys: `toolbar-background` (`surface4` light, `base` dark), `menu-background`, `card-background`, coverage, performance ratings.
- Direct `--ref-palette-*`: Performance flame-chart categories (`loading` `scripting` `rendering` ...), memory pie, navigation drawer selected fill.
- Hardcoded: `google-ai-blue/green`, `strokestyle` (`rgb(11 87 208 / 10%)` light, matching default primary), `ai-assistance-input-divider`.

Flame-chart category colors have **0 CSS `var()`**. `models/trace/Styles.js` passes `'--app-color-loading'` etc. into `ThemeSupport.getComputedValue`. CSS-only counts mark them unused; the Performance panel still paints them.

### Bugs in this sheet

| Issue                                   | Where                                                                                                             |
| --------------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| `--ref-palette-green4`                  | Dark `--color-continue-to-location-async-hover`. No such token. Meant `green40`.                                  |
| `--ref-palette-neutral87`               | Light `--app-color-other`. No such token. Invalid color.                                                          |
| `--sys-color-gradient-primary/tertiary` | Dark block redefines **sys** tokens inside the app sheet. Wrong layer. Already set in `design_system_tokens.css`. |

`--text-disabled` aliases `--ref-palette-neutral60` instead of a sys token. `--color-primary` / `--color-primary-old` stay Google Blue rgb and ignore the palette.

## Sizes, type, shape, motion

`--sys-size-N` is 1px, 2px, then a 4px-based scale up to `--sys-size-41` (1280px).

| Token          |  px | Files | Hits |
| -------------- | --: | ----: | ---: |
| `--sys-size-5` |   8 |    83 |  225 |
| `--sys-size-3` |   4 |    97 |  199 |
| `--sys-size-8` |  16 |    64 |  193 |
| `--sys-size-2` |   2 |    68 |  168 |
| `--sys-size-4` |   6 |    72 |  152 |
| `--sys-size-6` |  12 |    68 |  136 |
| `--sys-size-9` |  20 |    48 |  114 |
| `--sys-size-1` |   1 |    49 |   81 |

`--sys-size-37` to `--sys-size-41` (768px-1280px) have 0 CSS hits.

Typography: UI is `body4` (12px) and `body5` (11px). `--sys-typescale-body4-regular` is 32 files / 48 hits. Entire `body1` and `headline1-3` composite tokens are unused. `headline5` (14px) is the largest type that actually paints.

`--sys-typescale-body4` (no `-regular`) is referenced by AI assistance CSS and is **undefined**. Those rules drop the `font` declaration.

Shape: `--sys-shape-corner-extra-small` (4px) 35 files / 52 hits. Elevation level 4 and 5 unused. Motion tokens are sparse (durations 1-5 hits).

This fork does not overlay size, type, shape, or motion.

## `inspectorCommon.css` and `inspector.css`

Global reset and chrome: `box-sizing`, flex helpers, `body` color/background, form controls, `.webkit-html-*` syntax, forced-colors.

Top tokens in that sheet: `--sys-size-2`, `--sys-color-state-hover-on-subtle`, `--sys-color-state-focus-ring`, `--sys-color-on-surface`, `--sys-color-cdt-base-container`.

`inspector.css` (this repo) only restyles unchecked checkboxes:

```css
input[type="checkbox"]:not(:checked, .-theme-preserve) {
  box-shadow: inset 0 0 0 12px var(--sys-color-surface3);
}
```

`apply` appends that onto `inspectorCommon.css.js`. A fresh extract without running the script has no overlay marker there.

`devtools_app.html` still flashes `body { background-color: rgb(41 42 45) }` under `prefers-color-scheme: dark` before tokens apply.

## `theme.css` vs the rest

Current overlay strategy: retint the **palette**, then patch dividers and `baseline-default` surfaces.

| Sets                                                                   | What follows                                      |
| ---------------------------------------------------------------------- | ------------------------------------------------- |
| all 190 `--ref-palette-*`                                              | almost every `--sys-color-*` that aliases palette |
| `--sys-color-divider` `divider-on-tonal-container` `divider-prominent` | hairlines (`divider-prominent` unused)            |
| `--sys-color-surface1` through `surface5` under `&.baseline-default`   | Chrome blue-baseline surfaces                     |
| `--divider-line` scrollbar colors                                      | app leftovers                                     |

Does **not** set `--sys-color-cdt-base-container`, `--sys-color-on-surface`, `--sys-color-primary`, syntax tokens, or bright accents. Those follow the palette aliases above.

Still painted with upstream rgb after overlay:

- warning/error/green tinted surfaces
- disabled / hover-blend / scrim / focus-highlight
- `--color-*` / `--legacy-*` / `--issue-color-*` / `--input-outline`
- `--app-color-strokestyle` and Google AI brand colors
- elevation shadows
- HTML preload background
- `floaty.css`

JS canvas (`FlameChart`, `TimelineOverviewPane`, `trace/Styles.js`) reads sys and app tokens through `getComputedValue`. A token with 0 CSS hits can still paint the Performance panel.

## What to tune from here

1. **Palette knobs in `config.css`** (`--hue` `--sat-in` `--spread` `--hue-*`) already retint chrome, syntax, and icons that go through `--ref-palette-*`.
2. **Hardcoded sys surfaces** (`surface-yellow` `surface-error` `surface-green` and state washes) stay Google yellow/red/green until someone maps them to palette mixes.
3. **`--color-*` legacy** ignores the overlay. Anything still on `--color-background` / `--color-text-primary` / `--legacy-accent-color` stays Material Grey/Blue.
4. **`--app-color-*` flame-chart ramps** follow palette (they alias `--ref-palette-blue70` etc.). Invalid `neutral87` / `green4` do not.
5. **`inspector.css`** is the place for chrome-element fixes that tokens cannot express (current checkbox fill).
