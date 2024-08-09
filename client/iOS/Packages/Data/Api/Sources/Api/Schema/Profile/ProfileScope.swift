protocol ProfileScope: Scope {}
extension ProfileScope {
    var scope: String {
        "/profile"
    }
}

public enum Profile {}
