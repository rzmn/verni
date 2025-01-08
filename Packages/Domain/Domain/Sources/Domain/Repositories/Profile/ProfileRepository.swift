public protocol ProfileRepository: Sendable {
    var profile: Profile? { get async }
}
