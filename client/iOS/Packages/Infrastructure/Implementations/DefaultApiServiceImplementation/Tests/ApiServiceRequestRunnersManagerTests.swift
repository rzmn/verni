import Testing
import ApiService
import Foundation
import Logging
@testable import DefaultApiServiceImplementation

actor TokenRefresherMock: TokenRefresher, Loggable {
    let logger: Logger = .shared
    private var accessTokenValue: String?
    let refreshTokensValue: Result<String, RefreshTokenFailureReason>
    let refreshTokensResponseTimeSec: UInt64

    init(accessTokenValue: String?, refreshTokensValue: Result<String, RefreshTokenFailureReason>, refreshTokensResponseTimeSec: UInt64) {
        self.accessTokenValue = accessTokenValue
        self.refreshTokensValue = refreshTokensValue
        self.refreshTokensResponseTimeSec = refreshTokensResponseTimeSec
    }

    func accessToken() async -> String? {
        accessTokenValue
    }
    
    func refreshTokens() async throws(RefreshTokenFailureReason) {
        logI { "run refreshTokens" }
        try! await Task.sleep(nanoseconds: refreshTokensResponseTimeSec * NSEC_PER_SEC)
        logI { "finished refreshTokens" }
        switch refreshTokensValue {
        case .success(let success):
            accessTokenValue = success
        case .failure(let error):
            throw error
        }
    }
}

struct MockResponse: Decodable {}

struct MockRequest: ApiServiceRequest, Loggable {
    static var accessTokenShouldFailLabel: String {
        "accessTokenShouldFailLabel"
    }

    let logger: Logger = .shared
    let label: String

    let path: String = ""
    let parameters: [String: String] = [:]
    let httpMethod: String = ""

    var headers: [String: String] = [:]
    mutating func setHeader(key: String, value: String) {
        logI { "req[\(label)] \(key)=\(value)" }
        headers[key] = value
    }
}

actor WasFailedBasedOnLabelHandler {
    var wasFailedBasedOnLabel = false
    func markFailed() {
        wasFailedBasedOnLabel = true
    }
}

struct MockRequestRunnerFactory: ApiServiceRequestRunnerFactory, Loggable, Sendable {
    let logger: Logger = .shared
    let runResult: Result<MockResponse, ApiServiceError>
    let runResponseTimeSec: UInt64
    let label: String
    let wasFailedBasedOnLabelHandler = WasFailedBasedOnLabelHandler()

    func create(accessToken: String?) -> ApiServiceRequestRunner {
        logI { "create request \(label)" }
        return RequestRunnerMock(
            runResult: runResult,
            runResponseTimeSec: runResponseTimeSec,
            label: label,
            handler: wasFailedBasedOnLabelHandler
        )
    }
}

struct RequestRunnerMock: ApiServiceRequestRunner, Loggable {
    
    let logger: Logger = .shared
    let runResult: Result<MockResponse, ApiServiceError>
    let runResponseTimeSec: UInt64
    let label: String
    let handler: WasFailedBasedOnLabelHandler

    func run<Request, Response>(
        request: Request
    ) async throws(ApiServiceError) -> Response where Request: ApiServiceRequest, Response : Decodable & Sendable {
        logI { "\(label) run req[\((request as! MockRequest).label)]" }
        try! await Task.sleep(nanoseconds: runResponseTimeSec * NSEC_PER_SEC)
        logI { "\(label) finished req[\((request as! MockRequest).label)]" }
        let wasFailedBasedOnLabel = await handler.wasFailedBasedOnLabel
        if (request as! MockRequest).label == MockRequest.accessTokenShouldFailLabel && !wasFailedBasedOnLabel {
            await handler.markFailed()
            throw .unauthorized
        } else {
            switch runResult {
            case .success(let response):
                return response as! Response
            case .failure(let error):
                throw error
            }
        }
    }
}

@Suite struct ApiServiceRequestRunnersManagerTests {
    @Test func testRequestsLimitNoRefresh() async throws {
        let runner = MaxSimultaneousRequestsRestrictor(
            limit: 5,
            manager: ApiServiceRequestRunnersManager(
                runnerFactory: MockRequestRunnerFactory(
                    runResult: .success(MockResponse()),
                    runResponseTimeSec: 1,
                    label: "runner"
                ),
                tokenRefresher: TokenRefresherMock(
                    accessTokenValue: nil,
                    refreshTokensValue: .success("123"),
                    refreshTokensResponseTimeSec: 2
                )
            )
        )
        async let a: MockResponse = try runner.run(request: MockRequest(label: "1"))
        async let b: MockResponse = try runner.run(request: MockRequest(label: "2"))
        async let c: MockResponse = try runner.run(request: MockRequest(label: MockRequest.accessTokenShouldFailLabel))
        async let d: MockResponse = try runner.run(request: MockRequest(label: "4"))
        async let e: MockResponse = try runner.run(request: MockRequest(label: "5"))
        async let f: MockResponse = try runner.run(request: MockRequest(label: "6"))

        let _: [MockResponse] = try await [
            a, b, c, d, e, f
        ]

    }
}
