import SwiftUI

struct CommandLensPreviewControl: View {
    let title: String
    let shortcut: String

    var body: some View {
        VStack(spacing: 8) {
            Text(shortcut)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(shortcut.contains("⌘") ? .red : .black.opacity(0.72), in: .rect(cornerRadius: 6))
            Button(title) { }
                .disabled(true)
        }
    }
}
