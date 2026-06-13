import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var rightClickMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Local monitor: catches events delivered to OUR app (global monitors
        // explicitly skip own-app events, which is why right-clicks on our
        // own status bar button were never seen). Returning nil consumes the
        // event so the system "Remove from Menu Bar" menu doesn't also appear.
        rightClickMonitor = NSEvent.addLocalMonitorForEvents(matching: .rightMouseDown) { [weak self] event in
            guard let self, self.handleRightClick(event) else { return event }
            return nil
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let monitor = rightClickMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    // Returns true if the event was consumed (right-click on our menu bar strip).
    @discardableResult
    private func handleRightClick(_ event: NSEvent) -> Bool {
        let mouse = NSEvent.mouseLocation

        let screen = NSScreen.screens.first(where: { $0.frame.contains(mouse) }) ?? NSScreen.main
        guard let screen else { return false }
        let menuBarMinY = screen.frame.maxY - NSStatusBar.system.thickness
        guard mouse.y >= menuBarMinY else { return false }

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

        // nil view → at is interpreted as screen coordinates.
        menu.popUp(positioning: nil, at: mouse, in: nil)
        return true
    }

    @objc private func openSettings() {
        NotificationCenter.default.post(name: .wcbOpenSettings, object: nil)
        Task { @MainActor in NSApp.activate(ignoringOtherApps: true) }
    }
}

extension Notification.Name {
    static let wcbOpenSettings = Notification.Name("wcbOpenSettings")
}
