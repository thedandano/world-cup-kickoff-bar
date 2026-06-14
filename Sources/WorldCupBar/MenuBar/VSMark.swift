import SwiftUI
import WorldCupBarCore

/// A drawn "vs" mark shown between two teams. Color is inherited from the
/// caller's `.foregroundStyle`; `size` sets the glyph height in points.
/// `compact` switches the tall `clash` mark to a single-line layout for the
/// menu bar and list rows.
struct VSMark: View {
    let style: VSMarkStyle
    var size: CGFloat = 20
    var compact: Bool = false

    var body: some View {
        switch style {
        case .italic:
            Text("vs")
                .font(.system(size: size, weight: .regular, design: .serif))
                .italic()
        case .ring:
            ZStack {
                Circle()
                    .strokeBorder(lineWidth: max(1.2, size * 0.07))
                Text("VS")
                    .font(.system(size: size * 0.42, weight: .bold))
            }
            .frame(width: size, height: size)
        case .slash:
            HStack(spacing: size * 0.04) {
                Text("v").font(.system(size: size, weight: .medium))
                slash(height: size * 0.95, thickness: max(1.5, size * 0.08))
                Text("s").font(.system(size: size, weight: .medium))
            }
        case .clash:
            // Only clash needs a compact variant: its tall V/S offset doesn't
            // fit a single line. The other three are already single-line.
            if compact {
                clashCompact
            } else {
                clashMark
            }
        }
    }

    private var clashMark: some View {
        ZStack {
            Text("V")
                .font(.system(size: size, weight: .heavy))
                .offset(x: -size * 0.28, y: -size * 0.21)
            Text("S")
                .font(.system(size: size, weight: .heavy))
                .offset(x: size * 0.28, y: size * 0.21)
            slash(height: size * 1.40, thickness: max(2, size * 0.10))
        }
        .frame(width: size * 1.5, height: size * 1.6)
    }

    private var clashCompact: some View {
        HStack(spacing: size * 0.04) {
            Text("V").font(.system(size: size, weight: .heavy))
            slash(height: size * 1.05, thickness: max(1.5, size * 0.09))
            Text("S").font(.system(size: size, weight: .heavy))
        }
    }

    private func slash(height: CGFloat, thickness: CGFloat) -> some View {
        Capsule()
            .frame(width: thickness, height: height)
            .rotationEffect(.degrees(18))
    }
}

#Preview {
    HStack(spacing: 24) {
        ForEach(VSMarkStyle.allCases, id: \.self) { style in
            VStack(spacing: 8) {
                VSMark(style: style, size: 30)
                Text(style.displayName).font(.caption)
            }
        }
    }
    .foregroundStyle(.purple)
    .padding(40)
}
