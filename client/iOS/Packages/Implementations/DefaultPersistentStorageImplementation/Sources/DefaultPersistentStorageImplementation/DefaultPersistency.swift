import DataTransferObjects
import SwiftData
import Logging
import PersistentStorage
internal import SwiftUI

class DefaultPersistency: Persistency {
    let logger: Logger

    private let modelContext: ModelContext
    private let hostId: UserDto.ID
    private let queue = DispatchQueue(label: "\(DefaultPersistency.self)")

    init(
        modelContext: ModelContext,
        hostId: UserDto.ID,
        refreshToken: PersistentRefreshToken,
        logger: Logger
    ) {
        self.modelContext = modelContext
        self.hostId = hostId
        self.refreshToken = refreshToken.payload
        self.logger = logger
    }

    public var refreshToken: String {
        didSet {
            let newValue = refreshToken
            queue.async {
                self.modelContext.insert(PersistentRefreshToken(payload: newValue))
                do {
                    try self.modelContext.save()
                } catch {
                    self.logE { "failed to update token error: \(error)" }
                }
            }
        }
    }

    public func getHostInfo() async -> UserDto? {
        await user(id: hostId)
    }

    public func user(id: UserDto.ID) async -> UserDto? {
        await withCheckedContinuation { continuation in
            queue.async {
                let descriptor = {
                    var d = FetchDescriptor<PersistentUser>(predicate: #Predicate { user in
                        user.payload.login == id
                    })
                    d.fetchLimit = 1
                    return d
                }()
                do {
                    continuation.resume(returning: try self.modelContext.fetch(descriptor).map(\.payload).first)
                } catch {
                    self.logE { "fetch user failed error: \(error)" }
                    continuation.resume(returning: nil)
                    return
                }
            }
        }
    }

    public func update(users: [UserDto]) {
        queue.async {
            users.map(PersistentUser.init).forEach(self.modelContext.insert)
            do {
                try self.modelContext.save()
            } catch {
                self.logE { "failed to update users error: \(error)" }
            }
        }
    }

    func invalidate() {
        // TODO:
    }
}

extension DefaultPersistency: Loggable {}
