import AppKit
import Foundation
import Observation

@MainActor
@Observable
final class QOLSettings {
    private static let suiteName = "com.omeriadon.QOL"
    private static let notificationName = Notification.Name("com.omeriadon.QOL.settingsDidChange")

    private let defaults: UserDefaults

    var musicPulseEnabled: Bool { didSet { save(musicPulseEnabled, for: "musicPulseEnabled") } }
    var musicPulseRingCount: Int { didSet { save(musicPulseRingCount, for: "musicPulseRingCount") } }
    var musicPulseOpacity: Double { didSet { save(musicPulseOpacity, for: "musicPulseOpacity") } }
    var musicPulseExpansion: Double { didSet { save(musicPulseExpansion, for: "musicPulseExpansion") } }
    var musicPulseDuration: Double { didSet { save(musicPulseDuration, for: "musicPulseDuration") } }
    var musicPulseLineWidth: Double { didSet { save(musicPulseLineWidth, for: "musicPulseLineWidth") } }

    var commandLensEnabled: Bool { didSet { save(commandLensEnabled, for: "commandLensEnabled") } }
    var commandLensHoldDelay: Double { didSet { save(commandLensHoldDelay, for: "commandLensHoldDelay") } }
    var commandLensShowUnassigned: Bool { didSet { save(commandLensShowUnassigned, for: "commandLensShowUnassigned") } }
    var commandLensOpacity: Double { didSet { save(commandLensOpacity, for: "commandLensOpacity") } }

    var appCapsuleEnabled: Bool { didSet { save(appCapsuleEnabled, for: "appCapsuleEnabled") } }
    var appCapsuleShowDocument: Bool { didSet { save(appCapsuleShowDocument, for: "appCapsuleShowDocument") } }
    var appCapsuleShowUnsaved: Bool { didSet { save(appCapsuleShowUnsaved, for: "appCapsuleShowUnsaved") } }

    init() {
        let defaults = UserDefaults(suiteName: Self.suiteName) ?? .standard
        self.defaults = defaults

        musicPulseEnabled = defaults.object(forKey: "musicPulseEnabled") as? Bool ?? true
        musicPulseRingCount = defaults.object(forKey: "musicPulseRingCount") as? Int ?? 3
        musicPulseOpacity = defaults.object(forKey: "musicPulseOpacity") as? Double ?? 0.72
        musicPulseExpansion = defaults.object(forKey: "musicPulseExpansion") as? Double ?? 1.34
        musicPulseDuration = defaults.object(forKey: "musicPulseDuration") as? Double ?? 1.8
        musicPulseLineWidth = defaults.object(forKey: "musicPulseLineWidth") as? Double ?? 2.0

        commandLensEnabled = defaults.object(forKey: "commandLensEnabled") as? Bool ?? true
        commandLensHoldDelay = defaults.object(forKey: "commandLensHoldDelay") as? Double ?? 0.45
        commandLensShowUnassigned = defaults.object(forKey: "commandLensShowUnassigned") as? Bool ?? true
        commandLensOpacity = defaults.object(forKey: "commandLensOpacity") as? Double ?? 0.9

        appCapsuleEnabled = defaults.object(forKey: "appCapsuleEnabled") as? Bool ?? true
        appCapsuleShowDocument = defaults.object(forKey: "appCapsuleShowDocument") as? Bool ?? true
        appCapsuleShowUnsaved = defaults.object(forKey: "appCapsuleShowUnsaved") as? Bool ?? true
    }

    func applyChanges() {
        defaults.synchronize()
        DistributedNotificationCenter.default().postNotificationName(
            Self.notificationName,
            object: nil,
            userInfo: nil,
            deliverImmediately: true
        )
    }

    func restartDock() {
        applyChanges()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        process.arguments = ["Dock"]
        try? process.run()
    }

    func previewMusicPulse() {
        applyChanges()
        post(name: "com.omeriadon.QOL.previewMusicPulse")
    }

    func previewCommandLens() {
        applyChanges()
        post(name: "com.omeriadon.QOL.previewCommandLens")
    }

    private func save(_ value: Any, for key: String) {
        defaults.set(value, forKey: key)
        applyChanges()
    }

    private func post(name: String) {
        DistributedNotificationCenter.default().postNotificationName(
            Notification.Name(name),
            object: nil,
            userInfo: nil,
            deliverImmediately: true
        )
    }
}
