import AsyncExtensions

public protocol ProfileRepository: Sendable {
    var updates: any AsyncBroadcast<Profile> { get }
    
    var profile: Profile { get async }
}
