import OpenAPIRuntime
import Foundation

extension UndocumentedPayload {
    public var logDescription: String? {
        get async throws {
            if let jsonString = try await body?.jsonString {
                return jsonString
            } else {
                return "\(self)"
            }
        }
    }
}

extension OpenAPIRuntime.HTTPBody {
    public var jsonString: String? {
        get async throws {
            String(
                data: Data(
                    try await ArraySlice(collecting: self, upTo: 2 * 1024 * 1024)
                ),
                encoding: .utf8
            )
        }
    }
}
