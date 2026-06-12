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
