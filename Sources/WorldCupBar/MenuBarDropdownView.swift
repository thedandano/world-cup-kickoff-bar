import AppKit
import SwiftUI
import WorldCupBarCore

struct MenuBarDropdownView: View {
    @Environment(\.openWindow) private var openWindow
    @Bindable var viewModel: WorldCupBarViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            toolbarSection
            highlightedMatchSection

            if viewModel.contentState != .postTournament {
                searchField
            }

            if !viewModel.availableCountries.isEmpty || !viewModel.followedCountries.isEmpty {
                followedCountriesSection
            }

            upcomingMatchesSection
            footerSection
        }
        .padding(16)
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
            }
            .buttonStyle(.borderless)
            .help("Settings")
            .accessibilityLabel("Settings")
        }
    }

    private var highlightedMatchSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(highlightTitle)
                    .font(.system(size: 17, weight: .semibold))
                    .monospacedDigit()

                Spacer()

                if let match = viewModel.highlightedMatch {
                    StatusPill(text: viewModel.statusLine(for: match), isLive: match.status.isLive)
                }
            }

            Text(highlightSubtitle)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.primary.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.primary.opacity(0.10), lineWidth: 0.5)
                )
        )
    }

    private var searchField: some View {
        TextField("Search matches or countries", text: $viewModel.searchText)
            .textFieldStyle(.roundedBorder)
            .font(.system(size: 13))
    }

    private var followedCountriesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Following")

            if viewModel.followedCountries.isEmpty {
                Text(viewModel.availableCountries.isEmpty ? "Team list is loading." : "Not following anyone. Add teams in Settings.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
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
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Upcoming")

            if viewModel.upcomingMatches.isEmpty {
                Text(upcomingEmptyStateText)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.upcomingMatches.prefix(5)) { match in
                        MatchRow(
                            match: match,
                            title: viewModel.dropdownMatchupTitle(for: match),
                            time: viewModel.localTime(for: match.kickoffDate)
                        )

                        if match.id != viewModel.upcomingMatches.prefix(5).last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private var footerSection: some View {
        VStack(spacing: 8) {
            Divider()

            Text(viewModel.footerStatusText)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
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
}

private struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.secondary)
    }
}

private struct StatusPill: View {
    let text: String
    let isLive: Bool

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .monospacedDigit()
            .foregroundStyle(isLive ? Color.green : Color.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(isLive ? Color.green.opacity(0.12) : Color.secondary.opacity(0.10))
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
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(Color.primary.opacity(0.06))
                .overlay(
                    Capsule()
                        .strokeBorder(Color.primary.opacity(0.10), lineWidth: 0.5)
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
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 12)

            Text(time)
                .font(.system(size: 12, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 10)
    }
}
