import SwiftUI
import SwiftData

@main
struct DoodlePopApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.light)
        }
        .modelContainer(for: [Drawing.self])
    }
}
