import Testing
import Networking
@testable import DefaultNetworkingImplementation

@Suite struct EndpointTests {

    @Test func testEndpointPath() {

        // given

        let path = "https://url.com"

        // when

        let endpoint = Endpoint(path: path)

        // then

        #expect(endpoint.path == path)
    }

    @Test func testEndpointPathLeadingSlash() {

        // given

        let path = "https://url.com"

        // when

        let endpoint = Endpoint(path: path + "/")

        // then

        #expect(endpoint.path == path)
    }
}
