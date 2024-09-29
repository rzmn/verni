import SwiftUI
import DefaultDependencies
import AppBase
import App

enum State {
    case launched(any ScreenProvider<Void, AppView>)
    case launching
}

@MainActor class Launch: ObservableObject {
    @Published var state: State

    init() {
        self.state = .launching
        Task { @MainActor in
            let screenProvider = await DefaultAppFactory(
                // swiftlint:disable:next force_try
                di: try! await DefaultDependenciesAssembly()
            ).create()
            state = .launched(screenProvider)
        }
    }
}

@main
struct MainApp: SwiftUI.App {
    @StateObject var launch = Launch()

    var body: some Scene {
        WindowGroup {
            switch launch.state {
            case .launched(let appScreenProvider):
                appScreenProvider.instantiate { /* empty */}
            case .launching:
                Text("launching...")
            }
        }
    }
}
