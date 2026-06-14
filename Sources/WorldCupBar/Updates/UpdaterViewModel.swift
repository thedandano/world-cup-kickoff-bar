import Combine
import Sparkle
import SwiftUI

@MainActor
@Observable
final class UpdaterViewModel {
    private(set) var canCheckForUpdates = false

    private let updater: SPUUpdater
    private var cancellable: AnyCancellable?

    init(updater: SPUUpdater) {
        self.updater = updater
        canCheckForUpdates = updater.canCheckForUpdates
        cancellable = updater.publisher(for: \.canCheckForUpdates)
            .receive(on: RunLoop.main)
            .sink { [weak self] value in
                self?.canCheckForUpdates = value
            }
    }

    func checkForUpdates() {
        updater.checkForUpdates()
    }
}
