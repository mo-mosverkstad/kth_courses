# Importing the Catch Up! wireframes into Figma

## What to import

| File | Frame size represented | Screens |
|---|---|---|
| `CatchUp_Mobile_390.figma.svg` | 390 × 844 (phone) | 10 |
| `CatchUp_TabletPortrait_834.figma.svg` | 834 × 1112 (tablet portrait) | 4 |
| `CatchUp_Desktop_1280.figma.svg` | 1280 × 800 (laptop / tablet landscape) | 4 |

Drag the file onto the Figma canvas, or **File → Import**. One file per page works
well: `Mobile`, `Tablet portrait`, `Desktop`.

## Why these files and not the ones in `../`

The files in `mockups/` are the **authored** sources. They keep all
styling in a single `<style>` block so the wireframes stay editable by hand — change
one rule and every card updates.

Figma's SVG importer does **not** apply CSS class rules from a `<style>` block.
Importing an authored file directly gives you correctly-positioned but unstyled
shapes (black fills, no strokes, default text size).

The `.figma.svg` files are generated from the authored ones with every class
resolved into plain presentation attributes and the `<style>` block removed. They
are byte-different but **pixel-identical**: verified at 0 differing pixels against
the approved renders for all three breakpoints.

Do not hand-edit the `.figma.svg` files. Edit the authored SVG and regenerate:

```bash
bash build_figma_svgs.sh
```

## After import — three things worth doing

**1. Turn the screen groups into frames.** Each screen is a named group
(`M00-SignIn-Join`, `M01-Home`, …, `T01-Home`, …, `D03-Options-ThreePane`). Select a
group and press `Ctrl/Cmd + Alt + G` to wrap it in a frame, then set the frame size
to the real device size from the table above. The wireframes are drawn at 0.72 scale
so all three sheets share one visual density, so scale the frame contents by
**1.389** (= 1 / 0.72) if you want true device pixels.

**2. Text is real text.** Every label is a `<text>` element, so it stays editable
after import — you can retype copy without redrawing anything. The font is
`Segoe UI` with `Helvetica, Arial` fallbacks; if Figma prompts for a missing font,
substituting Inter or Roboto changes metrics slightly but nothing breaks.

**3. Expect flat layers, not components.** SVG carries no component, auto-layout, or
constraint information — that is a format limitation, not something lost in
conversion. If the group wants a real component library, the candidates are the
option card, the per-member travel bar, the primary/secondary buttons, the status
chip and the card shell. Build those once from the imported shapes and the rest of
the kit assembles from them.

## Known cosmetic caveat

A handful of glyphs (`✓ ⚡ ⏱ ☑ ⟳ 🌧 ⇄`) depend on the renderer's font fallback.
Chrome and Figma render them; some lightweight SVG renderers (ImageMagick, older
Office previews) drop them. They are decoration — no information exists only in a
glyph. If a target tool drops them, replace with the drawn equivalents already used
for the numbered map pins.

## Colour and type tokens

Pulled from the `<style>` block of the authored files, for rebuilding as Figma styles:

| Token | Value | Used for |
|---|---|---|
| Ink | `#1f2630` | body text |
| Ink muted | `#5a6472` | labels |
| Ink faint | `#78828f` | hints, metadata |
| Brand dark | `#2f4858` | header bar, desktop sidebar, headings |
| Brand | `#2f6f8f` | primary buttons, data bars, selection |
| Accent | `#c05746` | map pins, "needs you" |
| Success | `#2d6a4f` | confirmed, satisfied constraints |
| Warning | `#9a5b00` | unmet limits, partial data |
| Surface | `#ffffff` / `#fbfcfd` | frame / card |
| Canvas | `#f4f5f7` | sheet background |
| Hairline | `#e3e7ec` | dividers |
| Map | `#dde7ec` | map plate |

Type scale (as drawn, 0.72 scale): 14 px headings, 11.5 px bold body, 11 px body,
10 px label, 9 px hint. Weights 400 and 700 only.
