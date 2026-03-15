import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var configManager:          ConfigManager!
    private var menuBarController:       MenuBarController!
    private var keyboardSwitcher:        KeyboardSwitcher!
    private var dockWatcher:             DockWatcher!
    private var settingsWindowController: SettingsWindowController!
    private var aboutWindowController:    AboutWindowController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        configManager = ConfigManager()

        keyboardSwitcher = KeyboardSwitcher(configManager: configManager)
        dockWatcher      = DockWatcher(configManager: configManager)

        settingsWindowController = SettingsWindowController(configManager: configManager)
        aboutWindowController    = AboutWindowController()

        menuBarController = MenuBarController(
            configManager: configManager,
            settingsWindowController: settingsWindowController,
            aboutWindowController: aboutWindowController
        )
        menuBarController.register(keyboardSwitcher)
        menuBarController.register(dockWatcher)
        menuBarController.start()

        let config = configManager.config
        if config.keyboardSwitcher.enabled { keyboardSwitcher.start() }
        if config.dockWatcher.enabled      { dockWatcher.start()      }

        log("osx-utils-automation started")
    }
}
