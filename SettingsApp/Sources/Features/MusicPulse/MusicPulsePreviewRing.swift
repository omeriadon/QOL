import SwiftUI

struct MusicPulsePreviewRing: View {
    let index: Int
    let ringCount: Int
    let opacity: Double
    let expansion: Double
    let lineWidth: Double

    var body: some View {
        Circle()
            .stroke(.red.opacity(ringOpacity), lineWidth: lineWidth)
            .frame(width: 64, height: 64)
            .scaleEffect(staticScale)
    }

    private var staticScale: Double {
        let progress = Double(index + 1) / Double(max(ringCount, 1))
        return 0.92 + progress * (expansion - 0.92)
    }

    private var ringOpacity: Double {
        let progress = Double(index) / Double(max(ringCount, 1))
        return opacity * (1 - progress * 0.75)
    }
}
