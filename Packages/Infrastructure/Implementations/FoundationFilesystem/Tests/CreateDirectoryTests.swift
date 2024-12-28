import Testing
import Foundation
@testable import FoundationFilesystem

@Suite struct CreateDirectoryTests {

    @Test
    func ok() {

        // given

        let directory = URL(filePath: NSTemporaryDirectory())
            .appending(component: UUID().uuidString)
        let manager = FoundationFileManager()

        // when

        do {
            try manager.createDirectory(at: directory)

            // then

        } catch {
            Issue.record("\(error)")
        }
    }

    @Test
    func successIfAlreadyExists() {

        // given

        let directory = URL(filePath: NSTemporaryDirectory())
            .appending(component: UUID().uuidString)
        let manager = FoundationFileManager()

        // when

        do {
            try manager.createDirectory(at: directory)
            try manager.createDirectory(at: directory)

            // then

        } catch {
            Issue.record("\(error)")
        }
    }

    @Test
    func failWhenPathIsReferringToFile() {

        // given

        let directory = URL(filePath: NSTemporaryDirectory())
            .appending(component: UUID().uuidString)
        let manager = FoundationFileManager()
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
        let manager = FoundationFileManager()

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
