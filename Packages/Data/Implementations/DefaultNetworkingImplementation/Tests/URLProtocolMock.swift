import Foundation
import Base
@testable import AsyncExtensions

@MainActor class URLProtocolMock: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) private(set) static var mockURLs = [URL?: (error: Error?, data: Data?, response: URLResponse?)]()
    nonisolated(unsafe) private(set) static var loadsCount: Int = 0
    nonisolated(unsafe) private(set) static var taskFactory: TaskFactory?

    static func setMockUrls(_ urls: [URL?: (error: Error?, data: Data?, response: URLResponse?)]) async {
        loadsCount = 0
        mockURLs = urls
    }

    static func setTaskFactory(_ taskFactory: TaskFactory) async {
        self.taskFactory = taskFactory
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let taskFactory = Self.taskFactory else {
            return assertionFailure()
        }
        taskFactory.task {
            await self.loading()
        }
    }

    @MainActor private func loading() async {
        URLProtocolMock.loadsCount += 1
        if let url = request.url {
            if let (error, data, response) = URLProtocolMock.mockURLs[url] {
                if let responseStrong = response {
                    client?.urlProtocol(self, didReceive: responseStrong, cacheStoragePolicy: .notAllowed)
                }
                if let dataStrong = data {
                    client?.urlProtocol(self, didLoad: dataStrong)
                }
                if let errorStrong = error {
                    client?.urlProtocol(self, didFailWithError: errorStrong)
                }
            }
        }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {
        // empty
    }
}
