import AppKit

final class WelcomeWindowController: NSWindowController {

    private let configManager:  ConfigManager
    private let moduleRegistry: ModuleRegistry

    /// Called after the user dismisses the welcome screen.
    /// AppDelegate uses this to kick off `moduleRegistry.startAll()`.
    var onCompleted: (() -> Void)?

    private var checkboxes: [NSButton] = []

    init(configManager: ConfigManager, moduleRegistry: ModuleRegistry) {
        self.configManager  = configManager
        self.moduleRegistry = moduleRegistry
        super.init(window: nil)
        buildWindow()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Build

    private func buildWindow() {
        let w = NSWindow(
            contentRect: .zero,
            styleMask:   [.titled],     // no close button — must complete setup
            backing:     .buffered,
            defer:       false
        )
        w.title                = "Welcome to osx-utils-automation"
        w.isReleasedWhenClosed = false

        let content = w.contentView!

        // App icon / header
        let iconView           = NSImageView(image: NSImage(named: NSImage.applicationIconName) ?? NSImage())
        iconView.imageScaling  = .scaleProportionallyUpOrDown
        iconView.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel         = NSTextField(labelWithString: "Welcome!")
        titleLabel.font        = .boldSystemFont(ofSize: 18)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let subtitleLabel      = NSTextField(wrappingLabelWithString:
            "Choose which modules you'd like to enable. You can change this any time in Settings."
        )
        subtitleLabel.textColor = .secondaryLabelColor
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Module checkboxes
        let modulesStack         = NSStackView()
        modulesStack.orientation = .vertical
        modulesStack.alignment   = .leading
        modulesStack.spacing     = 12
        modulesStack.translatesAutoresizingMaskIntoConstraints = false

        for (idx, desc) in ModuleRegistry.available.enumerated() {
            let checkbox   = NSButton(checkboxWithTitle: desc.displayName, target: nil, action: nil)
            checkbox.state = .on     // all enabled by default
            checkbox.tag   = idx
            checkbox.translatesAutoresizingMaskIntoConstraints = false

            let descLabel       = NSTextField(wrappingLabelWithString: desc.description)
            descLabel.textColor = .secondaryLabelColor
            descLabel.font      = .systemFont(ofSize: NSFont.smallSystemFontSize)
            descLabel.translatesAutoresizingMaskIntoConstraints = false

            let row         = NSStackView(views: [checkbox, descLabel])
            row.orientation = .vertical
            row.alignment   = .leading
            row.spacing     = 3

            modulesStack.addArrangedSubview(row)
            checkboxes.append(checkbox)
        }

        let startButton        = NSButton(title: "Get Started", target: self, action: #selector(getStartedTapped))
        startButton.bezelStyle = .rounded
        startButton.keyEquivalent = "\r"
        startButton.translatesAutoresizingMaskIntoConstraints = false

        for sub in [iconView, titleLabel, subtitleLabel, modulesStack, startButton] {
            content.addSubview(sub)
        }

        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: content.topAnchor, constant: 32),
            iconView.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 64),
            iconView.heightAnchor.constraint(equalToConstant: 64),

            titleLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 12),
            titleLabel.centerXAnchor.constraint(equalTo: content.centerXAnchor),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 32),
            subtitleLabel.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -32),

            modulesStack.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
            modulesStack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 32),
            modulesStack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -32),

            startButton.topAnchor.constraint(equalTo: modulesStack.bottomAnchor, constant: 28),
            startButton.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -32),
            startButton.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -24),

            content.widthAnchor.constraint(greaterThanOrEqualToConstant: 380),
        ])

        self.window = w
        content.layoutSubtreeIfNeeded()
        w.setContentSize(content.fittingSize)
    }

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        window?.center()
        window?.makeKeyAndOrderFront(nil)
    }

    // MARK: - Actions

    @objc private func getStartedTapped() {
        // Save selected modules to config
        let selected = checkboxes
            .filter { $0.state == .on }
            .map    { ModuleRegistry.available[$0.tag].id }
        configManager.setRegisteredModules(selected)

        window?.close()
        onCompleted?()
    }
}
