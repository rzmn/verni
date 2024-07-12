import UIKit
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

    func sceneDidDisconnect(_ scene: UIScene) {
        // empty
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // empty
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // empty
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // empty
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // empty
    }
}

