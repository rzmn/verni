import Foundation
import VisionKit

@MainActor
class AddFriendByQrModel {
    enum FailureReason: Error {
        case canceledManually
        case alreadyRunning
        case internalError(Error)
    }

    private var scannerAvailable: Bool {
        DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }
    private let appRouter: AppRouter

    private var result: InternalUrl?
    private var continuation: CheckedContinuation<Result<InternalUrl, FailureReason>, Never>?

    init(appRouter: AppRouter) {
        self.appRouter = appRouter
    }

    func start() async -> Result<InternalUrl, FailureReason> {
        guard continuation == nil else {
            return .failure(.alreadyRunning)
        }
        let viewController = DataScannerViewController(
            recognizedDataTypes: [.barcode()],
            qualityLevel: .fast,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isHighlightingEnabled: true
        )
        viewController.delegate = self
        do {
            try viewController.startScanning()
        } catch {
            return .failure(.internalError(error))
        }
        await appRouter.present(viewController) {
            guard let continuation = self.continuation else { return }
            let result = self.result
            self.result = nil
            self.continuation = nil
            if let result {
                continuation.resume(returning: .success(result))
            } else {
                continuation.resume(returning: .failure(.canceledManually))
            }
        }
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }
}

extension AddFriendByQrModel: DataScannerViewControllerDelegate {
    func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
        Task {
            await handle(dataScanner: dataScanner, items: allItems)
        }
    }

    func dataScanner(_ dataScanner: DataScannerViewController, didUpdate updatedItems: [RecognizedItem], allItems: [RecognizedItem]) {
        Task {
            await handle(dataScanner: dataScanner, items: allItems)
        }
    }

    private func handle(dataScanner: DataScannerViewController, items: [RecognizedItem]) async {
        guard continuation != nil, result == nil else {
            return
        }
        for item in items {
            guard case .barcode(let barcode) = item else {
                continue
            }
            guard let url = barcode.payloadStringValue.flatMap(InternalUrl.init(string:)) else {
                continue
            }
            dataScanner.stopScanning()
            result = url
            await appRouter.pop(dataScanner)
            return
        }
    }
}
