// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription
let package = Package(
    name: "RemoteSyncEngine",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "RemoteSyncEngine",
            targets: ["RemoteSyncEngine"]
        )
    ],
    dependencies: [
        .package(path: "../Api"),
        .package(path: "../PersistentStorage"),
        .package(path: "../SyncEngine"),
        .package(path: "../../Infrastructure/Base"),
        .package(path: "../../Infrastructure/Logging"),
        .package(path: "../../Infrastructure/AsyncExtensions"),
    ],
    targets: [
        .target(
            name: "RemoteSyncEngine",
            dependencies: [
                "Api",
                "SyncEngine",
                "PersistentStorage",
                "Base",
                "Logging",
                "AsyncExtensions",
            ]
        )
    ]
)

// autogen_script_content (/Users/rzmn/Projects/verni/swiftverni/Scripts/package_swift_autogen.sh) start - do not modify
extension Package.Dependency {
    enum TargetType {
        case interface(String)
        case implementation(interface: String, implementation: String)
    }

    enum LocalPackage {
        case currentLayer(TargetType)
    }

    static func local(_ localPackage: LocalPackage) -> Package.Dependency {
        let root: String
        let type: TargetType
        switch localPackage {
        case .currentLayer(let targetType):
            root = "../../"
            type = targetType
        }
        switch type {
        case .interface(let interface):
            return .package(path: "\(root)/\(interface)/Interface/\(interface)")
        case .implementation(let interface, let implementation):
            return .package(path: "\(root)/\(interface)/Implementations/\(implementation)")
        }
    }
}
// autogen_script_content (/Users/rzmn/Projects/verni/swiftverni/Scripts/package_swift_autogen.sh) end - do not modify
