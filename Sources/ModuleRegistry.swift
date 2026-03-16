import AppKit

// MARK: - ModuleDescriptor

struct ModuleDescriptor {
    let id:          String
    let displayName: String
    let description: String
    let make:        (ConfigManager) -> any Automation
}

// MARK: - ModuleRegistry

final class ModuleRegistry {

    // All modules the app knows about — new modules are added here
    static let available: [ModuleDescriptor] = [
        ModuleDescriptor(
            id:          "keyboard-switcher",
            displayName: "Keyboard Layout Switcher",
            description: "Switches input layout when a USB keyboard is connected or disconnected.",
            make:        { KeyboardSwitcher(configManager: $0) }
        ),
        ModuleDescriptor(
            id:          "dock-watcher",
            displayName: "DisplayLink Dock Watcher",
            description: "Launches DisplayLink Manager when a Dell D6000 dock connects.",
            make:        { DockWatcher(configManager: $0) }
        ),
    ]

    /// Currently active automations (those whose IDs are in config.registeredModules)
    private(set) var active: [any Automation] = []

    private let configManager: ConfigManager

    /// Called whenever the active list changes or any automation's status changes.
    /// MenuBarController uses this to redraw the icon.
    var onChanged: (() -> Void)?

    init(configManager: ConfigManager) {
        self.configManager = configManager
        buildActive()
    }

    // MARK: - Lifecycle

    /// Start all active automations that are enabled in config.
    func startAll() {
        let config = configManager.config
        for automation in active {
            automation.reloadConfig(from: config)
        }
    }

    // MARK: - Register / Unregister

    /// Add a module to the active list. It appears in the menu as disabled until the user enables it.
    func activate(moduleId: String) {
        guard !active.contains(where: { $0.id == moduleId }) else { return }
        guard let desc = ModuleRegistry.available.first(where: { $0.id == moduleId }) else { return }
        configManager.setRegistered(moduleId: moduleId, registered: true)
        active.append(wired(desc.make(configManager)))
        onChanged?()
    }

    /// Stop and remove a module from the active list.
    func deactivate(moduleId: String) {
        guard let idx = active.firstIndex(where: { $0.id == moduleId }) else { return }
        let automation = active[idx]
        if automation.isEnabled { automation.stop() }
        automation.onStatusChanged = nil
        active.remove(at: idx)
        configManager.setRegistered(moduleId: moduleId, registered: false)
        onChanged?()
    }

    // MARK: - Config reload

    /// Called when config.json changes on disk (FSEvents). Reloads each active automation.
    /// If registeredModules changed in the file, rebuilds the active list.
    func reloadFromConfig() {
        let newRegistered = configManager.config.registeredModules
        let currentIds    = active.map { $0.id }

        if newRegistered.sorted() != currentIds.sorted() {
            // Module list changed in config file — rebuild
            for automation in active {
                if automation.isEnabled { automation.stop() }
                automation.onStatusChanged = nil
            }
            buildActive()
            startAll()
        } else {
            // Same modules — just forward config changes
            let config = configManager.config
            for automation in active { automation.reloadConfig(from: config) }
        }
        onChanged?()
    }

    // MARK: - Private

    private func buildActive() {
        let registered = configManager.config.registeredModules
        active = ModuleRegistry.available
            .filter { registered.contains($0.id) }
            .map    { wired($0.make(configManager)) }
    }

    private func wired(_ automation: any Automation) -> any Automation {
        var a = automation
        a.onStatusChanged = { [weak self] in
            DispatchQueue.main.async { self?.onChanged?() }
        }
        return a
    }
}
