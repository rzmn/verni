import Base

public struct CredentialsDto: Codable, Sendable {
    public let email: String
    public let password: String

    public init(email: String, password: String) {
        self.email = email
        self.password = password
    }
}

extension CredentialsDto: CustomStringConvertible {
    public var description: String {
        "<email:\(email) pwd:\(String(password.prefix(3)) + (password.count > 3 ? "..." : ""))>"
    }
}
