import SwiftUI
import WorldCupBarCore

struct SettingsView: View {
    @ObservedObject var viewModel: WorldCupBarViewModel
    @State private var countrySearch = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header
                displaySection
                followedCountriesSection
                analyticsSection
                notificationsSection
                dataSection
            }
            .padding(.horizontal, 34)
            .padding(.vertical, 30)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(minWidth: 720, minHeight: 620)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("World Cup Bar Settings")
                .font(.system(size: 22, weight: .semibold))

            Text("Set what appears in the menu bar.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
    }

    private var displaySection: some View {
        SettingsSection(
            title: "Display",
            subtitle: "Choose the compact match label."
        ) {
            HStack(alignment: .center, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Menu bar display")
                        .font(.system(size: 14, weight: .medium))
                    Text("Show team codes or flags.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Picker("Menu bar display", selection: $viewModel.displayMode) {
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

    private var followedCountriesSection: some View {
        SettingsSection(
            title: "Following",
            subtitle: "Teams you follow get priority in the menu bar."
        ) {
            VStack(spacing: 0) {
                if viewModel.availableCountries.isEmpty {
                    Text("Team list will appear after the first live refresh.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .padding(16)
                } else {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search countries", text: $countrySearch)
                            .textFieldStyle(.plain)
                        if !countrySearch.isEmpty {
                            Button {
                                countrySearch = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                    Divider()

                    let filtered = viewModel.availableCountries.filter { country in
                        countrySearch.isEmpty
                            || country.name.localizedCaseInsensitiveContains(countrySearch)
                            || country.code.localizedCaseInsensitiveContains(countrySearch)
                    }

                    if filtered.isEmpty {
                        Text("No countries match \"\(countrySearch)\".")
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
                                Divider()
                                    .padding(.leading, 46)
                            }
                        }
                    }
                }
            }

            Text("Live followed matches appear before upcoming matches.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
    }

    private var analyticsSection: some View {
        SettingsSection(
            title: "Analytics",
            subtitle: "Control product analytics."
        ) {
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

    private var notificationsSection: some View {
        SettingsSection(
            title: "Notifications",
            subtitle: "Get alerted before followed matches kick off."
        ) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Kickoff alert")
                        .font(.system(size: 14, weight: .medium))
                    Text("Notify before a followed match starts.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Picker("Kickoff alert", selection: $viewModel.notificationMinutesBefore) {
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

    private var dataSection: some View {
        SettingsSection(
            title: "Data",
            subtitle: "Refresh the current match list."
        ) {
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
                    Task {
                        await viewModel.refresh()
                    }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
            .padding(16)
        }
    }
}

private struct SettingsSection<Content: View>: View {
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
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(nsColor: .controlBackgroundColor))
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
