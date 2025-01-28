import AsyncExtensions
import Entities

public enum EmailUpdateError: Error, Sendable {
    case alreadyTaken
    case wrongFormat
    case other(GeneralError)
}

public enum PasswordUpdateError: Error, Sendable {
    case wrongFormat
    case incorrectOldPassword
    case other(GeneralError)
}

public protocol ProfileRepository: Sendable {
    var updates: any AsyncBroadcast<Profile> { get }
    
    var profile: Profile { get async }
    
    func updateEmail(_ email: String) async throws(EmailUpdateError)
    func updatePassword(old: String, new: String) async throws(PasswordUpdateError)
}
