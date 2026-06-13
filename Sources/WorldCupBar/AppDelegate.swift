import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var rightClickMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Global monitors run on the main thread, so no dispatch needed.
        rightClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: .rightMouseDown) { [weak self] event in
            self?.handleRightClick(event)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let monitor = rightClickMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    private func handleRightClick(_ event: NSEvent) {
        let mouse = NSEvent.mouseLocation

        // Only act when the right-click lands in the menu bar strip.
        let screen = NSScreen.screens.first(where: { $0.frame.contains(mouse) }) ?? NSScreen.main
        guard let screen else { return }
        let menuBarMinY = screen.frame.maxY - NSStatusBar.system.thickness
        guard mouse.y >= menuBarMinY else { return }

        let menu = NSMenu()

        let settingsItem = NSMenuItem(
            title: "Settings…",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.keyEquivalentModifierMask = .command
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit World Cup Bar",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        quitItem.keyEquivalentModifierMask = .command
        menu.addItem(quitItem)

        // nil view → location is in screen coordinates.
        menu.popUp(positioning: nil, at: mouse, in: nil)
    }

    @objc private func openSettings() {
        NotificationCenter.default.post(name: .wcbOpenSettings, object: nil)
        Task { @MainActor in NSApp.activate(ignoringOtherApps: true) }
    }
}

extension Notification.Name {
    static let wcbOpenSettings = Notification.Name("wcbOpenSettings")
}
