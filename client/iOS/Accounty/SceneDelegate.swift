import UIKit
import DesignSystem
import DefaultDependencies

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    private var model: AppModel?
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        SetupAppearance()
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            let appRouter = AppRouter(window: window)
            self.window = window
            Task {
                model = await AppModel(di: DefaultDependenciesAssembly(), appRouter: appRouter)
            }
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        print("open url \(URLContexts)")
        guard let context = URLContexts.first else {
            return
        }
        Task {
            await model?.resolve(url: context.url.absoluteString)
        }
    }
}

