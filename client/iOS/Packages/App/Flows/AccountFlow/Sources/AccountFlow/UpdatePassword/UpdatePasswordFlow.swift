import AppBase
import Combine
import Domain
import DI
import Security

actor UpdatePasswordFlow {
    private let router: AppRouter
    private let profileEditing: ProfileEditingUseCase
    private lazy var presenter = UpdatePasswordFlowPresenter(router: router, flow: self)

    public let subject = CurrentValueSubject<UpdatePasswordState, Never>(.initial)

    private let oldPasswordSubject = CurrentValueSubject<String, Never>(UpdatePasswordState.initial.oldPassword)
    private let newPasswordSubject = CurrentValueSubject<String, Never>(UpdatePasswordState.initial.newPassword)
    private let repeatNewPasswordSubject = CurrentValueSubject<String, Never>(UpdatePasswordState.initial.repeatNewPassword)
    private let newPasswordHint = CurrentValueSubject<String?, Never>(UpdatePasswordState.initial.newPasswordHint)
    private let repeatNewPasswordHint = CurrentValueSubject<String?, Never>(UpdatePasswordState.initial.repeatNewPasswordHint)

    private var subscriptions = Set<AnyCancellable>()

    private let passwordValidation: PasswordValidationUseCase
    private let profileRepository: UsersRepository
    private let profile: Profile

    private var flowContinuation: Continuation?

    init(di: ActiveSessionDIContainer, router: AppRouter, profile: Profile) {
        self.router = router
        self.profile = profile
        self.profileEditing = di.profileEditingUseCase()
        self.profileRepository = di.usersRepository()
        self.passwordValidation = di.appCommon().passwordValidationUseCase()
    }
}

extension UpdatePasswordFlow: Flow {
    enum FailureReason: Error {
        case canceledManually
    }

    func perform(willFinish: ((Result<Profile, FailureReason>) async -> Void)?) async -> Result<Profile, FailureReason> {

        Publishers.CombineLatest(newPasswordSubject, repeatNewPasswordSubject)
            .map { password, repeatPassword in
                if repeatPassword.isEmpty {
                    return true
                }
                return password == repeatPassword
            }
            .map { (matches: Bool) -> String? in
                if matches {
                    return nil
                } else {
                    return "password_repeat_did_not_match".localized
                }
            }
            .sink(receiveValue: repeatNewPasswordHint.send)
            .store(in: &subscriptions)

        newPasswordSubject
            .flatMap { password in
                Future<Result<Void, PasswordValidationError>, Never>.init { promise in
                    guard !password.isEmpty else {
                        return promise(.success(.success(())))
                    }
                    Task {
                        promise(.success(await self.passwordValidation.validatePassword(password)))
                    }
                }
            }.map { result -> String? in
                switch result {
                case .success:
                    return nil
                case .failure(let error):
                    switch error {
                    case .tooShort(let minAllowedLength):
                        return String(format: "password_too_short".localized, minAllowedLength)
                    case .invalidFormat:
                        return "password_invalid_format".localized
                    }
                }
            }
            .sink(receiveValue: newPasswordHint.send)
            .store(in: &subscriptions)

        let textFields = Publishers.CombineLatest3(oldPasswordSubject, newPasswordSubject, repeatNewPasswordSubject)
        let hints = Publishers.CombineLatest(newPasswordHint, repeatNewPasswordHint)
        Publishers.CombineLatest(textFields, hints)
            .map { value in
                let (textFields, hints) = value
                let (oldPassword, newPassword, repeatNewPassword) = textFields
                let (newPasswordHint, repeatNewPasswordHint) = hints
                return UpdatePasswordState(
                    oldPassword: oldPassword,
                    newPassword: newPassword,
                    repeatNewPassword: repeatNewPassword,
                    newPasswordHint: newPasswordHint,
                    repeatNewPasswordHint: repeatNewPasswordHint
                )
            }
            .removeDuplicates()
            .sink(receiveValue: subject.send)
            .store(in: &subscriptions)

        return await withCheckedContinuation { continuation in
            self.flowContinuation = Continuation(continuation: continuation, willFinishHandler: willFinish)
            Task.detached { @MainActor in
                await self.presenter.presentPasswordEditing { [weak self] in
                    guard let self else { return }
                    await handle(result: .failure(.canceledManually))
                }
            }
        }
    }

    func updatePassword() async {
        guard subject.value.canConfirm else {
            return await presenter.errorHaptic()
        }
        let newPassword = repeatNewPasswordSubject.value
        switch await profileEditing.updatePassword(old: oldPasswordSubject.value, new: newPassword) {
        case .success:
            SecAddSharedWebCredential(
                "d5d29sfljfs1v5kq0382.apigw.yandexcloud.net" as CFString,
                profile.email as CFString,
                newPassword as CFString, { error in
                    print("\(error.debugDescription)")
                }
            )
            switch await profileRepository.getHostInfo() {
            case .success(let profile):
                await presenter.successHaptic()
                await presenter.presentSuccess()
                await handle(result: .success(profile))
            case .failure(let reason):
                switch reason {
                case .noConnection:
                    await presenter.presentNoConnection()
                case .notAuthorized:
                    await presenter.presentNotAuthorized()
                case .other(let error):
                    await presenter.presentInternalError(error)
                }
            }
        case .failure(let error):
            switch error {
            case .validationError:
                // TODO: separate wrong old password and wrong fmt cases ?
                await presenter.presentHint(message: "change_password_format_error".localized)
            case .other(let error):
                switch error {
                case .noConnection:
                    await presenter.presentNoConnection()
                case .notAuthorized:
                    await presenter.presentNotAuthorized()
                case .other(let error):
                    await presenter.presentInternalError(error)
                }
            }
        }
    }

    @MainActor
    func update(oldPassword: String) {
        oldPasswordSubject.send(oldPassword)
    }

    @MainActor
    func update(newPassword: String) {
        newPasswordSubject.send(newPassword)
    }

    @MainActor
    func update(repeatNewPassword: String) {
        repeatNewPasswordSubject.send(repeatNewPassword)
    }

    private func handle(result: Result<Profile, FailureReason>) async {
        guard let flowContinuation else {
            return
        }
        self.flowContinuation = nil
        await flowContinuation.willFinishHandler?(result)
        if case .failure(let error) = result, case .canceledManually = error {
        } else {
            await presenter.cancelPasswordEditing()
        }
        flowContinuation.continuation.resume(returning: result)
    }
}
