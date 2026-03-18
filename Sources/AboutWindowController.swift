import AppKit

final class AboutWindowController: NSObject {

    private var window: NSWindow?

    func showWindow() {
        if let existing = window, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        window = makeWindow()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func makeWindow() -> NSWindow {
        let win = NSWindow(
            contentRect: .zero,
            styleMask:   [.titled, .closable],
            backing:     .buffered,
            defer:       false
        )
        win.title = "About latch"
        win.isReleasedWhenClosed = false

        let content = win.contentView!

        // ── Icon ────────────────────────────────────────────────────────
        let iconView = NSImageView()
        iconView.image = NSImage(named: NSImage.applicationIconName)
        iconView.imageScaling = .scaleProportionallyUpOrDown
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 80),
            iconView.heightAnchor.constraint(equalToConstant: 80),
        ])

        // ── Labels ───────────────────────────────────────────────────────
        let nameLabel = NSTextField(labelWithString: "latch")
        nameLabel.font      = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize + 2)
        nameLabel.alignment = .center

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let versionLabel = NSTextField(labelWithString: "Version \(version)")
        versionLabel.font      = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        versionLabel.textColor = .secondaryLabelColor
        versionLabel.alignment = .center

        let taglineLabel = NSTextField(wrappingLabelWithString:
            "macOS menu bar utility for hardware-triggered automations")
        taglineLabel.font           = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        taglineLabel.textColor      = .secondaryLabelColor
        taglineLabel.alignment      = .center
        taglineLabel.preferredMaxLayoutWidth = 260

        // ── Repo link ────────────────────────────────────────────────────
        let linkButton = NSButton(title: "", target: self, action: #selector(openRepo))
        linkButton.attributedTitle = NSAttributedString(
            string: "View on GitHub",
            attributes: [
                .font:            NSFont.systemFont(ofSize: NSFont.systemFontSize),
                .foregroundColor: NSColor.linkColor,
                .underlineStyle:  NSUnderlineStyle.single.rawValue,
            ]
        )
        linkButton.isBordered = false

        // ── Stack ────────────────────────────────────────────────────────
        let stack = NSStackView(views: [iconView, nameLabel, versionLabel, taglineLabel, linkButton])
        stack.orientation  = .vertical
        stack.alignment    = .centerX
        stack.spacing      = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.setCustomSpacing(12, after: iconView)
        stack.setCustomSpacing(10, after: taglineLabel)

        content.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: content.topAnchor,       constant: 24),
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor,  constant: 24),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -24),
            stack.bottomAnchor.constraint(equalTo: content.bottomAnchor,    constant: -24),
        ])

        // Size window to fit content, then centre
        content.layoutSubtreeIfNeeded()
        win.setContentSize(content.fittingSize)
        win.center()
        return win
    }

    @objc private func openRepo() {
        if let url = URL(string: "https://github.com/tinkermesomething/latch") {
            NSWorkspace.shared.open(url)
        }
    }
}
