import SaveCredendialsUseCase
import Foundation
import Security
import Logging

public struct EmptySaveCredendialsUseCase: SaveCredendialsUseCase {
    public init() {}
    
    public func save(email: String, password: String) async {
        // empty
    }
}

public struct DefaultSaveCredendialsUseCase {
    public let logger: Logger
    private let website: String

    public init(website: String, logger: Logger) {
        self.website = website
        self.logger = logger
    }
}

extension DefaultSaveCredendialsUseCase: SaveCredendialsUseCase {
    public func save(email: String, password: String) async {
        SecAddSharedWebCredential(
            website as CFString,
            email as CFString,
            password as CFString, { error in
                logger.logE { "save credentials failed error: \(error.debugDescription)" }
            }
        )
    }
}

extension DefaultSaveCredendialsUseCase: Loggable {}
