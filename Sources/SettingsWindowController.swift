import AppKit
import Carbon.HIToolbox

final class SettingsWindowController: NSObject, NSWindowDelegate {

    private var window: NSWindow?
    private let configManager: ConfigManager

    // Controls
    private var autoDetectCheckbox: NSButton!
    private var macLayoutPopup:     NSPopUpButton!
    private var pcLayoutPopup:      NSPopUpButton!

    // All available layout IDs, in display order
    private var availableLayouts: [String] = []

    init(configManager: ConfigManager) {
        self.configManager = configManager
        super.init()
    }

    func showWindow() {
        if window == nil { buildWindow() }
        populateAndSync()
        // Re-size to content each time it opens so larger fonts are accommodated
        if let content = window?.contentView {
            content.layoutSubtreeIfNeeded()
            window?.setContentSize(content.fittingSize)
        }
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Build

    private func buildWindow() {
        let w = NSWindow(
            contentRect: .zero,
            styleMask:   [.titled, .closable],
            backing:     .buffered,
            defer:       false
        )
        w.title                = "osx-utils-automation — Settings"
        w.delegate             = self
        w.isReleasedWhenClosed = false

        let content = w.contentView!

        // ── Section header ───────────────────────────────────────────────
        let header = makeLabel("Keyboard Layout Switcher", bold: true)

        let divider = NSBox()
        divider.boxType = .separator

        // ── Auto-detect checkbox ─────────────────────────────────────────
        autoDetectCheckbox = NSButton(
            checkboxWithTitle: "Auto-detect from enabled input sources",
            target: self, action: #selector(autoDetectToggled)
        )

        // ── Mac layout row ───────────────────────────────────────────────
        let macLabel = makeLabel("Mac layout:")
        macLabel.alignment = .right
        macLabel.widthAnchor.constraint(equalToConstant: 90).isActive = true
        macLayoutPopup = NSPopUpButton()

        let macRow = NSStackView(views: [macLabel, macLayoutPopup])
        macRow.orientation = .horizontal
        macRow.spacing     = 8

        // ── PC layout row ────────────────────────────────────────────────
        let pcLabel = makeLabel("PC layout:")
        pcLabel.alignment = .right
        pcLabel.widthAnchor.constraint(equalToConstant: 90).isActive = true
        pcLayoutPopup = NSPopUpButton()

        let pcRow = NSStackView(views: [pcLabel, pcLayoutPopup])
        pcRow.orientation = .horizontal
        pcRow.spacing     = 8

        // ── Button row ───────────────────────────────────────────────────
        let cancelBtn = NSButton(title: "Cancel", target: self, action: #selector(cancel))
        cancelBtn.bezelStyle    = .rounded
        cancelBtn.keyEquivalent = "\u{1b}"

        let saveBtn = NSButton(title: "Save", target: self, action: #selector(save))
        saveBtn.bezelStyle    = .rounded
        saveBtn.keyEquivalent = "\r"
        saveBtn.highlight(true)

        // Spacer pushes buttons to the right
        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let buttonRow = NSStackView(views: [spacer, cancelBtn, saveBtn])
        buttonRow.orientation = .horizontal
        buttonRow.spacing     = 8

        // ── Main vertical stack ──────────────────────────────────────────
        let stack = NSStackView(views: [header, divider, autoDetectCheckbox, macRow, pcRow, buttonRow])
        stack.orientation = .vertical
        stack.alignment   = .leading
        stack.spacing     = 10
        stack.translatesAutoresizingMaskIntoConstraints = false

        // Wider spacing around the divider and before buttons
        stack.setCustomSpacing(4,  after: header)
        stack.setCustomSpacing(12, after: autoDetectCheckbox)
        stack.setCustomSpacing(16, after: pcRow)

        // Rows and button row fill the full width
        for view in [divider, autoDetectCheckbox!, macRow, pcRow, buttonRow] {
            view.translatesAutoresizingMaskIntoConstraints = false
            stack.addConstraint(
                view.widthAnchor.constraint(equalTo: stack.widthAnchor)
            )
        }

        // Minimum width so dropdowns have enough room
        stack.widthAnchor.constraint(greaterThanOrEqualToConstant: 360).isActive = true

        content.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: content.topAnchor,        constant: 20),
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor,   constant: 20),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor,  constant: -20),
            stack.bottomAnchor.constraint(equalTo: content.bottomAnchor,     constant: -20),
        ])

        self.window = w
    }

    // MARK: - Populate

    private func populateAndSync() {
        availableLayouts = fetchAvailableLayouts()
        let shortNames   = availableLayouts.map { shortName($0) }

        for popup in [macLayoutPopup, pcLayoutPopup] {
            popup!.removeAllItems()
            popup!.addItems(withTitles: shortNames)
        }

        let cfg    = configManager.config.keyboardSwitcher
        let isAuto = cfg.macLayout == nil && cfg.pcLayout == nil
        autoDetectCheckbox.state = isAuto ? .on : .off

        if !isAuto {
            if let mac = cfg.macLayout, let idx = availableLayouts.firstIndex(of: mac) {
                macLayoutPopup.selectItem(at: idx)
            }
            if let pc = cfg.pcLayout, let idx = availableLayouts.firstIndex(of: pc) {
                pcLayoutPopup.selectItem(at: idx)
            }
        } else {
            if let detected = autoDetect() {
                if let idx = availableLayouts.firstIndex(of: detected.mac) { macLayoutPopup.selectItem(at: idx) }
                if let idx = availableLayouts.firstIndex(of: detected.pc)  { pcLayoutPopup.selectItem(at: idx) }
            }
        }

        setLayoutControlsEnabled(!isAuto)
    }

    private func fetchAvailableLayouts() -> [String] {
        guard let listRef = TISCreateInputSourceList(nil, false) else { return [] }
        let sources = listRef.takeRetainedValue() as? [TISInputSource] ?? []
        return sources.compactMap { source -> String? in
            guard let ptr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else { return nil }
            let id = Unmanaged<CFString>.fromOpaque(ptr).takeUnretainedValue() as String
            return id.hasPrefix("com.apple.keylayout.") ? id : nil
        }.sorted()
    }

    private func autoDetect() -> (mac: String, pc: String)? {
        guard let pc = availableLayouts.first(where: { $0.hasSuffix("-PC") }) else { return nil }
        let base = pc.replacingOccurrences(of: "-PC", with: "")
        let mac  = availableLayouts.first(where: { $0 == base })
                ?? availableLayouts.first(where: { !$0.hasSuffix("-PC") })
        guard let mac else { return nil }
        return (mac: mac, pc: pc)
    }

    // MARK: - Actions

    @objc private func autoDetectToggled(_ sender: NSButton) {
        setLayoutControlsEnabled(sender.state == .off)
    }

    @objc private func save() {
        let isAuto = autoDetectCheckbox.state == .on

        if isAuto {
            configManager.setKeyboardLayouts(mac: nil, pc: nil)
        } else {
            let selMac = macLayoutPopup.indexOfSelectedItem
            let selPc  = pcLayoutPopup.indexOfSelectedItem
            guard selMac >= 0, selPc >= 0,
                  selMac < availableLayouts.count, selPc < availableLayouts.count else {
                let alert = NSAlert()
                alert.messageText    = "Invalid layout selection"
                alert.informativeText = "Please select a valid Mac and PC layout from the dropdowns."
                alert.alertStyle     = .warning
                alert.runModal()
                return
            }
            configManager.setKeyboardLayouts(
                mac: availableLayouts[selMac],
                pc:  availableLayouts[selPc]
            )
        }
        configManager.onChanged?()
        window?.close()
    }

    @objc private func cancel() { window?.close() }

    // MARK: - Helpers

    private func setLayoutControlsEnabled(_ enabled: Bool) {
        macLayoutPopup.isEnabled = enabled
        pcLayoutPopup.isEnabled  = enabled
    }

    private func makeLabel(_ title: String, bold: Bool = false) -> NSTextField {
        let tf = NSTextField(labelWithString: title)
        tf.font = bold
            ? NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)
            : NSFont.systemFont(ofSize: NSFont.systemFontSize)
        return tf
    }

    private func shortName(_ id: String) -> String {
        id.replacingOccurrences(of: "com.apple.keylayout.", with: "")
    }

    func windowWillClose(_ notification: Notification) {}
}
