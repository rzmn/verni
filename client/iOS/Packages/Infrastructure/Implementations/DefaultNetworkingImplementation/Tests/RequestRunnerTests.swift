import XCTest
import Networking
@testable import DefaultNetworkingImplementation

class RequestRunnerTests: XCTestCase {
    let maxRetryCount = 1
    lazy var backoff = ExponentialBackoff(base: 1, retryCount: 0, maxRetryCount: maxRetryCount)

    @MainActor func testSuccess() async throws {
        let url = URL(string: "url.com")!
        let data = "{\"k\": \"v\"}".data(using: .utf8)!
        let expectedResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)

        await URLProtocolMock.setMockUrls([
            url: (nil, data, expectedResponse),
        ])
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.protocolClasses = [URLProtocolMock.self]
        let mockedSession =  URLSession(configuration: sessionConfiguration)

        let runner = RequestRunner(
            session: mockedSession,
            request: URLRequest(url: url),
            logger: .shared,
            backoff: backoff
        )
        let response = try await runner.run()

        XCTAssertEqual(response.data, data)
        XCTAssertEqual(response.code, HttpCode.success(.ok))
        XCTAssertEqual(URLProtocolMock.loadsCount, 1)
    }

    @MainActor func testWrongResponseType() async throws {
        let url = URL(string: "url.com")!
        let data = "{\"k\": \"v\"}".data(using: .utf8)!
        let expectedResponse = URLResponse(url: url, mimeType: "", expectedContentLength: 0, textEncodingName: nil)

        await URLProtocolMock.setMockUrls([
            url: (nil, data, expectedResponse),
        ])
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.protocolClasses = [URLProtocolMock.self]
        let mockedSession =  URLSession(configuration: sessionConfiguration)

        let runner = RequestRunner(
            session: mockedSession,
            request: URLRequest(url: url),
            logger: .shared,
            backoff: backoff
        )
        do {
            let _ = try await runner.run()
            return XCTAssert(false)
        } catch {
            guard case .badResponse = error else {
                return XCTAssert(false)
            }
            XCTAssertEqual(URLProtocolMock.loadsCount, 1)
        }
    }

    @MainActor func testNoConnectionBackoff() async throws {
        let url = URL(string: "url.com")!
        let error = NSError(domain: NSURLErrorDomain, code: URLError.Code.networkConnectionLost.rawValue)

        await URLProtocolMock.setMockUrls([
            url: (error, nil, nil),
        ])
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.protocolClasses = [URLProtocolMock.self]
        let mockedSession =  URLSession(configuration: sessionConfiguration)

        let runner = RequestRunner(
            session: mockedSession,
            request: URLRequest(url: url),
            logger: .shared,
            backoff: backoff
        )
        do {
            let _ = try await runner.run()
            return XCTAssert(false)
        } catch {
            guard case .noConnection = error else {
                return XCTAssert(false)
            }
            XCTAssertEqual(URLProtocolMock.loadsCount, maxRetryCount + 1)
        }
    }

    @MainActor func testNoBackoffErrorUnknownDomain() async throws {
        let url = URL(string: "url.com")!
        let error = NSError(domain: "fake domain", code: -2222)

        await URLProtocolMock.setMockUrls([
            url: (error, nil, nil),
        ])
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.protocolClasses = [URLProtocolMock.self]
        let mockedSession =  URLSession(configuration: sessionConfiguration)

        let runner = RequestRunner(
            session: mockedSession,
            request: URLRequest(url: url),
            logger: .shared,
            backoff: backoff
        )
        do {
            let _ = try await runner.run()
            return XCTAssert(false)
        } catch {
            guard case .cannotSend = error else {
                return XCTAssert(false)
            }
            XCTAssertEqual(URLProtocolMock.loadsCount, 1)
        }
    }

    @MainActor func testNoBackoffErrorKnownDomain() async throws {
        let url = URL(string: "url.com")!
        let error = NSError(domain: NSURLErrorDomain, code: -2222)

        await URLProtocolMock.setMockUrls([
            url: (error, nil, nil),
        ])
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.protocolClasses = [URLProtocolMock.self]
        let mockedSession =  URLSession(configuration: sessionConfiguration)

        let runner = RequestRunner(
            session: mockedSession,
            request: URLRequest(url: url),
            logger: .shared,
            backoff: backoff
        )
        do {
            let _ = try await runner.run()
            return XCTAssert(false)
        } catch {
            guard case .cannotSend = error else {
                return XCTAssert(false)
            }
            XCTAssertEqual(URLProtocolMock.loadsCount, 1)
        }
    }

    @MainActor func testServerErrorBackoff() async throws {
        let url = URL(string: "url.com")!
        let data = "{\"k\": \"v\"}".data(using: .utf8)!
        let expectedResponse = HTTPURLResponse(url: url, statusCode: 500, httpVersion: nil, headerFields: nil)

        await URLProtocolMock.setMockUrls([
            url: (nil, data, expectedResponse),
        ])
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.protocolClasses = [URLProtocolMock.self]
        let mockedSession =  URLSession(configuration: sessionConfiguration)

        let runner = RequestRunner(
            session: mockedSession,
            request: URLRequest(url: url),
            logger: .shared,
            backoff: backoff
        )
        let response = try await runner.run()

        XCTAssertEqual(response.data, data)
        XCTAssertEqual(response.code, HttpCode.serverError(.internalServerError))
        XCTAssertEqual(URLProtocolMock.loadsCount, maxRetryCount + 1)
    }
}
