import UIKit
import App
import DefaultDependencies

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    private var _app: App?
    func app() async -> App {
        guard let _app else {
            let app = await App(di: await DefaultDependenciesAssembly())
            _app = app
            return app
        }
        return _app
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Task {
            await app().registerPushToken(
                token: deviceToken
            )
        }
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) async -> UIBackgroundFetchResult {
        .noData
    }
}

