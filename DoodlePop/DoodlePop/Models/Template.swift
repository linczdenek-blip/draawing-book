import SwiftUI

/// A bundled coloring-page template.
struct Template: Identifiable, Hashable {
    enum Difficulty: String, CaseIterable { case easy = "Easy 🐣", tricky = "Tricky 🦕" }
    enum Category: String, CaseIterable, Identifiable {
        case animals = "Animals"
        case vehicles = "Vehicles"
        case magic = "Magic"
        case nature = "Nature"
        case favorites = "Favorites"
        var id: String { rawValue }
    }

    let id: String          // matches asset name of bundled line-art PNG/SVG
    let title: String
    let category: Category
    let difficulty: Difficulty
    let glyph: TemplateGlyph
}

enum TemplateGlyph: String {
    case cat, dog, dino, rocket, cake, unicorn, butterfly, house, fish, tree, car, sun
}

enum TemplateLibrary {
    static let all: [Template] = [
        .init(id: "cat",       title: "Cool Cat",     category: .animals,  difficulty: .easy,   glyph: .cat),
        .init(id: "dog",       title: "Happy Dog",    category: .animals,  difficulty: .easy,   glyph: .dog),
        .init(id: "fish",      title: "Blue Fish",    category: .animals,  difficulty: .easy,   glyph: .fish),
        .init(id: "butterfly", title: "Butterfly",    category: .animals,  difficulty: .tricky, glyph: .butterfly),
        .init(id: "dino",      title: "Friendly Dino",category: .animals,  difficulty: .tricky, glyph: .dino),

        .init(id: "rocket",    title: "Rocket",       category: .vehicles, difficulty: .easy,   glyph: .rocket),
        .init(id: "car",       title: "Red Car",      category: .vehicles, difficulty: .easy,   glyph: .car),

        .init(id: "unicorn",   title: "Unicorn",      category: .magic,    difficulty: .tricky, glyph: .unicorn),
        .init(id: "cake",      title: "Birthday Cake",category: .magic,    difficulty: .easy,   glyph: .cake),

        .init(id: "house",     title: "My House",     category: .nature,   difficulty: .easy,   glyph: .house),
        .init(id: "tree",      title: "Big Tree",     category: .nature,   difficulty: .easy,   glyph: .tree),
        .init(id: "sun",       title: "Sunny Day",    category: .nature,   difficulty: .easy,   glyph: .sun),
    ]

    static func shelves() -> [(Template.Category, [Template])] {
        Template.Category.allCases
            .filter { $0 != .favorites }
            .map { cat in (cat, all.filter { $0.category == cat }) }
    }
}
