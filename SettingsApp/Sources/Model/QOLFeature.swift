import Foundation

enum QOLFeature: String, CaseIterable, Identifiable {
    case musicPulse
    case cursor
    case folderLook
    case softScrollEdges

    var id: Self { self }

    var title: String {
        switch self {
        case .musicPulse: "Music Pulse"
        case .cursor: "Cursor"
        case .folderLook: "Folder Look"
        case .softScrollEdges: "Soft Scroll Edges"
        }
    }

    var systemImage: String {
        switch self {
        case .musicPulse: "music.note"
        case .cursor: "cursorarrow"
        case .folderLook: "folder"
        case .softScrollEdges: "scroll"
        }
    }
}
