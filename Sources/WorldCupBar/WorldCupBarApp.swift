import Sparkle
import SwiftUI
import WorldCupBarCore

@main
struct WorldCupBarApp: App {
    @State private var viewModel: WorldCupBarViewModel
    @State private var updaterViewModel: UpdaterViewModel
    private let updaterController: SPUStandardUpdaterController

    init() {
        let controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        updaterController = controller
        _updaterViewModel = State(wrappedValue: UpdaterViewModel(updater: controller.updater))
        let monitoring = WorldCupMonitoringService(configuration: .fromEnvironment())
        let repository = WorldCupRepository(
            client: WorldCup26APIClient(),
            mapper: WorldCup26Mapper(),
            store: WorldCupSnapshotStore(fileURL: Self.snapshotCacheURL),
            telemetry: monitoring
        )
        _viewModel = State(
            wrappedValue: WorldCupBarViewModel(
                repository: repository,
                analytics: monitoring
            )
        )
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarDropdownView(viewModel: viewModel)
                .frame(width: 360)
                .tint(WCBColor.accent)
                .task {
                    await NotificationScheduler.shared.requestPermission()
                    await viewModel.start()
                }
        } label: {
            Text(viewModel.menuBarTitle)
                .font(.system(size: 13, weight: .semibold, design: .default))
                .monospacedDigit()
        }
        .menuBarExtraStyle(.window)

        Window("World Cup Bar Settings", id: "settings") {
            SettingsView(viewModel: viewModel, updaterViewModel: updaterViewModel)
                .tint(WCBColor.accent)
        }
        .defaultSize(width: 760, height: 680)
    }

    private static var snapshotCacheURL: URL {
        let applicationSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(filePath: NSTemporaryDirectory())
        return applicationSupport
            .appending(path: "WorldCupBar")
            .appending(path: "snapshot-cache.json")
    }
}
