import Base

public struct CredentialsDto: Codable {
    public let login: String
    public let password: String

    public init(login: String, password: String) {
        self.login = login
        self.password = password
    }
}

extension CredentialsDto: CompactDescription {}
