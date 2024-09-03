import Foundation
import Networking
internal import Base

struct UrlRequestBuilderBodyEncoder {
    let encoder: JSONEncoder

    init(encoder: JSONEncoder) {
        self.encoder = encoder
    }

    func encodeBody<T: NetworkRequest>(
        from request: T
    ) throws(NetworkServiceError) -> Data? {
        guard let request = request as? (any NetworkRequestWithBody) else {
            return nil
        }
        let data: Data
        do {
            data = try encoder.encode(request.body)
        } catch {
            throw .cannotBuildRequest(
                InternalError.error(
                    "bad request body: \(request.body)",
                    underlying: error
                )
            )
        }
        return data
    }
}
