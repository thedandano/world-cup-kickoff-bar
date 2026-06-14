import SwiftUI
import WorldCupBarCore

struct SettingsView: View {
    var viewModel: WorldCupBarViewModel
    var updaterViewModel: UpdaterViewModel
    @State private var selectedPanel: SettingsPanel? = .display

    private var activePanel: SettingsPanel { selectedPanel ?? .following }

    var body: some View {
        NavigationSplitView {
            List(SettingsPanel.allCases, id: \.self, selection: $selectedPanel) { panel in
                Label(panel.title, systemImage: panel.icon)
                    .foregroundStyle(Color.primary)
                    .tag(panel)
            }
            .navigationSplitViewColumnWidth(min: 160, ideal: 180)
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            .background(WCBVibrancyBackground().ignoresSafeArea())
        } detail: {
            ZStack {
                WCBVibrancyBackground()
                    .ignoresSafeArea()
                detailContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .tint(WCBColor.accent)
        .frame(minWidth: 680, minHeight: 480)
        .background(SettingsWindowBackground().ignoresSafeArea())
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
    case display, notifications, following, analytics, data

    var title: String {
        switch self {
        case .display:       return "Display"
        case .notifications: return "Notifications"
        case .following:     return "Following"
        case .analytics:     return "Analytics"
        case .data:          return "Data"
        }
    }

    var icon: String {
        switch self {
        case .display:       return "menubar.rectangle"
        case .notifications: return "bell"
        case .following:     return "star"
        case .analytics:     return "chart.bar"
        case .data:          return "arrow.clockwise.icloud"
        }
    }
}

// MARK: - Panels

private struct DisplayPanel: View {
    @Bindable var viewModel: WorldCupBarViewModel

    var body: some View {
        PanelScrollView(title: "Display", subtitle: "Choose the compact match label.") {
            SettingsCard {
                HStack(alignment: .center, spacing: WCBSpacing.lg) {
                    VStack(alignment: .leading, spacing: WCBSpacing.xs) {
                        Text("Display mode")
                            .font(WCBFont.rowPrimary)
                        Text("Show team codes or flag emoji.")
                            .font(WCBFont.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Picker("Display mode", selection: $viewModel.displayMode) {
                        Text("Abbreviations").tag(DisplayMode.abbreviations)
                        Text("Flags").tag(DisplayMode.flags)
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .tint(WCBColor.accent)
                    .frame(width: 250)
                    .help("Controls whether compact match labels use team codes or flags.")
                }
                .padding(WCBSpacing.md)
            }
        }
    }
}

private struct FollowingPanel: View {
    var viewModel: WorldCupBarViewModel
    @State private var search = ""

    private var filtered: [Country] {
        guard !search.isEmpty else { return viewModel.availableCountries }
        return viewModel.availableCountries.filter {
            $0.name.localizedCaseInsensitiveContains(search)
                || $0.code.localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        PanelScrollView(title: "Following", subtitle: "Teams you follow get priority in the menu bar.") {
            SettingsCard {
                if viewModel.availableCountries.isEmpty {
                    Text("Team list will appear after the first live refresh.")
                        .font(WCBFont.caption)
                        .foregroundStyle(.secondary)
                        .padding(WCBSpacing.md)
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
                    .padding(.horizontal, WCBSpacing.md)
                    .padding(.vertical, 10)

                    Divider()

                    if filtered.isEmpty {
                        Text("No countries match \"\(search)\".")
                            .font(WCBFont.caption)
                            .foregroundStyle(.secondary)
                            .padding(WCBSpacing.md)
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
                        .font(WCBFont.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, WCBSpacing.md)
                        .padding(.vertical, 12)
                }
            }
        }
    }
}

private struct NotificationsPanel: View {
    @Bindable var viewModel: WorldCupBarViewModel

    var body: some View {
        PanelScrollView(title: "Notifications", subtitle: "Get notified before followed matches kick off.") {
            SettingsCard {
                HStack(spacing: WCBSpacing.md) {
                    VStack(alignment: .leading, spacing: WCBSpacing.xs) {
                        Text("Alert timing")
                            .font(WCBFont.rowPrimary)
                        Text("Notify before a followed match starts.")
                            .font(WCBFont.caption)
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
                    .tint(WCBColor.accent)
                    .frame(width: 120)
                }
                .padding(WCBSpacing.md)
            }
        }
    }
}

private struct AnalyticsPanel: View {
    @Bindable var viewModel: WorldCupBarViewModel

    var body: some View {
        PanelScrollView(title: "Analytics", subtitle: "Control product analytics.") {
            SettingsCard {
                HStack(spacing: WCBSpacing.md) {
                    VStack(alignment: .leading, spacing: WCBSpacing.xs) {
                        Text("Usage analytics")
                            .font(WCBFont.rowPrimary)
                        Text("Turn off product analytics any time.")
                            .font(WCBFont.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Toggle("Usage analytics", isOn: $viewModel.analyticsEnabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .tint(WCBColor.accent)
                }
                .padding(WCBSpacing.md)
            }
        }
    }
}

private struct DataPanel: View {
    var viewModel: WorldCupBarViewModel
    var updaterViewModel: UpdaterViewModel

    var body: some View {
        PanelScrollView(title: "Data", subtitle: "Refresh match data or check for app updates.") {
            SettingsCard {
                HStack(spacing: WCBSpacing.md) {
                    VStack(alignment: .leading, spacing: WCBSpacing.xs) {
                        Text("Match data")
                            .font(WCBFont.rowPrimary)
                        Text(viewModel.footerStatusText)
                            .font(WCBFont.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        Task { await viewModel.refresh() }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
                .padding(WCBSpacing.md)

                Divider().padding(.leading, WCBSpacing.md)

                HStack(spacing: WCBSpacing.md) {
                    VStack(alignment: .leading, spacing: WCBSpacing.xs) {
                        Text("App updates")
                            .font(WCBFont.rowPrimary)
                        Text("Check for a new version of World Cup Bar.")
                            .font(WCBFont.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Check for Updates") {
                        updaterViewModel.checkForUpdates()
                    }
                    .disabled(!updaterViewModel.canCheckForUpdates)
                }
                .padding(WCBSpacing.md)
            }
        }
    }
}

// MARK: - Shared layout components

// Scrolling container for a settings panel. The view's title and one-line
// description live at the top of the scroll content, so they scroll away with
// the rest of the panel instead of sitting in a fixed window chrome.
private struct PanelScrollView<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: WCBSpacing.lg) {
                VStack(alignment: .leading, spacing: WCBSpacing.xs) {
                    Text(title)
                        .font(WCBFont.viewTitle)
                        .foregroundStyle(WCBColor.label)
                    Text(subtitle)
                        .font(WCBFont.viewSubtitle)
                        .foregroundStyle(.secondary)
                }
                content
            }
            .padding(.horizontal, WCBSpacing.lg)
            .padding(.top, WCBSpacing.xl)
            .padding(.bottom, WCBSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// A rounded, hairline-bordered group container for control rows. The section
// heading now lives in PanelScrollView's title, so the card itself is chrome.
private struct SettingsCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: WCBRadius.md)
                .fill(WCBColor.cardFill)
                .overlay(
                    RoundedRectangle(cornerRadius: WCBRadius.md)
                        .strokeBorder(WCBColor.cardBorder, lineWidth: 0.5)
                )
        )
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
                    .font(WCBFont.rowPrimary)
                Text(country.code)
                    .font(WCBFont.codeMono)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 24)

            Toggle(country.name, isOn: $isFollowed)
                .labelsHidden()
                .toggleStyle(.switch)
                .tint(WCBColor.accent)
        }
        .padding(.horizontal, WCBSpacing.md)
        .frame(minHeight: 48)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
