import UIKit
import Combine
import Domain
import AppBase
internal import DesignSystem
internal import Base

class AddExpenseView: View<AddExpenseViewActions> {
    private var subscriptions = Set<AnyCancellable>()

    private let whoOws = SegmentedControl(
        config: SegmentedControl.Config(
            items: [
                SegmentedControl.Config.Item(
                    title: "expense_i_owe".localized
                ),
                SegmentedControl.Config.Item(
                    title: "expense_i_am_owed".localized
                )
            ]
        )
    )
    private let splitEqually = Switch(
        config: Switch.Config(
            on: true
        )
    )
    private let splitEquallyDescription = {
        let label = UILabel()
        label.font = .p.text
        label.textColor = .p.primary
        label.text = "expense_split_equally".localized
        return label
    }()
    private let chooseCounterparty = Button(
        config: Button.Config(
            style: .primary,
            title: "expense_choose_counterparty".localized
        )
    )
    private let counterpartyAvatar = {
        let size: CGFloat = 44
        let frame = CGRect(origin: .zero, size: CGSize(width: size, height: size))
        let view = AvatarView(frame: frame)
        view.fitSize = frame.size
        view.layer.masksToBounds = true
        view.layer.cornerRadius = size / 2
        view.contentMode = .scaleAspectFill
        return view
    }()
    private let counterpartyName = {
        let label = UILabel()
        label.font = .p.text
        label.textColor = .p.primary
        return label
    }()
    private let expenseDescription = TextField(
        config: TextField.Config(
            placeholder: "expense_description_placeholder".localized,
            content: .someDescription
        )
    )
    private let expenseAmount = TextField(
        config: TextField.Config(
            placeholder: "expense_cost_placeholder".localized,
            content: .numberPad
        )
    )

    override func setupView() {
        backgroundColor = .p.background
        [
            whoOws,
            splitEqually,
            chooseCounterparty,
            expenseDescription,
            expenseAmount,
            splitEquallyDescription,
            counterpartyAvatar,
            counterpartyName
        ].forEach(addSubview)
        chooseCounterparty.tapPublisher
            .sink(receiveValue: curry(model.handle)(.onPickCounterpartyTap))
            .store(in: &subscriptions)
        splitEqually.isOnPublisher
            .sink(receiveValue: model.handle • AddExpenseViewActionType.onSplitRuleTap)
            .store(in: &subscriptions)
        whoOws.selectedIndexPublisher
            .map { $0 == 0 }
            .sink(receiveValue: model.handle • AddExpenseViewActionType.onOwnershipTap)
            .store(in: &subscriptions)
        expenseDescription.textPublisher
            .map { $0 ?? "" }
            .sink(receiveValue: model.handle • AddExpenseViewActionType.onDescriptionChanged)
            .store(in: &subscriptions)
        expenseAmount.textPublisher
            .map { $0 ?? "" }
            .sink(receiveValue: model.handle • AddExpenseViewActionType.onExpenseAmountChanged)
            .store(in: &subscriptions)
        expenseAmount.delegate = self
        expenseDescription.delegate = self
        model.state
            .sink(receiveValue: render)
            .store(in: &subscriptions)
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let paddedBounds = CGSize(width: bounds.width - .p.defaultHorizontal * 2, height: bounds.height)
        for index in 0 ..< whoOws.numberOfSegments {
            whoOws.setWidth(paddedBounds.width / CGFloat(whoOws.numberOfSegments), forSegmentAt: index)
        }
        whoOws.frame = CGRect(
            x: .p.defaultHorizontal,
            y: safeAreaInsets.top + .p.defaultVertical,
            width: paddedBounds.width,
            height: whoOws.sizeThatFits(paddedBounds).height
        )
        let splitEquallySize = splitEqually.sizeThatFits(paddedBounds)
        splitEqually.frame = CGRect(
            x: .p.defaultHorizontal,
            y: whoOws.frame.maxY + .p.defaultVertical,
            width: splitEquallySize.width,
            height: splitEquallySize.height
        )
        let splitEquallyDescriptionSize = splitEquallyDescription.sizeThatFits(
            CGSize(
                width: bounds.width - splitEqually.frame.maxX - .p.defaultHorizontal * 2,
                height: .p.buttonHeight
            )
        )
        splitEquallyDescription.frame = CGRect(
            x: splitEqually.frame.maxX + .p.defaultHorizontal,
            y: splitEqually.frame.midY - splitEquallyDescriptionSize.height / 2,
            width: splitEquallyDescriptionSize.width,
            height: splitEquallyDescriptionSize.height
        )
        if let text = counterpartyName.text, !text.isEmpty {
            let chooseCounterpartyWidth = chooseCounterparty.intrinsicContentSize.width + .p.defaultHorizontal * 2
            chooseCounterparty.frame = CGRect(
                x: bounds.width - chooseCounterpartyWidth - .p.defaultHorizontal,
                y: splitEqually.frame.maxY + .p.defaultVertical,
                width: chooseCounterpartyWidth,
                height: .p.buttonHeight
            )
            let counterpartyAvatarSize = counterpartyAvatar.sizeThatFits(paddedBounds)
            counterpartyAvatar.frame = CGRect(
                x: .p.defaultHorizontal,
                y: chooseCounterparty.frame.midY - counterpartyAvatarSize.height / 2,
                width: counterpartyAvatarSize.width,
                height: counterpartyAvatarSize.height
            )
            let counterpartyNameSize = counterpartyName.sizeThatFits(
                CGSize(
                    width: chooseCounterparty.frame.minX - counterpartyAvatar.frame.maxX - .p.defaultHorizontal,
                    height: chooseCounterparty.frame.height
                )
            )
            counterpartyName.frame = CGRect(
                x: counterpartyAvatar.frame.maxX + .p.defaultHorizontal,
                y: chooseCounterparty.frame.midY - counterpartyNameSize.height / 2,
                width: counterpartyNameSize.width,
                height: counterpartyNameSize.height
            )
        } else {
            chooseCounterparty.frame = CGRect(
                x: .p.defaultHorizontal,
                y: splitEqually.frame.maxY + .p.defaultVertical,
                width: paddedBounds.width,
                height: .p.buttonHeight
            )
        }
        expenseDescription.frame = CGRect(
            x: .p.defaultHorizontal,
            y: chooseCounterparty.frame.maxY + .p.defaultVertical,
            width: paddedBounds.width,
            height: .p.buttonHeight
        )
        expenseAmount.frame = CGRect(
            x: .p.defaultHorizontal,
            y: expenseDescription.frame.maxY + .p.defaultVertical,
            width: paddedBounds.width,
            height: .p.buttonHeight
        )
    }

    private func render(state: AddExpenseState) {
        whoOws.selectedSegmentIndex = state.expenseOwnership == .iOwe ? 0 : 1
        splitEqually.isOn = state.splitEqually
        let needsLayout: Bool
        if let counterparty = state.counterparty {
            needsLayout = counterpartyName.isHidden
            counterpartyName.text = counterparty.displayName
            counterpartyAvatar.avatarId = counterparty.avatar?.id
            counterpartyName.isHidden = false
            counterpartyAvatar.isHidden = false
        } else {
            needsLayout = !counterpartyName.isHidden
            counterpartyName.text = nil
            counterpartyAvatar.avatarId = nil
            counterpartyName.isHidden = true
            counterpartyAvatar.isHidden = true
        }
        if needsLayout {
            setNeedsLayout()
        }
    }
}

extension AddExpenseView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case expenseAmount:
            model.handle(.onDoneTap)
        case expenseDescription:
            expenseAmount.becomeFirstResponder()
        default:
            break
        }
        return true
    }
}
