import SwiftUI

struct SoftScrollEdgesSettingsView: View {
    @Bindable var settings: QOLSettings

    var body: some View {
        Form {
            Section {
                FeatureHeader(
                    title: "Soft Scroll Edges",
                    subtitle: "Traverses AppKit view and controller trees and changes every compatible scroll-edge style to soft.",
                    systemImage: "scroll"
                )
            }

            Section("Behaviour") {
                Toggle("Force Soft Scroll Edges", isOn: $settings.softScrollEdgesEnabled)
            }

            Section {
                Button("Reapply to Open Applications", systemImage: "checkmark", action: settings.applyChanges)
            } footer: {
                Text("This installs automatically when each application starts. QOL immediately traverses existing windows, watches newly added views, and forces compatible titlebar and split-view accessory setters to soft. The button only refreshes applications that are already open.")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Soft Scroll Edges")
    }
}
