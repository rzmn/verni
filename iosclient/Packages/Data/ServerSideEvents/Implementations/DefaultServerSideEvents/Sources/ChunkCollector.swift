import Foundation
import Logging

enum ChunkCollectorOutput: Sendable {
    case badFormat
    case incomplete(String)
    case completed(String)
}

protocol ChunkCollector: Sendable {
    func onDataReceived(_ data: Data) async -> [ChunkCollectorOutput]
}
