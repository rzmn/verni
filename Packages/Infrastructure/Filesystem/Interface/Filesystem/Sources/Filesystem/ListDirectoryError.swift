public enum ListDirectoryError: Error, Sendable {
    case noSuchDirectory
    case urlIsReferringToFile
    case `internal`(Error)
}
