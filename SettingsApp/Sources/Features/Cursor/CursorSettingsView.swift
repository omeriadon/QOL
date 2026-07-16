import SwiftUI

struct CursorSettingsView: View {
    @Bindable var settings: QOLSettings

    var body: some View {
        Form {
            Section {
                FeatureHeader(
                    title: "Cursor",
                    subtitle: "Replaces the standard AppKit arrow with a static rounded rectangle, ranging from a square to a circle.",
                    systemImage: "cursorarrow"
                )
                CursorPreview(settings: settings)
                    .frame(height: 150)
            }

            Section("Fill") {
                Toggle("Enable Custom Cursor", isOn: $settings.cursorEnabled)
                LabeledContent("Size") {
                    Slider(value: $settings.cursorSize, in: 6...64)
                        .frame(width: 220)
                }
                LabeledContent("Corner radius") {
                    Slider(value: $settings.cursorCornerRadius, in: 0...32)
                        .frame(width: 220)
                }
                ColorPicker("Color", selection: $settings.cursorFillColor, supportsOpacity: false)
                LabeledContent("Opacity") {
                    Slider(value: $settings.cursorFillOpacity, in: 0.05...1.0)
                        .frame(width: 220)
                }
            }

            Section("Outline") {
                Toggle("Enable Outline", isOn: $settings.cursorOutlineEnabled)
                ColorPicker("Color", selection: $settings.cursorOutlineColor, supportsOpacity: false)
                    .disabled(!settings.cursorOutlineEnabled)
                LabeledContent("Opacity") {
                    Slider(value: $settings.cursorOutlineOpacity, in: 0.05...1.0)
                        .frame(width: 220)
                }
                .disabled(!settings.cursorOutlineEnabled)
                LabeledContent("Width") {
                    Slider(value: $settings.cursorOutlineWidth, in: 0.5...5.0)
                        .frame(width: 220)
                }
                .disabled(!settings.cursorOutlineEnabled)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Cursor")
    }
}
