import SwiftUI

/// Notebook-paper feel: warm paper + faint dot grid (matches wireframe body bg).
struct PaperBackground: View {
    var notebookLines: Bool = false

    var body: some View {
        ZStack {
            Theme.Palette.paper.ignoresSafeArea()
            Canvas { ctx, size in
                let step: CGFloat = 22
                let dot: CGFloat = 1.2
                let color1 = Color.black.opacity(0.06)
                let color2 = Color.black.opacity(0.04)
                var y: CGFloat = 0
                while y < size.height {
                    var x: CGFloat = 0
                    let offset: CGFloat = (Int(y / step) % 2 == 0) ? 0 : step / 2
                    while x < size.width {
                        let p = CGRect(x: x + offset, y: y, width: dot, height: dot)
                        ctx.fill(Path(ellipseIn: p), with: .color(Int(y / step) % 2 == 0 ? color1 : color2))
                        x += step
                    }
                    y += step
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            if notebookLines {
                Canvas { ctx, size in
                    var y: CGFloat = 28
                    while y < size.height {
                        var path = Path()
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                        ctx.stroke(path, with: .color(.black.opacity(0.07)), lineWidth: 1)
                        y += 30
                    }
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }
        }
    }
}
