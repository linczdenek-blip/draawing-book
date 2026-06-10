import SwiftUI
import SwiftData

/// Kid profile picker + creation, plus the "For grown-ups" privacy note.
/// Everything is stored only on this iPad.
struct ProfileSheet: View {
    let profiles: [Profile]
    @Binding var currentProfileID: String

    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    @State private var newName = ""
    @State private var newEmoji = "🙂"
    @State private var newAge = 5

    private static let emojis = ["🙂", "😺", "🦄", "🦖", "🚀", "🌈", "🐯", "🐸"]

    var body: some View {
        ZStack {
            PaperBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    Text("Who is coloring?").font(Theme.Fonts.caveat(40))

                    // Existing profiles
                    HStack(spacing: 18) {
                        ForEach(profiles) { p in
                            Button {
                                currentProfileID = p.id.uuidString
                                SoundFX.toolTap()
                                dismiss()
                            } label: {
                                VStack(spacing: 6) {
                                    Circle()
                                        .fill(p.id.uuidString == currentProfileID
                                              ? Theme.Palette.accentYellow : .white)
                                        .frame(width: 76, height: 76)
                                        .overlay(Circle().stroke(Theme.Palette.ink, lineWidth: 2))
                                        .overlay(Text(p.emoji).font(.system(size: 40)))
                                        .hardShadow()
                                    Text("\(p.name) · \(p.age)")
                                        .font(Theme.Fonts.hand(16))
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // New profile
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Add a kid").font(Theme.Fonts.caveat(28))
                        TextField("Name", text: $newName)
                            .font(Theme.Fonts.hand(20))
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 12).fill(.white))
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .stroke(Theme.Palette.ink, lineWidth: 2))
                            .frame(maxWidth: 320)
                        HStack(spacing: 10) {
                            ForEach(Self.emojis, id: \.self) { e in
                                Button { newEmoji = e } label: {
                                    Text(e).font(.system(size: 28))
                                        .frame(width: 48, height: 48)
                                        .background(Circle().fill(newEmoji == e
                                            ? Theme.Palette.accentYellow : .white))
                                        .overlay(Circle().stroke(Theme.Palette.ink, lineWidth: 2))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        HStack(spacing: 14) {
                            Stepper("Age: \(newAge)", value: $newAge, in: 2...10)
                                .font(Theme.Fonts.hand(18))
                                .frame(maxWidth: 220)
                            SketchyPill(label: "Add ✚", fill: Theme.Palette.accentTeal) {
                                let trimmed = newName.trimmingCharacters(in: .whitespaces)
                                guard !trimmed.isEmpty else { return }
                                let p = Profile(name: trimmed, emoji: newEmoji, age: newAge)
                                ctx.insert(p)
                                try? ctx.save()
                                currentProfileID = p.id.uuidString
                                newName = ""
                            }
                        }
                    }
                    .padding(20)
                    .background(RoundedRectangle(cornerRadius: 18).fill(.white.opacity(0.6)))
                    .overlay(RoundedRectangle(cornerRadius: 18)
                        .stroke(Theme.Palette.ink, style: StrokeStyle(lineWidth: 2, dash: [8, 6])))

                    // Privacy — the "For grown-ups" promise
                    VStack(alignment: .leading, spacing: 8) {
                        Text("For grown-ups 🔒").font(Theme.Fonts.caveat(28))
                        ForEach([
                            "Everything stays on this iPad — there is no account, no server, no cloud.",
                            "No ads, no tracking, no analytics, no third-party SDKs.",
                            "Photos are converted to coloring pages on the device and never leave it.",
                            "Sharing or printing a drawing is protected by a grown-ups question.",
                            "Names and ages above are only used for the greeting on the home screen."
                        ], id: \.self) { line in
                            Label {
                                Text(line).font(Theme.Fonts.hand(16))
                            } icon: {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(Theme.Palette.accentTeal)
                            }
                        }
                    }
                    .padding(20)
                    .background(RoundedRectangle(cornerRadius: 18).fill(.white.opacity(0.6)))
                    .overlay(RoundedRectangle(cornerRadius: 18)
                        .stroke(Theme.Palette.ink, lineWidth: 2))
                }
                .padding(36)
            }
        }
    }
}
