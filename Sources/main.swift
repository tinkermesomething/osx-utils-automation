import AppKit

// Global log function — all output goes to NSLog (captured by LaunchAgent stdout → log file)
func log(_ msg: String) { NSLog("osx-utils-automation: %@", msg) }

// Single-instance guard — terminate immediately if another instance is already running.
// Uses bundle identifier so it works regardless of how the binary was launched.
let bundleID = Bundle.main.bundleIdentifier ?? "com.local.osx-utils-automation"
let running  = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
if running.count > 1 {
    log("Another instance is already running — exiting.")
    exit(0)
}

let app      = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)  // no dock icon
app.run()
