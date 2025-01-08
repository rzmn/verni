import Domain
import PersistentStorage
import AsyncExtensions
import Base
import Foundation
import Logging
import DataLayerDependencies
import Api
internal import ApiDomainConvenience

actor Engine {
    private let data: AnonymousDataLayerSession

    init(
        data: AnonymousDataLayerSession
    ) {
        self.data = data
    }

    func start() {
        
    }

    func push(operation: Components.Schemas.Operation) async {
        await push(operations: [operation])
    }

    func push(operations: [Components.Schemas.Operation]) async {
    }
}

struct State {
    let profile: Profile
    
}
