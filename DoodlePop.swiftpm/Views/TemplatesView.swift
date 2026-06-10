import SwiftUI
import SwiftData

/// Templates — Netflix-style horizontal shelves.
/// Top shelf: "My drawings". Below: Animals / Vehicles / Magic / Nature shelves.
struct TemplatesView: View {
    let navigate: (AppRoute) -> Void
    @Query(sort: \Drawing.updatedAt, order: .reverse) private var drawings: [Drawing]
    @State private var difficultyFilter: Template.Difficulty? = nil

    var body: some View {
        ZStack {
            PaperBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    header
                    filterPills
                    if !drawings.isEmpty {
                        Shelf(title: "My drawings") {
                            HStack(spacing: 18) {
                                ForEach(drawings.prefix(8)) { d in
                                    MyDrawingCard(drawing: d) {
                                        navigate(.canvas(templateID: nil, drawingID: d.id, photoPNG: nil))
                                    }
                                }
                            }
                        }
                    }
                    ForEach(TemplateLibrary.shelves(), id: \.0) { (cat, items) in
                        Shelf(title: cat.rawValue) {
                            HStack(spacing: 18) {
                                ForEach(filtered(items)) { t in
                                    TemplateCard(template: t) {
                                        navigate(.canvas(templateID: t.id, drawingID: nil, photoPNG: nil))
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 28)
            }
        }
    }

    private func filtered(_ items: [Template]) -> [Template] {
        guard let f = difficultyFilter else { return items }
        return items.filter { $0.difficulty == f }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Templates").font(Theme.Fonts.caveat(44))
                Squiggle(width: 200)
            }
            Spacer()
            Text("Pick a page to color in")
                .font(Theme.Fonts.hand(18)).foregroundStyle(Theme.Palette.muted)
        }
    }

    private var filterPills: some View {
        HStack(spacing: 10) {
            FilterPill(label: "All", selected: difficultyFilter == nil) {
                difficultyFilter = nil
            }
            ForEach(Template.Difficulty.allCases, id: \.self) { d in
                FilterPill(label: d.rawValue, selected: difficultyFilter == d) {
                    difficultyFilter = d
                }
            }
        }
    }
}

private struct FilterPill: View {
    let label: String
    let selected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(Theme.Fonts.hand(16))
                .foregroundStyle(selected ? Theme.Palette.paper : Theme.Palette.ink)
                .padding(.horizontal, 14).padding(.vertical, 7)
                .background(Capsule().fill(selected ? Theme.Palette.ink : Theme.Palette.paper))
                .overlay(Capsule().stroke(Theme.Palette.ink, lineWidth: 2))
                .hardShadow()
        }
        .buttonStyle(.plain)
    }
}

private struct Shelf<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(Theme.Fonts.caveat(28))
                Squiggle(width: 90, color: Theme.Palette.ink, lineWidth: 2)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                content().padding(.vertical, 6).padding(.trailing, 24)
            }
        }
    }
}

private struct TemplateCard: View {
    let template: Template
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    SketchyCard(fill: .white, corner: 18) { EmptyView() }
                    GlyphView(kind: template.glyph, partial: true)
                        .padding(16)
                }
                .frame(width: 200, height: 200)
                HStack {
                    Text(template.title).font(Theme.Fonts.hand(16))
                    Spacer()
                    Text(template.difficulty.rawValue)
                        .font(Theme.Fonts.hand(12))
                        .foregroundStyle(Theme.Palette.muted)
                }
                .frame(width: 200)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct MyDrawingCard: View {
    let drawing: Drawing
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    SketchyCard(fill: .white, corner: 18) { EmptyView() }
                    if let img = drawing.thumbnail {
                        Image(uiImage: img).resizable().scaledToFit().padding(16)
                    } else {
                        Text("(blank)").font(Theme.Fonts.hand(16))
                            .foregroundStyle(Theme.Palette.muted)
                    }
                }
                .frame(width: 200, height: 200)
                Text(drawing.title).font(Theme.Fonts.hand(16)).frame(width: 200)
            }
        }
        .buttonStyle(.plain)
    }
}
