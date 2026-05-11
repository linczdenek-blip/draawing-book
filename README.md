# DoodlePop — iPad coloring app for kids

SwiftUI iPad app for kids 3–7 to color templates, free-draw on a blank page,
or magically turn a photo into a coloring page. Local-first MVP — no accounts,
no backend.

> Packaged as a **Swift Playgrounds App Package (`.swiftpm`)** so you can build
> and run it **directly on your iPad — no Mac, no Xcode, no Apple Developer
> account required**.

## Design (from the Claude Design wireframes)

- **Home — Variant A**: two giant start tiles (Blank page · Photo magic) above
  a recent-drawings strip.
- **Templates — Netflix shelves**: horizontal shelves per category, "My
  drawings" shelf on top, difficulty filter pills.
- **Canvas — Variant A**: bottom toolbar (age `2–4`) or left rail (age `5–7`)
  toggled by the age switch in the top bar. Drawing via PencilKit.
- **Photo Magic**: PhotosPicker → Core Image edge-detection → "Color it!"
  opens Canvas.

Palette: paper `#F6F1E6`, ink `#1F1D1A`, accents red/yellow/teal/blue/purple/peach,
4 4 0 hard offset shadow. Fonts: Caveat + Patrick Hand (graceful fallback to
system font if not installed).

---

## Install on iPad — step by step (no Mac needed)

### 1. Install Swift Playgrounds on the iPad

Open the **App Store** on the iPad → search **"Swift Playgrounds"** (made by
Apple) → install. It's free. Requires **iPadOS 17 or newer**.

### 2. Get the project onto the iPad

Pick the easiest option for you:

**A. Working Copy (recommended — pulls straight from GitHub)**
   1. Install **Working Copy** from the App Store (free for cloning).
   2. Open Working Copy → `+` → **Clone repository** → paste this repo's
      GitHub URL.
   3. Tap the cloned repo → tap `DoodlePop.swiftpm` → **Share → Open in
      Swift Playgrounds**.

**B. AirDrop from a computer**
   1. On a Mac/PC clone the repo:
      ```
      git clone <repo-url>
      ```
   2. AirDrop (Mac) or email/cloud-share the `DoodlePop.swiftpm` **folder**
      (it must keep the `.swiftpm` extension) to the iPad.
   3. iPad → Files app → tap the `.swiftpm` → it opens in Swift Playgrounds.

**C. iCloud Drive / Dropbox / Google Drive**
   - Upload the whole `DoodlePop.swiftpm` folder, on the iPad open it from
     Files. Same result.

### 3. Open in Swift Playgrounds

Swift Playgrounds shows DoodlePop on the *My Playgrounds* screen.
Tap it. The first build takes ~30 s.

### 4. Sign in with your Apple ID (one-time)

When you tap the **▶ Run** button (top-right), Playgrounds asks you to sign
in with an Apple ID to sign the app. A normal (free) Apple ID is fine — no
$99/yr developer account needed.

### 5. Run it

Tap **▶ Run** at the top right. The app launches full-screen on the iPad.

### 6. (Optional) Install it like a real app

To pin DoodlePop to the iPad home screen:

   Swift Playgrounds → DoodlePop tile → tap `•••` → **Add to Home Screen**.

Now it has its own icon and launches independently of Swift Playgrounds.
Free Apple ID-signed apps need to be re-built every **7 days** (re-open in
Swift Playgrounds and re-run). With a paid developer account, signing is good
for 1 year.

### 7. Update later

   - **Working Copy**: open repo → **Pull** → re-open in Swift Playgrounds.
   - **Other methods**: re-share the new `.swiftpm` folder over the previous one.

---

## Project layout

```
DoodlePop.swiftpm/
  Package.swift              # iOSApplication manifest (iPad, landscape, photo+camera)
  DoodlePopApp.swift         # @main, SwiftData container
  DesignSystem/
    Theme.swift              # palette, fonts, hard shadow modifier
    PaperBackground.swift    # warm paper + dot grid
  Models/
    Drawing.swift            # @Model — saved drawing with thumbnail
    Template.swift           # 12 bundled coloring-page templates
  Views/
    RootView.swift           # NavigationStack + routes
    HomeView.swift           # Wireframe Home A
    TemplatesView.swift      # Netflix shelves
    CanvasView.swift         # PencilKit + tools + age-mode toggle
    PhotoMagicView.swift     # photo → coloring page (CIEdges pipeline)
    Components/
      SketchyShapes.swift    # SketchyCard, Squiggle, TapeTag, ColorChip, SketchyPill
      GlyphView.swift        # hand-drawn line-art glyphs (cat, dog, dino, …)
```

## What's stubbed for later

- **Flood fill (paint bucket)**: currently maps to a thick pen. Replace with a
  Metal-backed raster floodfill.
- **Stickers / glitter**: tool icons exist; tap-to-insert is not implemented.
- **Mascot guide & coloring music**: not in MVP.
- **Guided Access / parental lock**: deferred.

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| "Untrusted developer" alert on first launch | iPad → Settings → General → VPN & Device Management → tap your Apple ID → **Trust**. |
| Fonts look like plain system text | Optional — drop `Caveat-Bold.ttf` and `PatrickHand-Regular.ttf` from [Google Fonts](https://fonts.google.com) into `DoodlePop.swiftpm/Resources/` and update `Package.swift` to list them under `resources:`. |
| Build fails: "Cannot find type 'Drawing' in scope" | Make sure the whole `.swiftpm` folder transferred (Files → check it's a *package*, not a single file). |
| App quits after 7 days | Re-open in Swift Playgrounds and tap Run again. |
