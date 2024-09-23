import UIKit
internal import ProgressHUD

@MainActor public func setupAppearance() {
    let appearance = UINavigationBarAppearance()
    appearance.backButtonAppearance.normal.titleTextAttributes = [
        .font: UIFont.palette.title3,
        .foregroundColor: UIColor.palette.primary
    ]
    appearance.backButtonAppearance.normal.titleTextAttributes = [
        .font: UIFont.palette.title3,
        .foregroundColor: UIColor.palette.primary
    ]
    appearance.largeTitleTextAttributes = [
        .foregroundColor: UIColor.palette.primary,
        .font: UIFont.palette.title1
    ]
    appearance.titleTextAttributes = [
        .foregroundColor: UIColor.palette.primary,
        .font: UIFont.palette.title2
    ]
    UINavigationBar.appearance().standardAppearance = appearance

    ProgressHUD.animationType = .circleStrokeSpin
    ProgressHUD.colorAnimation = .palette.accent
    UIImage(systemName: "network.slash").flatMap {
        ProgressHUD.imageError = $0.withTintColor(.palette.accent, renderingMode: .alwaysOriginal)
    }
    ProgressHUD.fontStatus = .palette.title3
    ProgressHUD.colorStatus = .palette.primary
    ProgressHUD.mediaSize = 44
}
