import SwiftUI

/// Rounded rectangle with ink outline + hard offset shadow (the wireframe's "SkRect").
struct SketchyCard<Content: View>: View {
    var fill: Color = .white
    var corner: CGFloat = 24
    var strokeWidth: CGFloat = 2
    var shadow: ShadowSpec = Theme.hardShadow
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(fill)
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .stroke(Theme.Palette.ink, lineWidth: strokeWidth)
            content()
        }
        .hardShadow(shadow)
    }
}

/// A short hand-drawn squiggle underline.
struct Squiggle: View {
    var width: CGFloat = 130
    var color: Color = Theme.Palette.accentRed
    var lineWidth: CGFloat = 3
    var body: some View {
        Canvas { ctx, size in
            var path = Path()
            let segments = max(6, Int(size.width / 14))
            let amp: CGFloat = 4
            for i in 0...segments {
                let x = CGFloat(i) / CGFloat(segments) * size.width
                let y = size.height / 2 + (i % 2 == 0 ? -amp : amp)
                if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                else { path.addLine(to: CGPoint(x: x, y: y)) }
            }
            ctx.stroke(path, with: .color(color),
                       style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
        }
        .frame(width: width, height: 12)
    }
}

/// Yellow tilted "tag" pill like the wireframe variant labels.
struct TapeTag: View {
    let text: String
    var tilt: Double = -2
    var body: some View {
        Text(text)
            .font(Theme.Fonts.caveat(18))
            .padding(.horizontal, 10).padding(.vertical, 2)
            .background(
                Capsule().fill(Theme.Palette.accentYellow)
            )
            .overlay(Capsule().stroke(Theme.Palette.ink, lineWidth: 1.5))
            .rotationEffect(.degrees(tilt))
    }
}

/// Filled color chip with ink outline (palette swatch).
struct ColorChip: View {
    let color: Color
    var size: CGFloat = 36
    var selected: Bool = false
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .overlay(Circle().stroke(Theme.Palette.ink, lineWidth: 1.5))
            .overlay(
                Circle().stroke(Theme.Palette.ink, lineWidth: selected ? 3 : 0)
                    .padding(-5)
            )
    }
}

/// "SkPill" — handwritten pill button.
struct SketchyPill: View {
    let label: String
    var fill: Color = .white
    var foreground: Color = Theme.Palette.ink
    var size: CGFloat = 18
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(Theme.Fonts.hand(size))
                .foregroundStyle(foreground)
                .padding(.horizontal, 16).padding(.vertical, 8)
                .background(Capsule().fill(fill))
                .overlay(Capsule().stroke(Theme.Palette.ink, lineWidth: 2))
                .hardShadow()
        }
        .buttonStyle(.plain)
    }
}
