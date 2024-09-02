import Foundation

extension Task where Success == Never, Failure == Never {
    static func wait(basedOn backoff: ExponentialBackoff) async throws {
        try await Self.sleep(for: .milliseconds(Int(backoff.base * pow(2, Double(backoff.retryCount)) * 1000)))
    }
}
