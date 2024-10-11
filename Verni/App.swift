import SwiftUI
import DefaultDependencies
import AppBase
import App

@main
struct App: SwiftUI.App {
    private let provider = DefaultAppFactory(
        // swiftlint:disable:next force_try
        di: try! DefaultDependenciesAssembly(),
        haptic: DefaultHapticManager()
    ).create()

    var body: some Scene {
        WindowGroup {
            provider.instantiate { /* empty */ }
        }
    }
}
