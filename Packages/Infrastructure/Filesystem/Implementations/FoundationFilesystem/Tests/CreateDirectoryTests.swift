import Testing
import Foundation
import TestLogging
@testable import FoundationFilesystem

@Suite struct CreateDirectoryTests {
    @Test
    func ok() {

        // given

        let directory = URL(filePath: NSTemporaryDirectory())
            .appending(component: UUID().uuidString)
        let manager = FoundationFileManager(logger: TestLogger(prefix: #function))

        // when

        do {
            let created = try manager.createDirectory(at: directory)

            // then

            #expect(created)
        } catch {
            Issue.record("\(error)")
        }
    }

    @Test
    func successIfAlreadyExists() {

        // given

        let directory = URL(filePath: NSTemporaryDirectory())
            .appending(component: UUID().uuidString)
        let manager = FoundationFileManager(logger: TestLogger(prefix: #function))

        // when

        do {
            let created = try manager.createDirectory(at: directory)
            let createdSecondTime = try manager.createDirectory(at: directory)

            // then

            #expect(created && !createdSecondTime)
        } catch {
            Issue.record("\(error)")
        }
    }

    @Test
    func failWhenPathIsReferringToFile() {

        // given

        let directory = URL(filePath: NSTemporaryDirectory())
            .appending(component: UUID().uuidString)
        let manager = FoundationFileManager(logger: TestLogger(prefix: #function))
        try! manager.createFile(at: directory)

        // when

        do {
            try manager.createDirectory(at: directory)
            Issue.record()
        } catch {
            guard case .urlIsReferringToFile = error else {
                Issue.record()
                return
            }

            // then

        }
    }

    @Test
    func failWhenSomethingWrongWithUrl() {

        // given

        let parent = URL(filePath: NSTemporaryDirectory())
            .appending(component: UUID().uuidString)
        try! Foundation.FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true, attributes: [.posixPermissions: 0])
        let directory = parent.appending(component: UUID().uuidString)
        let manager = FoundationFileManager(logger: TestLogger(prefix: #function))

        // when

        do {
            try manager.createDirectory(at: directory)
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
