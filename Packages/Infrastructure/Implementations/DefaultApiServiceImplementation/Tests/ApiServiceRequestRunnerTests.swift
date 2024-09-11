import Testing
import ApiService
import Foundation
import Logging
import Networking
@testable import MockNetworkingImplementation
@testable import DefaultApiServiceImplementation

@Suite struct ApiServiceRequestRunnerTests {

    @Test func testSetAuthHeader() async throws {

        // given

        let request = MockRequest(label: "r", headers: [:])
        let token = "123"
        let runner = DefaultApiServiceRequestRunner(
            networkService: MockRequestService(
                result: .success(NetworkServiceResponse(code: .success(.ok), data: try JSONEncoder().encode(MockResponse())))
            ),
            accessToken: token
        )

        // when

        let _: MockResponse = try await runner.run(request: request)

        // then

        #expect(request.headers["Authorization"] == "Bearer \(token)")
    }

    @Test func testFailedOnDecode() async throws {

        // given

        let request = MockRequest(label: "r", headers: [:])
        let token = "123"
        let runner = DefaultApiServiceRequestRunner(
            networkService: MockRequestService(
                result: .success(NetworkServiceResponse(code: .success(.ok), data: Data()))
            ),
            accessToken: token
        )

        // when

        let serviceError: ApiServiceError
        do {
            let _: MockResponse = try await runner.run(request: request)
            Issue.record()
            return
        } catch {
            serviceError = error
        }

        // then

        guard case .decodingFailed = serviceError else {
            Issue.record()
            return
        }
    }

    @Test func testFailedNoConnection() async throws {

        // given

        let request = MockRequest(label: "r", headers: [:])
        let token = "123"
        let runner = DefaultApiServiceRequestRunner(
            networkService: MockRequestService(
                result: .failure(.noConnection(NSError(domain: "", code: -1)))
            ),
            accessToken: token
        )

        // when

        let serviceError: ApiServiceError
        do {
            let _: MockResponse = try await runner.run(request: request)
            Issue.record()
            return
        } catch {
            serviceError = error
        }

        // then

        guard case .noConnection = serviceError else {
            Issue.record()
            return
        }
    }

    @Test func testUnauthorized() async throws {

        // given

        let request = MockRequest(label: "r", headers: [:])
        let token = "123"
        let runner = DefaultApiServiceRequestRunner(
            networkService: MockRequestService(
                result: .success(NetworkServiceResponse(code: .clientError(.unauthorized), data: Data()))
            ),
            accessToken: token
        )

        // when

        let serviceError: ApiServiceError
        do {
            let _: MockResponse = try await runner.run(request: request)
            Issue.record()
            return
        } catch {
            serviceError = error
        }

        // then

        guard case .unauthorized = serviceError else {
            Issue.record()
            return
        }
    }

    @Test func testFailedInternal() async throws {

        // given

        let request = MockRequest(label: "r", headers: [:])
        let token = "123"
        let runner = DefaultApiServiceRequestRunner(
            networkService: MockRequestService(
                result: .failure(.badResponse(NSError(domain: "", code: -1)))
            ),
            accessToken: token
        )

        // when

        let serviceError: ApiServiceError
        do {
            let _: MockResponse = try await runner.run(request: request)
            Issue.record()
            return
        } catch {
            serviceError = error
        }

        // then

        guard case .internalError = serviceError else {
            Issue.record()
            return
        }
    }

    @Test func testUnknownError() async throws {

        // given

        let request = MockRequest(label: "r", headers: [:])
        let token = "123"
        let runner = DefaultApiServiceRequestRunner(
            networkService: MockRequestService(
                result: .success(NetworkServiceResponse(code: .clientError(.badRequest), data: Data()))
            ),
            accessToken: token
        )

        // when

        let serviceError: ApiServiceError
        do {
            let _: MockResponse = try await runner.run(request: request)
            Issue.record()
            return
        } catch {
            serviceError = error
        }

        // then

        guard case .internalError = serviceError else {
            Issue.record()
            return
        }
    }
}
