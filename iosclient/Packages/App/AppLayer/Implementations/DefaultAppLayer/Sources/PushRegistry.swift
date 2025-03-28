import Foundation
import Entities
import DomainLayer
import PushRegistrationUseCase
internal import Logging

actor PushRegistry {
    let logger: Logger
    
    private var pushToken: Data?
    private var currentSession: HostedDomainLayer?
    private var isTokenRegisteredForUserId = [User.Identifier: Bool]()
    
    init(logger: Logger) {
        self.logger = logger
    }
    
    func registerPushToken(token: Data) {
        guard pushToken != token else {
            return
        }
        isTokenRegisteredForUserId.removeAll()
        pushToken = token
        registerTokenForCurrentSession()
    }
    
    func attachSession(session: HostedDomainLayer) {
        currentSession = session
        registerTokenForCurrentSession()
    }
    
    func detachSession() {
        guard let currentSession else {
            return
        }
        self.currentSession = nil
        Task {
            await currentSession
                .pushRegistrationUseCase()
                .unregister()
        }
    }
}

extension PushRegistry {
    private func registerTokenForCurrentSession() {
        guard let pushToken, let currentSession else {
            return
        }
        guard !isTokenRegisteredForUserId[currentSession.userId, default: false] else {
            return
        }
        isTokenRegisteredForUserId[currentSession.userId] = true
        logger.logI { "registering token for \(currentSession.userId)..." }
        Task {
            await currentSession
                .pushRegistrationUseCase()
                .registerForPush(token: pushToken)
        }
    }
}

extension PushRegistry: Loggable {}
