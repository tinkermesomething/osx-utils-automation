import AppKit

final class UpdateWindowController: NSWindowController {

    private var releaseInfo: ReleaseInfo!
    private let configManager: ConfigManager

    init(configManager: ConfigManager) {
        self.configManager = configManager
        super.init(window: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Public

    func showUpdate(_ info: ReleaseInfo) {
        releaseInfo = info
        if window == nil { buildWindow() }
        updateContent()
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
        window?.center()
    }

    // MARK: - Build

    private var titleLabel:   NSTextField!
    private var notesView:    NSScrollView!
    private var notesText:    NSTextView!
    private var skipButton:   NSButton!
    private var downloadButton: NSButton!

    private func buildWindow() {
        let w = NSWindow(
            contentRect: .zero,
            styleMask:   [.titled, .closable],
            backing:     .buffered,
            defer:       false
        )
        w.title = "Update Available"
        w.isReleasedWhenClosed = false

        let content = w.contentView!
        content.translatesAutoresizingMaskIntoConstraints = false

        // Title label
        titleLabel = NSTextField(labelWithString: "")
        titleLabel.font = .boldSystemFont(ofSize: 16)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(titleLabel)

        // Subtitle
        let subtitle = NSTextField(labelWithString: "Release notes:")
        subtitle.textColor = .secondaryLabelColor
        subtitle.font = .systemFont(ofSize: 12)
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(subtitle)

        // Scrollable notes
        notesText = NSTextView()
        notesText.isEditable      = false
        notesText.isSelectable    = true
        notesText.backgroundColor = .textBackgroundColor
        notesText.font            = .monospacedSystemFont(ofSize: 12, weight: .regular)
        notesText.textContainerInset = NSSize(width: 8, height: 8)
        notesText.autoresizingMask = [.width]

        notesView = NSScrollView()
        notesView.documentView         = notesText
        notesView.hasVerticalScroller  = true
        notesView.hasHorizontalScroller = false
        notesView.autohidesScrollers   = true
        notesView.borderType           = .bezelBorder
        notesView.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(notesView)

        // Skip button
        skipButton = NSButton(title: "Skip This Version", target: self, action: #selector(skipTapped))
        skipButton.bezelStyle = .rounded
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(skipButton)

        // Download button (primary)
        downloadButton = NSButton(title: "Download", target: self, action: #selector(downloadTapped))
        downloadButton.bezelStyle = .rounded
        downloadButton.keyEquivalent = "\r"
        downloadButton.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(downloadButton)

        // Dismiss button
        let dismissButton = NSButton(title: "Later", target: self, action: #selector(dismissTapped))
        dismissButton.bezelStyle = .rounded
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(dismissButton)

        NSLayoutConstraint.activate([
            // Title
            titleLabel.topAnchor.constraint(equalTo: content.topAnchor,       constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -24),

            // Subtitle
            subtitle.topAnchor.constraint(equalTo: titleLabel.bottomAnchor,    constant: 16),
            subtitle.leadingAnchor.constraint(equalTo: content.leadingAnchor,  constant: 24),

            // Notes scroll view
            notesView.topAnchor.constraint(equalTo: subtitle.bottomAnchor,     constant: 6),
            notesView.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 24),
            notesView.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -24),
            notesView.heightAnchor.constraint(equalToConstant: 180),

            // Buttons row — right-aligned
            downloadButton.topAnchor.constraint(equalTo: notesView.bottomAnchor, constant: 20),
            downloadButton.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -24),
            downloadButton.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -20),

            dismissButton.centerYAnchor.constraint(equalTo: downloadButton.centerYAnchor),
            dismissButton.trailingAnchor.constraint(equalTo: downloadButton.leadingAnchor, constant: -8),

            skipButton.centerYAnchor.constraint(equalTo: downloadButton.centerYAnchor),
            skipButton.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 24),

            // Minimum window width
            content.widthAnchor.constraint(greaterThanOrEqualToConstant: 440),
        ])

        self.window = w
        content.layoutSubtreeIfNeeded()
        w.setContentSize(content.fittingSize)
    }

    private func updateContent() {
        titleLabel.stringValue = "osx-utils-automation \(releaseInfo.version) is available"
        let notes = releaseInfo.releaseNotes.isEmpty ? "(No release notes provided.)" : releaseInfo.releaseNotes
        notesText.string = notes
    }

    // MARK: - Actions

    @objc private func downloadTapped() {
        NSWorkspace.shared.open(releaseInfo.htmlURL)
        window?.close()
    }

    @objc private func skipTapped() {
        configManager.skipVersion(releaseInfo.version)
        window?.close()
    }

    @objc private func dismissTapped() {
        window?.close()
    }
}
