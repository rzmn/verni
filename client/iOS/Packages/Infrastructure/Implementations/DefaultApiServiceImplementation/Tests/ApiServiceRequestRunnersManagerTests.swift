import Testing
import ApiService
import Foundation
import Logging
@testable import DefaultApiServiceImplementation

actor TokenRefresherMock: TokenRefresher, Loggable {
    let logger: Logger = .shared
    private var accessTokenValue: String?
    let refreshTokensValue: Result<String?, RefreshTokenFailureReason>
    let refreshTokensResponseTimeSec: UInt64

    init(accessTokenValue: String?, refreshTokensValue: Result<String?, RefreshTokenFailureReason>, refreshTokensResponseTimeSec: UInt64) {
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
                    accessTokenValue: "123",
                    refreshTokensValue: .success("123"),
                    refreshTokensResponseTimeSec: 4
                )
            )
        )

        var lowerTimeLimitReached = false
        Task.detached {
            try? await Task.sleep(timeInterval: 1.5)
            lowerTimeLimitReached = true
        }
        var upperTimeLimitReached = false
        Task.detached {
            try? await Task.sleep(timeInterval: 2.5)
            upperTimeLimitReached = true
        }

        async let a: MockResponse = try runner.run(request: MockRequest(label: "1"))
        async let b: MockResponse = try runner.run(request: MockRequest(label: "2"))
        async let c: MockResponse = try runner.run(request: MockRequest(label: "3"))
        async let d: MockResponse = try runner.run(request: MockRequest(label: "4"))
        async let e: MockResponse = try runner.run(request: MockRequest(label: "5"))
        async let f: MockResponse = try runner.run(request: MockRequest(label: "6"))

        let _: [MockResponse] = try await [
            a, b, c, d, e, f
        ]

        #expect(lowerTimeLimitReached)
        #expect(!upperTimeLimitReached)
    }

    @Test func testRequestsLimitRefreshOnStart() async throws {
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

        var lowerTimeLimitReached = false
        Task.detached {
            try? await Task.sleep(timeInterval: 2.5)
            lowerTimeLimitReached = true
        }
        var upperTimeLimitReached = false
        Task.detached {
            try? await Task.sleep(timeInterval: 3.5)
            upperTimeLimitReached = true
        }

        async let a: MockResponse = try runner.run(request: MockRequest(label: "1"))
        async let b: MockResponse = try runner.run(request: MockRequest(label: "2"))

        let _: [MockResponse] = try await [
            a, b
        ]

        #expect(lowerTimeLimitReached)
        #expect(!upperTimeLimitReached)
    }

    @Test func testNoRefresherNoToken() async throws {
        let runner = MaxSimultaneousRequestsRestrictor(
            limit: 5,
            manager: ApiServiceRequestRunnersManager(
                runnerFactory: MockRequestRunnerFactory(
                    runResult: .success(MockResponse()),
                    runResponseTimeSec: 1,
                    label: "runner"
                ),
                tokenRefresher: nil
            )
        )

        var lowerTimeLimitReached = false
        Task.detached {
            try? await Task.sleep(timeInterval: 0.5)
            lowerTimeLimitReached = true
        }
        var upperTimeLimitReached = false
        Task.detached {
            try? await Task.sleep(timeInterval: 1.5)
            upperTimeLimitReached = true
        }

        async let a: MockResponse = try runner.run(request: MockRequest(label: "1"))
        async let b: MockResponse = try runner.run(request: MockRequest(label: "2"))

        let _: [MockResponse] = try await [
            a, b
        ]

        #expect(lowerTimeLimitReached)
        #expect(!upperTimeLimitReached)
    }

    @Test func testRequestsReRunOnTokenFailed() async throws {
        let runner = MaxSimultaneousRequestsRestrictor(
            limit: 5,
            manager: ApiServiceRequestRunnersManager(
                runnerFactory: MockRequestRunnerFactory(
                    runResult: .success(MockResponse()),
                    runResponseTimeSec: 1,
                    label: "runner"
                ),
                tokenRefresher: TokenRefresherMock(
                    accessTokenValue: "123",
                    refreshTokensValue: .success("123"),
                    refreshTokensResponseTimeSec: 2
                )
            )
        )

        var lowerTimeLimitReached = false
        Task.detached {
            try? await Task.sleep(timeInterval: 3.5)
            lowerTimeLimitReached = true
        }
        var upperTimeLimitReached = false
        Task.detached {
            try? await Task.sleep(timeInterval: 4.5)
            upperTimeLimitReached = true
        }

        async let a: MockResponse = try runner.run(request: MockRequest(label: "1"))
        async let b: MockResponse = try runner.run(request: MockRequest(label: MockRequest.accessTokenShouldFailLabel))

        let _: [MockResponse] = try await [
            a, b
        ]

        #expect(lowerTimeLimitReached)
        #expect(!upperTimeLimitReached)
    }

    @Test func testRequestsRefreshFailed() async throws {
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
                    refreshTokensValue: .failure(.expired(NSError(domain: "", code: -1))),
                    refreshTokensResponseTimeSec: 2
                )
            )
        )

        var lowerTimeLimitReached = false
        Task.detached {
            try? await Task.sleep(timeInterval: 1.5)
            lowerTimeLimitReached = true
        }
        var upperTimeLimitReached = false
        Task.detached {
            try? await Task.sleep(timeInterval: 2.5)
            upperTimeLimitReached = true
        }

        async let a: MockResponse = try runner.run(request: MockRequest(label: "1"))
        async let b: MockResponse = try runner.run(request: MockRequest(label: MockRequest.accessTokenShouldFailLabel))

        do {
            let _: [MockResponse] = try await [
                a, b
            ]
            Issue.record()
        } catch {
            guard let error = error as? ApiServiceError, case .unauthorized = error else {
                Issue.record()
                return
            }
        }
        #expect(lowerTimeLimitReached)
        #expect(!upperTimeLimitReached)
    }

    @Test func testRequestsRefreshFailedOnReRun() async throws {
        let runner = MaxSimultaneousRequestsRestrictor(
            limit: 5,
            manager: ApiServiceRequestRunnersManager(
                runnerFactory: MockRequestRunnerFactory(
                    runResult: .failure(.noConnection(NSError(domain: "", code: -1))),
                    runResponseTimeSec: 1,
                    label: "runner"
                ),
                tokenRefresher: TokenRefresherMock(
                    accessTokenValue: nil,
                    refreshTokensValue: .failure(.noConnection(NSError(domain: "", code: -1))),
                    refreshTokensResponseTimeSec: 2
                )
            )
        )

        var lowerTimeLimitReached = false
        Task.detached {
            try? await Task.sleep(timeInterval: 1.5)
            lowerTimeLimitReached = true
        }
        var upperTimeLimitReached = false
        Task.detached {
            try? await Task.sleep(timeInterval: 2.5)
            upperTimeLimitReached = true
        }

        async let a: MockResponse = try runner.run(request: MockRequest(label: MockRequest.accessTokenShouldFailLabel))

        do {
            let _: [MockResponse] = try await [
                a
            ]
            Issue.record()
        } catch {
            guard let error = error as? ApiServiceError, case .noConnection = error else {
                Issue.record()
                return
            }
        }
        #expect(lowerTimeLimitReached)
        #expect(!upperTimeLimitReached)
    }

    @Test func testRequestsFailedWithSuccessToken() async throws {
        let runner = MaxSimultaneousRequestsRestrictor(
            limit: 5,
            manager: ApiServiceRequestRunnersManager(
                runnerFactory: MockRequestRunnerFactory(
                    runResult: .failure(.noConnection(NSError(domain: "", code: -1))),
                    runResponseTimeSec: 1,
                    label: "runner"
                ),
                tokenRefresher: TokenRefresherMock(
                    accessTokenValue: "123",
                    refreshTokensValue: .failure(.noConnection(NSError(domain: "", code: -1))),
                    refreshTokensResponseTimeSec: 2
                )
            )
        )

        var lowerTimeLimitReached = false
        Task.detached {
            try? await Task.sleep(timeInterval: 0.5)
            lowerTimeLimitReached = true
        }
        var upperTimeLimitReached = false
        Task.detached {
            try? await Task.sleep(timeInterval: 1.5)
            upperTimeLimitReached = true
        }

        async let a: MockResponse = try runner.run(request: MockRequest(label: "a"))

        do {
            let _: [MockResponse] = try await [
                a
            ]
            Issue.record()
        } catch {
            guard let error = error as? ApiServiceError, case .noConnection = error else {
                Issue.record()
                return
            }
        }
        #expect(lowerTimeLimitReached)
        #expect(!upperTimeLimitReached)
    }
}
