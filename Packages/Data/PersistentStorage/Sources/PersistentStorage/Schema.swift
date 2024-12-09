import DataTransferObjects

public enum Schema {
    public static var refreshToken: Descriptor<Unkeyed, String> {
        Descriptor(id: "refreshToken")
    }
    
    public static var profile: Descriptor<Unkeyed, ProfileDto> {
        Descriptor(id: "profile")
    }
    
    public static var users: Descriptor<UserDto.Identifier, UserDto> {
        Descriptor(id: "users")
    }
    
    public static var spendingCounterparties: Descriptor<Unkeyed, [BalanceDto]> {
        Descriptor(id: "spendingCounterparties")
    }
    
    public static var spendingsHistory: Descriptor<UserDto.Identifier, [IdentifiableExpenseDto]> {
        Descriptor(id: "spendingsHistory")
    }
    
    public static var friends: Descriptor<FriendshipKindSetDto, [FriendshipKindDto: [UserDto]]> {
        Descriptor(id: "friends")
    }
}
