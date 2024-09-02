import Foundation

public struct AvatarDataDto: Codable, Sendable {
    public let id: UserDto.Avatar.ID
    public let base64Data: String?
}
