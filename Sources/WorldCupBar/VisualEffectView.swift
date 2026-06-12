import AppKit
import SwiftUI

struct VisualEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let container = NSView()
        container.wantsLayer = true

        let effectView = NSVisualEffectView()
        effectView.material = .hudWindow
        effectView.blendingMode = .behindWindow
        effectView.state = .active
        effectView.isEmphasized = true
        effectView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(effectView)

        let tintView = NSView()
        tintView.wantsLayer = true
        tintView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(tintView)

        NSLayoutConstraint.activate([
            effectView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            effectView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            effectView.topAnchor.constraint(equalTo: container.topAnchor),
            effectView.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            tintView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            tintView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            tintView.topAnchor.constraint(equalTo: container.topAnchor),
            tintView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        applyTint(to: tintView, for: NSApp.effectiveAppearance)
        return container
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let tintView = nsView.subviews.last else { return }
        applyTint(to: tintView, for: NSApp.effectiveAppearance)
    }

    private func applyTint(to view: NSView, for appearance: NSAppearance) {
        let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        view.layer?.backgroundColor = isDark
            ? NSColor.black.withAlphaComponent(0.25).cgColor
            : NSColor.white.withAlphaComponent(0.40).cgColor
    }
}

// Configures the hosting NSWindow for full translucency and installs a
// behind-window NSVisualEffectView at the contentView level — behind the
// NSSplitView — so both columns show the frosted glass effect.
// Placed as a background() on the settings root view.
struct SettingsWindowBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView { NSView() }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            guard let window = nsView.window, let contentView = window.contentView else { return }
            window.isOpaque = false
            window.backgroundColor = .clear
            window.titlebarAppearsTransparent = true
            // Forces white title bar text regardless of desktop colour.
            if window.appearance?.name != .darkAqua {
                window.appearance = NSAppearance(named: .darkAqua)
            }
            Self.ensureVibrancy(in: contentView)
            Self.clearSplitPanes(in: contentView)
        }
    }

    // Inserts one NSVisualEffectView behind all other content in the window.
    private static let vibrancyID = NSUserInterfaceItemIdentifier("wcb.settings.vibrancy")

    private static func ensureVibrancy(in root: NSView) {
        if root.subviews.contains(where: { $0.identifier == vibrancyID }) { return }
        let fx = NSVisualEffectView()
        fx.identifier = vibrancyID
        fx.material = .hudWindow
        fx.blendingMode = .behindWindow
        fx.state = .active
        fx.translatesAutoresizingMaskIntoConstraints = false
        let anchor = root.subviews.first
        root.addSubview(fx, positioned: .below, relativeTo: anchor)
        NSLayoutConstraint.activate([
            fx.topAnchor.constraint(equalTo: root.topAnchor),
            fx.bottomAnchor.constraint(equalTo: root.bottomAnchor),
            fx.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            fx.trailingAnchor.constraint(equalTo: root.trailingAnchor)
        ])
    }

    // Clears the NSSplitView container and its non-vibrancy pane NSViews so
    // the window-level vibrancy shows through instead of their default fill.
    private static func clearSplitPanes(in view: NSView) {
        if let split = view as? NSSplitView {
            split.wantsLayer = true
            split.layer?.backgroundColor = NSColor.clear.cgColor
            for pane in split.subviews where !(pane is NSVisualEffectView) {
                pane.wantsLayer = true
                pane.layer?.backgroundColor = NSColor.clear.cgColor
                for child in pane.subviews where !(child is NSVisualEffectView) {
                    child.wantsLayer = true
                    child.layer?.backgroundColor = NSColor.clear.cgColor
                }
            }
        }
        for sub in view.subviews where !(sub is NSVisualEffectView) {
            clearSplitPanes(in: sub)
        }
    }
}
