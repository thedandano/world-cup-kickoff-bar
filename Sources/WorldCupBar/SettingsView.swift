import SwiftUI
import WorldCupBarCore

struct SettingsView: View {
    @ObservedObject var viewModel: WorldCupBarViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header
                displaySection
                followedCountriesSection
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

            Text("Choose how the menu bar reads and which countries affect the live score priority.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
    }

    private var displaySection: some View {
        SettingsSection(
            title: "Display",
            subtitle: "Controls the compact menu bar label and match rows."
        ) {
            HStack(alignment: .center, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Menu bar display")
                        .font(.system(size: 14, weight: .medium))
                    Text("Use country codes for clarity or flags for a tighter glance.")
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
            title: "Followed Countries",
            subtitle: "Live matches for these countries appear first in the menu bar."
        ) {
            VStack(spacing: 0) {
                ForEach(viewModel.availableCountries) { country in
                    CountrySettingsRow(
                        country: country,
                        isFollowed: Binding(
                            get: { viewModel.followedCountryCodes.contains(country.code) },
                            set: { viewModel.setFollowed(country, isFollowed: $0) }
                        )
                    )

                    if country.id != viewModel.availableCountries.last?.id {
                        Divider()
                            .padding(.leading, 46)
                    }
                }
            }

            Text("The menu bar dropdown shows followed countries as read-only chips. Editing stays here.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
    }

    private var dataSection: some View {
        SettingsSection(
            title: "Data",
            subtitle: "This prototype uses mock match data while the provider boundary stays modular."
        ) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Mock data adapter")
                        .font(.system(size: 14, weight: .medium))
                    Text("No user API key is needed in this version.")
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
