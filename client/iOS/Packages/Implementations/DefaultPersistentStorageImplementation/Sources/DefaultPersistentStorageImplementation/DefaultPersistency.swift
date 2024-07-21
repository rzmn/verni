import DataTransferObjects
import SwiftData
import Logging
import PersistentStorage
internal import SwiftUI

@StorageActor class DefaultPersistency: Persistency {
    let logger: Logger

    private let modelContext: ModelContext
    private let hostId: UserDto.ID
    private let queue = DispatchQueue(label: "\(DefaultPersistency.self)")
    private var refreshToken: String

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

    func getRefreshToken() async -> String {
        refreshToken
    }

    func update(refreshToken: String) async {
        self.refreshToken = refreshToken
        do {
            try modelContext.delete(model: PersistentRefreshToken.self)
            modelContext.insert(PersistentRefreshToken(payload: refreshToken))
            try modelContext.save()
        } catch {
            self.logE { "failed to update token error: \(error)" }
        }
    }

    public func getHostInfo() async -> UserDto? {
        await user(id: hostId)
    }

    public func user(id: UserDto.ID) async -> UserDto? {
        let descriptor = {
            var d = FetchDescriptor<PersistentUser>(predicate: #Predicate { user in
                user.payload.login == id
            })
            d.fetchLimit = 1
            return d
        }()
        do {
            return try modelContext.fetch(descriptor).map(\.payload).first
        } catch {
            self.logE { "fetch user failed error: \(error)" }
            return nil
        }
    }

    public func update(users: [UserDto]) async {
        users.map(PersistentUser.init).forEach(modelContext.insert)
        do {
            try self.modelContext.save()
        } catch {
            self.logE { "failed to update users error: \(error)" }
        }
    }

    func invalidate() async {
        modelContext.container.deleteAllData()
    }
}

extension DefaultPersistency: Loggable {}
