import SwiftUI
import SwiftData

/// Home — implements Wireframe Home Variant A:
/// "Hi, kid 👋" header, two GIANT start tiles (Blank page + Photo magic),
/// then a "My drawings" strip of 4 recent tiles.
struct HomeView: View {
    let navigate: (AppRoute) -> Void
    @Environment(\.modelContext) private var ctx
    @Query(sort: \Drawing.updatedAt, order: .reverse) private var drawings: [Drawing]

    var body: some View {
        ZStack {
            PaperBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    twoBigStartActions
                    myDrawingsHeader
                    drawingsRow
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 28)
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Hi, friend! 👋").font(Theme.Fonts.caveat(48))
                Squiggle(width: 210)
                Text("Pick something to color today")
                    .font(Theme.Fonts.hand(20)).foregroundStyle(Theme.Palette.muted)
            }
            Spacer()
            avatarChip
        }
    }

    private var avatarChip: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(Theme.Palette.accentPeach)
                .frame(width: 56, height: 56)
                .overlay(Circle().stroke(Theme.Palette.ink, lineWidth: 2))
                .overlay(Text("🙂").font(.system(size: 28)))
                .hardShadow()
            Text("kiddo · 5").font(Theme.Fonts.hand(14))
                .foregroundStyle(Theme.Palette.muted)
        }
    }

    // MARK: Two big start actions

    private var twoBigStartActions: some View {
        HStack(spacing: 24) {
            BigStartTile(
                title: "New blank page",
                subtitle: "Start drawing on a clean sheet",
                hint: "↗ tap anywhere",
                fill: Theme.Palette.accentYellow,
                foreground: Theme.Palette.ink
            ) {
                IconBadge(systemName: "paintpalette.fill", tint: Theme.Palette.accentRed)
            } action: {
                navigate(.canvas(templateID: nil, drawingID: nil, photoPNG: nil))
            }

            BigStartTile(
                title: "Photo magic ✨",
                subtitle: "Turn a photo into a coloring page",
                hint: "↗ pick from library",
                fill: Theme.Palette.accentRed,
                foreground: .white
            ) {
                IconBadge(systemName: "camera.fill", tint: Theme.Palette.accentYellow)
            } action: {
                navigate(.photoMagic)
            }
        }
        .frame(height: 220)
    }

    // MARK: My drawings

    private var myDrawingsHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("My drawings").font(Theme.Fonts.caveat(28))
                Squiggle(width: 130, color: Theme.Palette.ink, lineWidth: 2)
            }
            Spacer()
            Button { navigate(.templates) } label: {
                Text("Templates →").font(Theme.Fonts.hand(18))
                    .foregroundStyle(Theme.Palette.muted)
            }
        }
    }

    private var drawingsRow: some View {
        let placeholders = Array(repeating: nil as Drawing?, count: max(0, 4 - drawings.count))
        let cells: [Drawing?] = drawings.prefix(4).map { Optional($0) } + placeholders
        return HStack(spacing: 22) {
            ForEach(Array(cells.enumerated()), id: \.offset) { _, drawing in
                DrawingTile(drawing: drawing) {
                    if let d = drawing {
                        navigate(.canvas(templateID: nil, drawingID: d.id, photoPNG: nil))
                    } else {
                        navigate(.canvas(templateID: nil, drawingID: nil, photoPNG: nil))
                    }
                }
            }
        }
        .frame(height: 260)
    }
}

// MARK: - Big start tile

private struct BigStartTile<Icon: View>: View {
    let title: String
    let subtitle: String
    let hint: String
    let fill: Color
    let foreground: Color
    @ViewBuilder var icon: () -> Icon
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topLeading) {
                SketchyCard(fill: fill, corner: 24) { EmptyView() }
                HStack(alignment: .top, spacing: 20) {
                    icon()
                    VStack(alignment: .leading, spacing: 8) {
                        Text(title)
                            .font(Theme.Fonts.caveat(36))
                            .foregroundStyle(foreground)
                        Text(subtitle)
                            .font(Theme.Fonts.hand(18))
                            .foregroundStyle(foreground.opacity(0.85))
                        Text(hint)
                            .font(Theme.Fonts.hand(15))
                            .foregroundStyle(foreground.opacity(0.7))
                    }
                    Spacer()
                }
                .padding(28)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct IconBadge: View {
    let systemName: String
    let tint: Color
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.white)
                .frame(width: 88, height: 88)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Theme.Palette.ink, lineWidth: 2)
                )
            Image(systemName: systemName)
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(tint)
        }
    }
}

// MARK: - Recent drawing tile

private struct DrawingTile: View {
    let drawing: Drawing?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    SketchyCard(fill: .white, corner: 18) { EmptyView() }
                    if let img = drawing?.thumbnail {
                        Image(uiImage: img).resizable().scaledToFit().padding(20)
                    } else {
                        Text("(blank)")
                            .font(Theme.Fonts.hand(16))
                            .foregroundStyle(Theme.Palette.muted)
                    }
                    if drawing?.inProgress == true {
                        VStack {
                            HStack {
                                Text("in progress")
                                    .font(Theme.Fonts.hand(12))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8).padding(.vertical, 3)
                                    .background(Capsule().fill(Theme.Palette.accentRed))
                                    .overlay(Capsule().stroke(Theme.Palette.ink, lineWidth: 1.5))
                                Spacer()
                            }
                            Spacer()
                        }
                        .padding(10)
                    }
                }
                Text(drawing?.title ?? "Untitled")
                    .font(Theme.Fonts.hand(16))
                Text(drawing?.relativeAgo ?? "new")
                    .font(Theme.Fonts.hand(12))
                    .foregroundStyle(Theme.Palette.muted)
            }
        }
        .buttonStyle(.plain)
    }
}
