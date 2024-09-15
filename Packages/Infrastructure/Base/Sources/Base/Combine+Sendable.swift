import Combine

extension AnyPublisher: @retroactive @unchecked Sendable {}
extension PassthroughSubject: @retroactive @unchecked Sendable {}
extension Published.Publisher: @retroactive @unchecked Sendable where Value: Sendable {}

extension Publisher where Failure == Never, Output: Sendable {
    @MainActor public func sinkAssumingMainActor(onReceive: @MainActor @escaping (Output) -> Void) -> AnyCancellable {
        sink { output in
            MainActor.assumeIsolated {
                onReceive(output)
            }
        }
    }

    @MainActor public func weakSinkAssumingMainActor<T: AnyObject>(
        object: T,
        handler: @MainActor @escaping (T, Output) -> Void
    ) -> AnyCancellable {
        sink { [weak object] output in
            MainActor.assumeIsolated { [weak object] in
                guard let object else { return }
                handler(object, output)
            }
        }
    }
}

extension Publisher where Failure == Never, Output == Void {
    @MainActor public func weakSinkAssumingMainActor<T: AnyObject>(
        object: T,
        handler: @MainActor @escaping (T) -> @MainActor () -> Void
    ) -> AnyCancellable {
        sink { [weak object] output in
            MainActor.assumeIsolated { [weak object] in
                guard let object else { return }
                handler(object)()
            }
        }
    }
}
