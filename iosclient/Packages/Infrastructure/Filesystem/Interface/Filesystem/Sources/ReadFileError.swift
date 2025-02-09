public enum ReadFileError: Error, Sendable {
    case noSuchFile
    case urlIsReferringToDirectory
    case `internal`(Error)
}
