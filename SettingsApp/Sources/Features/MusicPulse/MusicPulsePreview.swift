import SwiftUI

struct MusicPulsePreview: View {
    let settings: QOLSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(.black.opacity(0.78))

            ForEach(0..<settings.musicPulseRingCount, id: \.self) { index in
                MusicPulsePreviewRing(
                    index: index,
                    ringCount: settings.musicPulseRingCount,
                    opacity: settings.musicPulseOpacity,
                    expansion: settings.musicPulseExpansion,
                    lineWidth: settings.musicPulseLineWidth
                )
            }

            Image(systemName: "music.note")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 62, height: 62)
                .background(
                    LinearGradient(colors: [.red, .pink], startPoint: .bottomLeading, endPoint: .topTrailing),
                    in: .rect(cornerRadius: 14)
                )
        }
        .id(previewConfiguration)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Preview of concentric red rings radiating from the Music Dock icon")
    }

    private var previewConfiguration: String {
        [
            String(settings.musicPulseRingCount),
            String(settings.musicPulseOpacity),
            String(settings.musicPulseExpansion),
            String(settings.musicPulseLineWidth),
            String(reduceMotion)
        ].joined(separator: ":")
    }
}
