import Testing
import Foundation
import Networking
import TestInfrastructure
@testable import DefaultNetworkingImplementation

@Suite struct UrlRequestBuilderTests {
    let infrastructure = TestInfrastructureLayer()

    @Test func testUrlRequestBuilderWithBody() throws {

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
            logger: infrastructure.logger
        )

        // when

        let request = try builder.build()

        // then

        #expect(try JSONDecoder().decode(MockNetworkRequestBody.self, from: request.httpBody!) == body)
        #expect(request.httpMethod == httpMethod)
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        for (key, value) in headers {
            #expect(value == request.value(forHTTPHeaderField: key))
        }
    }
}
