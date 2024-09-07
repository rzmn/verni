import Testing
import Foundation
import Networking
@testable import DefaultNetworkingImplementation

struct FailableEncodable: Encodable {
    let data: String

    func encode(to encoder: any Encoder) throws {
        throw NSError(domain: "", code: -1)
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

        // then

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

        let serviceError: NetworkServiceError
        do {
            let _ = try encoder.encodeBody(from: request)!
            Issue.record()
            return
        } catch {
            serviceError = error
        }

        // then

        guard case .cannotBuildRequest = serviceError else {
            Issue.record()
            return
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
