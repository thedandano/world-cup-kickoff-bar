import AppKit
import SwiftUI
import WorldCupBarCore

struct MenuBarDropdownView: View {
    @Environment(\.openWindow) private var openWindow
    @Bindable var viewModel: WorldCupBarViewModel
    @State private var selectedTab: MatchListTab = .following

    var body: some View {
        VStack(alignment: .leading, spacing: WCBSpacing.medium) {
            toolbarSection
            highlightedMatchSection
            matchesSection
            footerSection
        }
        .padding(.horizontal, WCBSpacing.medium)
        .padding(.vertical, 14)
        .background(WCBVibrancyBackground().ignoresSafeArea())
    }

    private var toolbarSection: some View {
        HStack {
            refreshButton
            Spacer()
            settingsButton
        }
        .padding(.horizontal, 2)
    }

    private var refreshButton: some View {
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
    }

    private var settingsButton: some View {
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

    private var highlightedMatchSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            railHeader

            if let match = spotlightMatch {
                HeroMatchRow(
                    match: match,
                    centerText: centerStatusText(for: match),
                    showLivePill: match.status.isLive,
                    style: viewModel.vsMarkStyle
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

    private var railHeader: some View {
        HStack(alignment: .center) {
            LiveRail(text: railTitle, isLive: spotlightIsLive)

            Spacer()

            Text(railDetail)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(WCBColor.secondaryLabel)
                .lineLimit(1)
        }
    }

    private var spotlight: MatchDisplayState {
        viewModel.dropdownSpotlight(followedOnly: selectedTab == .following)
    }

    private var spotlightMatch: WorldCupMatch? {
        guard case .content = viewModel.contentState else { return nil }
        return spotlight.match
    }

    private var spotlightIsLive: Bool {
        guard case .content = viewModel.contentState else { return false }
        if case .live = spotlight { return true }
        return false
    }

    private var matchesSection: some View {
        VStack(alignment: .leading, spacing: WCBSpacing.small) {
            Picker("Match list", selection: $selectedTab) {
                ForEach(MatchListTab.allCases) { tab in
                    Text(tab.title).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: .infinity)

            matchList(for: selectedTab)
        }
    }

    @ViewBuilder
    private func matchList(for tab: MatchListTab) -> some View {
        let matches = tab == .following ? viewModel.followedUpcomingMatches : viewModel.upcomingMatches

        if matches.isEmpty {
            Text(emptyText(for: tab))
                .font(WCBFont.caption)
                .foregroundStyle(WCBColor.secondaryLabel)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
        } else {
            VStack(spacing: 0) {
                ForEach(matches.prefix(5)) { match in
                    MatchRow(
                        match: match,
                        style: viewModel.vsMarkStyle,
                        time: viewModel.scheduledTime(for: match.kickoffDate)
                    )

                    if match.id != matches.prefix(5).last?.id {
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

    private func emptyText(for tab: MatchListTab) -> String {
        switch tab {
        case .following:
            return viewModel.followedCountryCodes.isEmpty
                ? "You're not following any teams. Add teams in Settings."
                : "No upcoming matches for the teams you follow."
        case .all:
            return upcomingEmptyStateText
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

    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: WCBRadius.large)
            .fill(WCBColor.cardFill)
            .overlay(
                RoundedRectangle(cornerRadius: WCBRadius.large)
                    .strokeBorder(WCBColor.cardBorder, lineWidth: 0.5)
            )
    }
}

// MARK: - Text helpers

private extension MenuBarDropdownView {
    var highlightTitle: String {
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

    var highlightSubtitle: String {
        switch viewModel.contentState {
        case .loading:
            return "Loading the latest World Cup matches."
        case .unavailable:
            return "Live match data is unavailable right now."
        case .postTournament:
            return "The 2026 tournament is complete. The app will wait for the next World Cup."
        case .content:
            return selectedTab == .following
                ? "No upcoming matches for the teams you follow."
                : "No upcoming matches right now."
        }
    }

    var railTitle: String {
        switch viewModel.contentState {
        case .loading:
            return "Loading"
        case .unavailable:
            return "Offline"
        case .postTournament:
            return "2026 complete"
        case .content:
            switch spotlight {
            case .live:
                return "Live now"
            case .upcoming, .empty:
                return "Up next"
            }
        }
    }

    var railDetail: String {
        spotlightMatch?.venue ?? ""
    }

    var upcomingEmptyStateText: String {
        switch viewModel.contentState {
        case .postTournament:
            return "No more fixtures remain in the 2026 tournament."
        case .unavailable:
            return "Upcoming matches will appear once live data returns."
        default:
            return "No upcoming matches match this search."
        }
    }

    func liveScoreTitle(for match: WorldCupMatch) -> String {
        guard let score = match.score else {
            return "\(viewModel.matchupTitle(for: match)) Live"
        }

        return switch viewModel.displayMode {
        case .abbreviations:
            "\(match.home.code) \(score.home)-\(score.away) \(match.away.code)"
        case .flags:
            {
                let homeLabel = match.home.hasRenderableFlag ? match.home.flagEmoji : match.home.code
                let awayLabel = match.away.hasRenderableFlag ? match.away.flagEmoji : match.away.code
                return "\(homeLabel) \(score.home)-\(score.away) \(awayLabel)"
            }()
        }
    }

    func centerStatusText(for match: WorldCupMatch) -> String {
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
}

private struct LiveRail: View {
    let text: String
    let isLive: Bool

    var body: some View {
        HStack(spacing: 8) {
            if isLive {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
            }

            Text(text.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isLive ? Color.green : WCBColor.secondaryLabel)
                .tracking(0.3)
        }
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

private struct HeroMatchRow: View {
    let match: WorldCupMatch
    let centerText: String
    let showLivePill: Bool
    let style: VSMarkStyle

    var body: some View {
        HStack(alignment: .center, spacing: 18) {
            teamColumn(country: match.home, alignment: .leading)

            VStack(spacing: 6) {
                if showLivePill {
                    Text(scoreText)
                        .font(.system(size: 28, weight: .medium))
                        .monospacedDigit()
                        .foregroundStyle(Color.green)
                } else {
                    VSMark(style: style, size: 22)
                        .foregroundStyle(WCBColor.secondaryLabel)
                }

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
            teamFlagAndCode(country: country, alignment: alignment)

            Text(country.name)
                .font(.system(size: 12))
                .foregroundStyle(WCBColor.secondaryLabel)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : .trailing)
    }

    @ViewBuilder
    private func teamFlagAndCode(country: Country, alignment: HorizontalAlignment) -> some View {
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
    }
}

private enum MatchListTab: String, CaseIterable, Identifiable {
    case following
    case all

    var id: String { rawValue }

    var title: String {
        switch self {
        case .following: return "Following"
        case .all:       return "All Matches"
        }
    }
}
