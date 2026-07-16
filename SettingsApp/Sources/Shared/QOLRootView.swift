import SwiftUI

struct QOLRootView: View {
    @Bindable var settings: QOLSettings
    @State private var selection: QOLFeature? = .musicPulse

    var body: some View {
        NavigationSplitView {
            List(QOLFeature.allCases, selection: $selection) { feature in
                Label(feature.title, systemImage: feature.systemImage)
                    .tag(feature)
            }
            .navigationTitle("QOL")
            .navigationSplitViewColumnWidth(min: 190, ideal: 220)
        } detail: {
            switch selection ?? .musicPulse {
            case .musicPulse:
                MusicPulseSettingsView(settings: settings)
            case .commandLens:
                CommandLensSettingsView(settings: settings)
            case .appCapsule:
                AppCapsuleSettingsView(settings: settings)
            }
        }
        .frame(minWidth: 720, minHeight: 540)
    }
}

#Preview {
    QOLRootView(settings: QOLSettings())
}

