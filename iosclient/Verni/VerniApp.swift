import SwiftUI

@main
struct VerniApp: App {
    @UIApplicationDelegateAdaptor(VerniAppDelegate.self) private var appDelegate
    
    var body: some Scene {
        WindowGroup {
            appDelegate.assembly.appModel.view()
        }
    }
}
