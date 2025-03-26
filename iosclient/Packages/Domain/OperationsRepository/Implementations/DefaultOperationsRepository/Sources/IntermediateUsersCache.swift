import Foundation
import Filesystem
import Entities
import Logging
internal import Convenience

actor IntermediateUsersCache {
    let logger: Logger
    private var ramCache = [User.Identifier: User]()
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    private let fileManager: Filesystem.FileManager
    private let cacheDirectory: URL
    
    init(
        fileManager: Filesystem.FileManager,
        logger: Logger
    ) throws {
        self.logger = logger
        self.fileManager = fileManager
        
        guard let defaultCacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            let message = "cannot find cache directory"
            logger.logE { message }
            throw InternalError.error(message)
        }
        self.cacheDirectory = defaultCacheDirectory.appending(component: "verni.users.intermediate")
        do {
            try fileManager.createDirectory(
                at: cacheDirectory
            )
        } catch {
            logger.logE { "failed to create cache directory for intermediate users cache" }
            throw error
        }
    }
    
    subscript(id: User.Identifier) -> User? {
        get {
            if let user = ramCache[id] {
                return user
            }
            let data: Data
            do {
                data = try fileManager.readFile(
                    at: cacheDirectory.appending(component: id)
                )
            } catch {
                guard case .noSuchFile = error else {
                    logE { "failed to read from cache file: \(error)" }
                    return nil
                }
                return nil
            }
            let user: UserData
            do {
                user = try decoder.decode(UserData.self, from: data)
            } catch {
                logE { "failed to decode cache value \(error)" }
                return nil
            }
            return User(
                id: user.id,
                payload: UserPayload(
                    displayName: user.name,
                    avatar: user.avatarId
                )
            )
        }
        set {
            do {
                if let newValue {
                    let data: Data
                    do {
                        data = try encoder.encode(
                            UserData(
                                id: newValue.id,
                                name: newValue.payload.displayName,
                                avatarId: newValue.payload.avatar
                            )
                        )
                        try fileManager.removeItem(
                            at: cacheDirectory.appending(component: id)
                        )
                    } catch {
                        return logE { "failed to encode user data \(error)" }
                    }
                    do {
                        try fileManager.createFile(
                            at: cacheDirectory.appending(component: id),
                            content: data
                        )
                    } catch {
                        return logE { "failed to write user data \(error)" }
                    }
                    ramCache[id] = newValue
                } else {
                    ramCache[id] = nil
                    do {
                        try fileManager.removeItem(
                            at: cacheDirectory.appending(component: id)
                        )
                    } catch {
                        logE { "failed to remove cache file \(error)" }
                    }
                }
            }
        }
    }
}

extension IntermediateUsersCache {
    private struct UserData: Codable {
        let id: User.Identifier
        let name: String
        let avatarId: Image.Identifier?
    }
}

extension IntermediateUsersCache: Loggable {}
