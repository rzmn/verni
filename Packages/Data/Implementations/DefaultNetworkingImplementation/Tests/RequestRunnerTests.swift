import Networking
import Testing
import Foundation
import Base
@testable import AsyncExtensions
@testable import DefaultNetworkingImplementation

@Suite(.serialized) struct RequestRunnerTests {
    static let maxRetryCount = 1
    let backoff = ExponentialBackoff(base: 1, retryCount: 0, maxRetryCount: maxRetryCount)
    let taskFactory: TestTaskFactory

    init() async {
        taskFactory = TestTaskFactory()
        await URLProtocolMock.setTaskFactory(taskFactory)
    }

    @Test @MainActor func testSuccess() async throws {

        // given

        let url = URL(string: "url.com")!
        let data = "{\"k\": \"v\"}".data(using: .utf8)!
        let expectedResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)

        await URLProtocolMock.setMockUrls([
            url: (nil, data, expectedResponse)
        ])
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.protocolClasses = [URLProtocolMock.self]
        let mockedSession =  URLSession(configuration: sessionConfiguration)

        // when

        let runner = RequestRunner(
            session: mockedSession,
            request: URLRequest(url: url),
            logger: .shared,
            backoff: backoff
        )
        let response = try await runner.run()

        // then

        #expect(response.data == data)
        #expect(response.code == HttpCode.success(.ok))
        #expect(URLProtocolMock.loadsCount == 1)
    }

    @Test @MainActor func testWrongResponseType() async throws {

        // given

        let url = URL(string: "url.com")!
        let data = "{\"k\": \"v\"}".data(using: .utf8)!
        let expectedResponse = URLResponse(url: url, mimeType: "", expectedContentLength: 0, textEncodingName: nil)

        await URLProtocolMock.setMockUrls([
            url: (nil, data, expectedResponse)
        ])
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.protocolClasses = [URLProtocolMock.self]
        let mockedSession =  URLSession(configuration: sessionConfiguration)

        // when

        let runner = RequestRunner(
            session: mockedSession,
            request: URLRequest(url: url),
            logger: .shared,
            backoff: backoff
        )
        let apiError: NetworkServiceError
        do {
            _ = try await runner.run()
            Issue.record()
            return
        } catch {
            apiError = error
        }

        // then

        guard case .badResponse = apiError else {
            Issue.record()
            return
        }
        #expect(URLProtocolMock.loadsCount == 1)
    }

    @Test @MainActor func testNoConnectionBackoff() async throws {

        // given

        let url = URL(string: "url.com")!
        let error = NSError(domain: NSURLErrorDomain, code: URLError.Code.networkConnectionLost.rawValue)

        await URLProtocolMock.setMockUrls([
            url: (error, nil, nil)
        ])
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.protocolClasses = [URLProtocolMock.self]
        let mockedSession =  URLSession(configuration: sessionConfiguration)

        // when

        let runner = RequestRunner(
            session: mockedSession,
            request: URLRequest(url: url),
            logger: .shared,
            backoff: backoff
        )
        let apiError: NetworkServiceError
        do {
            _ = try await runner.run()
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
        #expect(URLProtocolMock.loadsCount == Self.maxRetryCount + 1)
    }

    @Test @MainActor func testNoBackoffErrorUnknownDomain() async throws {

        // given

        let url = URL(string: "url.com")!
        let error = NSError(domain: "fake domain", code: -2222)

        await URLProtocolMock.setMockUrls([
            url: (error, nil, nil)
        ])
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.protocolClasses = [URLProtocolMock.self]
        let mockedSession =  URLSession(configuration: sessionConfiguration)

        // when

        let runner = RequestRunner(
            session: mockedSession,
            request: URLRequest(url: url),
            logger: .shared,
            backoff: backoff
        )
        let apiError: NetworkServiceError
        do {
            _ = try await runner.run()
            Issue.record()
            return
        } catch {
            apiError = error
        }

        // then

        guard case .cannotSend = apiError else {
            Issue.record()
            return
        }
        #expect(URLProtocolMock.loadsCount == 1)
    }

    @Test @MainActor func testNoBackoffErrorKnownDomain() async throws {

        // given

        let url = URL(string: "url.com")!
        let error = NSError(domain: NSURLErrorDomain, code: -2222)

        await URLProtocolMock.setMockUrls([
            url: (error, nil, nil)
        ])
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.protocolClasses = [URLProtocolMock.self]
        let mockedSession =  URLSession(configuration: sessionConfiguration)

        // when

        let runner = RequestRunner(
            session: mockedSession,
            request: URLRequest(url: url),
            logger: .shared,
            backoff: backoff
        )
        let apiError: NetworkServiceError
        do {
            _ = try await runner.run()
            Issue.record()
            return
        } catch {
            apiError = error
        }

        // then

        guard case .cannotSend = apiError else {
            Issue.record()
            return
        }
        #expect(URLProtocolMock.loadsCount == 1)
    }

    @Test @MainActor func testServerErrorBackoff() async throws {

        // given

        let url = URL(string: "url.com")!
        let data = "{\"k\": \"v\"}".data(using: .utf8)!
        let expectedResponse = HTTPURLResponse(url: url, statusCode: 500, httpVersion: nil, headerFields: nil)

        await URLProtocolMock.setMockUrls([
            url: (nil, data, expectedResponse)
        ])
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.protocolClasses = [URLProtocolMock.self]
        let mockedSession =  URLSession(configuration: sessionConfiguration)

        // when

        let runner = RequestRunner(
            session: mockedSession,
            request: URLRequest(url: url),
            logger: .shared,
            backoff: backoff
        )
        let response = try await runner.run()

        // then

        #expect(response.data == data)
        #expect(response.code == HttpCode.serverError(.internalServerError))
        #expect(URLProtocolMock.loadsCount == Self.maxRetryCount + 1)
    }
}
