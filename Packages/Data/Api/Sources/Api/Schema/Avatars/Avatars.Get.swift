import DataTransferObjects

extension Avatars {
    public struct Get: ApiMethod, AvatarsScope {
        public typealias Response = [ImageDto.Identifier: ImageDto]

        public struct Parameters: Encodable, Sendable {
            public let ids: [ImageDto.Identifier]
        }
        public let parameters: Parameters

        public var path: String {
            scope + "/get"
        }

        public var method: HttpMethod {
            .get
        }

        public init(ids: [ImageDto.Identifier]) {
            self.parameters = Parameters(ids: ids)
        }
    }
}
