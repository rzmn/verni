import DataTransferObjects

extension Avatars {
    public struct Get: ApiMethod, AvatarsScope {
        public typealias Response = [UserDto.Avatar.Identifier: AvatarDataDto]

        public struct Parameters: Encodable, Sendable {
            public let ids: [UserDto.Avatar.Identifier]
        }
        public let parameters: Parameters

        public var path: String {
            scope + "/get"
        }

        public var method: HttpMethod {
            .get
        }

        public init(ids: [UserDto.Avatar.Identifier]) {
            self.parameters = Parameters(ids: ids)
        }
    }
}
