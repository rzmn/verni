import Foundation

public struct AvatarDataDto: Codable, Sendable {
    public let id: UserDto.Avatar.ID
    public let base64Data: String?

    public init(id: UserDto.Avatar.ID, base64Data: String?) {
        self.id = id
        self.base64Data = base64Data
    }
}
