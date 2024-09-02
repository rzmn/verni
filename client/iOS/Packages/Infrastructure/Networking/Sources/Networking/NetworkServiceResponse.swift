import Foundation

public struct NetworkServiceResponse: Sendable {
    public let code: HttpCode
    public let data: Data

    public init(code: HttpCode, data: Data) {
        self.code = code
        self.data = data
    }
}
