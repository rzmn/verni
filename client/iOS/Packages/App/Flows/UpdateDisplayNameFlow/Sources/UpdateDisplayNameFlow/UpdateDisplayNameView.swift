import AppBase
import UIKit
import Combine
internal import Base
internal import DesignSystem

class UpdateDisplayNameView: View<UpdateDisplayNameFlow> {
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
        backgroundColor = .p.background
        [newDisplayName, confirm].forEach(addSubview)
        newDisplayName.delegate = self
        newDisplayName.addAction({ [weak model, weak newDisplayName] in
            guard let model, let newDisplayName else { return }
            model.update(displayName: newDisplayName.text ?? "")
        }, for: .editingChanged)
        confirm.addAction({ [weak self] in
            self?.endEditing(true)
            self?.model.confirmDisplayName()
        }, for: .touchUpInside)
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap)))
        model.subject
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
            x: .p.defaultHorizontal,
            y: safeAreaInsets.top + .p.defaultVertical,
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
