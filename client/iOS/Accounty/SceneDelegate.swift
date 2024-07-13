import UIKit
import App
import DefaultDependencies

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    private var model: AppModel?
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            let appRouter = AppRouter(window: window)
            self.window = window
            Task {
                model = await AppModel(di: DefaultDependenciesAssembly(), appRouter: appRouter)
                await model?.performFlow()
            }
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        print("open url \(URLContexts)")
        guard let context = URLContexts.first else {
            return
        }
        guard let model else {
            return
        }
        Task {
            await model.handle(url: context.url.absoluteString)
        }
    }
}

