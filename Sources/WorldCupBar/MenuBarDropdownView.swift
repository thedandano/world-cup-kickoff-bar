import AppKit
import SwiftUI
import WorldCupBarCore

struct MenuBarDropdownView: View {
    @Environment(\.openWindow) private var openWindow
    @ObservedObject var viewModel: WorldCupBarViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            toolbarSection
            highlightedMatchSection
            searchField
            followedCountriesSection
            upcomingMatchesSection
            footerSection
        }
        .padding(16)
        .background(Color(nsColor: .windowBackgroundColor))
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
            }
            .buttonStyle(.borderless)
            .help("Refresh mock data")
            .accessibilityLabel("Refresh mock data")

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

            if let match = viewModel.highlightedMatch {
                Text(match.venue)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            } else {
                Text("No matches available in mock data.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }

    private var searchField: some View {
        TextField("Search matches or countries", text: $viewModel.searchText)
            .textFieldStyle(.roundedBorder)
            .font(.system(size: 13))
    }

    private var followedCountriesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Followed countries")

            if viewModel.followedCountries.isEmpty {
                Text("No followed countries. Add them in Settings.")
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
                Text("No upcoming matches match this search.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.upcomingMatches.prefix(5)) { match in
                        MatchRow(match: match, title: viewModel.matchupTitle(for: match), time: viewModel.localTime(for: match.kickoffDate))

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

            Text(mockStatusText)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var highlightTitle: String {
        switch viewModel.displayState {
        case .live(let match):
            return liveScoreTitle(for: match)
        case .upcoming(let match):
            return viewModel.matchupTitle(for: match)
        case .empty:
            return "World Cup"
        }
    }

    private var mockStatusText: String {
        if let refreshErrorMessage = viewModel.refreshErrorMessage {
            return refreshErrorMessage
        }

        guard let lastUpdated = viewModel.lastUpdated else {
            return "Mock data adapter"
        }

        return "Mock data, updated \(viewModel.localTime(for: lastUpdated))"
    }

    private func liveScoreTitle(for match: WorldCupMatch) -> String {
        guard let score = match.score else {
            return "\(viewModel.matchupTitle(for: match)) Live"
        }

        return "\(match.home.code) \(score.home)-\(score.away) \(match.away.code)"
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
            Text(country.flagEmoji)
            Text(country.code)
                .fontWeight(.semibold)
        }
        .font(.system(size: 12))
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
}

private struct MatchRow: View {
    let match: WorldCupMatch
    let title: String
    let time: String

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color.accentColor.opacity(0.75))
                .frame(width: 6, height: 6)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .monospacedDigit()
                Text(match.venue)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(time)
                .font(.system(size: 12, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 7)
    }
}
