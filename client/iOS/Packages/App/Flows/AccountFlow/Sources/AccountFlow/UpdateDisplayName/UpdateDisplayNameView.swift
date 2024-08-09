import AppBase
import UIKit
internal import Base
internal import DesignSystem

class UpdateDisplayNameView: View<UpdateDisplayNameFlow> {
    private let newDisplayName = TextField(
        config: TextField.Config(
            placeholder: "enter_new_display_name_placeholder".localized,
            content: .unspecified
        )
    )
    private let confirm = Button(
        config: Button.Config(
            style: .primary,
            title: "common_confirm".localized
        )
    )
    override func setupView() {
        backgroundColor = .p.background
        [newDisplayName, confirm].forEach(addSubview)
        newDisplayName.delegate = self
        newDisplayName.addAction({ [weak model, weak newDisplayName] in
            guard let model, let newDisplayName else { return }
            model.update(displayName: newDisplayName.text ?? "")
        }, for: .editingChanged)
        confirm.addAction({ [weak model] in
            await model?.confirmDisplayName()
        }, for: .touchUpInside)
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap)))
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        newDisplayName.frame = CGRect(
            x: .p.defaultHorizontal,
            y: safeAreaInsets.top + .p.defaultVertical,
            width: bounds.width - .p.defaultHorizontal * 2,
            height: .p.buttonHeight
        )
        confirm.frame = CGRect(
            x: .p.defaultHorizontal,
            y: bounds.maxY - safeAreaInsets.bottom - .p.buttonHeight - .p.defaultVertical,
            width: bounds.width - .p.defaultHorizontal * 2,
            height: .p.buttonHeight
        )
    }

    @objc private func onTap() {
        endEditing(true)
    }
}

extension UpdateDisplayNameView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case newDisplayName:
            Task.detached {
                await self.model.confirmDisplayName()
            }
        default:
            break
        }
        return true
    }
}
