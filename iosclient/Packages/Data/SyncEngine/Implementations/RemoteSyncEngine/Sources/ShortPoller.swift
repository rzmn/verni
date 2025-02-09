import Api
import Foundation
import AsyncExtensions
import Logging

protocol UpdatesListener: Sendable {
    func start(onReceive: @escaping @Sendable ([Components.Schemas.SomeOperation]) -> Void) async
    func stop() async
}

actor ShortPoller: UpdatesListener {
    let logger: Logger
    
    private let api: APIProtocol
    private let taskFactory: TaskFactory
    private var timer: Timer?
    private var callback: (@Sendable ([Components.Schemas.SomeOperation]) -> Void)?
    
    init(
        api: APIProtocol,
        logger: Logger,
        taskFactory: TaskFactory
    ) {
        self.api = api
        self.logger = logger
        self.taskFactory = taskFactory
    }
}

extension ShortPoller {
    func start(onReceive: @escaping @Sendable ([Components.Schemas.SomeOperation]) -> Void) {
        callback = onReceive
        
        stop()
        
        timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            taskFactory.task { [weak self] in
                guard let self else { return }
                await pull()
            }
        }
        
        taskFactory.task { [weak self] in
            guard let self else { return }
            await pull()
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        callback = nil
    }
    
    private func pull() async {
        logger.logW { "pulling updates..." }
        let response: Operations.PullOperations.Output
        do {
            response = try await api.pullOperations(
                .init(
                    query: .init(_type: .large)
                )
            )
        } catch {
            return logger.logW { "pull failed: \(error)" }
        }
        let operations: [Components.Schemas.SomeOperation]
        do {
            operations = try response.get()
        } catch {
            switch error {
            case .expected(let payload):
                return logW { "login finished with error: \(payload)" }
            case .undocumented(let statusCode, let payload):
                return logE { "login undocumented response code: \(statusCode), payload: \(payload)" }
            }
        }
    }
}

extension ShortPoller: Loggable {}
