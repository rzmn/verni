protocol ProfileScope: Scope {}
extension ProfileScope {
    var scope: String {
        "/friends"
    }
}

public enum Profile {}
