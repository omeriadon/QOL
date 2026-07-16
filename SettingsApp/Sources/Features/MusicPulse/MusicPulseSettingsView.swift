import SwiftUI

struct MusicPulseSettingsView: View {
    @Bindable var settings: QOLSettings

    var body: some View {
        Form {
            Section {
                FeatureHeader(
                    title: "Music Pulse",
                    subtitle: "A fixed red border matching Music’s icon shape appears during playback.",
                    systemImage: "music.note"
                )
                MusicPulsePreview(settings: settings)
                    .frame(height: 150)
            }

            Section("Behaviour") {
                Toggle("Enable Music Pulse", isOn: $settings.musicPulseEnabled)
            }

            Section("Appearance") {
                LabeledContent("Opacity") {
                    Slider(value: $settings.musicPulseOpacity, in: 0.05...1.0)
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
                Text("The border is static. Playback state changes apply automatically.")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Music Pulse")
    }
}
