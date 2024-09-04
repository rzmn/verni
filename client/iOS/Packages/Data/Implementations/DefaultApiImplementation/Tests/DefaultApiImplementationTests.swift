import Testing
import Foundation
@testable import DefaultApiImplementation

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
}
