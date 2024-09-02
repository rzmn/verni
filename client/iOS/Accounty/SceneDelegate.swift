import UIKit
import App

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    private func app() async -> App? {
        await (UIApplication.shared.delegate as? AppDelegate)?.app()
    }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            self.window = window
            Task.detached {
                await self.app()?.start(on: window)
            }
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        print("open url \(URLContexts)")
        guard let context = URLContexts.first else {
            return
        }
        Task {
            await self.app()?.handle(url: context.url.absoluteString)
        }
    }
}

