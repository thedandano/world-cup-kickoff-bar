import AppKit
import SwiftUI

// Makes the hosting NSWindow translucent so the behind-window vibrancy shows
// through: non-opaque with a clear background. The title bar is removed via
// `.windowStyle(.hiddenTitleBar)` on the settings scene, so there is no
// title-bar text to keep legible and the window is free to follow the system
// light/dark appearance (matching the menu-bar popover). Place as
// `.background()` on the settings root view.
struct SettingsWindowBackground: NSViewRepresentable {
    func makeNSView(context _: Context) -> NSView { NSView() }

    func updateNSView(_ nsView: NSView, context _: Context) {
        DispatchQueue.main.async {
            guard let window = nsView.window else { return }
            window.isOpaque = false
            window.backgroundColor = .clear
        }
    }
}

// A behind-window NSVisualEffectView sized to fill whatever SwiftUI view it
// backs. The app's single source of translucency: stacked behind the settings
// window (both sidebar and detail columns) and the menu-bar dropdown so every
// surface shares one continuous frosted-glass material at the same opacity.
// A List sitting on top must use `.scrollContentBackground(.hidden)` so this
// shows through instead of the heavier system sidebar material.
struct WCBVibrancyBackground: NSViewRepresentable {
    func makeNSView(context _: Context) -> NSVisualEffectView {
        let effectView = NSVisualEffectView()
        effectView.material = .sidebar
        effectView.blendingMode = .behindWindow
        effectView.state = .active
        return effectView
    }

    func updateNSView(_: NSVisualEffectView, context _: Context) {}
}
