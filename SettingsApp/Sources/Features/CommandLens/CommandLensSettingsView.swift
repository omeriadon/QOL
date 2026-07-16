import SwiftUI

struct CommandLensSettingsView: View {
    @Bindable var settings: QOLSettings

    var body: some View {
        Form {
            Section {
                FeatureHeader(
                    title: "Command Lens",
                    subtitle: "Hold Command to reveal keyboard shortcuts and readable action names over visible AppKit controls.",
                    systemImage: "command"
                )

                CommandLensPreview()
                .frame(height: 120)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Preview of shortcut labels above application controls")
            }

            Section("Behaviour") {
                Toggle("Enable Command Lens", isOn: $settings.commandLensEnabled)
                Toggle("Label actions without shortcuts", isOn: $settings.commandLensShowUnassigned)
                LabeledContent("Hold delay") {
                    Slider(value: $settings.commandLensHoldDelay, in: 0.15...1.5)
                        .frame(width: 220)
                }
            }

            Section("Appearance") {
                LabeledContent("Badge opacity") {
                    Slider(value: $settings.commandLensOpacity, in: 0.35...1.0)
                        .frame(width: 220)
                }
            }

            Section {
                Button("Preview in Frontmost App", systemImage: "play", action: settings.previewCommandLens)
                Button("Apply Changes", systemImage: "checkmark", action: settings.applyChanges)
            } footer: {
                Text("Changes apply immediately in loaded applications. Newly enabled injection requires relaunching the affected application.")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Command Lens")
    }

}
