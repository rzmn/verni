import Foundation

extension Task where Success == Never, Failure == Never {
    public static func sleep(timeInterval: TimeInterval) async throws {
        try await Self.sleep(for: .milliseconds(Int(timeInterval * 1000)))
    }
}
