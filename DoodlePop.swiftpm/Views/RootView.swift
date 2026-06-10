import SwiftUI
import SwiftData

enum AppRoute: Hashable {
    case canvas(templateID: String?, drawingID: UUID?, photoPNG: Data?)
    case templates
    case photoMagic
}

struct RootView: View {
    @State private var path: [AppRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(navigate: { path.append($0) })
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .canvas(let tid, let did, let photo):
                        CanvasView(templateID: tid, drawingID: did, photoTemplatePNG: photo)
                    case .templates:
                        TemplatesView(navigate: { path.append($0) })
                    case .photoMagic:
                        PhotoMagicView(navigate: { path.append($0) })
                    }
                }
        }
    }
}
