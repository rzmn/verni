public struct DirectoryMask: OptionSet, Sendable {
    public static let file = DirectoryMask(rawValue: 1 << 0)
    public static let directory = DirectoryMask(rawValue: 1 << 1)

    public let rawValue: Int
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}
