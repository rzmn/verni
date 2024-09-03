import XCTest
import Networking
@testable import DefaultNetworkingImplementation

struct FailableEncodable: Encodable {
    let data: String

    func encode(to encoder: any Encoder) throws {
        throw NSError()
    }
}

class UrlRequestBuilderBodyEncoderTests: XCTestCase {
    func testEncodeBody() throws {

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

        XCTAssertEqual(try JSONDecoder().decode(MockNetworkRequestBody.self, from: encoded), body)
    }

    func testEncodeBodyFail() throws {

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
            XCTAssert(false)
        } catch {
            guard case .cannotBuildRequest = error else {
                return XCTAssert(false)
            }
        }
    }

    func testEncodeRequestWithoutBody() throws {

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

        XCTAssertNil(try encoder.encodeBody(from: request))
    }
}
