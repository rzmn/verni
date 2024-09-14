import Testing
import Foundation
import Networking
@testable import DefaultNetworkingImplementation

@Suite struct UrlBuilderTests {
    @Test func testUrlBuilderNoParameters() throws {

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

        #expect(url.absoluteString == endpoint.path + requestPath)
    }

    @Test func testUrlBuilderWithParameters() throws {

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

        #expect(parametersFromComponents == parameters)
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

        #expect {
            try builder.build()
        } throws: { error in
            guard let error = error as? NetworkServiceError, case .cannotBuildRequest = error else {
                return false
            }
            return true
        }
    }
}
