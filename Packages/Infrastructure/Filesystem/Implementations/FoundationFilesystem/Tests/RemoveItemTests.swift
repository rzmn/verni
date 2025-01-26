import Testing
import Foundation
import TestLogging
@testable import FoundationFilesystem

@Suite struct RemoveItemTests {

    @Test
    func okWhenItemIsFile() throws {

        // given

        let file = URL(filePath: NSTemporaryDirectory())
            .appending(component: UUID().uuidString)
        let manager = FoundationFileManager(logger: TestLogger(prefix: #function))
        try! manager.createFile(at: file)

        // when

        do {
            try manager.removeItem(at: file)

            // then

        } catch {
            Issue.record("\(error)")
        }
    }

    @Test
    func okWhenItemIsDirectory() throws {

        // given

        let directory = URL(filePath: NSTemporaryDirectory())
            .appending(component: UUID().uuidString)
        let manager = FoundationFileManager(logger: TestLogger(prefix: #function))
        try! manager.createDirectory(at: directory)

        // when

        do {
            try manager.removeItem(at: directory)

            // then

        } catch {
            Issue.record("\(error)")
        }
    }

    @Test
    func okWhenDoesNotExists() throws {

        // given

        let file = URL(filePath: NSTemporaryDirectory())
            .appending(component: UUID().uuidString)
        let manager = FoundationFileManager(logger: TestLogger(prefix: #function))

        // when

        do {
            try manager.removeItem(at: file)

            // then

        } catch {
            Issue.record("\(error)")
        }
    }

    @Test
    func failInternalError() throws {

        // given

        let file = URL(filePath: NSTemporaryDirectory())
            .appending(component: UUID().uuidString)
        try! Foundation.FileManager.default.createDirectory(at: file, withIntermediateDirectories: true, attributes: [.posixPermissions: 0])

        let manager = FoundationFileManager(logger: TestLogger(prefix: #function))

        // when

        do {
            try manager.removeItem(at: file)
            Issue.record()
        } catch {
            guard case .internal = error else {
                Issue.record()
                return
            }

            // then

        }
    }
}
