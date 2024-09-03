import XCTest
import Networking
@testable import DefaultNetworkingImplementation

class UrlBuilderTests: XCTestCase {
    func testUrlBuilderNoParameters() throws {

        // given

        let requestPath = "/path"
        let endpoint = Endpoint(path: "https://url.com")
        let method = "method"
        let request = MockNetworkRequest(
            path: requestPath,
            headers: [:],
            parameters: [:],
            httpMethod: method
        )

        // when

        let url = try UrlBuilder(endpoint: endpoint, request: request, logger: .shared).build()

        // then

        XCTAssert(url.absoluteString == endpoint.path + requestPath)
    }

    func testUrlBuilderWithParameters() throws {

        // given

        let requestPath = "/path"
        let endpoint = Endpoint(path: "https://url.com")
        let method = "method"
        let parameters = [
            "a":"A",
            "b": "B"
        ]
        let request = MockNetworkRequest(
            path: requestPath,
            headers: [:],
            parameters: parameters,
            httpMethod: method
        )

        // when

        let url = try UrlBuilder(endpoint: endpoint, request: request, logger: .shared).build()


        // then

        let urlComponents = URLComponents(string: url.absoluteString)!
        let parametersFromComponents = urlComponents.queryItems!.reduce(into: [:]) { dict, item in
            dict[item.name] = item.value
        }

        XCTAssertEqual(parametersFromComponents, parameters)
    }

    func testUrlBuilderFailed() {

        // given

        let requestPath = "\\broken%path"
        let endpoint = Endpoint(path: "https://url.com")
        let method = "method"
        let request = MockNetworkRequest(
            path: requestPath,
            headers: [:],
            parameters: [:],
            httpMethod: method
        )

        // when

        let builder = UrlBuilder(endpoint: endpoint, request: request, logger: .shared)

        // then

        XCTAssertThrowsError(try builder.build())
    }
}
