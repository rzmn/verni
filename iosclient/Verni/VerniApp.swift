import SwiftUI
import DefaultAppLayer
import DefaultDomainLayer
import DefaultDataLayer
import DefaultInfrastructureLayer
import DesignSystem

@main
struct VerniApp: App {
    let factory = DefaultAppFactory {
        let infrastructure = DefaultInfrastructureLayer()
        let data: DefaultDataLayer
        do {
            data = try DefaultDataLayer(
                infrastructure: infrastructure
            )
        } catch {
            fatalError("failed to initialize data layer error: \(error)")
        }
        return await DefaultSandboxDomainLayer(
            infrastructure: infrastructure,
            data: data
        )
    }
    
    var body: some Scene {
        WindowGroup {
            factory.view()
        }
        .environment(AvatarView.Repository.preview)
    }
}
