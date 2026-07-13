// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacroLink",
    platforms: [.iOS(.v16)],
    products: [
        .executable(name: "MacroLink", targets: ["MacroLink"])
    ],
    targets: [
        .executableTarget(
            name: "MacroLink",
            path: "MacroLink",
            resources: [
                .process("Resources")
            ]
        )
    ]
)