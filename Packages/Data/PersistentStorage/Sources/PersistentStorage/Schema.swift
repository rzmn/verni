import DataTransferObjects

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

    public static var profile: AnyDescriptor<Unkeyed, ProfileDto> {
        AnyDescriptor(id: "profile")
    }

    public static var users: AnyDescriptor<UserDto.Identifier, UserDto> {
        AnyDescriptor(id: "users")
    }

    public static var spendingCounterparties: AnyDescriptor<Unkeyed, [BalanceDto]> {
        AnyDescriptor(id: "spendingCounterparties")
    }

    public static var spendingsHistory: AnyDescriptor<UserDto.Identifier, [IdentifiableExpenseDto]> {
        AnyDescriptor(id: "spendingsHistory")
    }

    public static var friends: AnyDescriptor<FriendshipKindSetDto, [FriendshipKindDto: [UserDto]]> {
        AnyDescriptor(id: "friends")
    }
}
