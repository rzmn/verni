import SwiftUI
import DefaultDependencies
import App

enum State {
    case launched(AppFlow)
    case launching
}

@MainActor class Launch: ObservableObject {
    @Published var state: State

    init() {
        self.state = .launching
        Task { @MainActor in
            // swiftlint:disable:next force_try
            let appFlow = await AppFlow(di: try! await DefaultDependenciesAssembly())
            state = .launched(appFlow)
        }
    }
}

@main
struct MainApp: SwiftUI.App {
    @StateObject var launch = Launch()

    var body: some Scene {
        WindowGroup {
            switch launch.state {
            case .launched(let appFlow):
                appFlow.instantiate { /* empty */}
            case .launching:
                Text("launching...")
            }
        }
    }
}
