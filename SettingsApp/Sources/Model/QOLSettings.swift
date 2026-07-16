import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class QOLSettings {
    private static let suiteName = "com.omeriadon.QOL"
    private static let notificationName = Notification.Name("com.omeriadon.QOL.settingsDidChange")

    private let defaults: UserDefaults

    var musicPulseEnabled: Bool { didSet { save(musicPulseEnabled, for: "musicPulseEnabled") } }
    var musicPulseMinimumOpacity: Double { didSet { save(musicPulseMinimumOpacity, for: "musicPulseMinimumOpacity") } }
    var musicPulseMaximumOpacity: Double { didSet { save(musicPulseMaximumOpacity, for: "musicPulseMaximumOpacity") } }
    var musicPulseFadeInterval: Double { didSet { save(musicPulseFadeInterval, for: "musicPulseFadeInterval") } }
    var musicPulseBorderWidth: Double { didSet { save(musicPulseBorderWidth, for: "musicPulseBorderWidth") } }
    var musicPulseCornerRadius: Double { didSet { save(musicPulseCornerRadius, for: "musicPulseCornerRadius") } }

    var cursorEnabled: Bool { didSet { save(cursorEnabled, for: "cursorEnabled") } }
    var cursorFillColor: Color { didSet { saveColor(cursorFillColor, for: "cursorFillColor") } }
    var cursorFillOpacity: Double { didSet { save(cursorFillOpacity, for: "cursorFillOpacity") } }
    var cursorOutlineEnabled: Bool { didSet { save(cursorOutlineEnabled, for: "cursorOutlineEnabled") } }
    var cursorOutlineColor: Color { didSet { saveColor(cursorOutlineColor, for: "cursorOutlineColor") } }
    var cursorOutlineOpacity: Double { didSet { save(cursorOutlineOpacity, for: "cursorOutlineOpacity") } }
    var cursorOutlineWidth: Double { didSet { save(cursorOutlineWidth, for: "cursorOutlineWidth") } }
    var cursorSize: Double { didSet { save(cursorSize, for: "cursorSize") } }
    var cursorCornerRadius: Double { didSet { save(cursorCornerRadius, for: "cursorCornerRadius") } }

    var softScrollEdgesEnabled: Bool { didSet { save(softScrollEdgesEnabled, for: "softScrollEdgesEnabled") } }

    init() {
        let defaults = UserDefaults(suiteName: Self.suiteName) ?? .standard
        self.defaults = defaults

        musicPulseEnabled = defaults.object(forKey: "musicPulseEnabled") as? Bool ?? true
        musicPulseMinimumOpacity = defaults.object(forKey: "musicPulseMinimumOpacity") as? Double ?? 0.24
        musicPulseMaximumOpacity = defaults.object(forKey: "musicPulseMaximumOpacity") as? Double ?? 0.95
        musicPulseFadeInterval = defaults.object(forKey: "musicPulseFadeInterval") as? Double ?? 0.45
        musicPulseBorderWidth = defaults.object(forKey: "musicPulseBorderWidth") as? Double ?? 2.5
        musicPulseCornerRadius = defaults.object(forKey: "musicPulseCornerRadius") as? Double ?? 14.0

        cursorEnabled = defaults.object(forKey: "cursorEnabled") as? Bool ?? true
        cursorFillColor = Self.color(defaults: defaults, key: "cursorFillColor", fallback: .black)
        cursorFillOpacity = defaults.object(forKey: "cursorFillOpacity") as? Double ?? 1.0
        cursorOutlineEnabled = defaults.object(forKey: "cursorOutlineEnabled") as? Bool ?? true
        cursorOutlineColor = Self.color(defaults: defaults, key: "cursorOutlineColor", fallback: .white)
        cursorOutlineOpacity = defaults.object(forKey: "cursorOutlineOpacity") as? Double ?? 0.92
        cursorOutlineWidth = defaults.object(forKey: "cursorOutlineWidth") as? Double ?? 1.5
        cursorSize = defaults.object(forKey: "cursorSize") as? Double ?? 22.0
        cursorCornerRadius = defaults.object(forKey: "cursorCornerRadius") as? Double ?? 11.0

        softScrollEdgesEnabled = defaults.object(forKey: "softScrollEdgesEnabled") as? Bool ?? true
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
        run("/usr/bin/killall", arguments: ["Dock"])
    }

    func previewMusicPulse() {
        applyChanges()
        post(name: "com.omeriadon.QOL.previewMusicPulse")
    }

    private func run(_ executable: String, arguments: [String]) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        try? process.run()
    }

    private func save(_ value: Any, for key: String) {
        defaults.set(value, forKey: key)
        applyChanges()
    }

    private func saveColor(_ color: Color, for key: String) {
        guard let color = NSColor(color).usingColorSpace(.sRGB) else { return }
        let serialized = [color.redComponent, color.greenComponent, color.blueComponent]
            .map(String.init)
            .joined(separator: ",")
        save(serialized, for: key)
    }

    private func post(name: String) {
        DistributedNotificationCenter.default().postNotificationName(
            Notification.Name(name),
            object: nil,
            userInfo: nil,
            deliverImmediately: true
        )
    }

    private static func color(defaults: UserDefaults, key: String, fallback: Color) -> Color {
        guard let value = defaults.string(forKey: key) else { return fallback }
        let components = value.split(separator: ",").compactMap { Double($0) }
        guard components.count == 3 else { return fallback }
        return Color(red: components[0], green: components[1], blue: components[2])
    }
}
