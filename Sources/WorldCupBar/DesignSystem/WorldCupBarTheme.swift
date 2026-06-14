import SwiftUI

// MARK: - Color tokens
enum WCBColor {
    // Brand accent — lavender purple
    static let accent       = Color(red: 0.576, green: 0.439, blue: 0.820)
    static let accentSubtle = Color(red: 0.576, green: 0.439, blue: 0.820).opacity(0.12)

    // Adaptive (NSColor-backed so they flip correctly in light/dark)
    static let windowBackground  = Color(nsColor: .windowBackgroundColor)
    static let controlBackground = Color(nsColor: .controlBackgroundColor)
    static let separator         = Color(nsColor: .separatorColor)
    static let label             = Color(nsColor: .labelColor)
    static let secondaryLabel    = Color(nsColor: .secondaryLabelColor)

    // Translucent card/control chrome, layered over the behind-window vibrancy.
    static let cardFill    = Color.primary.opacity(WCBOpacity.cardFill)
    static let controlFill = Color.primary.opacity(WCBOpacity.controlFill)
    static let cardBorder  = Color.primary.opacity(WCBOpacity.border)
}

// MARK: - Spacing tokens
enum WCBSpacing {
    static let extraSmall: CGFloat = 4
    static let small: CGFloat      = 8
    static let medium: CGFloat     = 16
    static let large: CGFloat      = 24
    static let extraLarge: CGFloat = 32
}

// MARK: - Radius tokens
enum WCBRadius {
    static let small: CGFloat  = 8
    static let medium: CGFloat = 12
    static let large: CGFloat  = 16
}

// MARK: - Opacity tokens
enum WCBOpacity {
    static let disabled: Double = 0.38
    static let secondary: Double = 0.55

    // Translucent surfaces layered over the window's behind-window vibrancy.
    static let cardFill: Double = 0.04       // panels / cards
    static let controlFill: Double = 0.08    // chips / pills
    static let border: Double = 0.08         // hairline borders
}

// MARK: - Typography tokens
enum WCBFont {
    static let viewTitle: Font = .system(size: 22, weight: .bold)
    static let viewSubtitle: Font = .system(size: 13)
    static let cardTitle: Font = .system(size: 14, weight: .semibold)
    static let rowPrimary: Font = .system(size: 14, weight: .medium)
    static let caption: Font = .system(size: 12)
    static let codeMono: Font = .system(size: 11, weight: .medium, design: .monospaced)
}
