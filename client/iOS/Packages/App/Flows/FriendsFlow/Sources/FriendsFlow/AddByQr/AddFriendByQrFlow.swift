import Foundation
import VisionKit
import AppBase

actor AddFriendByQrFlow {
    public static func isAvailable() async -> Bool {
        let supported = await DataScannerViewController.isSupported
        let available = await DataScannerViewController.isAvailable
        return supported && available
    }

    private let router: AppRouter
    private var dataScannerDelegateAdapter: DataScannerDelegateAdapter?
    private var continuation: Continuation?

    init(router: AppRouter) async {
        self.router = router
        dataScannerDelegateAdapter = await DataScannerDelegateAdapter { [weak self] url, scanner in
            guard let self else { return }
            await handle(result: .success(url), dataScannerToDismiss: scanner)
        }
    }
}

extension AddFriendByQrFlow: Flow {
    enum TerminationEvent: Error {
        case canceledManually
        case internalError(Error)
    }

    func perform() async -> Result<AppUrl, TerminationEvent> {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            Task.detached { @MainActor [weak self] in
                await self?.presentDataScanner()
            }
        }
    }

    @MainActor
    private func presentDataScanner() async {
        let viewController = DataScannerViewController(
            recognizedDataTypes: [.barcode()],
            qualityLevel: .fast,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isHighlightingEnabled: true
        )
        viewController.delegate = await dataScannerDelegateAdapter
        do {
            try viewController.startScanning()
        } catch {
            return await handle(result: .failure(.internalError(error)))
        }
        let routable = AnyRoutable(controller: viewController, name: "qr scanner")
        await router.present(routable) { [weak self] in
            await self?.handle(result: .failure(.canceledManually))
        }
    }

    private func handle(result: Result<AppUrl, TerminationEvent>, dataScannerToDismiss: DataScannerViewController? = nil) async {
        guard let continuation else { return }
        self.continuation = nil
        if let dataScannerToDismiss {
            await router.pop(dataScannerToDismiss)
        }
        continuation.resume(returning: result)
    }
}

extension AddFriendByQrFlow {
    private class DataScannerDelegateAdapter: NSObject, DataScannerViewControllerDelegate {
        private let onData: @MainActor (AppUrl, DataScannerViewController) async -> Void

        init(onData: @escaping @MainActor (AppUrl, DataScannerViewController) async -> Void) {
            self.onData = onData
        }

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
            for item in items {
                guard case .barcode(let barcode) = item else {
                    continue
                }
                guard let url = barcode.payloadStringValue.flatMap(AppUrl.init(string:)) else {
                    continue
                }
                dataScanner.stopScanning()
                return await onData(url, dataScanner)
            }
        }
    }
}
