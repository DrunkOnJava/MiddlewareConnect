// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "MiddlewareConnect",
    platforms: [
        .macOS(.v12),
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "MiddlewareConnect",
            targets: ["MiddlewareConnect"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.6.1"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2")
    ],
    targets: [
        .target(
            name: "MiddlewareConnect",
            dependencies: ["Alamofire", "KeychainAccess"]
        ),
        .testTarget(
            name: "MiddlewareConnectTests",
            dependencies: ["MiddlewareConnect"],
            path: "Tests/MiddlewareConnectTests"
        ),
        .testTarget(
            name: "LLMServiceProviderTests",
            dependencies: ["MiddlewareConnect"],
            path: "Tests/LLMServiceProviderTests"
        )
    ]
)
