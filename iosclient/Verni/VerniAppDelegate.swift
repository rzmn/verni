import UIKit
import Assembly

class VerniAppDelegate: NSObject, UIApplicationDelegate {
    let assembly = {
        do {
            return try Assembly()
        } catch {
            fatalError("failed to initialize dependencies assembly error: \(error)")
        }
    }()
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        return true
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task {
            await assembly.appModel.registerPushToken(token: deviceToken)
        }
    }
}
