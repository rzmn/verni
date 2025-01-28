import Testing
import Foundation
import TestLogging
@testable import FoundationFilesystem

@Suite struct CreateFileTests {

    @Test
    func ok() throws {

        // given

        let file = URL(filePath: NSTemporaryDirectory())
            .appending(component: UUID().uuidString)
        let manager = FoundationFileManager(logger: TestLogger(prefix: #function))

        // when

        do {
            try manager.createFile(at: file)

            // then

        } catch {
            Issue.record("\(error)")
        }
    }

    @Test
    func failIfAlreadyExists() {

        // given

        let file = URL(filePath: NSTemporaryDirectory())
            .appending(component: UUID().uuidString)
        let manager = FoundationFileManager(logger: TestLogger(prefix: #function))

        // when

        do {
            try manager.createFile(at: file)
            try manager.createFile(at: file)

            Issue.record()
        } catch {
            guard case .alreadyExists = error else {
                Issue.record()
                return
            }

            // then

        }
    }

    @Test
    func failWhenPathIsReferringToDirectory() {

        // given

        let directory = URL(filePath: NSTemporaryDirectory())
            .appending(component: UUID().uuidString)
        let manager = FoundationFileManager(logger: TestLogger(prefix: #function))
        try! manager.createDirectory(at: directory)

        // when

        do {
            try manager.createFile(at: directory)
            Issue.record()
        } catch {
            guard case .urlIsReferringToDirectory = error else {
                Issue.record()
                return
            }

            // then

        }
    }

    @Test
    func failWhenSomethingWrongWithUrl() {

        // given

        let directory = URL(filePath: NSTemporaryDirectory())
            .appending(component: UUID().uuidString)
        try! Foundation.FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0])
        let file = directory.appending(component: UUID().uuidString)
        let manager = FoundationFileManager(logger: TestLogger(prefix: #function))

        // when

        do {
            try manager.createFile(at: file)
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
