import SwiftUI

struct FolderLookSettingsView: View {
    var body: some View {
        Form {
            Section {
                FeatureHeader(
                    title: "Folder Look",
                    subtitle: "The default folder art is a protected macOS system resource, not a safe live QOL tweak.",
                    systemImage: "folder"
                )
            }

            Section("System Resources") {
                LabeledContent("Generic icon") {
                    Text("CoreTypes.bundle/Contents/Resources/GenericFolderIcon.icns")
                        .textSelection(.enabled)
                }
                LabeledContent("Folder variants") {
                    Text("IconsetResources.bundle/Contents/Resources/Folder_*.png")
                        .textSelection(.enabled)
                }
            }

            Section {
                Text("/System/Library/CoreServices")
                    .font(.body.monospaced())
                    .textSelection(.enabled)
            } header: {
                Text("Location")
            } footer: {
                Text("These files live on the sealed system volume and are served through IconServices caches. QOL does not modify them or hook Finder’s private icon pipeline.")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Folder Look")
    }
}
