import SwiftUI

struct AppCapsuleSettingsView: View {
    @Bindable var settings: QOLSettings

    var body: some View {
        Form {
            Section {
                FeatureHeader(
                    title: "App Capsule",
                    subtitle: "The application menu becomes a compact capsule containing its icon, active document, and unsaved state.",
                    systemImage: "menubar.rectangle"
                )

                HStack {
                    HStack(spacing: 7) {
                        Image(nsImage: NSWorkspace.shared.icon(forFile: "/System/Applications/Notes.app"))
                            .resizable()
                            .frame(width: 17, height: 17)
                            .accessibilityHidden(true)
                        Text("Notes  ·  Ideas")
                            .font(.callout.weight(.semibold))
                        Circle()
                            .fill(.red)
                            .frame(width: 6, height: 6)
                            .accessibilityLabel("Unsaved")
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.quaternary, in: .capsule)
                    Spacer()
                }
                .padding(.vertical, 16)
            }

            Section("Contents") {
                Toggle("Enable App Capsule", isOn: $settings.appCapsuleEnabled)
                Toggle("Show active document", isOn: $settings.appCapsuleShowDocument)
                Toggle("Show unsaved indicator", isOn: $settings.appCapsuleShowUnsaved)
            }

            Section {
                Button("Apply Changes", systemImage: "checkmark", action: settings.applyChanges)
            } footer: {
                Text("The capsule remains the application menu. Normal clicking and menu-bar tracking continue to expose its menu.")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("App Capsule")
    }
}

