import UIKit
internal import ProgressHUD

@MainActor
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

    ProgressHUD.animationType = .circleStrokeSpin
    ProgressHUD.colorAnimation = .p.accent
    UIImage(systemName: "network.slash").flatMap {
        ProgressHUD.imageError = $0.withTintColor(.p.accent, renderingMode: .alwaysOriginal)
    }
    ProgressHUD.fontStatus = .p.title3
    ProgressHUD.colorStatus = .p.primary
    ProgressHUD.mediaSize = 44
}
