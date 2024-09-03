import XCTest
import Networking
@testable import DefaultNetworkingImplementation

class UrlRequestBuilderTests: XCTestCase {

    func testUrlRequestBuilderWithBody() throws {

        // given

        let url = URL(string: "url.com")!
        let body = MockNetworkRequestBody(data: "data")
        let httpMethod = "method"
        let headers = [
            "h": "H"
        ]
        let builder = UrlRequestBuilder(
            url: url,
            request: MockNetworkRequestWithBody(
                request: MockNetworkRequest(
                    path: "/path",
                    headers: headers,
                    parameters: [:],
                    httpMethod: httpMethod
                ),
                body: body
            ),
            encoder: UrlRequestBuilderBodyEncoder(
                encoder: JSONEncoder()
            ),
            logger: .shared
        )

        // when

        let request = try builder.build()

        // then

        XCTAssertEqual(
            try JSONDecoder().decode(MockNetworkRequestBody.self, from: request.httpBody!),
            body
        )
        XCTAssertEqual(request.httpMethod, httpMethod)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
        for (key, value) in headers {
            XCTAssertEqual(value, request.value(forHTTPHeaderField: key))
        }
    }
}
