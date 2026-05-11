import Foundation
import SwiftData
import UIKit

@Model
final class Drawing {
    var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    /// PNG of the drawing strokes only.
    @Attribute(.externalStorage) var strokesPNG: Data?
    /// PNG of the source template (line-art) under the strokes, if any.
    @Attribute(.externalStorage) var templatePNG: Data?
    /// PNG thumbnail used in tiles and shelves.
    @Attribute(.externalStorage) var thumbnailPNG: Data?
    var inProgress: Bool

    init(title: String = "Untitled",
         strokesPNG: Data? = nil,
         templatePNG: Data? = nil,
         thumbnailPNG: Data? = nil,
         inProgress: Bool = true) {
        self.id = UUID()
        self.title = title
        self.createdAt = .now
        self.updatedAt = .now
        self.strokesPNG = strokesPNG
        self.templatePNG = templatePNG
        self.thumbnailPNG = thumbnailPNG
        self.inProgress = inProgress
    }
}

extension Drawing {
    var thumbnail: UIImage? {
        thumbnailPNG.flatMap { UIImage(data: $0) }
    }
    var relativeAgo: String {
        let fmt = RelativeDateTimeFormatter()
        fmt.unitsStyle = .short
        return fmt.localizedString(for: updatedAt, relativeTo: .now)
    }
}
