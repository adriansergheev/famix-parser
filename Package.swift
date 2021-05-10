// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "cli",
    platforms: [.macOS(.v10_15)],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.

//        .target(name: <#T##String#>, dependencies: <#T##[Target.Dependency]#>, path: <#T##String?#>, exclude: <#T##[String]#>, sources: <#T##[String]?#>, resources: <#T##[Resource]?#>, publicHeadersPath: <#T##String?#>, cSettings: <#T##[CSetting]?#>, cxxSettings: <#T##[CXXSetting]?#>, swiftSettings: <#T##[SwiftSetting]?#>, linkerSettings: <#T##[LinkerSetting]?#>)
        .target(
            name: "cli",
            dependencies: []
        ),
        .testTarget(
            name: "cliTests",
            dependencies: ["cli"])
    ]
)
