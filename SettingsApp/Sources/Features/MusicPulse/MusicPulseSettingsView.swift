import SwiftUI

struct MusicPulseSettingsView: View {
    @Bindable var settings: QOLSettings

    var body: some View {
        Form {
            Section {
                FeatureHeader(
                    title: "Music Pulse",
                    subtitle: "A red border matching Music’s icon shape quickly fades between two opacities during playback.",
                    systemImage: "music.note"
                )
                MusicPulsePreview(settings: settings)
                    .frame(height: 150)
            }

            Section("Behaviour") {
                Toggle("Enable Music Pulse", isOn: $settings.musicPulseEnabled)
                LabeledContent("Fade interval") {
                    Slider(value: $settings.musicPulseFadeInterval, in: 0.15...1.5)
                        .frame(width: 220)
                }
            }

            Section("Appearance") {
                LabeledContent("Minimum opacity") {
                    Slider(value: $settings.musicPulseMinimumOpacity, in: 0.05...0.9)
                        .frame(width: 220)
                }
                LabeledContent("Maximum opacity") {
                    Slider(value: $settings.musicPulseMaximumOpacity, in: 0.1...1.0)
                        .frame(width: 220)
                }
                LabeledContent("Border width") {
                    Slider(value: $settings.musicPulseBorderWidth, in: 0.5...8.0)
                        .frame(width: 220)
                }
                LabeledContent("Corner radius") {
                    Slider(value: $settings.musicPulseCornerRadius, in: 0...32)
                        .frame(width: 220)
                }
            }

            Section {
                Button("Preview in Dock", systemImage: "play", action: settings.previewMusicPulse)
                Button("Apply and Restart Dock", systemImage: "arrow.clockwise", action: settings.restartDock)
            } footer: {
                Text("The border does not expand or change shape. Playback state changes apply automatically.")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Music Pulse")
    }
}
