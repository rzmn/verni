import Testing
import Foundation
import Networking
@testable import DefaultNetworkingImplementation

struct FailableEncodable: Encodable {
    let data: String

    func encode(to encoder: any Encoder) throws {
        throw NSError()
    }
}

@Suite struct UrlRequestBuilderBodyEncoderTests {
    @Test func testEncodeBody() throws {

        // given

        let body = MockNetworkRequestBody(data: "data")
        let httpMethod = "method"
        let request = MockNetworkRequestWithBody(
            request: MockNetworkRequest(
                path: "/path",
                headers: [:],
                parameters: [:],
                httpMethod: httpMethod
            ),
            body: body
        )
        let encoder = UrlRequestBuilderBodyEncoder(
            encoder: JSONEncoder()
        )

        // when

        let encoded = try encoder.encodeBody(from: request)!

        #expect(try JSONDecoder().decode(MockNetworkRequestBody.self, from: encoded) == body)
    }

    @Test func testEncodeBodyFail() throws {

        // given

        let body = FailableEncodable(data: "data")
        let httpMethod = "method"
        let request = MockNetworkRequestWithBody(
            request: MockNetworkRequest(
                path: "/path",
                headers: [:],
                parameters: [:],
                httpMethod: httpMethod
            ),
            body: body
        )
        let encoder = UrlRequestBuilderBodyEncoder(
            encoder: JSONEncoder()
        )

        // when

        do {
            let _ = try encoder.encodeBody(from: request)!
            Issue.record()
        } catch {
            guard case .cannotBuildRequest = error else {
                Issue.record()
                return
            }
        }
    }

    @Test func testEncodeRequestWithoutBody() throws {

        // given

        let httpMethod = "method"
        let request = MockNetworkRequest(
            path: "/path",
            headers: [:],
            parameters: [:],
            httpMethod: httpMethod
        )
        let encoder = UrlRequestBuilderBodyEncoder(
            encoder: JSONEncoder()
        )

        // when

        #expect(try encoder.encodeBody(from: request) == nil)
    }
}
