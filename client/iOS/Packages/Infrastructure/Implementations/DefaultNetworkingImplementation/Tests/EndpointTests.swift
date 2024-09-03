import XCTest
import Networking
@testable import DefaultNetworkingImplementation

class EndpointTests: XCTestCase {

    func testEndpointPath() {
        let path = "https://url.com"
        let endpoint = Endpoint(path: path)

        XCTAssertEqual(endpoint.path, path)
    }

    func testEndpointPathLeadingSlash() {
        let path = "https://url.com"
        let endpoint = Endpoint(path: path + "/")

        XCTAssertEqual(endpoint.path, path)
    }
}
