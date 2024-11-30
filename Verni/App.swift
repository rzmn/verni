import SwiftUI
import DefaultDependencies
import AppBase
import DesignSystem
import App
import DI

@main
struct App: SwiftUI.App {
    private let di: AnonymousDomainLayerSession
    private let provider: any ScreenProvider<Void, AppView>
    
    init() {
        // swiftlint:disable:next force_try
        di = try! DefaultDependenciesAssembly()
        provider = DefaultAppFactory(
            di: di,
            haptic: DefaultHapticManager()
        ).create()
    }

    var body: some Scene {
        WindowGroup {
            provider.instantiate { /* empty */ }
                .environment(
                    AvatarView.Repository { id in
                        await self.di.appCommon.avatarsRepository.get(id: id)
                    }
                )
        }
    }
}

