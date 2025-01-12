import Foundation

struct PrinterWithCurrentDate: Printer {
    private let formatter: DateFormatter

    init() {
        let formatter = DateFormatter()
#if DEBUG
        formatter.dateFormat = "HH:mm:ss"
#else
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
#endif
        self.formatter = formatter
    }

    // swiftlint:disable:next no_direct_standard_out_logs
    func print(_ message: String) {
#if DEBUG
        // swiftlint:disable:next no_direct_standard_out_logs
        Swift.print("[verni] \(formatter.string(from: Date())) \(message)")
#else
        // swiftlint:disable:next no_direct_standard_out_logs
        Swift.print("\(formatter.string(from: Date())) \(message)")
#endif

    }
}
