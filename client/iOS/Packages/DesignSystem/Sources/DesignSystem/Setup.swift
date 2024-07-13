import UIKit

public func SetupAppearance() {
    let appearance = UINavigationBarAppearance()
    appearance.backButtonAppearance.normal.titleTextAttributes = [
        .font: UIFont.p.title3,
        .foregroundColor: UIColor.p.accent
    ]
    appearance.largeTitleTextAttributes = [
        .foregroundColor: UIColor.p.primary,
        .font: UIFont.p.title1
    ]
    appearance.titleTextAttributes = [
        .foregroundColor: UIColor.p.primary,
        .font: UIFont.p.title2
    ]
    UINavigationBar.appearance().standardAppearance = appearance
}
