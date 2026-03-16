import Foundation

enum LaunchAtLogin {

    private static let label    = "com.local.osx-utils-automation"
    private static var plistPath: String {
        "\(NSHomeDirectory())/Library/LaunchAgents/\(label).plist"
    }

    static func isEnabled() -> Bool {
        launchctl("list", label) == 0
    }

    static func setEnabled(_ enabled: Bool) {
        let uid = String(getuid())
        if enabled {
            launchctl("bootstrap", "gui/\(uid)", plistPath)
        } else {
            launchctl("bootout", "gui/\(uid)/\(label)")
        }
    }

    @discardableResult
    private static func launchctl(_ args: String...) -> Int32 {
        let task = Process()
        task.executableURL  = URL(fileURLWithPath: "/bin/launchctl")
        task.arguments      = args
        task.standardOutput = FileHandle.nullDevice
        task.standardError  = FileHandle.nullDevice
        try? task.run()
        task.waitUntilExit()
        return task.terminationStatus
    }
}
