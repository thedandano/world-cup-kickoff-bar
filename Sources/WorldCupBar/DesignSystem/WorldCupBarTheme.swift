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

    // Card chrome
    static let cardBorder = Color.primary.opacity(0.10)
}

// MARK: - Spacing tokens
enum WCBSpacing {
    static let xs: CGFloat  =  4
    static let sm: CGFloat  =  8
    static let md: CGFloat  = 16
    static let lg: CGFloat  = 24
    static let xl: CGFloat  = 32
}

// MARK: - Radius tokens
enum WCBRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
}

// MARK: - Opacity tokens
enum WCBOpacity {
    static let disabled: Double = 0.38
    static let secondary: Double = 0.55
    static let cardBorder: Double = 0.10
}

// MARK: - Typography tokens
enum WCBFont {
    static let cardTitle: Font = .system(size: 14, weight: .semibold)
    static let rowPrimary: Font = .system(size: 14, weight: .medium)
    static let caption: Font = .system(size: 12)
    static let codeMono: Font = .system(size: 11, weight: .medium, design: .monospaced)
}
