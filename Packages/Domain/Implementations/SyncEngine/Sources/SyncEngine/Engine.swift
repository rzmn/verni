import Domain
import PersistentStorage
import AsyncExtensions
import Base
import Foundation
import Logging
import DataLayerDependencies
import Infrastructure
import Api
internal import ApiDomainConvenience

actor Engine {
    private let infrastructure: InfrastructureLayer
    private let data: AnonymousDataLayerSession

    init(infrastructure: InfrastructureLayer) {
        self.infrastructure = infrastructure
    }

    func start() {

    }

    func push(operation: Components.Schemas.Operation) async {
        await push(operations: [operation])
    }

    func push(operations: [Components.Schemas.Operation]) async {
        infrastructure.
    }
}

struct State {
    let profile: Profile
    
}
