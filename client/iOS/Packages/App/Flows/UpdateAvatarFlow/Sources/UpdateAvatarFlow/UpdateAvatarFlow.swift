import Domain
import DI
import AppBase
import UIKit
import AVKit

public actor UpdateAvatarFlow {
    private let router: AppRouter
    private let profileEditing: ProfileEditingUseCase
    private var pickPhotoDelegateAdapter: PickPhotoDelegateAdapter?
    private let presenter: UpdateAvatarFlowPresenter

    public init(di: ActiveSessionDIContainer, router: AppRouter) {
        self.router = router
        self.profileEditing = di.profileEditingUseCase()
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

    public enum TerminationEvent {
        case canceled
        case successfullySet
    }

    public func perform() async -> TerminationEvent {
        let result = await doPerform()
        return result
    }

    private func doPerform() async -> TerminationEvent {
        let photo: UIImage
        switch await pickPhoto() {
        case .failure(let error):
            switch error {
            case .canceledManually:
                return .canceled
            case .internalError:
                await presenter.presentInternalError(error)
                return .canceled
            }
        case .success(let image):
            photo = image
        }
        guard let ciImage = CIImage(image: photo) else {
            await presenter.presentWrongFormat()
            return .canceled
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
            return .canceled
        }
        await presenter.presentLoading()
        switch await profileEditing.setAvatar(imageData: data) {
        case .success:
            await presenter.successHaptic()
            await presenter.presentSuccess()
            return .successfullySet
        case .failure(let error):
            switch error {
            case .wrongFormat:
                await presenter.presentWrongFormat()
            case .other(let error):
                await presenter.presentGeneralError(error)
            }
            return .canceled
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
