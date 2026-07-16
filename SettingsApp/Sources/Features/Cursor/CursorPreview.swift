import SwiftUI

struct CursorPreview: View {
    let settings: QOLSettings

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(.quaternary)

            RoundedRectangle(cornerRadius: settings.cursorCornerRadius * 2.0)
                .fill(settings.cursorFillColor.opacity(settings.cursorFillOpacity))
                .stroke(
                    settings.cursorOutlineEnabled
                        ? settings.cursorOutlineColor.opacity(settings.cursorOutlineOpacity)
                        : .clear,
                    lineWidth: settings.cursorOutlineWidth * 2.0
                )
                .frame(width: settings.cursorSize * 2.0, height: settings.cursorSize * 2.0)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Preview of the custom rounded rectangle cursor")
    }
}
