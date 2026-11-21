# Catch Up! — responsive design spec

Three breakpoints, one component set. The mobile design is unchanged; the other two
rearrange the same components rather than introducing new ones.

| Breakpoint | Range | Frame drawn | Sheet |
|---|---|---|---|
| Mobile | `< 600 px` | 390 × 844 | `mockups/CatchUp_Mobile_390.svg` |
| Tablet portrait | `600 – 1023 px` | 834 × 1112 | `mockups/CatchUp_TabletPortrait_834.svg` |
| Laptop / tablet landscape | `≥ 1024 px` | 1280 × 800 | `mockups/CatchUp_Desktop_1280.svg` |

Tablet landscape (1024 × 768 and up) uses the laptop layout. A 10-inch tablet rotated
to landscape is ~1024–1180 px wide, which is enough for the sidebar and the three-pane
options view, so it does not need a layout of its own.

```css
/* mobile first — no media query is the mobile case */
@media (min-width: 600px)  { /* tablet portrait */ }
@media (min-width: 1024px) { /* laptop + tablet landscape */ }
```

---

## What changes, and why

### Navigation

| Mobile | Tablet portrait | Laptop / landscape |
|---|---|---|
| Dark top bar + bottom tab bar | Dark top bar + **left icon rail** (89 px, icon over label) | **Left sidebar** (208 px, labelled) absorbing the brand bar; content gets its own light header |

The sidebar is not just the tab bar made wider. At the laptop width it also carries
the saved defaults, the signed-in identity, and — inside a Catch Up — the stage list
(Overview / Availability / Options / Vote / Result), which on mobile only exists as a
progress indicator. Navigation state lives in the router and is treated as
application state at every breakpoint, so this is one presenter reading the same
state, not three navigation implementations.

### The options screen

This is the screen the breakpoints exist for.

- **Mobile** — map and list are two tabs. Choosing a pin and reading its numbers
  costs a tap, and the detail explanation is a separate screen.
- **Tablet portrait** — the tab switch disappears. Map on top, full-width list below,
  both visible. Each card has room to show one bar per member side by side.
- **Laptop / landscape** — three panes with no navigation at all: list, map, and the
  "Why this one?" detail simultaneously. Selecting a card pans the map and swaps the
  detail pane. `↑ ↓` moves the selection.

The same `OptionsPresenter` feeds all three. The breakpoint decides which views are
mounted, not what data is selected.

### Detail and voting

Mobile keeps these as screens 6 and 7. Tablet portrait merges them so the reasoning
and the vote are on one screen. The laptop layout goes further and puts the result
preview next to the votes, which is what makes it safe to show the organiser's
irreversible "Close vote & confirm" with its consequences visible.

### Cards per row

One (mobile) → two (tablet) → three (laptop). Same card, same copy, same type scale.

### Forms

Mobile is one field per vertical step. Tablet portrait splits the step into two
columns so a wizard step fits without scrolling. The laptop layout adds a persistent
summary panel in the third of the screen mobile cannot spare, so the consequences of
the form are visible while it is being filled in.

---

## What deliberately does not change

- **The type scale.** 14 / 11.5 / 11 / 10 / 9 px at every breakpoint. Wider screens
  get more columns, not bigger text.
- **Colour, spacing rhythm, corner radii, and the component shapes.**
- **Copy.** The same labels and the same explanations everywhere, so a user who
  learns the app on a phone is not relearning it on a laptop.
- **One obvious primary action per screen.**
- **Information parity.** Nothing reachable on mobile is dropped at a larger width,
  and nothing is laptop-only except *arrangement*. The readiness panel and the
  summary panel show derived state that mobile also has — mobile just surfaces it
  as a line of text instead of a panel.
- **Per-member travel bars.** Never collapsed to an average, at any width.
- **Partial-failure behaviour.** A failing data source degrades one card. It never
  replaces a pane or a screen with an error.

---

## Accessibility notes that are breakpoint-dependent

- The list route to every option is complete at all three widths, so the map is never
  the only way to reach information. At the laptop width the map sits between two
  usable panes rather than being the primary surface.
- Touch targets stay at mobile sizing on the tablet breakpoints — tablets are touch
  devices, so the laptop layout keeps the same hit areas even though a pointer could
  manage smaller ones.
- Focus order follows the DOM: sidebar → content header → primary pane → secondary
  panes. The three-pane view does not trap focus in the map.
- The icon rail labels its icons. No icon-only navigation at any width.

---

## Implementation note

The breakpoint is read once and published into application state, so presenters
select a layout the same way they select any other state. Views stay unaware of
media queries.

```js
// model/layoutSlice.js — one source of truth, no media queries in views
const breakpoint = width < 600 ? 'mobile'
                 : width < 1024 ? 'tabletPortrait'
                 : 'wide';
```

This keeps the responsive behaviour inside the architecture the course is grading
rather than scattering `window.matchMedia` calls through the view layer. It also
means the layout can be forced during a user test without resizing a window.
