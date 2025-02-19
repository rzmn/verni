import Api
import Convenience
import AsyncExtensions
import Logging
import Foundation

actor SSEService {
    private let publisher: EventPublisher<RemoteUpdate>
    private let url: URL
    private var task: Task<Void, Never>?
    
    let logger: Logger
    private let taskFactory: TaskFactory
    private let session: URLSession
    
    init(
        taskFactory: TaskFactory, 
        logger: Logger, 
        endpoint: URL,
        session: URLSession = .shared
    ) async {
        self.logger = logger.with(prefix: "[sse] ")
        self.taskFactory = taskFactory
        self.session = session
        self.publisher = EventPublisher()
        self.url = endpoint.appendingPathComponent("/operationsQueue")
    }
    
    private func processEvents() async {
        do {
            let (stream, response) = try await session.bytes(from: url)
            
            guard
                let httpResponse = response as? HTTPURLResponse,
                (200...299).contains(httpResponse.statusCode)
            else {
                logE { "invalid response from SSE endpoint: \(response)" }
                return
            }
            
            for try await line in stream.lines {
                let prefix = "data: "
                guard line.hasPrefix(prefix) else { continue }
                
                let jsonData = line.dropFirst(prefix.count)
                
                do {
                    await publisher.notify(
                        .newOperationsAvailable(
                            try JSONDecoder().decode(
                                [Components.Schemas.SomeOperation].self,
                                from: Data(jsonData.utf8)
                            )
                        )
                    )
                } catch {
                    logE { "failed to decode SSE data error: \(error)" }
                }
            }
        } catch {
            logE { "SSE connection error: \(error)" }
        }
    }
}

extension SSEService: RemoteUpdatesService {
    var eventSource: any EventSource<RemoteUpdate> {
        publisher
    }
    
    func start() async {
        logI { "starting SSE service" }
        task = taskFactory.task { [weak self] in
            guard let self else { return }
            await processEvents()
        }
    }
    
    func stop() async {
        logI { "stopping SSE service" }
        task?.cancel()
        task = nil
    }
}

extension SSEService: Loggable {}
