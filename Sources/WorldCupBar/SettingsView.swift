import SwiftUI
import WorldCupBarCore

struct SettingsView: View {
    @ObservedObject var viewModel: WorldCupBarViewModel
    @ObservedObject var updaterViewModel: UpdaterViewModel
    @State private var selectedPanel: SettingsPanel? = .following

    private var activePanel: SettingsPanel { selectedPanel ?? .following }

    var body: some View {
        NavigationSplitView {
            List(SettingsPanel.allCases, id: \.self, selection: $selectedPanel) { panel in
                Label(panel.title, systemImage: panel.icon)
                    .tag(panel)
            }
            .navigationSplitViewColumnWidth(min: 160, ideal: 180)
            .listStyle(.sidebar)
        } detail: {
            ZStack {
                VisualEffectBackground().ignoresSafeArea()
                detailContent
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 680, minHeight: 480)
    }

    @ViewBuilder
    private var detailContent: some View {
        switch activePanel {
        case .display:       DisplayPanel(viewModel: viewModel)
        case .following:     FollowingPanel(viewModel: viewModel)
        case .notifications: NotificationsPanel(viewModel: viewModel)
        case .analytics:     AnalyticsPanel(viewModel: viewModel)
        case .data:          DataPanel(viewModel: viewModel, updaterViewModel: updaterViewModel)
        }
    }
}

// MARK: - Panel enum

private enum SettingsPanel: CaseIterable, Hashable {
    case display, following, notifications, analytics, data

    var title: String {
        switch self {
        case .display:       return "Display"
        case .following:     return "Following"
        case .notifications: return "Notifications"
        case .analytics:     return "Analytics"
        case .data:          return "Data"
        }
    }

    var icon: String {
        switch self {
        case .display:       return "menubar.rectangle"
        case .following:     return "star"
        case .notifications: return "bell"
        case .analytics:     return "chart.bar"
        case .data:          return "arrow.clockwise.icloud"
        }
    }
}

// MARK: - Panels

private struct DisplayPanel: View {
    @ObservedObject var viewModel: WorldCupBarViewModel

    var body: some View {
        PanelScrollView {
            SettingsCard(title: "Menu Bar Display", subtitle: "Choose the compact match label.") {
                HStack(alignment: .center, spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Display mode")
                            .font(.system(size: 14, weight: .medium))
                        Text("Show team codes or flag emoji.")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Picker("Display mode", selection: $viewModel.displayMode) {
                        Text("Abbreviations").tag(DisplayMode.abbreviations)
                        Text("Flags").tag(DisplayMode.flags)
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(width: 250)
                    .help("Controls whether compact match labels use team codes or flags.")
                }
                .padding(16)
            }
        }
    }
}

private struct FollowingPanel: View {
    @ObservedObject var viewModel: WorldCupBarViewModel
    @State private var search = ""

    private var filtered: [Country] {
        guard !search.isEmpty else { return viewModel.availableCountries }
        return viewModel.availableCountries.filter {
            $0.name.localizedCaseInsensitiveContains(search)
                || $0.code.localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        PanelScrollView {
            SettingsCard(
                title: "Following",
                subtitle: "Teams you follow get priority in the menu bar."
            ) {
                if viewModel.availableCountries.isEmpty {
                    Text("Team list will appear after the first live refresh.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .padding(16)
                } else {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search countries", text: $search)
                            .textFieldStyle(.plain)
                        if !search.isEmpty {
                            Button { search = "" } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                    Divider()

                    if filtered.isEmpty {
                        Text("No countries match \"\(search)\".")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .padding(16)
                    } else {
                        ForEach(filtered) { country in
                            CountrySettingsRow(
                                country: country,
                                isFollowed: Binding(
                                    get: { viewModel.followedCountryCodes.contains(country.code) },
                                    set: { viewModel.setFollowed(country, isFollowed: $0) }
                                )
                            )
                            if country.id != filtered.last?.id {
                                Divider().padding(.leading, 46)
                            }
                        }
                    }

                    Divider()

                    Text("Live followed matches appear before upcoming matches.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }
            }
        }
    }
}

private struct NotificationsPanel: View {
    @ObservedObject var viewModel: WorldCupBarViewModel

    var body: some View {
        PanelScrollView {
            SettingsCard(title: "Kickoff Alerts", subtitle: "Get notified before followed matches kick off.") {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Alert timing")
                            .font(.system(size: 14, weight: .medium))
                        Text("Notify before a followed match starts.")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Picker("Alert timing", selection: $viewModel.notificationMinutesBefore) {
                        Text("Off").tag(0)
                        Text("5 min").tag(5)
                        Text("15 min").tag(15)
                        Text("30 min").tag(30)
                        Text("60 min").tag(60)
                    }
                    .labelsHidden()
                    .frame(width: 120)
                }
                .padding(16)
            }
        }
    }
}

private struct AnalyticsPanel: View {
    @ObservedObject var viewModel: WorldCupBarViewModel

    var body: some View {
        PanelScrollView {
            SettingsCard(title: "Analytics", subtitle: "Control product analytics.") {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Usage analytics")
                            .font(.system(size: 14, weight: .medium))
                        Text("Turn off product analytics any time.")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Toggle("Usage analytics", isOn: $viewModel.analyticsEnabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
                .padding(16)
            }
        }
    }
}

private struct DataPanel: View {
    @ObservedObject var viewModel: WorldCupBarViewModel
    @ObservedObject var updaterViewModel: UpdaterViewModel

    var body: some View {
        PanelScrollView {
            SettingsCard(title: "Data", subtitle: "Refresh match data or check for app updates.") {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Match data")
                            .font(.system(size: 14, weight: .medium))
                        Text(viewModel.footerStatusText)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        Task { await viewModel.refresh() }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
                .padding(16)

                Divider().padding(.leading, 16)

                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("App updates")
                            .font(.system(size: 14, weight: .medium))
                        Text("Check for a new version of World Cup Bar.")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Check for Updates") {
                        updaterViewModel.checkForUpdates()
                    }
                    .disabled(!updaterViewModel.canCheckForUpdates)
                }
                .padding(16)
            }
        }
    }
}

// MARK: - Shared layout components

private struct PanelScrollView<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                content
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct SettingsCard<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 0) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.primary.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
                    )
            )
        }
    }
}

private struct CountrySettingsRow: View {
    let country: Country
    @Binding var isFollowed: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text(country.flagEmoji)
                .font(.system(size: 16))
                .frame(width: 24, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(country.name)
                    .font(.system(size: 14, weight: .medium))
                Text(country.code)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .monospaced()
            }

            Spacer(minLength: 24)

            Toggle(country.name, isOn: $isFollowed)
                .labelsHidden()
                .toggleStyle(.switch)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 48)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
