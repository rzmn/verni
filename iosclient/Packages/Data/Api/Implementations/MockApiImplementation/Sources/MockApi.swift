import Api
import OpenAPIRuntime
import Foundation

public final class MockApi: @unchecked Sendable {
    public init() {}
    
    // Common configuration
    public var shouldFailRequest = false
    
    // Operation-specific configuration
    public var avatars: [String: Components.Schemas.Image] = [:]
    public var pushedOperations: [Components.Schemas.SomeOperation] = []
    public var confirmedOperationIds: [String] = []
    public var lastConfirmationCode: String?
    
    // Call counts
    public var getAvatarsCallCount = 0
    public var pushOperationsCallCount = 0
    public var confirmOperationsCallCount = 0
    public var sendCodeCallCount = 0
    public var confirmEmailCallCount = 0
    
    public var registerForPushNotificationsCallCount = 0
    public var lastPushToken: String?
}

extension MockApi: APIProtocol {
    public func getAvatars(_ input: Operations.GetAvatars.Input) async throws -> Operations.GetAvatars.Output {
        getAvatarsCallCount += 1
        if shouldFailRequest {
            return .internalServerError(.init(body: .json(.init(error: .init(reason: ._internal)))))
        }
        let requestedIds = input.query.ids
        let response = avatars.filter { requestedIds.contains($0.key) }
        return .ok(.init(body: .json(.init(response: .init(additionalProperties: response)))))
    }
    
    public func pushOperations(_ input: Operations.PushOperations.Input) async throws -> Operations.PushOperations.Output {
        pushOperationsCallCount += 1
        if shouldFailRequest {
            return .internalServerError(.init(body: .json(.init(error: .init(reason: ._internal)))))
        }
        switch input.body {
        case .json(let payload):
            pushedOperations = payload.operations
            return .ok(.init(body: .json(.init(response: payload.operations))))
        }
    }
    
    public func confirmOperations(_ input: Operations.ConfirmOperations.Input) async throws -> Operations.ConfirmOperations.Output {
        confirmOperationsCallCount += 1
        if shouldFailRequest {
            return .internalServerError(.init(body: .json(.init(error: .init(reason: ._internal)))))
        }
        confirmedOperationIds = input.query.ids
        return .ok(.init(body: .json(.init(response: .init()))))
    }
    
    public func sendEmailConfirmationCode(_ input: Operations.SendEmailConfirmationCode.Input) async throws -> Operations.SendEmailConfirmationCode.Output {
        sendCodeCallCount += 1
        if shouldFailRequest {
            return .internalServerError(.init(body: .json(.init(error: .init(reason: ._internal)))))
        }
        return .ok(.init(body: .json(.init(response: .init()))))
    }
    
    public func confirmEmail(_ input: Operations.ConfirmEmail.Input) async throws -> Operations.ConfirmEmail.Output {
        confirmEmailCallCount += 1
        switch input.body {
        case .json(let payload):
            lastConfirmationCode = payload.code
        }
        if shouldFailRequest {
            return .internalServerError(.init(body: .json(.init(error: .init(reason: ._internal)))))
        }
        return .ok(.init(body: .json(.init(response: .init()))))
    }
    
    public func registerForPushNotifications(_ input: Operations.RegisterForPushNotifications.Input) async throws -> Operations.RegisterForPushNotifications.Output {
        registerForPushNotificationsCallCount += 1
        if shouldFailRequest {
            return .internalServerError(.init(body: .json(.init(error: .init(reason: ._internal)))))
        }
        switch input.body {
        case .json(let payload):
            lastPushToken = payload.token
        }
        return .ok(.init(body: .json(.init(response: .init()))))
    }
    
    // Unimplemented methods
    public func signup(_ input: Operations.Signup.Input) async throws -> Operations.Signup.Output { fatalError("Not implemented") }
    public func login(_ input: Operations.Login.Input) async throws -> Operations.Login.Output { fatalError("Not implemented") }
    public func refreshSession(_ input: Operations.RefreshSession.Input) async throws -> Operations.RefreshSession.Output { fatalError("Not implemented") }
    public func updateEmail(_ input: Operations.UpdateEmail.Input) async throws -> Operations.UpdateEmail.Output { fatalError("Not implemented") }
    public func updatePassword(_ input: Operations.UpdatePassword.Input) async throws -> Operations.UpdatePassword.Output { fatalError("Not implemented") }
    public func searchUsers(_ input: Operations.SearchUsers.Input) async throws -> Operations.SearchUsers.Output { fatalError("Not implemented") }
    public func pullOperations(_ input: Operations.PullOperations.Input) async throws -> Operations.PullOperations.Output { fatalError("Not implemented") }
}
