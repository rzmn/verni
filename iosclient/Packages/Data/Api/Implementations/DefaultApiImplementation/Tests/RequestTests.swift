import Testing
import Foundation
import Api
@testable import DefaultApiImplementation

@Suite struct RequestTests {
    @Test func testRequest() async throws {

        // given

        var request = AnyApiServiceRequest(path: "", parameters: [:], httpMethod: .get)
        let headers = [
            "h": "H",
            "V": "v"
        ]

        // when

        for (key, value) in headers {
            request.setHeader(key: key, value: value)
        }

        // then

        #expect(request.headers == headers)
    }

    @Test func testRequestWithParameters() async throws {

        // given

        struct Body: Encodable, Sendable, Equatable {
            let data: Int
        }
        let path = "path"
        let parameters = ["para": "meters"]
        let method = HttpMethod.post
        let headers = ["he": "aders"]
        let additionalHeaders = ["new": "value"]
        let request = AnyApiServiceRequest(
            path: path,
            headers: headers,
            parameters: parameters,
            httpMethod: method
        )
        let body = Body(data: 42)

        // when

        var requestWithBody = AnyApiServiceRequestWithBody(
            request: request,
            body: body
        )
        for (key, value) in additionalHeaders {
            requestWithBody.setHeader(key: key, value: value)
        }

        // then

        #expect(request.headers == headers)
        #expect(requestWithBody.path == request.path)
        #expect(requestWithBody.parameters == request.parameters)
        #expect(requestWithBody.httpMethod == request.httpMethod)
        #expect(requestWithBody.headers == additionalHeaders.reduce(into: headers, { dict, kv in
            dict[kv.key] = kv.value
        }))
    }
}
