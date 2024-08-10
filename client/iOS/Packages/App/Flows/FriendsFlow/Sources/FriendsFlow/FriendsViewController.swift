import AppBase
import UIKit

class FriendsViewController: ViewController<FriendsView, FriendsFlow> {

}

extension FriendsViewController: Routable {
    func create(onClose: @escaping @MainActor (UIViewController) async -> Void) -> UIViewController {
        self.onClose = onClose
        return self
    }
    
    var name: String {
        "friends"
    }
}
