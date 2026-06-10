import SwiftUI
import UIKit

/// Simple math question that small kids can't answer — standard parental gate
/// shown before anything leaves the app (share / print).
struct ParentGateView: View {
    let onSuccess: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var a = Int.random(in: 6...9)
    @State private var b = Int.random(in: 3...9)
    @State private var shake = false

    private var options: [Int] {
        let correct = a * b
        return [correct, correct - a, correct + b].shuffled()
    }
    @State private var shuffled: [Int] = []

    var body: some View {
        ZStack {
            PaperBackground()
            VStack(spacing: 24) {
                Text("For grown-ups 🧑‍🦱")
                    .font(Theme.Fonts.caveat(40))
                Text("To share, answer this:")
                    .font(Theme.Fonts.hand(20))
                    .foregroundStyle(Theme.Palette.muted)
                Text("\(a) × \(b) = ?")
                    .font(Theme.Fonts.caveat(56))
                    .modifier(ShakeEffect(animatableData: shake ? 1 : 0))

                HStack(spacing: 18) {
                    ForEach(shuffled, id: \.self) { value in
                        SketchyPill(label: "\(value)",
                                    fill: .white, size: 26) {
                            if value == a * b {
                                dismiss()
                                onSuccess()
                            } else {
                                SoundFX.wrong()
                                a = Int.random(in: 6...9)
                                b = Int.random(in: 3...9)
                                shuffled = options
                                withAnimation(.default) { shake.toggle() }
                            }
                        }
                    }
                }

                SketchyPill(label: "Cancel", fill: Theme.Palette.paper2) {
                    dismiss()
                }
            }
            .padding(40)
        }
        .onAppear { shuffled = options }
    }
}

struct ShakeEffect: GeometryEffect {
    var animatableData: CGFloat
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(
            translationX: 12 * sin(animatableData * .pi * 4), y: 0))
    }
}

/// UIKit share sheet (includes AirPrint, Save to Photos, Messages …).
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
