import SwiftUI
import SwiftData
import PencilKit
import UIKit

/// Canvas — Variant A: bottom toolbar (kid-mode) or left rail (complex-mode).
///
/// Layering, bottom to top:
///   white sheet → raster fill layer (paint bucket) → template line art
///   (glyph or photo-magic image) → PencilKit strokes.
/// The bucket floods the raster layer; template lines and kid strokes act as walls.
struct CanvasView: View {
    let templateID: String?
    let drawingID: UUID?
    var photoTemplatePNG: Data? = nil

    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    @State private var canvas = PKCanvasView()
    @State private var selectedColor: Color = Theme.Palette.accentRed
    // Bucket first: tap-to-fill is the core toddler interaction.
    @State private var selectedTool: ToolKind = .bucket
    @State private var ageMode: AgeMode = .simple
    @State private var drawing: Drawing?
    @State private var resolvedTemplateID: String?
    @State private var photoTemplate: UIImage?
    @State private var fillLayer: UIImage?
    @State private var fillHistory: [UIImage?] = []
    @State private var canvasSize: CGSize = .zero
    @State private var didSave = false

    private static let glyphPadding: CGFloat = 40
    private static let photoPadding: CGFloat = 24

    var body: some View {
        ZStack {
            PaperBackground()
            VStack(spacing: 0) {
                topBar
                canvasArea
                if ageMode == .simple { bottomToolbar }
            }
            if ageMode == .complex {
                HStack {
                    leftRail
                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear(perform: load)
        .onDisappear(perform: save)
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Theme.Palette.ink)
                    .padding(12)
                    .background(Circle().fill(.white))
                    .overlay(Circle().stroke(Theme.Palette.ink, lineWidth: 2))
                    .hardShadow()
            }
            Spacer()
            AgeModeToggle(mode: $ageMode)
            Spacer()
            SketchyPill(label: "Done", fill: Theme.Palette.accentTeal) {
                dismiss()
            }
        }
        .padding(20)
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
                    .allowsHitTesting(selectedTool != .bucket)
                if selectedTool == .bucket {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture(coordinateSpace: .local) { point in
                            bucketTap(at: point, in: geo.size)
                        }
                }
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Theme.Palette.ink, lineWidth: 2)
                    .allowsHitTesting(false)
            }
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

    // MARK: Bottom toolbar (simple)

    private var bottomToolbar: some View {
        HStack(spacing: 18) {
            ToolButton(kind: .crayon, selected: $selectedTool)
            ToolButton(kind: .bucket, selected: $selectedTool)
            ToolButton(kind: .eraser, selected: $selectedTool)
            Divider().frame(height: 32)
            HStack(spacing: 10) {
                ForEach(Theme.Palette.crayonPalette.indices, id: \.self) { i in
                    let c = Theme.Palette.crayonPalette[i]
                    ColorChip(color: c, size: 40, selected: c == selectedColor)
                        .onTapGesture { selectedColor = c }
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
        VStack(spacing: 14) {
            ForEach([ToolKind.pencil, .crayon, .marker, .bucket, .eraser, .undo, .redo],
                    id: \.self) { t in
                ToolButton(kind: t, selected: $selectedTool) {
                    if t == .undo { undoLast() }
                    else if t == .redo { canvas.undoManager?.redo() }
                }
            }
            Divider().frame(width: 36)
            ForEach(Theme.Palette.crayonPalette.indices, id: \.self) { i in
                let c = Theme.Palette.crayonPalette[i]
                ColorChip(color: c, size: 32, selected: c == selectedColor)
                    .onTapGesture { selectedColor = c }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 22).fill(.white)
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(Theme.Palette.ink, lineWidth: 2))
        )
        .hardShadow()
        .padding(.leading, 14).padding(.top, 84)
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
            fillHistory.append(fillLayer)
            fillLayer = newLayer
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
        if !fillHistory.isEmpty {
            fillLayer = fillHistory.removeLast()
        } else {
            canvas.undoManager?.undo()
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
    }

    private func save() {
        guard !didSave else { return }
        didSave = true

        let isEmpty = canvas.drawing.strokes.isEmpty && fillLayer == nil
        if isEmpty && drawing == nil { return }   // nothing to keep

        let strokes = canvas.drawing.dataRepresentation()
        let thumb = thumbnailPNGData()

        if let drawing {
            drawing.strokesData = strokes
            drawing.fillPNG = fillLayer?.pngData()
            drawing.thumbnailPNG = thumb ?? drawing.thumbnailPNG
            drawing.updatedAt = .now
        } else {
            let d = Drawing(title: template?.title ?? (photoTemplate != nil ? "Photo magic" : "Untitled"),
                            templateID: resolvedTemplateID,
                            strokesData: strokes,
                            fillPNG: fillLayer?.pngData(),
                            photoTemplatePNG: photoTemplate?.pngData(),
                            thumbnailPNG: thumb,
                            inProgress: true)
            ctx.insert(d)
        }
        try? ctx.save()
    }

    /// White sheet + fills + template + strokes flattened for tiles/shelves.
    @MainActor
    private func thumbnailPNGData() -> Data? {
        let size = canvasSize.width > 1 ? canvasSize : CGSize(width: 800, height: 600)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let img = UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            fillLayer?.draw(in: CGRect(origin: .zero, size: size))
            templateUIImage(size: size)?.draw(at: .zero, blendMode: .multiply, alpha: 1)
            canvas.drawing.image(from: CGRect(origin: .zero, size: size), scale: 1)
                .draw(at: .zero)
        }
        return img.pngData()
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
    case pencil, crayon, marker, bucket, eraser, undo, redo

    var symbol: String {
        switch self {
        case .pencil:  return "pencil.tip"
        case .crayon:  return "scribble"
        case .marker:  return "highlighter"
        case .bucket:  return "drop.fill"
        case .eraser:  return "eraser"
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
            else { selected = kind; onTap?() }
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

// MARK: - PencilKit bridge

struct PKCanvasViewRepresentable: UIViewRepresentable {
    @Binding var canvas: PKCanvasView
    @Binding var color: Color
    @Binding var tool: ToolKind

    func makeUIView(context: Context) -> PKCanvasView {
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.drawingPolicy = .anyInput
        applyTool()
        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        applyTool()
    }

    private func applyTool() {
        let uiColor = UIColor(color)
        switch tool {
        case .pencil:  canvas.tool = PKInkingTool(.pencil, color: uiColor, width: 3)
        case .crayon:  canvas.tool = PKInkingTool(.pen,    color: uiColor, width: 14)
        case .marker:  canvas.tool = PKInkingTool(.marker, color: uiColor.withAlphaComponent(0.6), width: 22)
        case .eraser:  canvas.tool = PKEraserTool(.bitmap)
        case .bucket, .undo, .redo: break   // bucket handled by tap overlay
        }
    }
}
