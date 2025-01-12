import Foundation

extension URLError {
    public static var noConnection: URLError {
        URLError(.notConnectedToInternet)
    }
}

extension Error {
    public var noConnection: URLError? {
        if let self = self as? URLError, self.code == URLError.noConnection.code {
            return self
        }
        return nil
    }
}
