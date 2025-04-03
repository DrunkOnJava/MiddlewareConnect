// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MiddlewareConnect",
    platforms: [.iOS(.v16)],
    products: [
        .library(
            name: "MiddlewareConnect",
            targets: ["MiddlewareConnect"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.6.4"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
    ],
    targets: [
        .target(
            name: "MiddlewareConnect",
            dependencies: ["Alamofire", "KeychainAccess"],
            path: ".",
            exclude: ["Preview Content", "Info.plist"],
            resources: [
                .process("Assets.xcassets"),
                .process("Preview Content/Preview Assets.xcassets")
            ]),
        .testTarget(
            name: "MiddlewareConnectTests",
            dependencies: ["MiddlewareConnect"]),
    ]
)
