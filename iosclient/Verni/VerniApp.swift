import SwiftUI
import Assembly

@main
struct VerniApp: App {
    let appFactory = {
        let bundleId = Bundle.main.bundleIdentifier.unsafelyUnwrapped
        let appGroupId = "group.\(bundleId)"
        do {
            return try Assembly(
                bundleId: bundleId,
                appGroupId: appGroupId
            ).appFactory
        } catch {
            fatalError("failed to initialize dependencies assembly")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            appFactory.view()
        }
    }
}
