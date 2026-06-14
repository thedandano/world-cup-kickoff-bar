import SwiftUI
import WorldCupBarCore

struct MatchRow: View {
    let match: WorldCupMatch
    let style: VSMarkStyle
    let time: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    teamLabel(match.home)
                    VSMark(style: style, size: 12, compact: true)
                        .foregroundStyle(WCBColor.secondaryLabel)
                    teamLabel(match.away)
                }
                .lineLimit(1)

                Text(match.venue)
                    .font(WCBFont.codeMono)
                    .foregroundStyle(WCBColor.secondaryLabel)
                    .lineLimit(1)
            }

            Spacer(minLength: 12)

            trailingColumn
        }
        .padding(.vertical, 9)
    }

    private var trailingColumn: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(time)
                .font(.system(size: 12, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(WCBColor.label)

            Text(match.status == .scheduled ? "Local" : "")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(WCBColor.secondaryLabel)
        }
    }

    private func teamLabel(_ country: Country) -> some View {
        HStack(spacing: 4) {
            if country.hasRenderableFlag {
                Text(country.flagEmoji)
            }
            Text(country.code)
                .font(.system(size: 13, weight: .medium))
        }
    }
}
