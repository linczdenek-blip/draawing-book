import SwiftUI

/// Full-screen confetti burst for the "finished a drawing" celebration.
/// Deterministic particles driven by TimelineView — no timers, no state churn.
struct ConfettiView: View {
    let startedAt = Date()

    private static let colors: [Color] = [
        Theme.Palette.accentRed, Theme.Palette.accentYellow,
        Theme.Palette.accentTeal, Theme.Palette.accentBlue,
        Theme.Palette.accentPurple, Theme.Palette.accentPeach
    ]

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { ctx, size in
                let t = timeline.date.timeIntervalSince(startedAt)
                guard t < 2.2 else { return }
                var seed: UInt64 = 0x9E3779B97F4A7C15
                func rnd() -> CGFloat {
                    seed = seed &* 6364136223846793005 &+ 1442695040888963407
                    return CGFloat((seed >> 33) % 10_000) / 10_000
                }
                for _ in 0..<140 {
                    let x0 = rnd() * size.width
                    let speed = 220 + rnd() * 380
                    let sway = (rnd() - 0.5) * 80
                    let delay = rnd() * 0.4
                    let w = 6 + rnd() * 8
                    let h = 8 + rnd() * 10
                    let spin = (rnd() - 0.5) * 12
                    let color = Self.colors[Int(rnd() * 6) % 6]

                    let tt = max(0, t - delay)
                    let y = -30 + speed * tt
                    guard y < size.height + 30 else { continue }
                    let x = x0 + sin(tt * 3) * sway

                    var p = ctx
                    p.translateBy(x: x, y: y)
                    p.rotate(by: .radians(tt * spin))
                    p.fill(Path(CGRect(x: -w/2, y: -h/2, width: w, height: h)),
                           with: .color(color))
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

/// Big bouncy "Yay!" badge shown together with the confetti.
struct CelebrationBadge: View {
    @State private var shown = false
    var body: some View {
        Text("Yay! 🎉")
            .font(Theme.Fonts.caveat(72))
            .padding(.horizontal, 44).padding(.vertical, 18)
            .background(
                Capsule().fill(Theme.Palette.accentYellow)
            )
            .overlay(Capsule().stroke(Theme.Palette.ink, lineWidth: 3))
            .hardShadow()
            .scaleEffect(shown ? 1 : 0.2)
            .rotationEffect(.degrees(shown ? -3 : 10))
            .animation(.spring(response: 0.4, dampingFraction: 0.55), value: shown)
            .onAppear { shown = true }
    }
}
