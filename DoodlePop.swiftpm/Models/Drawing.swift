import Foundation
import SwiftData
import UIKit

@Model
final class Drawing {
    var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    /// Template the drawing started from, if any (key into TemplateLibrary).
    var templateID: String?
    /// PencilKit drawing data — keeps strokes editable on re-open.
    @Attribute(.externalStorage) var strokesData: Data?
    /// PNG of the raster flood-fill layer beneath the strokes.
    @Attribute(.externalStorage) var fillPNG: Data?
    /// PNG of a photo-magic line-art template, if the drawing came from a photo.
    @Attribute(.externalStorage) var photoTemplatePNG: Data?
    /// Composite PNG thumbnail (white + fills + template + strokes).
    @Attribute(.externalStorage) var thumbnailPNG: Data?
    /// JSON-encoded [PlacedSticker].
    @Attribute(.externalStorage) var stickersJSON: Data?
    /// Kid profile this drawing belongs to.
    var profileID: UUID?
    var inProgress: Bool

    init(title: String = "Untitled",
         templateID: String? = nil,
         strokesData: Data? = nil,
         fillPNG: Data? = nil,
         photoTemplatePNG: Data? = nil,
         thumbnailPNG: Data? = nil,
         stickersJSON: Data? = nil,
         profileID: UUID? = nil,
         inProgress: Bool = true) {
        self.id = UUID()
        self.title = title
        self.createdAt = .now
        self.updatedAt = .now
        self.templateID = templateID
        self.strokesData = strokesData
        self.fillPNG = fillPNG
        self.photoTemplatePNG = photoTemplatePNG
        self.thumbnailPNG = thumbnailPNG
        self.stickersJSON = stickersJSON
        self.profileID = profileID
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
