import Foundation

public struct AvatarDataDto: Codable, Sendable {
    public let id: UserDto.Avatar.Identifier
    public let base64Data: String?

    public init(id: UserDto.Avatar.Identifier, base64Data: String?) {
        self.id = id
        self.base64Data = base64Data
    }
}
