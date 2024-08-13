import Domain
import Foundation
import Security

public class DefaultSaveCredendialsUseCase {
    private let website: String

    public init(website: String) {
        self.website = website
    }
}

extension DefaultSaveCredendialsUseCase: SaveCredendialsUseCase {
    public func save(email: String, password: String) async {
        SecAddSharedWebCredential(
            website as CFString,
            email as CFString,
            password as CFString, { error in
                print("\(error.debugDescription)")
            }
        )
    }
}
