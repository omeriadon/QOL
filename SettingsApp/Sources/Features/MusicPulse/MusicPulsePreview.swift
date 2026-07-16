import SwiftUI

struct MusicPulsePreview: View {
    let settings: QOLSettings

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(.black.opacity(0.78))

            Image(systemName: "music.note")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 62, height: 62)
                .background(
                    LinearGradient(colors: [.red, .pink], startPoint: .bottomLeading, endPoint: .topTrailing),
                    in: .rect(cornerRadius: settings.musicPulseCornerRadius)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: settings.musicPulseCornerRadius)
                        .stroke(.red.opacity(settings.musicPulseOpacity), lineWidth: settings.musicPulseBorderWidth)
                }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Preview of the red border around the Music Dock icon")
    }
}
