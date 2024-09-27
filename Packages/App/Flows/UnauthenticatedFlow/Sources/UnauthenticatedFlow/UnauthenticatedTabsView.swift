import UIKit
import AppBase
import SwiftUI
import SignInFlow

struct UnauthenticatedTabsView<SignInView: View>: View {
    @ViewBuilder private let signInView: () -> SignInView

    init(signInView: @escaping () -> SignInView) {
        self.signInView = signInView
    }

    var body: some View {
        TabView {
            signInView()
                .tabItem {
                    Label("Menu", systemImage: "list.dash")
                }
        }
    }
}

#Preview {
    UnauthenticatedTabsView {
        Text("sign in view")
    }
}
