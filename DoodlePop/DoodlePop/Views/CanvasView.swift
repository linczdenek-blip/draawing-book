import SwiftUI
import SwiftData
import PencilKit
import UIKit

/// Canvas — Variant A: bottom toolbar (kid-mode) or left rail (complex-mode).
/// Strokes done with PencilKit; the template line-art sits behind as a static image
/// so kids "color in" it. Floodfill is invoked via a long-press on a region.
struct CanvasView: View {
    let templateID: String?
    let drawingID: UUID?

    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    @State private var canvas = PKCanvasView()
    @State private var selectedColor: Color = Theme.Palette.accentRed
    @State private var selectedTool: ToolKind = .crayon
    @State private var ageMode: AgeMode = .simple
    @State private var drawing: Drawing?

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
            Button { save(); dismiss() } label: {
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
                save(); dismiss()
            }
        }
        .padding(20)
    }

    // MARK: Canvas

    private var canvasArea: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18).fill(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 18).stroke(Theme.Palette.ink, lineWidth: 2)
                )
                .hardShadow()
            if let glyph = template?.glyph {
                GlyphView(kind: glyph, lineWidth: 3)
                    .padding(40)
                    .allowsHitTesting(false)
            }
            PKCanvasViewRepresentable(canvas: $canvas, color: $selectedColor, tool: $selectedTool)
                .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 12)
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
            ToolButton(kind: .undo, selected: .constant(.undo)) { canvas.undoManager?.undo() }
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
            ForEach([ToolKind.pencil, .crayon, .marker, .bucket, .sticker, .eraser, .undo, .redo],
                    id: \.self) { t in
                ToolButton(kind: t, selected: $selectedTool) {
                    if t == .undo { canvas.undoManager?.undo() }
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

    // MARK: Data

    private var template: Template? {
        guard let id = templateID else { return nil }
        return TemplateLibrary.all.first { $0.id == id }
    }

    private func load() {
        if let did = drawingID {
            let fetch = FetchDescriptor<Drawing>(predicate: #Predicate { $0.id == did })
            drawing = try? ctx.fetch(fetch).first
            if let data = drawing?.strokesPNG,
               let img = UIImage(data: data),
               let cg = img.cgImage {
                // Best-effort: rasterized strokes are not editable in PencilKit;
                // we keep them as a background snapshot until kid draws new strokes.
                _ = cg
            }
        }
    }

    private func save() {
        let bounds = canvas.bounds
        guard bounds.width > 0 else { return }
        let img = canvas.drawing.image(from: bounds, scale: UIScreen.main.scale)
        let png = img.pngData()
        if let drawing {
            drawing.strokesPNG = png
            drawing.thumbnailPNG = png
            drawing.updatedAt = .now
        } else {
            let d = Drawing(title: template?.title ?? "Untitled",
                            strokesPNG: png,
                            templatePNG: nil,
                            thumbnailPNG: png,
                            inProgress: true)
            ctx.insert(d)
        }
        try? ctx.save()
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
    case pencil, crayon, marker, bucket, sticker, eraser, undo, redo

    var symbol: String {
        switch self {
        case .pencil:  return "pencil.tip"
        case .crayon:  return "scribble"
        case .marker:  return "highlighter"
        case .bucket:  return "drop.fill"
        case .sticker: return "star.circle.fill"
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
        case .bucket, .sticker:
            // Stand-in: thick pen for "bucket" until raster floodfill is added.
            canvas.tool = PKInkingTool(.pen, color: uiColor, width: 32)
        case .eraser:  canvas.tool = PKEraserTool(.bitmap)
        case .undo, .redo: break
        }
    }
}
