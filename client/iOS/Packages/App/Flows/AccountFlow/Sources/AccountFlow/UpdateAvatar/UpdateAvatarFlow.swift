import Domain
import DI
import AppBase
import UIKit
import AVKit

actor UpdateAvatarFlow {
    private let router: AppRouter
    private let profileEditing: ProfileEditingUseCase
    private let profileRepository: UsersRepository
    private var pickPhotoDelegateAdapter: PickPhotoDelegateAdapter?
    private let presenter: UpdateAvatarFlowPresenter

    init(di: ActiveSessionDIContainer, router: AppRouter) {
        self.router = router
        self.profileEditing = di.profileEditingUseCase()
        self.profileRepository = di.usersRepository()
        self.presenter = UpdateAvatarFlowPresenter(router: router)
    }

    private func retainPickPhotoDelegateAdapter(_ adapter: PickPhotoDelegateAdapter?) {
        self.pickPhotoDelegateAdapter = adapter
    }
}

extension UpdateAvatarFlow: Flow {
    enum PickPhotoTerminationEvent: Error {
        case canceledManually
        case internalError
    }

    enum TerminationEvent: Error {
        case canceled
    }

    func perform(willFinish: ((Result<Profile, TerminationEvent>) async -> Void)?) async -> Result<Profile, TerminationEvent> {
        let result = await doPerform()
        await willFinish?(result)
        return result
    }

    private func doPerform() async -> Result<Profile, TerminationEvent> {
        let photo: UIImage
        switch await pickPhoto() {
        case .failure(let error):
            switch error {
            case .canceledManually:
                return .failure(.canceled)
            case .internalError:
                await presenter.presentInternalError(error)
                return .failure(.canceled)
            }
        case .success(let image):
            photo = image
        }
        guard let ciImage = CIImage(image: photo) else {
            await presenter.presentWrongFormat()
            return .failure(.canceled)
        }
        let cropped = ciImage
            .cropped(to: AVMakeRect(aspectRatio: CGSize(width: 1, height: 1), insideRect: ciImage.extent))
        let side: CGFloat = 256
        let scaled = cropped
            .transformed(
                by: CGAffineTransform(
                    scaleX: min(1, side / cropped.extent.width),
                    y: min(1, side / cropped.extent.height)
                )
            )
        guard let data = UIImage(ciImage: scaled).jpegData(compressionQuality: 0.6) else {
            await presenter.presentWrongFormat()
            return .failure(.canceled)
        }
        await presenter.presentLoading()
        switch await profileEditing.setAvatar(imageData: data) {
        case .success:
            switch await profileRepository.getHostInfo() {
            case .success(let profile):
                await presenter.presentSuccess()
                return .success(profile)
            case .failure(let error):
                switch error {
                case .noConnection:
                    await presenter.presentNoConnection()
                case .notAuthorized:
                    await presenter.presentNotAuthorized()
                case .other(let error):
                    await presenter.presentInternalError(error)
                }
                return .failure(.canceled)
            }
        case .failure(let error):
            switch error {
            case .wrongFormat:
                await presenter.presentWrongFormat()
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
            return .failure(.canceled)
        }
    }

    @MainActor
    func pickPhoto() async -> Result<UIImage, PickPhotoTerminationEvent> {
        let pickerViewController = UIImagePickerController()
        pickerViewController.allowsEditing = true
        let routable = AnyRoutable(controller: pickerViewController, name: "image picker")

        return await withCheckedContinuation { @MainActor continuation in
            let delegateAdapter = PickPhotoDelegateAdapter { result in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    await router.pop(pickerViewController)
                    await retainPickPhotoDelegateAdapter(nil)
                    switch result {
                    case .success(let image):
                        return continuation.resume(returning: .success(image))
                    case .failure(let error):
                        switch error {
                        case .canceledManually:
                            return continuation.resume(returning: .failure(.canceledManually))
                        case .internalError:
                            return continuation.resume(returning: .failure(.internalError))
                        }
                    }
                }
            }
            pickerViewController.delegate = delegateAdapter
            Task { @MainActor in
                await self.retainPickPhotoDelegateAdapter(delegateAdapter)
                await router.present(routable)
            }
        }
    }
}

extension UpdateAvatarFlow {
    private class PickPhotoDelegateAdapter: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let onImage: (Result<UIImage, PickPhotoTerminationEvent>) -> Void

        init(onData: @escaping (Result<UIImage, PickPhotoTerminationEvent>) -> Void) {
            self.onImage = onData
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onImage(.failure(.canceledManually))
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.editedImage] as? UIImage {
                onImage(.success(image))
            } else if let image = info[.originalImage] as? UIImage {
                onImage(.success(image))
            } else {
                return onImage(.failure(.internalError))
            }
        }
    }
}
