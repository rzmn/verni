import Testing
import Foundation
import ApiService
@testable import Api
@testable import DefaultApiImplementation

struct MockMethodWithParametersAndResponse: ApiMethod {
    typealias Response = MockResponse
    typealias Parameters = MockParameters
    var path: String { "" }
    let method: HttpMethod
    let parameters: MockParameters
}

struct MockMethodWithNoParametersAndResponse: ApiMethod {
    typealias Response = MockResponse
    typealias Parameters = NoParameters
    var path: String { "" }
    let method: HttpMethod
    let parameters: NoParameters
}

struct MockMethodWithParametersAndNoResponse: ApiMethod {
    typealias Response = NoResponse
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
    ) async throws(ApiServiceError) -> Response where Request: ApiServiceRequest, Response: Decodable, Response: Sendable {
        try result.map {
            print("[debug] \(type(of: $0)) \(Response.self)")
            if Response.self == VoidApiResponseDto.self {
                return VoidApiResponseDto.success as! Response
            } else {
                return $0 as! Response
            }
        }.get()
    }
}

@Suite struct ResponseTests {

    @Test func testError() {
        struct S: Codable {
            let status: String
            let response: [String: Int]
        }
        let data = try! JSONEncoder().encode(S(status: "failed", response: ["code": 2]))
        let response  = try! JSONDecoder().decode(VoidApiResponseDto.self, from: data)
        guard case .failure(let apiError) = response else {
            Issue.record()
            return
        }
        #expect(apiError.code.rawValue == 2)
        #expect(apiError.description == nil)
    }

    @Test func testEmpty() {
        struct S: Codable {
            let status: String
        }
        let data = try! JSONEncoder().encode(S(status: "ok"))
        let response  = try! JSONDecoder().decode(VoidApiResponseDto.self, from: data)
        guard case .success = response else {
            Issue.record()
            return
        }
    }

    @Test func testSuccess() {
        struct Payload: Codable, Equatable {
            let data: String
        }
        struct S: Codable {
            let status: String
            let response: Payload
        }
        let payload = Payload(data: "123")
        let data = try! JSONEncoder().encode(S(status: "ok", response: payload))
        let response  = try! JSONDecoder().decode(ApiResponseDto<Payload>.self, from: data)
        guard case .success(let response) = response else {
            Issue.record()
            return
        }
        #expect(payload == response)
    }

    @Test func testGetRequestWithResponseAndParameters() async throws {
        let api = DefaultApi(service: MockApiService(result: .success(.success(MockResponse()))))
        let result = try await api.run(method: MockMethodWithParametersAndResponse(method: .get, parameters: MockParameters()))

        #expect(type(of: result) == MockResponse.self)
    }

    @Test func testPostRequestWithResponseAndParameters() async throws {
        let api = DefaultApi(service: MockApiService(result: .success(.success(MockResponse()))))
        let result = try await api.run(method: MockMethodWithParametersAndResponse(method: .post, parameters: MockParameters()))

        #expect(type(of: result) == MockResponse.self)
    }

    @Test func testRequestWithResponseAndNoParameters() async throws {
        let api = DefaultApi(service: MockApiService(result: .success(.success(MockResponse()))))
        let result = try await api.run(method: MockMethodWithNoParametersAndResponse(method: .get, parameters: NoParameters()))

        #expect(type(of: result) == MockResponse.self)
    }

    @Test func testRequestWithNoResponseAndParameters() async throws {
        let api = DefaultApi(service: MockApiService(result: .success(.success(MockResponse()))))
        let result: Void = try await api.run(method: MockMethodWithParametersAndNoResponse(method: .get, parameters: MockParameters()))

        #expect(type(of: result) == Void.self)
    }
}
