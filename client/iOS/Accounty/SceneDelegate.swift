import UIKit
import App
import DefaultDependencies

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    private var app: App?
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            self.window = window
            Task.detached { @MainActor [unowned self] in
                app = await App(di: DefaultDependenciesAssembly(), on: window)
                await app?.start()
            }
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        print("open url \(URLContexts)")
        guard let context = URLContexts.first else {
            return
        }
        guard let app else {
            return
        }
        Task {
            await app.handle(url: context.url.absoluteString)
        }
    }
}

