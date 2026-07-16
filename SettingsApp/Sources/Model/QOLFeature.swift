import Foundation

enum QOLFeature: String, CaseIterable, Identifiable {
    case musicPulse
    case commandLens
    case appCapsule

    var id: Self { self }

    var title: String {
        switch self {
        case .musicPulse: "Music Pulse"
        case .commandLens: "Command Lens"
        case .appCapsule: "App Capsule"
        }
    }

    var systemImage: String {
        switch self {
        case .musicPulse: "music.note"
        case .commandLens: "command"
        case .appCapsule: "menubar.rectangle"
        }
    }
}

