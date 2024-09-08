import Testing
import Foundation
@testable import DefaultApiImplementation

@Suite struct ResponseTests {

    @Test func testError() throws {

        // given

        struct Response: Codable {
            let status: String
            let response: [String: Int]
        }
        let data = try JSONEncoder().encode(
            Response(
                status: "failed",
                response: ["code": 2]
            )
        )

        // when

        let response  = try JSONDecoder().decode(VoidApiResponseDto.self, from: data)

        // then

        guard case .failure(let apiError) = response else {
            Issue.record()
            return
        }
        #expect(apiError.code.rawValue == 2)
        #expect(apiError.description == nil)
    }

    @Test func testEmpty() throws {

        // given

        struct Response: Codable {
            let status: String
        }
        let data = try JSONEncoder().encode(
            Response(
                status: "ok"
            )
        )

        // when

        let response  = try JSONDecoder().decode(VoidApiResponseDto.self, from: data)

        // then

        guard case .success = response else {
            Issue.record()
            return
        }
    }

    @Test func testSuccess() throws {

        // given

        struct Payload: Codable, Equatable {
            let data: String
        }
        struct Response: Codable {
            let status: String
            let response: Payload
        }
        let payload = Payload(
            data: "123"
        )
        let data = try JSONEncoder().encode(
            Response(
                status: "ok",
                response: payload
            )
        )

        // when

        let response  = try JSONDecoder().decode(ApiResponseDto<Payload>.self, from: data)

        // then

        guard case .success(let response) = response else {
            Issue.record()
            return
        }
        #expect(payload == response)
    }
}
