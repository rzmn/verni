import AppBase
import DesignSystem
import ProfileScreen
import SpendingsScreen
import SpendingsGroupScreen
import AddExpenseScreen
import UserPreviewScreen
import ProfileEditingScreen
import ActivitiesScreen
import Entities

public typealias ProfileScreenProvider = ScreenProvider<ProfileEvent, ProfileView, ProfileTransitions>
public typealias SpendingsScreenProvider = ScreenProvider<SpendingsEvent, SpendingsView, SpendingsTransitions>
public typealias AddExpenseScreenProvider = ScreenProvider<AddExpenseEvent, AddExpenseView, AddExpenseTransitions>
public typealias UserPreviewScreenProvider = ScreenProvider<UserPreviewEvent, UserPreviewView, UserPreviewTransitions>
public typealias SpendingsGroupScreenProvider = ScreenProvider<SpendingsGroupEvent, SpendingsGroupView, SpendingsGroupTransitions>
public typealias ProfileEditingScreenProvider = ScreenProvider<ProfileEditingEvent, ProfileEditingView, ProfileEditingTransitions>
public typealias ActivitiesScreenProvider = ScreenProvider<ActivitiesEvent, ActivitiesView, ActivitiesTransitions>

@MainActor public protocol HostedAppSession: SharedAppSessionConvertible, AnyObject {
    var sandbox: SandboxAppSession { get }
    var images: AvatarView.Repository { get }
    var profile: any ProfileScreenProvider { get }
    var profileEditing: any ProfileEditingScreenProvider { get }
    var spendings: any SpendingsScreenProvider { get }
    var addExpense: any AddExpenseScreenProvider { get }
    var activities: any ActivitiesScreenProvider { get }
    var userPreview: (User) async -> any UserPreviewScreenProvider { get }
    var spendingsGroup: (SpendingGroup.Identifier) async -> any SpendingsGroupScreenProvider { get }
    func logout() async
}

extension HostedAppSession {
    public var shared: SharedAppSession {
        sandbox.shared
    }
}

@dynamicMemberLookup
public struct AnyHostedAppSession: Equatable, Sendable {
    public static func == (lhs: AnyHostedAppSession, rhs: AnyHostedAppSession) -> Bool {
        lhs.value === rhs.value
    }
    
    public let value: HostedAppSession
    
    public init(value: HostedAppSession) {
        self.value = value
    }
    
    public subscript<T>(dynamicMember keyPath: KeyPath<HostedAppSession, T>) -> T {
        value[keyPath: keyPath]
    }
}
