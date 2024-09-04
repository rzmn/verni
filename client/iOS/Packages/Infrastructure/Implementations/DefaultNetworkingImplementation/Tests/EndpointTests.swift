import Testing
import Networking
@testable import DefaultNetworkingImplementation

@Suite struct EndpointTests {

    @Test func testEndpointPath() {
        let path = "https://url.com"
        let endpoint = Endpoint(path: path)

        #expect(endpoint.path == path)
    }

    @Test func testEndpointPathLeadingSlash() {
        let path = "https://url.com"
        let endpoint = Endpoint(path: path + "/")

        #expect(endpoint.path == path)
    }
}
