import Combine

extension Publisher where Self.Failure == Never {
    public func sink(receiveValue: @escaping ((Output) async -> Void)) -> AnyCancellable {
        sink { value in
            Task.detached {
                await receiveValue(value)
            }
        }
    }
}
