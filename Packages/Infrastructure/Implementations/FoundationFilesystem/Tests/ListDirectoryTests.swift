import Testing
import Foundation
import Filesystem
@testable import FoundationFilesystem

@Suite struct ListDirectoryTests {

    @Test(
        "List Directory With Any Mask",
        arguments: [
            [] as DirectoryMask,
            [.file],
            [.directory],
            [.file, .directory]
        ]
    )
    func ok(mask: DirectoryMask) {

        // given

        let sample = createSampleDirectoryWithContent()

        // when

        var content: [URL]
        do {
            content = try sample.manager.listDirectory(
                at: sample.directory,
                mask: mask
            )

        } catch {
            Issue.record("\(error)")
            return
        }

        // then

        if mask.contains(.directory) {
            let predicate: (URL) -> Bool = { $0.path() == sample.subdirectory.path() }
            #expect(content.filter(predicate).count == 1)
            content.removeAll(where: predicate)
        }
        if mask.contains(.file) {
            let predicate: (URL) -> Bool = { $0.path() == sample.file.path() }
            #expect(content.filter(predicate).count == 1)
            content.removeAll(where: predicate)
        }
        #expect(content.isEmpty)
    }

    @Test
    func failWhenDoesNotExists() {

        // given

        let manager = FoundationFileManager()
        let directory = URL(filePath: NSTemporaryDirectory())
            .appending(component: UUID().uuidString)

        // when

        do {
            let _ = try manager.listDirectory(
                at: directory,
                mask: []
            )
            Issue.record()
        } catch {
            guard case .noSuchDirectory = error else {
                Issue.record("\(error)")
                return
            }

            // then
        }
    }

    @Test
    func failWhenIsFileAtPath() {

        // given

        let manager = FoundationFileManager()
        let directory = URL(filePath: NSTemporaryDirectory())
            .appending(component: UUID().uuidString)
        try! manager.createFile(at: directory)

        // when

        do {
            let _ = try manager.listDirectory(
                at: directory,
                mask: []
            )
            Issue.record()
        } catch {
            guard case .urlIsReferringToFile = error else {
                Issue.record("\(error)")
                return
            }

            // then
        }
    }

    @Test
    func failInternalError() {

        // given

        let manager = FoundationFileManager()
        let directory = URL(filePath: NSTemporaryDirectory())
            .appending(component: UUID().uuidString)
        try! Foundation.FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0])

        // when

        do {
            let content = try manager.listDirectory(
                at: directory,
                mask: []
            )
            print("\(content)")
            Issue.record()
        } catch {
            guard case .internal = error else {
                Issue.record("\(error)")
                return
            }

            // then
        }
    }

    private struct SampleDirectoryWithContent {
        let manager: FoundationFileManager
        let directory: URL
        let file: URL
        let subdirectory: URL
    }

    private func createSampleDirectoryWithContent(
    ) -> SampleDirectoryWithContent {
        let directory = URL(filePath: NSTemporaryDirectory())
            .appending(component: UUID().uuidString)
        let manager = FoundationFileManager()
        try! manager.createDirectory(at: directory)
        let file = directory.appending(component: UUID().uuidString)
        let subdirectory = directory.appending(component: UUID().uuidString)
        try! manager.createFile(at: file)
        try! manager.createDirectory(at: subdirectory)
        return SampleDirectoryWithContent(
            manager: manager,
            directory: directory,
            file: file,
            subdirectory: subdirectory
        )
    }
}
