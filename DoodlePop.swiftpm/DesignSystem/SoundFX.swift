import UIKit
import AudioToolbox

/// Tiny feedback helper: haptics always, system sounds best-effort.
/// No audio assets, no network — everything stays on device.
enum SoundFX {
    static func fillPop() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        AudioServicesPlaySystemSound(1104)          // keyboard tap "pop"
    }

    static func stickerPlop() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        AudioServicesPlaySystemSound(1306)
    }

    static func toolTap() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func celebrate() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        AudioServicesPlaySystemSound(1335)          // fanfare-ish
    }

    static func wrong() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}
