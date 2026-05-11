import SwiftUI

/// Detailed coloring-page line-art glyphs, drawn directly with Canvas.
/// Sized to fit a 100x100 unit and scaled to the given frame.
struct GlyphView: View {
    let kind: TemplateGlyph
    /// Show some pre-colored regions (for thumbnails) vs. plain outline (for canvas).
    var partial: Bool = false
    var lineWidth: CGFloat = 2.5

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height) / 100
            Canvas { ctx, _ in
                let ink = GraphicsContext.Shading.color(Theme.Palette.ink)
                let stroke = StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                drawGlyph(kind: kind, ctx: &ctx, scale: s,
                          stroke: stroke, ink: ink, partial: partial)
            }
        }
    }
}

private func drawGlyph(kind: TemplateGlyph,
                       ctx: inout GraphicsContext,
                       scale s: CGFloat,
                       stroke: StrokeStyle,
                       ink: GraphicsContext.Shading,
                       partial: Bool) {
    func u(_ n: CGFloat) -> CGFloat { n * s }
    let cx: CGFloat = 50 * s
    let cy: CGFloat = 50 * s

    func fillIf(_ c: Color) -> GraphicsContext.Shading {
        partial ? .color(c) : .color(.clear)
    }

    func stroked(_ build: (inout Path) -> Void, fill: Color? = nil) {
        var p = Path(); build(&p)
        if let fill { ctx.fill(p, with: .color(fill)) }
        ctx.stroke(p, with: ink, style: stroke)
    }

    switch kind {
    case .cat:
        // head
        stroked({ p in
            p.addEllipse(in: CGRect(x: cx-u(34), y: cy+u(5)-u(30), width: u(68), height: u(60)))
        }, fill: partial ? Theme.Palette.accentYellow : nil)
        // ears
        stroked({ p in
            p.move(to: CGPoint(x: cx-u(26), y: cy-u(20)))
            p.addLine(to: CGPoint(x: cx-u(34), y: cy-u(40)))
            p.addLine(to: CGPoint(x: cx-u(12), y: cy-u(24)))
            p.closeSubpath()
        }, fill: partial ? Theme.Palette.accentYellow : nil)
        stroked({ p in
            p.move(to: CGPoint(x: cx+u(26), y: cy-u(20)))
            p.addLine(to: CGPoint(x: cx+u(34), y: cy-u(40)))
            p.addLine(to: CGPoint(x: cx+u(12), y: cy-u(24)))
            p.closeSubpath()
        }, fill: partial ? Theme.Palette.accentYellow : nil)
        // eyes
        for sign: CGFloat in [-1, 1] {
            stroked({ p in
                p.addEllipse(in: CGRect(x: cx+sign*u(11)-u(4), y: cy-u(2)-u(6),
                                        width: u(8), height: u(12)))
            }, fill: partial ? Theme.Palette.ink : nil)
        }
        // nose
        stroked({ p in
            p.move(to: CGPoint(x: cx-u(3), y: cy+u(7)))
            p.addLine(to: CGPoint(x: cx+u(3), y: cy+u(7)))
            p.addLine(to: CGPoint(x: cx, y: cy+u(11)))
            p.closeSubpath()
        }, fill: partial ? Theme.Palette.accentRed : nil)
        // whiskers
        for sign: CGFloat in [-1, 1] {
            stroked { p in
                p.move(to: CGPoint(x: cx+sign*u(6), y: cy+u(12)))
                p.addLine(to: CGPoint(x: cx+sign*u(28), y: cy+u(8)))
            }
            stroked { p in
                p.move(to: CGPoint(x: cx+sign*u(6), y: cy+u(15)))
                p.addLine(to: CGPoint(x: cx+sign*u(28), y: cy+u(15)))
            }
        }
        // mouth
        stroked { p in
            p.move(to: CGPoint(x: cx, y: cy+u(11)))
            p.addLine(to: CGPoint(x: cx, y: cy+u(15)))
        }
    case .dog:
        stroked({ p in
            p.addEllipse(in: CGRect(x: cx-u(30), y: cy+u(8)-u(28), width: u(60), height: u(56)))
        }, fill: partial ? Theme.Palette.accentPeach : nil)
        // ears
        for sign: CGFloat in [-1, 1] {
            stroked({ p in
                p.move(to: CGPoint(x: cx+sign*u(24), y: cy-u(15)))
                p.addQuadCurve(to: CGPoint(x: cx+sign*u(30), y: cy+u(20)),
                               control: CGPoint(x: cx+sign*u(38), y: cy))
            }, fill: partial ? Theme.Palette.accentPeach : nil)
        }
        // eyes & nose
        for sign: CGFloat in [-1, 1] {
            stroked { p in
                p.addEllipse(in: CGRect(x: cx+sign*u(8)-u(3), y: cy-u(4)-u(3), width: u(6), height: u(6)))
            }
        }
        stroked({ p in
            p.addEllipse(in: CGRect(x: cx-u(4), y: cy+u(6), width: u(8), height: u(6)))
        }, fill: partial ? Theme.Palette.ink : nil)
    case .fish:
        stroked({ p in
            p.addEllipse(in: CGRect(x: cx-u(35), y: cy-u(20), width: u(60), height: u(40)))
        }, fill: partial ? Theme.Palette.accentBlue : nil)
        stroked({ p in
            p.move(to: CGPoint(x: cx+u(25), y: cy))
            p.addLine(to: CGPoint(x: cx+u(45), y: cy-u(18)))
            p.addLine(to: CGPoint(x: cx+u(45), y: cy+u(18)))
            p.closeSubpath()
        }, fill: partial ? Theme.Palette.accentBlue : nil)
        stroked({ p in
            p.addEllipse(in: CGRect(x: cx-u(18), y: cy-u(8), width: u(8), height: u(8)))
        }, fill: partial ? .white : nil)
    case .rocket:
        stroked({ p in
            p.move(to: CGPoint(x: cx, y: cy-u(40)))
            p.addQuadCurve(to: CGPoint(x: cx+u(18), y: cy+u(10)),
                           control: CGPoint(x: cx+u(20), y: cy-u(20)))
            p.addLine(to: CGPoint(x: cx-u(18), y: cy+u(10)))
            p.addQuadCurve(to: CGPoint(x: cx, y: cy-u(40)),
                           control: CGPoint(x: cx-u(20), y: cy-u(20)))
            p.closeSubpath()
        }, fill: partial ? .white : nil)
        stroked({ p in
            p.addEllipse(in: CGRect(x: cx-u(7), y: cy-u(20), width: u(14), height: u(14)))
        }, fill: partial ? Theme.Palette.accentBlue : nil)
        // flames
        stroked({ p in
            p.move(to: CGPoint(x: cx-u(14), y: cy+u(10)))
            p.addLine(to: CGPoint(x: cx, y: cy+u(40)))
            p.addLine(to: CGPoint(x: cx+u(14), y: cy+u(10)))
            p.closeSubpath()
        }, fill: partial ? Theme.Palette.accentRed : nil)
    case .cake:
        for i in 0..<3 {
            let w: CGFloat = 60 - CGFloat(i)*16
            let y: CGFloat = cy+u(20) - CGFloat(i)*u(16)
            stroked({ p in
                p.addRoundedRect(in: CGRect(x: cx-u(w/2), y: y-u(12), width: u(w), height: u(14)),
                                 cornerSize: CGSize(width: u(3), height: u(3)))
            }, fill: partial ? [Theme.Palette.accentRed, Theme.Palette.accentYellow, Theme.Palette.accentTeal][i] : nil)
        }
        stroked { p in
            p.move(to: CGPoint(x: cx, y: cy-u(28)))
            p.addLine(to: CGPoint(x: cx, y: cy-u(40)))
        }
        stroked({ p in
            p.addEllipse(in: CGRect(x: cx-u(4), y: cy-u(46), width: u(8), height: u(10)))
        }, fill: partial ? Theme.Palette.accentYellow : nil)
    case .unicorn:
        stroked({ p in
            p.addEllipse(in: CGRect(x: cx-u(28), y: cy-u(15), width: u(56), height: u(45)))
        }, fill: partial ? .white : nil)
        stroked({ p in
            p.move(to: CGPoint(x: cx-u(5), y: cy-u(15)))
            p.addLine(to: CGPoint(x: cx, y: cy-u(40)))
            p.addLine(to: CGPoint(x: cx+u(5), y: cy-u(15)))
            p.closeSubpath()
        }, fill: partial ? Theme.Palette.accentYellow : nil)
        // mane
        for i in 0..<4 {
            stroked({ p in
                let x = cx - u(20) + CGFloat(i)*u(10)
                p.addEllipse(in: CGRect(x: x-u(6), y: cy-u(28), width: u(12), height: u(18)))
            }, fill: partial ? [Theme.Palette.accentRed, Theme.Palette.accentYellow,
                                Theme.Palette.accentTeal, Theme.Palette.accentPurple][i] : nil)
        }
    case .butterfly:
        for sign: CGFloat in [-1, 1] {
            stroked({ p in
                p.addEllipse(in: CGRect(x: cx+sign*u(18)-u(20), y: cy-u(22),
                                        width: u(20), height: u(22)))
            }, fill: partial ? Theme.Palette.accentPurple : nil)
            stroked({ p in
                p.addEllipse(in: CGRect(x: cx+sign*u(18)-u(20), y: cy,
                                        width: u(20), height: u(20)))
            }, fill: partial ? Theme.Palette.accentRed : nil)
        }
        stroked({ p in
            p.addEllipse(in: CGRect(x: cx-u(3), y: cy-u(22), width: u(6), height: u(44)))
        }, fill: partial ? Theme.Palette.ink : nil)
    case .house:
        stroked({ p in
            p.addRect(CGRect(x: cx-u(28), y: cy-u(10), width: u(56), height: u(40)))
        }, fill: partial ? Theme.Palette.accentRed : nil)
        stroked({ p in
            p.move(to: CGPoint(x: cx-u(32), y: cy-u(10)))
            p.addLine(to: CGPoint(x: cx, y: cy-u(40)))
            p.addLine(to: CGPoint(x: cx+u(32), y: cy-u(10)))
            p.closeSubpath()
        }, fill: partial ? Theme.Palette.accentTeal : nil)
        // door
        stroked({ p in
            p.addRect(CGRect(x: cx-u(7), y: cy+u(10), width: u(14), height: u(20)))
        }, fill: partial ? .white : nil)
        // window
        stroked({ p in
            p.addRect(CGRect(x: cx+u(10), y: cy, width: u(12), height: u(12)))
        })
        // chimney + smoke
        stroked { p in
            p.addRect(CGRect(x: cx+u(14), y: cy-u(34), width: u(7), height: u(14)))
        }
    case .tree:
        stroked({ p in
            p.addRect(CGRect(x: cx-u(7), y: cy+u(5), width: u(14), height: u(35)))
        }, fill: partial ? Theme.Palette.accentPeach : nil)
        stroked({ p in
            p.addEllipse(in: CGRect(x: cx-u(30), y: cy-u(40), width: u(60), height: u(55)))
        }, fill: partial ? Theme.Palette.accentTeal : nil)
    case .car:
        stroked({ p in
            p.addRoundedRect(in: CGRect(x: cx-u(36), y: cy-u(5), width: u(72), height: u(22)),
                             cornerSize: CGSize(width: u(6), height: u(6)))
        }, fill: partial ? Theme.Palette.accentRed : nil)
        stroked({ p in
            p.move(to: CGPoint(x: cx-u(24), y: cy-u(5)))
            p.addLine(to: CGPoint(x: cx-u(14), y: cy-u(22)))
            p.addLine(to: CGPoint(x: cx+u(14), y: cy-u(22)))
            p.addLine(to: CGPoint(x: cx+u(24), y: cy-u(5)))
            p.closeSubpath()
        }, fill: partial ? .white : nil)
        for sign: CGFloat in [-1, 1] {
            stroked({ p in
                p.addEllipse(in: CGRect(x: cx+sign*u(20)-u(7), y: cy+u(15),
                                        width: u(14), height: u(14)))
            }, fill: partial ? Theme.Palette.ink : nil)
        }
    case .sun:
        stroked({ p in
            p.addEllipse(in: CGRect(x: cx-u(20), y: cy-u(20), width: u(40), height: u(40)))
        }, fill: partial ? Theme.Palette.accentYellow : nil)
        for i in 0..<8 {
            let a = CGFloat(i) * .pi / 4
            stroked { p in
                p.move(to: CGPoint(x: cx + cos(a)*u(26), y: cy + sin(a)*u(26)))
                p.addLine(to: CGPoint(x: cx + cos(a)*u(38), y: cy + sin(a)*u(38)))
            }
        }
    case .dino:
        stroked({ p in
            p.addEllipse(in: CGRect(x: cx-u(30), y: cy-u(5), width: u(50), height: u(35)))
        }, fill: partial ? Theme.Palette.accentTeal : nil)
        stroked({ p in
            p.addEllipse(in: CGRect(x: cx+u(10), y: cy-u(30), width: u(28), height: u(28)))
        }, fill: partial ? Theme.Palette.accentTeal : nil)
        // spikes
        for i in 0..<5 {
            let x = cx-u(25)+CGFloat(i)*u(10)
            stroked({ p in
                p.move(to: CGPoint(x: x, y: cy-u(5)))
                p.addLine(to: CGPoint(x: x+u(4), y: cy-u(15)))
                p.addLine(to: CGPoint(x: x+u(8), y: cy-u(5)))
                p.closeSubpath()
            }, fill: partial ? Theme.Palette.accentYellow : nil)
        }
        // legs
        for sign: CGFloat in [-1, 1] {
            stroked { p in
                p.addRect(CGRect(x: cx+sign*u(15)-u(3), y: cy+u(28), width: u(6), height: u(12)))
            }
        }
    }
}
