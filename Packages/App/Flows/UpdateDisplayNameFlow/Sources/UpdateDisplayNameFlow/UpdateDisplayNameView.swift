import AppBase
import UIKit
import Combine
internal import Base
internal import DesignSystem

class UpdateDisplayNameView: UIKitBasedView<UpdateDisplayNameViewActions> {
    private let newDisplayName = TextField(
        config: TextField.Config(
            placeholder: "enter_new_display_name_placeholder".localized,
            content: .displayName
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
        backgroundColor = .palette.background
        for view in [newDisplayName, confirm] {
            addSubview(view)
        }
        newDisplayName.delegate = self
        newDisplayName.textPublisher
            .map { $0 ?? "" }
            .sink(receiveValue: model.handle • UpdateDisplayNameViewActionType.onDisplayNameTextChanged)
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
            }.store(in: &subscriptions)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        newDisplayName.frame = CGRect(
            x: .palette.defaultHorizontal,
            y: safeAreaInsets.top + .palette.defaultVertical,
            width: bounds.width - .palette.defaultHorizontal * 2,
            height: .palette.buttonHeight
        )
        let bottomInset = keyboardBottomInset == 0 ? safeAreaInsets.bottom : keyboardBottomInset
        confirm.frame = CGRect(
            x: .palette.defaultHorizontal,
            y: bounds.maxY - bottomInset - .palette.buttonHeight - .palette.defaultVertical,
            width: bounds.width - .palette.defaultHorizontal * 2,
            height: .palette.buttonHeight
        )
    }

    private func onConfirmTap() {
        endEditing(true)
        model.handle(.onConfirmTap)
    }

    @objc private func onTap() {
        endEditing(true)
    }

    private func render(state: UpdateDisplayNameState) {
        newDisplayName.render(
            TextField.Config(
                placeholder: "enter_new_display_name_placeholder".localized,
                content: .displayName,
                formatHint: state.displayNameHint
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

extension UpdateDisplayNameView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case newDisplayName:
            confirm.sendActions(for: .touchUpInside)
        default:
            break
        }
        return true
    }
}
