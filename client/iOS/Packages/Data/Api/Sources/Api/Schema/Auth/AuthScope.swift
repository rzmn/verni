protocol AuthScope: Scope {}
extension AuthScope {
    var scope: String {
        "/auth"
    }
}

public enum Auth {}
