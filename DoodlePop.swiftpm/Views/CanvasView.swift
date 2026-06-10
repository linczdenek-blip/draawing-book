import SwiftUI
import SwiftData
import PencilKit
import UIKit

/// Canvas — Variant A: bottom toolbar (kid-mode) or left rail (complex-mode).
///
/// Layering, bottom to top:
///   white sheet → raster fill layer (paint bucket) → template line art
///   (glyph or photo-magic image, multiply-blended) → PencilKit strokes →
///   stickers.
/// The bucket floods the raster layer; template lines and kid strokes act as walls.
struct CanvasView: View {
    let templateID: String?
    let drawingID: UUID?
    var photoTemplatePNG: Data? = nil

    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @AppStorage("currentProfileID") private var currentProfileID: String = ""

    @State private var canvas = PKCanvasView()
    @State private var selectedColor: Color = Theme.Palette.accentRed
    // Bucket first: tap-to-fill is the core toddler interaction.
    @State private var selectedTool: ToolKind = .bucket
    @State private var selectedSticker = "⭐"
    @State private var ageMode: AgeMode = .simple
    @State private var drawing: Drawing?
    @State private var resolvedTemplateID: String?
    @State private var photoTemplate: UIImage?
    @State private var fillLayer: UIImage?
    @State private var stickers: [PlacedSticker] = []
    @State private var actionLog: [CanvasAction] = []
    @State private var canvasSize: CGSize = .zero
    @State private var zoom: CGFloat = 1
    @State private var panOffset: CGSize = .zero
    @State private var panStart: CGSize = .zero
    @State private var celebrating = false
    @State private var showGate = false
    @State private var showShare = false
    @State private var shareImage: UIImage?
    @State private var didSave = false

    private static let glyphPadding: CGFloat = 40
    private static let photoPadding: CGFloat = 24
    private static let stickerTray = ["⭐", "❤️", "🌈", "😄", "🦋", "🌸", "👑", "⚽"]

    enum CanvasAction {
        case fill(previous: UIImage?)
        case sticker
    }

    var body: some View {
        ZStack {
            PaperBackground()
            VStack(spacing: 0) {
                topBar
                canvasArea
                if selectedTool == .sticker { stickerTrayBar }
                if ageMode == .simple { bottomToolbar }
            }
            if ageMode == .complex {
                HStack {
                    leftRail
                    Spacer()
                }
            }
            if celebrating {
                ConfettiView()
                CelebrationBadge()
            }
        }
        .navigationBarHidden(true)
        .onAppear(perform: load)
        .onDisappear(perform: save)
        .sheet(isPresented: $showGate) {
            ParentGateView {
                shareImage = compositeImage()
                showShare = true
            }
        }
        .sheet(isPresented: $showShare) {
            if let img = shareImage {
                ShareSheet(items: [img])
            }
        }
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack(spacing: 14) {
            Button { dismiss() } label: {
                roundIcon("chevron.left")
            }
            Spacer()
            AgeModeToggle(mode: $ageMode)
            Button { cycleZoom() } label: {
                roundIcon(zoom > 1 ? "minus.magnifyingglass" : "plus.magnifyingglass")
            }
            Spacer()
            Button { showGate = true } label: {
                roundIcon("square.and.arrow.up")
            }
            SketchyPill(label: "Done", fill: Theme.Palette.accentTeal) {
                finishAndCelebrate()
            }
        }
        .padding(20)
    }

    private func roundIcon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(Theme.Palette.ink)
            .frame(width: 46, height: 46)
            .background(Circle().fill(.white))
            .overlay(Circle().stroke(Theme.Palette.ink, lineWidth: 2))
            .hardShadow()
    }

    // MARK: Canvas

    private var canvasArea: some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: 18).fill(.white)
                if let fill = fillLayer {
                    Image(uiImage: fill)
                        .resizable()
                        .allowsHitTesting(false)
                }
                templateLayer
                PKCanvasViewRepresentable(canvas: $canvas, color: $selectedColor, tool: $selectedTool)
                    .allowsHitTesting(selectedTool != .bucket
                                      && selectedTool != .sticker
                                      && selectedTool != .move)
                stickersLayer(size: geo.size)
                if selectedTool == .bucket || selectedTool == .sticker {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture(coordinateSpace: .local) { point in
                            if selectedTool == .bucket {
                                bucketTap(at: point, in: geo.size)
                            } else {
                                placeSticker(at: point, in: geo.size)
                            }
                        }
                }
                if selectedTool == .move {
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture()
                                .onChanged { v in
                                    panOffset = clampPan(
                                        CGSize(width: panStart.width + v.translation.width,
                                               height: panStart.height + v.translation.height),
                                        in: geo.size)
                                }
                                .onEnded { _ in panStart = panOffset }
                        )
                }
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Theme.Palette.ink, lineWidth: 2)
                    .allowsHitTesting(false)
            }
            .scaleEffect(zoom)
            .offset(panOffset)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .onAppear { canvasSize = geo.size }
            .onChange(of: geo.size) { _, new in canvasSize = new }
        }
        .hardShadow()
        .padding(.horizontal, 28)
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private var templateLayer: some View {
        if let glyph = template?.glyph {
            GlyphView(kind: glyph, lineWidth: 3)
                .padding(Self.glyphPadding)
                .allowsHitTesting(false)
        } else if let img = photoTemplate {
            // Multiply lets the white background pass fills through; only the
            // dark lines stay visible.
            Image(uiImage: img)
                .resizable()
                .scaledToFit()
                .padding(Self.photoPadding)
                .blendMode(.multiply)
                .allowsHitTesting(false)
        }
    }

    private func stickersLayer(size: CGSize) -> some View {
        ForEach(stickers) { s in
            Text(s.emoji)
                .font(.system(size: s.size))
                .position(x: s.relX * size.width, y: s.relY * size.height)
                .allowsHitTesting(false)
        }
    }

    // MARK: Sticker tray

    private var stickerTrayBar: some View {
        HStack(spacing: 14) {
            ForEach(Self.stickerTray, id: \.self) { emoji in
                Button {
                    selectedSticker = emoji
                    SoundFX.toolTap()
                } label: {
                    Text(emoji)
                        .font(.system(size: 34))
                        .frame(width: 56, height: 56)
                        .background(
                            Circle().fill(selectedSticker == emoji
                                          ? Theme.Palette.accentYellow : .white)
                        )
                        .overlay(Circle().stroke(Theme.Palette.ink, lineWidth: 2))
                }
                .buttonStyle(.plain)
            }
            Spacer()
            Text("Tap the page to stick!")
                .font(Theme.Fonts.hand(16))
                .foregroundStyle(Theme.Palette.muted)
        }
        .padding(.horizontal, 28).padding(.bottom, 8)
    }

    // MARK: Bottom toolbar (simple)

    private var bottomToolbar: some View {
        HStack(spacing: 18) {
            ToolButton(kind: .bucket, selected: $selectedTool)
            ToolButton(kind: .crayon, selected: $selectedTool)
            ToolButton(kind: .rainbow, selected: $selectedTool)
            ToolButton(kind: .sticker, selected: $selectedTool)
            ToolButton(kind: .eraser, selected: $selectedTool)
            if zoom > 1 { ToolButton(kind: .move, selected: $selectedTool) }
            Divider().frame(height: 32)
            HStack(spacing: 10) {
                ForEach(Theme.Palette.crayonPalette.indices, id: \.self) { i in
                    let c = Theme.Palette.crayonPalette[i]
                    ColorChip(color: c, size: 40, selected: c == selectedColor)
                        .onTapGesture { selectedColor = c; SoundFX.toolTap() }
                }
            }
            Spacer()
            ToolButton(kind: .undo, selected: .constant(.undo)) { undoLast() }
            ToolButton(kind: .redo, selected: .constant(.redo)) { canvas.undoManager?.redo() }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22).fill(.white)
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(Theme.Palette.ink, lineWidth: 2))
        )
        .hardShadow()
        .padding(.horizontal, 28).padding(.bottom, 24)
    }

    // MARK: Left rail (complex)

    private var leftRail: some View {
        VStack(spacing: 12) {
            let rail: [ToolKind] = [.pencil, .crayon, .marker, .rainbow, .bucket, .sticker, .eraser]
                + (zoom > 1 ? [.move] : [])
                + [.undo, .redo]
            ForEach(rail, id: \.self) { t in
                ToolButton(kind: t, selected: $selectedTool) {
                    if t == .undo { undoLast() }
                    else if t == .redo { canvas.undoManager?.redo() }
                }
            }
            Divider().frame(width: 36)
            ForEach(Theme.Palette.crayonPalette.indices, id: \.self) { i in
                let c = Theme.Palette.crayonPalette[i]
                ColorChip(color: c, size: 30, selected: c == selectedColor)
                    .onTapGesture { selectedColor = c; SoundFX.toolTap() }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 22).fill(.white)
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(Theme.Palette.ink, lineWidth: 2))
        )
        .hardShadow()
        .padding(.leading, 14).padding(.top, 84)
    }

    // MARK: Zoom / pan

    private func cycleZoom() {
        SoundFX.toolTap()
        withAnimation(.spring(response: 0.35)) {
            if zoom > 1 {
                zoom = 1
                panOffset = .zero
                panStart = .zero
                if selectedTool == .move { selectedTool = .crayon }
            } else {
                zoom = 2
            }
        }
    }

    private func clampPan(_ proposed: CGSize, in size: CGSize) -> CGSize {
        let maxX = size.width * (zoom - 1) / 2
        let maxY = size.height * (zoom - 1) / 2
        return CGSize(width: min(maxX, max(-maxX, proposed.width)),
                      height: min(maxY, max(-maxY, proposed.height)))
    }

    // MARK: Stickers

    private func placeSticker(at point: CGPoint, in size: CGSize) {
        guard size.width > 1 else { return }
        stickers.append(PlacedSticker(emoji: selectedSticker,
                                      relX: point.x / size.width,
                                      relY: point.y / size.height))
        actionLog.append(.sticker)
        SoundFX.stickerPlop()
    }

    // MARK: Bucket / flood fill

    private func bucketTap(at point: CGPoint, in size: CGSize) {
        guard size.width > 1 else { return }
        let walls = wallsImage(size: size)
        let newLayer = FloodFill.fill(layer: fillLayer,
                                      walls: walls,
                                      size: size,
                                      seed: point,
                                      color: UIColor(selectedColor))
        if newLayer !== fillLayer {
            actionLog.append(.fill(previous: fillLayer))
            fillLayer = newLayer
            SoundFX.fillPop()
        }
    }

    /// Composite of template line art + kid strokes, in display coordinates.
    @MainActor
    private func wallsImage(size: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            if let img = templateUIImage(size: size) {
                img.draw(at: .zero)
            }
            let strokes = canvas.drawing.image(
                from: CGRect(origin: .zero, size: size), scale: 1)
            strokes.draw(at: .zero)
        }
    }

    /// Template rendered exactly as displayed (same padding / aspect fit).
    @MainActor
    private func templateUIImage(size: CGSize) -> UIImage? {
        if let glyph = template?.glyph {
            let inner = CGSize(width: size.width - 2 * Self.glyphPadding,
                               height: size.height - 2 * Self.glyphPadding)
            guard inner.width > 0, inner.height > 0 else { return nil }
            let renderer = ImageRenderer(
                content: GlyphView(kind: glyph, lineWidth: 3)
                    .frame(width: inner.width, height: inner.height))
            renderer.scale = 1
            guard let img = renderer.uiImage else { return nil }
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            return UIGraphicsImageRenderer(size: size, format: format).image { _ in
                img.draw(in: CGRect(origin: CGPoint(x: Self.glyphPadding, y: Self.glyphPadding),
                                    size: inner))
            }
        }
        if let photo = photoTemplate {
            let frame = CGRect(origin: .zero, size: size)
                .insetBy(dx: Self.photoPadding, dy: Self.photoPadding)
                .aspectFit(photo.size)
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            return UIGraphicsImageRenderer(size: size, format: format).image { _ in
                photo.draw(in: frame)
            }
        }
        return nil
    }

    private func undoLast() {
        SoundFX.toolTap()
        switch actionLog.popLast() {
        case .fill(let previous):
            fillLayer = previous
        case .sticker:
            if !stickers.isEmpty { stickers.removeLast() }
        case nil:
            canvas.undoManager?.undo()
        }
    }

    // MARK: Celebration

    private func finishAndCelebrate() {
        let isEmpty = canvas.drawing.strokes.isEmpty && fillLayer == nil && stickers.isEmpty
        if isEmpty {
            dismiss()
            return
        }
        SoundFX.celebrate()
        celebrating = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            dismiss()
        }
    }

    // MARK: Data

    private var template: Template? {
        guard let id = resolvedTemplateID else { return nil }
        return TemplateLibrary.all.first { $0.id == id }
    }

    private func load() {
        resolvedTemplateID = templateID
        if let data = photoTemplatePNG {
            photoTemplate = UIImage(data: data)
        }
        guard let did = drawingID else { return }
        let fetch = FetchDescriptor<Drawing>(predicate: #Predicate { $0.id == did })
        guard let found = try? ctx.fetch(fetch).first else { return }
        drawing = found
        resolvedTemplateID = found.templateID ?? templateID
        if let data = found.strokesData,
           let pk = try? PKDrawing(data: data) {
            canvas.drawing = pk
        }
        if let data = found.fillPNG {
            fillLayer = UIImage(data: data)
        }
        if photoTemplate == nil, let data = found.photoTemplatePNG {
            photoTemplate = UIImage(data: data)
        }
        if let data = found.stickersJSON,
           let decoded = try? JSONDecoder().decode([PlacedSticker].self, from: data) {
            stickers = decoded
        }
    }

    private func save() {
        guard !didSave else { return }
        didSave = true

        let isEmpty = canvas.drawing.strokes.isEmpty && fillLayer == nil && stickers.isEmpty
        if isEmpty && drawing == nil { return }   // nothing to keep

        let strokes = canvas.drawing.dataRepresentation()
        let thumb = compositeImage()?.pngData()
        let stickerData = try? JSONEncoder().encode(stickers)
        let profileUUID = UUID(uuidString: currentProfileID)

        if let drawing {
            drawing.strokesData = strokes
            drawing.fillPNG = fillLayer?.pngData()
            drawing.stickersJSON = stickerData
            drawing.thumbnailPNG = thumb ?? drawing.thumbnailPNG
            drawing.updatedAt = .now
        } else {
            let d = Drawing(title: template?.title ?? (photoTemplate != nil ? "Photo magic" : "Untitled"),
                            templateID: resolvedTemplateID,
                            strokesData: strokes,
                            fillPNG: fillLayer?.pngData(),
                            photoTemplatePNG: photoTemplate?.pngData(),
                            thumbnailPNG: thumb,
                            stickersJSON: stickerData,
                            profileID: profileUUID,
                            inProgress: true)
            ctx.insert(d)
        }
        try? ctx.save()
    }

    /// White sheet + fills + template + strokes + stickers — used for both
    /// thumbnails and sharing/printing.
    @MainActor
    private func compositeImage() -> UIImage? {
        let size = canvasSize.width > 1 ? canvasSize : CGSize(width: 800, height: 600)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2
        return UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            fillLayer?.draw(in: CGRect(origin: .zero, size: size))
            templateUIImage(size: size)?.draw(at: .zero, blendMode: .multiply, alpha: 1)
            canvas.drawing.image(from: CGRect(origin: .zero, size: size), scale: 1)
                .draw(at: .zero)
            for s in stickers {
                let font = UIFont.systemFont(ofSize: s.size)
                let str = NSAttributedString(string: s.emoji, attributes: [.font: font])
                let bounds = str.size()
                str.draw(at: CGPoint(x: s.relX * size.width - bounds.width / 2,
                                     y: s.relY * size.height - bounds.height / 2))
            }
        }
    }
}

// MARK: - Age mode

enum AgeMode: String, CaseIterable, Identifiable {
    case simple = "2–4", complex = "5–7"
    var id: String { rawValue }
}

private struct AgeModeToggle: View {
    @Binding var mode: AgeMode
    var body: some View {
        HStack(spacing: 0) {
            ForEach(AgeMode.allCases) { m in
                Button { mode = m } label: {
                    Text(m.rawValue)
                        .font(Theme.Fonts.hand(16))
                        .foregroundStyle(mode == m ? Theme.Palette.paper : Theme.Palette.ink)
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .background(mode == m ? Theme.Palette.ink : .clear)
                }
                .buttonStyle(.plain)
            }
        }
        .background(Capsule().fill(.white))
        .overlay(Capsule().stroke(Theme.Palette.ink, lineWidth: 2))
        .clipShape(Capsule())
        .hardShadow()
    }
}

// MARK: - Tools

enum ToolKind: String, Hashable {
    case pencil, crayon, marker, rainbow, bucket, sticker, eraser, move, undo, redo

    var symbol: String {
        switch self {
        case .pencil:  return "pencil.tip"
        case .crayon:  return "scribble"
        case .marker:  return "highlighter"
        case .rainbow: return "rainbow"
        case .bucket:  return "drop.fill"
        case .sticker: return "star.circle.fill"
        case .eraser:  return "eraser"
        case .move:    return "hand.draw"
        case .undo:    return "arrow.uturn.backward"
        case .redo:    return "arrow.uturn.forward"
        }
    }
}

private struct ToolButton: View {
    let kind: ToolKind
    @Binding var selected: ToolKind
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button {
            if kind == .undo || kind == .redo { onTap?() }
            else { selected = kind; SoundFX.toolTap(); onTap?() }
        } label: {
            Image(systemName: kind.symbol)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Theme.Palette.ink)
                .frame(width: 48, height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(selected == kind ? Theme.Palette.accentYellow : .white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14).stroke(Theme.Palette.ink, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Rainbow color cycling

enum RainbowCycler {
    static let colors: [UIColor] = [
        UIColor(Theme.Palette.accentRed),
        UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1),
        UIColor(Theme.Palette.accentYellow),
        UIColor(Theme.Palette.accentTeal),
        UIColor(Theme.Palette.accentBlue),
        UIColor(Theme.Palette.accentPurple),
        UIColor(red: 1.0, green: 0.5, blue: 0.75, alpha: 1)
    ]
    static var index = 0
    static var current: UIColor { colors[index % colors.count] }
    static func advance() { index = (index + 1) % colors.count }
}

// MARK: - PencilKit bridge

struct PKCanvasViewRepresentable: UIViewRepresentable {
    @Binding var canvas: PKCanvasView
    @Binding var color: Color
    @Binding var tool: ToolKind

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> PKCanvasView {
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.drawingPolicy = .anyInput
        canvas.delegate = context.coordinator
        applyTool()
        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        context.coordinator.parent = self
        applyTool()
    }

    fileprivate func applyTool() {
        let uiColor = UIColor(color)
        switch tool {
        case .pencil:  canvas.tool = PKInkingTool(.pencil, color: uiColor, width: 3)
        case .crayon:  canvas.tool = PKInkingTool(.pen,    color: uiColor, width: 14)
        case .marker:  canvas.tool = PKInkingTool(.marker, color: uiColor.withAlphaComponent(0.6), width: 22)
        case .rainbow: canvas.tool = PKInkingTool(.pen,    color: RainbowCycler.current, width: 16)
        case .eraser:  canvas.tool = PKEraserTool(.bitmap)
        case .bucket, .sticker, .move, .undo, .redo: break
        }
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: PKCanvasViewRepresentable
        private var strokeCount = 0

        init(_ parent: PKCanvasViewRepresentable) {
            self.parent = parent
        }

        // Each finished rainbow stroke advances to the next color.
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            let count = canvasView.drawing.strokes.count
            defer { strokeCount = count }
            guard parent.tool == .rainbow, count > strokeCount else { return }
            RainbowCycler.advance()
            canvasView.tool = PKInkingTool(.pen, color: RainbowCycler.current, width: 16)
        }
    }
}
