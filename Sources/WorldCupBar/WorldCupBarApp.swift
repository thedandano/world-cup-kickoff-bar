import AppKit
import Sparkle
import SwiftUI
import WorldCupBarCore

@main
struct WorldCupBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var viewModel: WorldCupBarViewModel
    @State private var updaterViewModel: UpdaterViewModel
    private let updaterController: SPUStandardUpdaterController
    // Retained for the app's lifetime: Sparkle holds the user-driver delegate
    // weakly. It brings this menu-bar (accessory) app to the front before
    // Sparkle shows a modal alert — otherwise the alert opens behind the active
    // app and its nested modal run loop freezes us in a buried, unclickable state.
    private let sparkleActivator = SparkleModalActivator()

    init() {
        let controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: sparkleActivator
        )
        updaterController = controller
        _updaterViewModel = State(wrappedValue: UpdaterViewModel(updater: controller.updater))
        let monitoring = WorldCupMonitoringService(configuration: .fromEnvironment())
        let repository = WorldCupRepository(
            dataSource: WorldCup26DataSource(),
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
                .frame(width: 400)
                .tint(WCBColor.accent)
                .task {
                    await NotificationScheduler.shared.requestPermission()
                }
        } label: {
            Text(viewModel.menuBarTitle)
                .font(.system(size: 13, weight: .semibold, design: .default))
                .monospacedDigit()
                .background(OpenWindowListener())
                .task {
                    await viewModel.start()
                }
        }
        .menuBarExtraStyle(.window)

        Window("World Cup Bar Settings", id: "settings") {
            SettingsView(viewModel: viewModel, updaterViewModel: updaterViewModel)
                .tint(WCBColor.accent)
        }
        .defaultSize(width: 760, height: 680)
        .windowStyle(.hiddenTitleBar)
    }

    private static var snapshotCacheURL: URL {
        let applicationSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(filePath: NSTemporaryDirectory())
        return applicationSupport
            .appending(path: "WorldCupBar")
            .appending(path: "snapshot-cache.json")
    }
}

// Listens for open-settings notifications posted by AppDelegate's right-click
// menu. Embedded in the always-rendered label view so openWindow is available.
private struct OpenWindowListener: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Color.clear.frame(width: 0, height: 0)
            .onReceive(NotificationCenter.default.publisher(for: .wcbOpenSettings)) { _ in
                // Pull the accessory app to the front first, then open Settings,
                // so the window lands in front instead of behind the active app.
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "settings")
            }
    }
}

/// Brings the app to the foreground right before Sparkle shows a modal alert.
///
/// World Cup Bar runs as a menu-bar (accessory) app, so AppKit does not
/// auto-activate it when Sparkle puts up an `NSAlert` via `-runModal`. Without
/// this, the alert is created behind the frontmost app and its nested modal run
/// loop freezes the app until a click the user can't reach. Sparkle invokes
/// `standardUserDriverWillShowModalAlert` precisely so background apps can pull
/// themselves forward first.
@MainActor
final class SparkleModalActivator: NSObject, @preconcurrency SPUStandardUserDriverDelegate {
    func standardUserDriverWillShowModalAlert() {
        NSApp.activate(ignoringOtherApps: true)
    }
}
