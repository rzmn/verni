import Foundation

public struct AvatarDataDto: Codable {
    public let id: UserDto.Avatar.ID
    public let base64Data: String?
}
