# dh2642_interaction_programming

Proposal and design deliverables for **Catch Up!**, a meeting space planner —
DH2642 / ID2216 HT26 project.

```
dh2642_interaction_programming/
├── README.md                          this file
├── CatchUpSubmissionProposal_Short.txt   ** THE FILE TO SUBMIT **
│                                      154 lines, one numbered section per
│                                      required item, no admin content
├── CatchUpSubmissionProposal.txt      long version of the same, 754 lines,
│                                      adds scope/phases/risks and ASCII
│                                      wireframes if a fuller answer is wanted
├── CatchUp_Project_Proposal.md        working notes, incl. the mapping to the
│                                      grading criteria (not for submission)
├── CatchUp_Responsive_Spec.md         breakpoints and what changes at each
└── mockups/
    ├── CatchUp_Mobile_390.svg         authored wireframes — edit these
    ├── CatchUp_Mobile_390.png         rendered sheet, 10 screens
    ├── CatchUp_TabletPortrait_834.svg
    ├── CatchUp_TabletPortrait_834.png rendered sheet, 4 screens
    ├── CatchUp_Desktop_1280.svg
    ├── CatchUp_Desktop_1280.png       rendered sheet, 4 screens
    └── figma/
        ├── README.md                  how to import, and the design tokens
        ├── CatchUp_*.figma.svg        import these into Figma
        ├── flatten_for_figma.py       generates the above from the authored SVGs
        └── build_figma_svgs.sh        runs the generator for all three sheets
```

## Which file do I open?

| I want to… | Open |
|---|---|
| **Submit the proposal** | `CatchUpSubmissionProposal_Short.txt` + the three PNGs |
| Pad the answer out if asked for more | `CatchUpSubmissionProposal.txt` |
| Read the working notes | `CatchUp_Project_Proposal.md` |
| See the screens | the `.png` files in `mockups/` |
| Edit a wireframe | the `.svg` files in `mockups/` |
| Work in Figma | `mockups/figma/*.figma.svg` — see `mockups/figma/README.md` first |
| Know what changes at each screen size | `CatchUp_Responsive_Spec.md` |

## Regenerating

PNGs are rendered from the authored SVGs with headless Chrome:

```powershell
& "C:\Program Files\Google\Chrome\Application\chrome.exe" --headless --disable-gpu `
  --hide-scrollbars --window-size=1660,1340 `
  --screenshot="mockups\CatchUp_Mobile_390.png" `
  "file:///<abs-path>/mockups/CatchUp_Mobile_390.svg"
```

Window sizes per sheet: mobile `1660x1340`, tablet portrait `1340x1830`,
desktop `1984x1372`.

Figma copies:

```bash
bash mockups/figma/build_figma_svgs.sh
```

Edit the authored SVG, then regenerate both the PNG and the Figma copy so the three
stay in sync. The Figma copies are verified pixel-identical to the authored renders.

## Note on the authored SVGs

Styling lives in one `<style>` block per file, so a change to a class updates every
card. Because CSS class rules override SVG presentation attributes, a per-element
`font-size="22"` on an element that also has a class has **no effect** — the class
value wins. Change the class, or use `style="font-size:22px"` on the element.
