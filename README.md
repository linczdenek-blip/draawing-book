# DoodlePop — iPad coloring app for kids

SwiftUI iPad app for kids 3–7 to color templates, free-draw on a blank page,
or magically turn a photo into a coloring page. Local-first MVP — no accounts,
no backend.

This implementation follows the **Drawing App Wireframes** handoff bundle from
Claude Design. Selected directions:

- **Home — Variant A**: two giant start tiles (Blank page · Photo magic) above a
  recent-drawings strip.
- **Templates — Netflix shelves**: horizontal shelves per category, with a
  "My drawings" shelf on top and difficulty filter pills.
- **Canvas — Variant A**: bottom toolbar (kid-mode `2–4`) or left rail
  (complex-mode `5–7`) toggled by the age switch in the top bar.
- **Photo Magic**: PhotosPicker → Core Image edge-detection pipeline → tap
  "Color it!" to open Canvas.

## Design tokens (mirrored from the wireframe CSS)

| Token            | Value     |
| ---------------- | --------- |
| Paper            | `#F6F1E6` |
| Ink              | `#1F1D1A` |
| Muted            | `#7C766C` |
| Accent (red)     | `#FF6B6B` |
| Accent (yellow)  | `#FFD23F` |
| Accent (teal)    | `#4EC3A8` |
| Accent (blue)    | `#5BA8E0` |
| Accent (purple)  | `#C89BF2` |
| Accent (peach)   | `#F7A072` |
| Hard shadow      | `4 4 0 ink` |

Fonts: **Caveat** (titles), **Patrick Hand** (body). Drop both `.ttf` files into
`DoodlePop/Resources/Fonts/` and they will register via `UIAppFonts` in
`Info.plist`.

## Project layout

```
DoodlePop/
  DoodlePopApp.swift         # @main, SwiftData container
  Info.plist                 # iPad landscape, photo + camera usage strings
  DesignSystem/
    Theme.swift              # palette, fonts, hard shadow modifier
    PaperBackground.swift    # warm paper + dot grid
  Models/
    Drawing.swift            # @Model — saved drawing with thumbnail
    Template.swift           # bundled coloring-page templates
  Views/
    RootView.swift           # NavigationStack + routes
    HomeView.swift           # Wireframe Home A
    TemplatesView.swift      # Netflix shelves
    CanvasView.swift         # PencilKit + tools + age-mode toggle
    PhotoMagicView.swift     # photo → coloring page (CIEdges pipeline)
    Components/
      SketchyShapes.swift    # SketchyCard, Squiggle, TapeTag, ColorChip, SketchyPill
      GlyphView.swift        # detailed line-art glyphs (cat, dog, dino, …)
```

## Bringing it into Xcode

1. Open Xcode → **New Project → App** (iOS, SwiftUI, Swift, bundle ID e.g.
   `com.yourname.doodlepop`).
2. Delete the placeholder `ContentView.swift` / `App.swift`, then drag the
   `DoodlePop/DoodlePop/` folder into the project navigator (check
   *Copy items if needed*, *Create groups*).
3. Set the target deployment to **iPadOS 17.0+** and **Device family: iPad**.
   Enable landscape only.
4. Add the two font files to `DoodlePop/Resources/Fonts/` and the target's
   **Build Phases → Copy Bundle Resources**.
5. Build & run on an iPad simulator (iPad Pro 11" landscape recommended).

## What's stubbed for later

- **Flood fill (paint bucket)**: currently maps to a thick pen. Replace with a
  Metal-backed raster floodfill that diffs into the strokes layer.
- **Stickers / glitter**: tool icons exist; tap to insert is not implemented.
- **Mascot guide & coloring music** (mentioned in chat): not in MVP.
- **Guided Access / parental lock**: deferred per design chat.
