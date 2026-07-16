import SwiftUI

struct SoftScrollEdgesSettingsView: View {
    @Bindable var settings: QOLSettings

    var body: some View {
        Form {
            Section {
                FeatureHeader(
                    title: "Soft Scroll Edges",
                    subtitle: "Redirects AppKit and SwiftUI hard or automatic scroll-edge styles to soft.",
                    systemImage: "scroll"
                )
            }

            Section("Behaviour") {
                Toggle("Force Soft Scroll Edges", isOn: $settings.softScrollEdgesEnabled)
            }

            Section {
                Button("Reapply to Open Applications", systemImage: "checkmark", action: settings.applyChanges)
            } footer: {
                Text("This installs automatically when each application starts. QOL redirects AppKit style sources, rebinds SwiftUI’s hard and automatic style accessors, and traverses compatible existing views. The button only refreshes applications that are already open.")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Soft Scroll Edges")
    }
}
