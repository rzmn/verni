import DataTransferObjects

extension Avatars {
    public struct Get: ApiMethod, AvatarsScope {
        public typealias Response = [UserDto.Avatar.ID: AvatarDataDto]

        public struct Parameters: Encodable {
            let ids: [UserDto.Avatar.ID]
        }
        public let parameters: Parameters

        public var path: String {
            scope + "/get"
        }

        public var method: HttpMethod {
            .get
        }

        public init(ids: [UserDto.Avatar.ID]) {
            self.parameters = Parameters(ids: ids)
        }
    }
}
