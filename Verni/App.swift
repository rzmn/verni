import SwiftUI
import DefaultDependencies
import AppBase
import App

@main
struct MainApp: SwiftUI.App {
    let provider = DefaultAppFactory(
        // swiftlint:disable:next force_try
        di: try! DefaultDependenciesAssembly()
    ).create()

    var body: some Scene {
        WindowGroup {
            provider.instantiate { /* empty */ }
        }
    }
}
