// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription
let package = Package(
    name: "AppBase",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "AppBase",
            targets: ["AppBase"]
        )
    ],
    dependencies: [
        .package(path: "../../Infrastructure/Base"),
        .package(path: "../../Infrastructure/Logging"),
        .package(path: "../../Domain/Domain"),
        .package(path: "../../DesignSystem"),
        .package(url: "https://github.com/Ekhoo/Device.git", from: "3.7.0"),
    ],
    targets: [
        .target(
            name: "AppBase",
            dependencies: [
                "Base",
                "Logging",
                "Domain",
                "DesignSystem",
                "Device",
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
            root = "../"
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
