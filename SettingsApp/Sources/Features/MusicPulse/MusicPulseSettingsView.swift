import SwiftUI

struct MusicPulseSettingsView: View {
    @Bindable var settings: QOLSettings

    var body: some View {
        Form {
            Section {
                FeatureHeader(
                    title: "Music Pulse",
                    subtitle: "Concentric red rings radiate from Music in the Dock while Apple Music is playing.",
                    systemImage: "music.note"
                )
                MusicPulsePreview(settings: settings)
                    .frame(height: 150)
            }

            Section("Behaviour") {
                Toggle("Enable Music Pulse", isOn: $settings.musicPulseEnabled)
                Stepper("Rings: \(settings.musicPulseRingCount)", value: $settings.musicPulseRingCount, in: 1...6)
                LabeledContent("Emission speed") {
                    Slider(value: $settings.musicPulseDuration, in: 0.6...4.0)
                        .frame(width: 220)
                }
                LabeledContent("Expansion") {
                    Slider(value: $settings.musicPulseExpansion, in: 1.05...1.8)
                        .frame(width: 220)
                }
            }

            Section("Appearance") {
                LabeledContent("Opacity") {
                    Slider(value: $settings.musicPulseOpacity, in: 0.1...1.0)
                        .frame(width: 220)
                }
                LabeledContent("Ring width") {
                    Slider(value: $settings.musicPulseLineWidth, in: 0.5...8.0)
                        .frame(width: 220)
                }
            }

            Section {
                Button("Preview in Dock", systemImage: "play", action: settings.previewMusicPulse)
                Button("Apply and Restart Dock", systemImage: "arrow.clockwise", action: settings.restartDock)
            } footer: {
                Text("Dock must restart after installing or replacing the tweak. Playback state changes apply automatically.")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Music Pulse")
    }
}
