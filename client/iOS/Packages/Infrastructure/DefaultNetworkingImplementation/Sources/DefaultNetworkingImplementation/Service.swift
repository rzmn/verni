import Foundation
import Networking
import Logging
import Base

public struct Endpoint {
    public let path: String

    public init(path: String) {
        self.path = path
    }
}

extension Endpoint: CompactDescription {}

class Service {
    private let _logger: Logger
    private let endpoint: Endpoint
    private let encoder = JSONEncoder()


    init(logger: Logger, endpoint: Endpoint) {
        self._logger = logger
        self.endpoint = endpoint

        logI { "initialized network service. endpoint: \(endpoint)" }
    }
}

private extension Endpoint {
    var pathWithoutTrailingSlash: String {
        path.hasSuffix("/") ? String(path.prefix(path.count - 1)) : path
    }
}

private extension NetworkRequestWithParameters {
    func jsonEncodedParameters(encoder: JSONEncoder) async throws -> Data {
        try encoder.encode(parameters)
    }
}

extension Service: NetworkService {
    struct Failure: Error, CustomStringConvertible {
        let description: String
    }

    struct ExpBackoff: CompactDescription {
        let base: TimeInterval = 0.5
        let retryCount: Int
        let maxRetryCount: Int = 3

        var shouldTryAgain: Bool {
            retryCount < maxRetryCount
        }
    }

    func run<T>(_ request: T) async -> Result<NetworkServiceResponse, NetworkServiceError> where T : NetworkRequest {
        await run(request, backoff: nil)
    }

    func run<T>(_ request: T, backoff: ExpBackoff?) async -> Result<NetworkServiceResponse, NetworkServiceError> where T : NetworkRequest {
        logI { "starting request \(request) retry=\(backoff?.description ?? "nil")" }
        let urlString = endpoint.pathWithoutTrailingSlash + request.path
        guard let url = URL(string: urlString) else {
            logE { "cannot build url with string \(urlString)" }
            return .failure(
                .cannotBuildRequest(
                    Failure(
                        description: "cannot build url with string \(urlString)"
                    )
                )
            )
        }
        let urlRequestBuildResult: Result<URLRequest, NetworkServiceError> = await {
            let parameters: Data?
            let requestUrl: URL
            if let requestWithParameters = request as? (any NetworkRequestWithParameters) {
                let data: Data
                do {
                    data = try await requestWithParameters.jsonEncodedParameters(encoder: encoder)
                } catch {
                    return .failure(
                        .cannotBuildRequest(
                            Failure(
                                description: "bar request parameters: \(requestWithParameters.parameters) error: \(error)"
                            )
                        )
                    )
                }
                self.logD { "\(request.path): body: \(String(data: data, encoding: .utf8) ?? "nil")" }
                parameters = data
                switch request.httpMethod {
                case .get:
                    guard var components = URLComponents(string: url.absoluteString) else {
                        logE { "cannot build url params with url \(url)" }
                        return .failure(
                            .cannotBuildRequest(
                                Failure(
                                    description: "cannot build url params with url \(url)"
                                )
                            )
                        )
                    }
                    components.queryItems = [
                        URLQueryItem(name: "data", value: String(data: data, encoding: .utf8))
                    ]
                    guard let finalUrl = components.url else {
                        logE { "cannot build url with components \(components)" }
                        return .failure(
                            .cannotBuildRequest(
                                Failure(
                                    description: "cannot build url with components \(components)"
                                )
                            )
                        )
                    }
                    requestUrl = finalUrl
                default:
                    requestUrl = url
                }
            } else {
                parameters = nil
                requestUrl = url
            }
            logI { "\(request.path) resolved url: \(requestUrl)" }
            var r = URLRequest(url: requestUrl)
            request.headers.forEach { key, value in
                r.setValue(value, forHTTPHeaderField: key)
                logD { "\(request.path): http header: (\(key): \(value))" }
            }
            r.httpMethod = request.httpMethod.rawValue
            if let parameters {
                switch request.httpMethod {
                case .get:
                    break
                default:
                    self.logD { "\(request.path): body: \(String(data: parameters, encoding: .utf8) ?? "nil")" }
                    r.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    r.httpBody = parameters
                }
            }
            return .success(r)
        }()
        let urlRequest: URLRequest
        switch urlRequestBuildResult {
        case .success(let request):
            urlRequest = request
        case .failure(let error):
            return .failure(error)
        }
        logI { "\(request.path): built request: \(urlRequest)" }
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: urlRequest)
            logD { "\(request.path): get JSON: \(String(data: data, encoding: .utf8) ?? "nil")" }
        } catch {
            let handle: (Error) -> NetworkServiceError = { error in
                if (error as NSError).domain == NSURLErrorDomain && ([.networkConnectionLost, .timedOut, .notConnectedToInternet] as [URLError.Code]).map(\.rawValue).contains((error as NSError).code) {
                    self.logE { "\(request.path): failed to run data task due connection problem" }
                    return .noConnection(error)
                } else {
                    self.logE { "\(request.path): failed to run data task error: \(error)" }
                    return .cannotSend(error)
                }
            }
            logD { "\(request.path): got error \(error). underlying: \((error as NSError).underlyingErrors.map { $0 as NSError })" }
            if let backoff {
                if backoff.shouldTryAgain {
                    logI { "\(request.path): backoff try \(backoff.retryCount)" }
                    let outError = error
                    do {
                        try await Task.sleep(for: .milliseconds(Int(backoff.base * pow(2, Double(backoff.retryCount)) * 1000)))
                        return await run(request, backoff: ExpBackoff(retryCount: backoff.retryCount + 1))
                    } catch {
                        logI { "\(request.path): backoff failed on try \(backoff.retryCount) error: \(error)" }
                        return .failure(handle(outError))
                    }
                } else {
                    logI { "\(request.path): stopping backoff error: \(error)" }
                    return .failure(handle(error))
                }
            } else {
                return await run(request, backoff: ExpBackoff(retryCount: 0))
            }
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            logE { "\(request.path): response is not an HTTPURLResponse. found: \(response)" }
            return .failure(.badResponse(Failure(description: "bad respose type: \(response)")))
        }
        logI { "\(request.path): got http response" }
        return .success(
            NetworkServiceResponse(
                code: HttpCode(
                    code: httpResponse.statusCode
                ),
                data: data
            )
        )
    }
}

extension Service: Loggable {
    var logger: Logger { _logger }
}
