import UIKit
import App

private extension UIApplicationDelegate {
    var _app: App? {
        (self as? AppDelegate)?.app
    }
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            self.window = window
            guard let app = UIApplication.shared.delegate?._app else {
                return
            }
            Task.detached {
                await app.start(on: window)
            }
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        print("open url \(URLContexts)")
        guard let context = URLContexts.first else {
            return
        }
        guard let app = UIApplication.shared.delegate?._app else {
            return
        }
        Task {
            await app.handle(url: context.url.absoluteString)
        }
    }
}

