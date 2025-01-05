import Api

public enum Schema {
    public static var identifierKey: String {
        "id"
    }

    public static var valueKey: String {
        "value"
    }

    public static var refreshToken: AnyDescriptor<Unkeyed, String> {
        AnyDescriptor(id: "refreshToken")
    }

    public static var profile: AnyDescriptor<Unkeyed, Components.Schemas.Profile> {
        AnyDescriptor(id: "profile")
    }

    public static var users: AnyDescriptor<String, Components.Schemas.User> {
        AnyDescriptor(id: "users")
    }
}
