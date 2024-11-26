import Foundation
import Domain
internal import DesignSystem

struct SpendingsState: Equatable, Sendable {
    enum PreviewsLoadingFailureReason: Equatable {
        case noInternet
    }
    
    struct Item: Equatable, Identifiable {
        let user: User
        let balance: [Currency: Cost]
        
        var id: String {
            user.id
        }
    }
    
    var previews: Loadable<[Item], PreviewsLoadingFailureReason>
}
