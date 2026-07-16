import SwiftUI

struct CommandLensPreview: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(.quaternary)
            HStack(spacing: 28) {
                CommandLensPreviewControl(title: "Back", shortcut: "⌘[")
                CommandLensPreviewControl(title: "Search", shortcut: "⌘F")
                CommandLensPreviewControl(title: "Share", shortcut: "Share")
            }
        }
    }
}

