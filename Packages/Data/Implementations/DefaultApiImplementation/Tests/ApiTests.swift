import Testing
import Foundation
import ApiService
import Base
@testable import Api
@testable import DefaultApiImplementation

struct MockMethodWithParametersAndResponse: ApiMethod {
    typealias Response = MockResponse
    typealias Parameters = MockParameters
    var path: String { "" }
    let method: HttpMethod
    let parameters: MockParameters
}

struct MockResponse: Decodable, Sendable {

}

struct MockParameters: Encodable, Sendable {

}

struct MockApiService: ApiService {
    let result: Result<ApiResponseDto<MockResponse>, ApiServiceError>

    func run<Request, Response>(
        request: Request
    ) async throws(ApiServiceError) -> Response
    where Request: ApiServiceRequest, Response: Decodable, Response: Sendable {
        try result.map {
            if Response.self == VoidApiResponseDto.self {
                return VoidApiResponseDto.success as! Response
            } else {
                return $0 as! Response
            }
        }.get()
    }
}

@Suite struct ApiTests {

    @Test func testGetRequestWithResponseAndParameters() async throws {

        // given

        let api = DefaultApi(service: MockApiService(result: .success(.success(MockResponse()))))

        // when

        let result = try await api.run(
            method: MockMethodWithParametersAndResponse(
                method: .get,
                parameters: MockParameters()
            )
        )

        // then

        #expect(type(of: result) == MockResponse.self)
    }

    @Test func testPostRequestWithResponseAndParameters() async throws {

        // given

        let api = DefaultApi(service: MockApiService(result: .success(.success(MockResponse()))))

        // when

        let result = try await api.run(
            method: MockMethodWithParametersAndResponse(
                method: .post,
                parameters: MockParameters()
            )
        )

        // then

        #expect(type(of: result) == MockResponse.self)
    }

    @Test func testRequestWithResponseAndNoParameters() async throws {

        // given

        struct MockMethodWithNoParametersAndResponse: ApiMethod {
            typealias Response = MockResponse
            typealias Parameters = NoParameters
            var path: String { "" }
            let method: HttpMethod
            let parameters: NoParameters
        }
        let api = DefaultApi(service: MockApiService(result: .success(.success(MockResponse()))))

        // when

        let result = try await api.run(
            method: MockMethodWithNoParametersAndResponse(
                method: .put,
                parameters: NoParameters()
            )
        )

        // then

        #expect(type(of: result) == MockResponse.self)
    }

    @Test func testRequestWithNoResponseAndParameters() async throws {

        // given

        struct MockMethodWithParametersAndNoResponse: ApiMethod {
            typealias Response = NoResponse
            typealias Parameters = MockParameters
            var path: String { "" }
            let method: HttpMethod
            let parameters: MockParameters
        }
        let api = DefaultApi(service: MockApiService(result: .success(.success(MockResponse()))))

        // when

        let result: Void = try await api.run(
            method: MockMethodWithParametersAndNoResponse(
                method: .delete,
                parameters: MockParameters()
            )
        )

        // then

        #expect(type(of: result) == Void.self)
    }

    @Test func testRequestWithNoResponseAndParametersButEncodingFailed() async throws {

        // given

        struct FailableEncodable: Encodable, Sendable {
            enum CodingKeys: CodingKey {
                case key
            }

            func encode(to encoder: any Encoder) throws {
                throw InternalError.error("", underlying: nil)
            }
        }
        struct MockMethodWithParametersAndNoResponse: ApiMethod {
            typealias Response = NoResponse
            typealias Parameters = FailableEncodable
            var path: String { "" }
            let method: HttpMethod
            let parameters: FailableEncodable
        }
        let api = DefaultApi(service: MockApiService(result: .success(.success(MockResponse()))))

        // when

        let apiError: ApiError
        do {
            try await api.run(
                method: MockMethodWithParametersAndNoResponse(
                    method: .get,
                    parameters: FailableEncodable()
                )
            )
            Issue.record()
            return
        } catch {
            apiError = error
        }

        // then

        guard case .internalError = apiError else {
            Issue.record()
            return
        }
    }

    @Test func testRequestErrorNoConnection() async throws {

        // given

        let api = DefaultApi(service: MockApiService(result: .failure(.noConnection(InternalError.error("", underlying: nil)))))

        // when

        let apiError: ApiError
        do {
            _ = try await api.run(
                method: MockMethodWithParametersAndResponse(
                    method: .get,
                    parameters: MockParameters()
                )
            )
            Issue.record()
            return
        } catch {
            apiError = error
        }

        // then

        guard case .noConnection = apiError else {
            Issue.record()
            return
        }
    }

    @Test func testRequestErrorUnauthorized() async throws {

        // given

        let api = DefaultApi(service: MockApiService(result: .failure(.unauthorized)))

        // when

        let apiError: ApiError
        do {
            _ = try await api.run(
                method: MockMethodWithParametersAndResponse(
                    method: .get,
                    parameters: MockParameters()
                )
            )
            Issue.record()
            return
        } catch {
            apiError = error
        }

        // then

        guard case .api(let code, _) = apiError, case .tokenExpired = code else {
            Issue.record()
            return
        }
    }

    @Test func testRequestInternalError() async throws {

        // given

        let api = DefaultApi(service: MockApiService(result: .failure(.decodingFailed(InternalError.error("", underlying: nil)))))

        // when

        let apiError: ApiError
        do {
            _ = try await api.run(
                method: MockMethodWithParametersAndResponse(
                    method: .get,
                    parameters: MockParameters()
                )
            )
            Issue.record()
            return
        } catch {
            apiError = error
        }

        // then

        guard case .internalError = apiError else {
            Issue.record()
            return
        }
    }
}
