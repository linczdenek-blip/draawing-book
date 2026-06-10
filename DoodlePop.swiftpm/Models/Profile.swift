import Foundation
import SwiftData

/// A kid profile. Stored only on this device — no account, no server.
@Model
final class Profile {
    var id: UUID
    var name: String
    var emoji: String
    var age: Int
    var createdAt: Date

    init(name: String, emoji: String = "🙂", age: Int = 5) {
        self.id = UUID()
        self.name = name
        self.emoji = emoji
        self.age = age
        self.createdAt = .now
    }
}

/// A placed sticker, persisted as JSON inside Drawing.
struct PlacedSticker: Codable, Hashable, Identifiable {
    var id = UUID()
    var emoji: String
    /// Position relative to canvas size (0…1) so it survives size changes.
    var relX: Double
    var relY: Double
    var size: Double = 56
}
