import AppBase
import UIKit
import Combine
internal import Base
internal import DesignSystem

@MainActor class UpdatePasswordView: View<UpdatePasswordViewActions> {
    private let oldPassword = TextField(
        config: TextField.Config(
            placeholder: "enter_old_pwd_placeholder".localized,
            content: .password
        )
    )
    private let newPassword = TextField(
        config: TextField.Config(
            placeholder: "enter_new_pwd_placeholder".localized,
            content: .newPassword
        )
    )
    private let newPasswordRepeat = TextField(
        config: TextField.Config(
            placeholder: "enter_old_pwd_placeholder_again".localized,
            content: .newPassword
        )
    )
    private let confirm = Button(
        config: Button.Config(
            style: .primary,
            title: "common_confirm".localized
        )
    )
    private var keyboardBottomInset: CGFloat = 0
    private var subscriptions = Set<AnyCancellable>()

    override func setupView() {
        backgroundColor = .p.background
        for view in [oldPassword, newPassword, newPasswordRepeat, confirm] {
            addSubview(view)
        }
        for textField in [oldPassword, newPassword, newPasswordRepeat] {
            textField.delegate = self
        }
        oldPassword.textPublisher
            .map { $0 ?? "" }
            .sink(receiveValue: model.handle • UpdatePasswordViewActionType.onOldPasswordTextChanged)
            .store(in: &subscriptions)
        newPassword.textPublisher
            .map { $0 ?? "" }
            .sink(receiveValue: model.handle • UpdatePasswordViewActionType.onNewPasswordTextChanged)
            .store(in: &subscriptions)
        newPasswordRepeat.textPublisher
            .map { $0 ?? "" }
            .sink(receiveValue: model.handle • UpdatePasswordViewActionType.onRepeatNewPasswordTextChanged)
            .store(in: &subscriptions)
        confirm.tapPublisher
            .sink { [weak self] in
                self?.onConfirmTap()
            }
            .store(in: &subscriptions)
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap)))
        model.state
            .sink(receiveValue: render)
            .store(in: &subscriptions)
        KeyboardObserver.shared.notifier
            .sink { [weak self] event in
                guard let self, !isInInteractiveTransition else { return }
                switch event.kind {
                case .willChangeFrame(let frame):
                    keyboardBottomInset = max(0, bounds.maxY - convert(frame, to: window).minY)
                case .willHide:
                    keyboardBottomInset = 0
                }
                setNeedsLayout()
                UIView.animate(
                    withDuration: event.animationDuration,
                    delay: 0,
                    options: event.options,
                    animations: layoutIfNeeded
                )
            }
            .store(in: &subscriptions)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        oldPassword.frame = CGRect(
            x: .p.defaultHorizontal,
            y: safeAreaInsets.top + .p.defaultVertical,
            width: bounds.width - .p.defaultHorizontal * 2,
            height: .p.buttonHeight
        )
        newPassword.frame = CGRect(
            x: .p.defaultHorizontal,
            y: oldPassword.frame.maxY + .p.vButtonSpacing,
            width: bounds.width - .p.defaultHorizontal * 2,
            height: .p.buttonHeight
        )
        newPasswordRepeat.frame = CGRect(
            x: .p.defaultHorizontal,
            y: newPassword.frame.maxY + .p.vButtonSpacing,
            width: bounds.width - .p.defaultHorizontal * 2,
            height: .p.buttonHeight
        )
        let bottomInset = keyboardBottomInset == 0 ? safeAreaInsets.bottom : keyboardBottomInset
        confirm.frame = CGRect(
            x: .p.defaultHorizontal,
            y: bounds.maxY - bottomInset - .p.buttonHeight - .p.defaultVertical,
            width: bounds.width - .p.defaultHorizontal * 2,
            height: .p.buttonHeight
        )
    }

    private func onConfirmTap() {
        endEditing(true)
        model.handle(.onUpdateTap)
    }

    @objc private func onTap() {
        endEditing(true)
    }

    private func render(state: UpdatePasswordState) {
        oldPassword.render(
            TextField.Config(
                placeholder: "enter_old_pwd_placeholder".localized,
                content: .password
            )
        )
        newPassword.render(
            TextField.Config(
                placeholder: "enter_new_pwd_placeholder".localized,
                content: .newPassword,
                formatHint: state.newPasswordHint
            )
        )
        newPasswordRepeat.render(
            TextField.Config(
                placeholder: "enter_old_pwd_placeholder_again".localized,
                content: .newPassword,
                formatHint: state.repeatNewPasswordHint
            )
        )
        confirm.render(
            config: Button.Config(
                style: .primary,
                title: "common_confirm".localized,
                enabled: state.canConfirm
            )
        )
    }
}

extension UpdatePasswordView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case newPasswordRepeat:
            model.handle(.onUpdateTap)
        case oldPassword:
            newPassword.becomeFirstResponder()
        case newPassword:
            newPasswordRepeat.becomeFirstResponder()
        case newPasswordRepeat:
            confirm.sendActions(for: .touchUpInside)
        default:
            break
        }
        return true
    }
}
