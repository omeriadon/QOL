import SwiftUI

@main
struct QOLApp: App {
    @State private var settings = QOLSettings()

    var body: some Scene {
        WindowGroup {
            QOLRootView(settings: settings)
        }
        .defaultSize(width: 860, height: 660)
        .windowResizability(.contentMinSize)
    }
}

