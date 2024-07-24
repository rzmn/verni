protocol UsersScope: Scope {}
extension UsersScope {
    var scope: String {
        "/users"
    }
}

public enum Users {}
