import AppKit
import SwiftUI
import WorldCupBarCore

struct MenuBarDropdownView: View {
    @Environment(\.openWindow) private var openWindow
    @Bindable var viewModel: WorldCupBarViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: WCBSpacing.md) {
            toolbarSection
            highlightedMatchSection

            upcomingMatchesSection

            if !viewModel.availableCountries.isEmpty || !viewModel.followedCountries.isEmpty {
                followedCountriesSection
            }
            footerSection
        }
        .padding(.horizontal, WCBSpacing.md)
        .padding(.vertical, 14)
        .background(VisualEffectBackground().ignoresSafeArea())
    }

    private var toolbarSection: some View {
        HStack {
            Button {
                Task {
                    await viewModel.refresh()
                }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .imageScale(.medium)
                    .rotationEffect(viewModel.isRefreshing ? .degrees(360) : .degrees(0))
                    .animation(
                        viewModel.isRefreshing
                            ? .linear(duration: 1).repeatForever(autoreverses: false)
                            : .default,
                        value: viewModel.isRefreshing
                    )
                    .foregroundStyle(WCBColor.accent)
            }
            .buttonStyle(.borderless)
            .help("Refresh live data")
            .accessibilityLabel("Refresh live data")
            .disabled(viewModel.isRefreshing)

            Spacer()

            Button {
                openWindow(id: "settings")
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                Image(systemName: "gearshape")
                    .imageScale(.medium)
                    .foregroundStyle(WCBColor.accent)
            }
            .buttonStyle(.borderless)
            .help("Settings")
            .accessibilityLabel("Settings")
        }
        .padding(.horizontal, 2)
    }

    private var highlightedMatchSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                LiveRail(text: railTitle, isLive: highlightedMatchIsLive)

                Spacer()

                Text(railDetail)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(WCBColor.secondaryLabel)
                    .lineLimit(1)
            }

            if let match = viewModel.highlightedMatch {
                HeroMatchRow(
                    match: match,
                    centerText: centerStatusText(for: match),
                    showLivePill: match.status.isLive
                )
            } else {
                Text(highlightSubtitle)
                    .font(WCBFont.caption)
                    .foregroundStyle(WCBColor.secondaryLabel)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(panelBackground)
    }

    private var followedCountriesSection: some View {
        VStack(alignment: .leading, spacing: WCBSpacing.sm) {
            SectionHeader(title: "Following")

            if viewModel.followedCountries.isEmpty {
                Text(viewModel.availableCountries.isEmpty ? "Team list is loading." : "Not following anyone. Add teams in Settings.")
                    .font(WCBFont.caption)
                    .foregroundStyle(WCBColor.secondaryLabel)
                    .padding(.horizontal, 2)
            } else {
                FlowLayout(spacing: 6) {
                    ForEach(viewModel.followedCountries) { country in
                        CountryChip(country: country)
                    }
                }
            }
        }
    }

    private var upcomingMatchesSection: some View {
        VStack(alignment: .leading, spacing: WCBSpacing.sm) {
            SectionHeader(title: "Upcoming")

            if viewModel.upcomingMatches.isEmpty {
                Text(upcomingEmptyStateText)
                    .font(WCBFont.caption)
                    .foregroundStyle(WCBColor.secondaryLabel)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.upcomingMatches.prefix(5)) { match in
                        MatchRow(
                            match: match,
                            title: viewModel.dropdownMatchupTitle(for: match),
                            time: viewModel.scheduledTime(for: match.kickoffDate)
                        )

                        if match.id != viewModel.upcomingMatches.prefix(5).last?.id {
                            Divider()
                                .overlay(WCBColor.separator)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(panelBackground)
            }
        }
    }

    private var footerSection: some View {
        VStack(spacing: 8) {
            Divider()

            Text(viewModel.footerStatusText)
                .font(.system(size: 11))
                .foregroundStyle(WCBColor.secondaryLabel)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var highlightTitle: String {
        switch viewModel.contentState {
        case .loading:
            return "Loading World Cup"
        case .unavailable:
            return "Live data unavailable"
        case .postTournament:
            return "See you in 2030!"
        case .content(let state):
            switch state {
            case .live(let match):
                return liveScoreTitle(for: match)
            case .upcoming(let match):
                return viewModel.dropdownMatchupTitle(for: match)
            case .empty:
                return "World Cup"
            }
        }
    }

    private var highlightSubtitle: String {
        if let match = viewModel.highlightedMatch {
            return match.venue
        }

        switch viewModel.contentState {
        case .loading:
            return "Loading the latest World Cup matches."
        case .unavailable:
            return "Live match data is unavailable right now."
        case .postTournament:
            return "The 2026 tournament is complete. The app will wait for the next World Cup."
        case .content:
            return "No tracked match is available right now."
        }
    }

    private var highlightedMatchIsLive: Bool {
        viewModel.highlightedMatch?.status.isLive == true
    }

    private var railTitle: String {
        switch viewModel.contentState {
        case .content(.live):
            return "Live now"
        case .content(.upcoming):
            return "Up next"
        case .loading:
            return "Loading"
        case .unavailable:
            return "Offline"
        case .postTournament:
            return "2026 complete"
        case .content(.empty):
            return "World Cup"
        }
    }

    private var railDetail: String {
        guard let match = viewModel.highlightedMatch else {
            return ""
        }

        return match.venue
    }

    private var upcomingEmptyStateText: String {
        switch viewModel.contentState {
        case .postTournament:
            return "No more fixtures remain in the 2026 tournament."
        case .unavailable:
            return "Upcoming matches will appear once live data returns."
        default:
            return "No upcoming matches match this search."
        }
    }

    private func liveScoreTitle(for match: WorldCupMatch) -> String {
        guard let score = match.score else {
            return "\(viewModel.matchupTitle(for: match)) Live"
        }

        return switch viewModel.displayMode {
        case .abbreviations:
            "\(match.home.code) \(score.home)-\(score.away) \(match.away.code)"
        case .flags:
            "\(match.home.hasRenderableFlag ? match.home.flagEmoji : match.home.code) \(score.home)-\(score.away) \(match.away.hasRenderableFlag ? match.away.flagEmoji : match.away.code)"
        }
    }

    private func centerStatusText(for match: WorldCupMatch) -> String {
        switch match.status {
        case .live(let minute):
            if let minute {
                return "\(minute)'"
            }
            return "LIVE"
        case .scheduled:
            return viewModel.scheduledTime(for: match.kickoffDate)
        case .finished:
            return "Final"
        }
    }

    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: WCBRadius.lg)
            .fill(WCBColor.controlBackground.opacity(0.72))
            .overlay(
                RoundedRectangle(cornerRadius: WCBRadius.lg)
                    .strokeBorder(WCBColor.cardBorder, lineWidth: 0.5)
            )
    }
}

private struct LiveRail: View {
    let text: String
    let isLive: Bool

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isLive ? Color.green : WCBColor.accent)
                .frame(width: 8, height: 8)

            Text(text.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isLive ? Color.green : WCBColor.secondaryLabel)
                .tracking(0.3)
        }
    }
}

private struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(WCBColor.secondaryLabel)
            .padding(.horizontal, 2)
    }
}

private struct StatusPill: View {
    let text: String
    let isLive: Bool

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .monospacedDigit()
            .foregroundStyle(isLive ? Color.green : WCBColor.secondaryLabel)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isLive ? Color.green.opacity(0.13) : WCBColor.controlBackground)
            )
    }
}

private struct CountryChip: View {
    let country: Country

    var body: some View {
        HStack(spacing: 5) {
            if country.hasRenderableFlag {
                Text(country.flagEmoji)
            }
            Text(country.code)
                .fontWeight(.semibold)
        }
        .font(.system(size: 12))
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(WCBColor.controlBackground.opacity(0.8))
                .overlay(
                    Capsule()
                        .strokeBorder(WCBColor.cardBorder, lineWidth: 0.5)
                )
        )
    }
}

private struct MatchRow: View {
    let match: WorldCupMatch
    let title: String
    let time: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text(match.venue)
                    .font(WCBFont.codeMono)
                    .foregroundStyle(WCBColor.secondaryLabel)
                    .lineLimit(1)
            }

            Spacer(minLength: 12)

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
        .padding(.vertical, 9)
    }
}

private struct HeroMatchRow: View {
    let match: WorldCupMatch
    let centerText: String
    let showLivePill: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 18) {
            teamColumn(country: match.home, alignment: .leading)

            VStack(spacing: 6) {
                Text(scoreText)
                    .font(.system(size: 28, weight: .medium))
                    .monospacedDigit()
                    .foregroundStyle(showLivePill ? Color.green : WCBColor.label)

                Text(centerText)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(showLivePill ? Color.green : WCBColor.secondaryLabel)
                    .monospacedDigit()
            }
            .frame(minWidth: 140)

            teamColumn(country: match.away, alignment: .trailing)
        }
    }

    private var scoreText: String {
        guard let score = match.score else {
            return "-  -"
        }
        return "\(score.home) - \(score.away)"
    }

    @ViewBuilder
    private func teamColumn(country: Country, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 6) {
            HStack(spacing: 10) {
                if alignment == .trailing {
                    Text(country.code)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(WCBColor.label)

                    if country.hasRenderableFlag {
                        Text(country.flagEmoji)
                            .font(.system(size: 32))
                    }
                } else {
                    if country.hasRenderableFlag {
                        Text(country.flagEmoji)
                            .font(.system(size: 32))
                    }

                    Text(country.code)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(WCBColor.label)
                }
            }

            Text(country.name)
                .font(.system(size: 12))
                .foregroundStyle(WCBColor.secondaryLabel)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : .trailing)
    }
}
