import SwiftUI
import WorldCupBarCore

@main
struct WorldCupBarApp: App {
    @StateObject private var viewModel = WorldCupBarViewModel(provider: MockMatchDataProvider())

    var body: some Scene {
        MenuBarExtra {
            MenuBarDropdownView(viewModel: viewModel)
                .frame(width: 360)
                .task {
                    await viewModel.refresh()
                }
        } label: {
            Text(viewModel.menuBarTitle)
                .font(.system(size: 13, weight: .semibold, design: .default))
                .monospacedDigit()
        }
        .menuBarExtraStyle(.window)

        Window("World Cup Bar Settings", id: "settings") {
            SettingsView(viewModel: viewModel)
        }
        .defaultSize(width: 760, height: 680)
    }
}
