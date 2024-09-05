import Testing
import ApiService
import Foundation
import Logging
import Networking
@testable import DefaultApiServiceImplementation

struct MockNetworkRequest: NetworkRequest {
    let path: String
    let headers: [String: String]
    let parameters: [String: String]
    let httpMethod: String
}

actor MockRequestService: NetworkService {
    let result: Result<NetworkServiceResponse, NetworkServiceError>

    init(result: Result<NetworkServiceResponse, NetworkServiceError>) {
        self.result = result
    }

    func run<T>(_ request: T) async throws(NetworkServiceError) -> NetworkServiceResponse where T: NetworkRequest {
        try result.get()
    }
}

@Suite struct ApiServiceRequestRunnerTests {

    @Test func testSetAuthHeader() async throws {
        let request = MockRequest(label: "r", headers: [:])

        let token = "123"
        let runner = DefaultApiServiceRequestRunner(
            networkService: MockRequestService(
                result: .success(NetworkServiceResponse(code: .success(.ok), data: try JSONEncoder().encode(MockResponse())))
            ),
            accessToken: token
        )
        let _: MockResponse = try await runner.run(request: request)

        #expect(request.headers["Authorization"] == "Bearer \(token)")
    }

    @Test func testFailedOnDecode() async throws {
        let request = MockRequest(label: "r", headers: [:])

        let token = "123"
        let runner = DefaultApiServiceRequestRunner(
            networkService: MockRequestService(
                result: .success(NetworkServiceResponse(code: .success(.ok), data: Data()))
            ),
            accessToken: token
        )
        do {
            let _: MockResponse = try await runner.run(request: request)
            Issue.record()
        } catch {
            guard case .decodingFailed = error else {
                Issue.record()
                return
            }
        }
    }

    @Test func testFailedNoConnection() async throws {
        let request = MockRequest(label: "r", headers: [:])

        let token = "123"
        let runner = DefaultApiServiceRequestRunner(
            networkService: MockRequestService(
                result: .failure(.noConnection(NSError(domain: "", code: -1)))
            ),
            accessToken: token
        )
        do {
            let _: MockResponse = try await runner.run(request: request)
            Issue.record()
        } catch {
            guard case .noConnection = error else {
                Issue.record()
                return
            }
        }
    }

    @Test func testUnauthorized() async throws {
        let request = MockRequest(label: "r", headers: [:])

        let token = "123"
        let runner = DefaultApiServiceRequestRunner(
            networkService: MockRequestService(
                result: .success(NetworkServiceResponse(code: .clientError(.unauthorized), data: Data()))
            ),
            accessToken: token
        )
        do {
            let _: MockResponse = try await runner.run(request: request)
            Issue.record()
        } catch {
            guard case .unauthorized = error else {
                Issue.record()
                return
            }
        }
    }

    @Test func testFailedInternal() async throws {
        let request = MockRequest(label: "r", headers: [:])

        let token = "123"
        let runner = DefaultApiServiceRequestRunner(
            networkService: MockRequestService(
                result: .failure(.badResponse(NSError(domain: "", code: -1)))
            ),
            accessToken: token
        )
        do {
            let _: MockResponse = try await runner.run(request: request)
            Issue.record()
        } catch {
            guard case .internalError = error else {
                Issue.record()
                return
            }
        }
    }

    @Test func testUnknownError() async throws {
        let request = MockRequest(label: "r", headers: [:])

        let token = "123"
        let runner = DefaultApiServiceRequestRunner(
            networkService: MockRequestService(
                result: .success(NetworkServiceResponse(code: .clientError(.badRequest), data: Data()))
            ),
            accessToken: token
        )
        do {
            let _: MockResponse = try await runner.run(request: request)
            Issue.record()
        } catch {
            guard case .internalError = error else {
                Issue.record()
                return
            }
        }
    }
}
